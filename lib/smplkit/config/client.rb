# frozen_string_literal: true

# The Smpl Config client — one unified +ConfigClient+.
#
# Smpl Config has two surfaces on a single client, mirroring how the audit and
# jobs clients expose their full surface from one class:
#
# * *Management surface* — pure CRUD, no live connection: +new+ / +get+ /
#   +list+ / +delete+ and the discovery buffer (+register_config+ /
#   +register_config_item+ / +flush+ / +pending_count+). The client owns the
#   discovery buffer directly.
# * *Live surface* — lazily connects to your running service on first use:
#   +subscribe+ (a live dict-like +LiveConfigProxy+), +get_value+ (an ad-hoc
#   resolved read), +bind+ (a live Struct/Hash binding), +on_change+, and
#   +refresh+. The first live call transparently flushes discovery, fetches and
#   resolves every config into the local cache, and opens the live-updates
#   WebSocket — no explicit install step.
#
# The client supports two construction shapes:
#
# * *Wired* into +Smplkit::Client+ — borrows the parent's config transport for
#   both runtime fetch and CRUD and the parent's shared WebSocket for the live
#   channel. This is the common path.
# * *Standalone* — +ConfigClient.new(api_key: ..., base_url: ..., ...)+ builds
#   and owns its own config transport, and on first live use opens and owns its
#   own WebSocket. +close+ tears down only the owned transport and owned
#   WebSocket.
module Smplkit
  module Config
    # Module-level helpers for the config client. Extracted so they can be
    # unit-tested without spinning up the full client.
    module Discovery
      module_function

      # Map a runtime value to a Config item type. Used both when binding a
      # Hash/Struct target and when supplying a default to +get_value(id, key,
      # default)+. +true+/+false+ are checked first because Ruby's
      # +Numeric+/+Integer+ tests would not accidentally claim them.
      def value_to_item_type(value)
        case value
        when true, false then "BOOLEAN"
        when Numeric then "NUMBER"
        else "STRING"
        end
      end

      # Walk a bound target, returning +[key, type, value, description]+ tuples
      # flattened to dot-notation. Nested Hashes / Structs are descended into;
      # everything else is treated as an opaque leaf.
      def iter_items(target, prefix: "")
        if target.is_a?(Hash)
          iter_hash_items(target, prefix: prefix)
        elsif target.is_a?(Struct)
          iter_struct_items(target, prefix: prefix)
        else
          []
        end
      end

      def iter_hash_items(hash, prefix: "")
        out = []
        hash.each do |raw_key, value|
          flat_key = "#{prefix}#{raw_key}"
          if value.is_a?(Hash) || value.is_a?(Struct)
            out.concat(iter_items(value, prefix: "#{flat_key}."))
          else
            out << [flat_key, value_to_item_type(value), value, nil]
          end
        end
        out
      end

      def iter_struct_items(struct, prefix: "")
        out = []
        struct.members.each do |member|
          value = struct[member]
          flat_key = "#{prefix}#{member}"
          if value.is_a?(Hash) || value.is_a?(Struct)
            out.concat(iter_items(value, prefix: "#{flat_key}."))
          else
            out << [flat_key, value_to_item_type(value), value, nil]
          end
        end
        out
      end

      # Apply a server-pushed value to a bound target in place. Walks the
      # dotted key path to the leaf's parent and assigns the value via
      # +Hash#[]=+ or +Struct#[]=+. Bails silently if any intermediate is
      # missing or not a supported container — the server may have items that
      # don't line up with what the bound target declared.
      def apply_change_to_target(target, dotted_key, value)
        parts = dotted_key.split(".")
        current = walk_to_leaf_parent(target, parts[0..-2])
        return if current.nil?

        last = parts.last
        if current.is_a?(Struct)
          assign_struct_member(current, last, value)
        elsif current.is_a?(Hash)
          current[last] = value
        end
      end

      def walk_to_leaf_parent(target, parts)
        current = target
        parts.each do |part|
          case current
          when Struct
            sym = part.to_sym
            return nil unless current.members.include?(sym)

            current = current[sym]
          when Hash
            return nil unless current.key?(part)

            current = current[part]
          else
            return nil
          end
        end
        current
      end

      def assign_struct_member(struct, name, value)
        sym = name.to_sym
        return unless struct.members.include?(sym)

        struct[sym] = value
      end
    end

    # Describes a single config value change. Frozen — fields are set at
    # construction and cannot be mutated afterward.
    class ConfigChangeEvent
      attr_reader :config_id, :item_key, :old_value, :new_value, :source

      def initialize(config_id:, item_key:, old_value:, new_value:, source:)
        @config_id = config_id
        @item_key = item_key
        @old_value = old_value
        @new_value = new_value
        @source = source
        freeze
      end

      def ==(other)
        other.is_a?(ConfigChangeEvent) &&
          config_id == other.config_id && item_key == other.item_key &&
          old_value == other.old_value && new_value == other.new_value &&
          source == other.source
      end
      alias eql? ==

      def hash = [config_id, item_key, old_value, new_value, source].hash
    end

    # A live, read-only, dict-like view of a config's resolved values.
    #
    # Returned by +ConfigClient#subscribe+. Always reflects the latest
    # server-pushed state — every read sees current values.
    #
    # Supports +[]+, +key?+, +keys+, +values+, +each_pair+, +to_h+, +size+, and
    # method-style attribute access for keys that don't collide with built-in
    # method names. Use subscript (+proxy["values"]+) for keys that do collide.
    #
    # For typed access via a Struct schema, use +ConfigClient#bind+ — bound
    # objects stay live on the same cache, with no proxy indirection.
    class LiveConfigProxy
      # Methods that live on the proxy itself; never resolved against the
      # cached values dictionary.
      OWN_METHODS = %i[config_id keys values each_pair each items to_h size length
                       key? include? has_key? on_change get].freeze

      def initialize(client, config_id)
        @client = client
        @config_id = config_id
      end

      attr_reader :config_id

      def keys = current_values.keys
      def values = current_values.values
      def each_pair(&) = current_values.each_pair(&)
      alias each each_pair
      def items = current_values.to_a
      def to_h = current_values.dup
      def size = current_values.size
      alias length size
      def key?(key) = current_values.key?(key.to_s)
      alias include? key?
      alias has_key? key?

      def [](key)
        current_values[key.to_s]
      end

      def get(key, default = nil)
        values = current_values
        values.key?(key.to_s) ? values[key.to_s] : default
      end

      def on_change(item_key = nil, &)
        if item_key.nil?
          @client.on_change(@config_id, &)
        else
          @client.on_change(@config_id, item_key: item_key.to_s, &)
        end
      end

      def respond_to_missing?(name, include_private = false)
        return true if OWN_METHODS.include?(name)

        current_values.key?(name.to_s) || super
      end

      def method_missing(name, *args)
        snapshot = current_values
        key = name.to_s
        return snapshot[key] if snapshot.key?(key) && args.empty?

        super
      end

      def to_s = "#<Smplkit::Config::LiveConfigProxy config_id=#{@config_id.inspect}>"
      alias inspect to_s

      private

      def current_values
        @client._cached_values(@config_id)
      end
    end

    # Normalize a +parent+ argument to a config id string.
    def self.resolve_parent_id(parent)
      return parent if parent.nil? || parent.is_a?(String)
      if parent.id.nil? || parent.id == ""
        raise ArgumentError, "parent config must be saved (have an id) before being used as a parent"
      end

      parent.id
    end

    # Build a standalone config transport and resolve the app base URL.
    #
    # +base_url+/+api_key+ are used directly when supplied (the path a top-level
    # client takes after it has already resolved them); otherwise the
    # management config resolver fills in whatever is missing (+~/.smplkit+ /
    # env vars / defaults). The app base URL is returned alongside so a
    # standalone client can open its own WebSocket against the event gateway.
    def self.config_transport(api_key:, base_url:, profile:, base_domain:, scheme:, debug:, extra_headers:)
      cfg = ConfigResolution.resolve_management_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme, debug: debug
      )
      resolved_key = api_key.nil? ? cfg.api_key : api_key
      merged = {}
      merged.merge!(cfg.extra_headers || {})
      merged.merge!(extra_headers || {})
      tcfg = ConfigResolution::ResolvedManagementConfig.new(
        api_key: resolved_key, base_domain: cfg.base_domain, scheme: cfg.scheme,
        debug: cfg.debug, extra_headers: merged
      )
      app_url = ConfigResolution.service_url(cfg.scheme, "app", cfg.base_domain)
      transport = Transport.build_api_client(SmplkitGeneratedClient::Config, "config", tcfg, base_url: base_url)
      [transport, app_url, resolved_key]
    end

    # The Smpl Config client (sync).
    #
    # One client exposes the full surface, reachable as +client.config+
    # (+Smplkit::Client+) or constructed directly:
    #
    #   config = Smplkit::ConfigClient.new(environment: "production")
    #   billing = config.new("billing", name: "Billing")
    #   billing.set_number("max_seats", 50)
    #   billing.save
    #   proxy = config.subscribe("billing")
    #   puts proxy["max_seats"]
    #
    # The management surface (+new+ / +get+ / +list+ / +delete+ and discovery)
    # is pure CRUD. The live surface (+subscribe+ / +get_value+ / +bind+ /
    # +on_change+ / +refresh+) connects lazily on first use — the first call
    # flushes discovery, fetches and resolves all configs into the local cache,
    # and opens the live-updates WebSocket. No explicit install step is
    # required.
    class ConfigClient
      # Sentinel distinguishing "no default supplied" from an explicit +nil+
      # default in +#get_value+.
      MISSING = Object.new.freeze
      private_constant :MISSING

      def initialize(api_key = nil, environment: nil, base_url: nil, profile: nil,
                     base_domain: nil, scheme: nil, debug: nil, extra_headers: nil,
                     parent: nil, transport: nil, metrics: nil)
        @parent = parent
        @metrics = metrics
        @environment = parent.nil? ? environment : parent._environment
        @service = parent&._service
        @standalone_api_key = nil
        if transport.nil?
          @http, @app_base_url, @standalone_api_key = Smplkit::Config.config_transport(
            api_key: api_key, base_url: base_url, profile: profile,
            base_domain: base_domain, scheme: scheme, debug: debug, extra_headers: extra_headers
          )
          @owns_transport = true
        else
          @http = transport
          @app_base_url = nil
          @owns_transport = false
        end
        @api = SmplkitGeneratedClient::Config::ConfigsApi.new(@http)

        # Discovery buffer is owned by this client (no management delegation).
        @buffer = ConfigRegistrationBuffer.new

        # Live-surface state.
        @config_cache = {}      # config_id -> { item_key => resolved_value }
        @raw_config_store = {}  # config_id -> Config
        @proxies = {}           # config_id -> LiveConfigProxy
        @bindings = {}          # config_id -> Hash | Struct (bound target)
        # Parent config id each binding was bound under (nil for roots) —
        # drives in-memory cache seeding through the bound parent chain.
        @bound_parents = {}
        @connected = false
        @lock = Mutex.new
        @listeners = [] # [callback, config_id_or_nil, item_key_or_nil]
        @ws_manager = nil
        @owns_ws = false
      end

      # ----------------------------------------------------------------
      # Management surface: CRUD (no live connection)
      # ----------------------------------------------------------------

      # Return a new unsaved +Config+. Call +Config#save+ to persist.
      #
      # +parent+ accepts either a config id (string) or an existing +Config+
      # instance — passing the instance lets you skip naming the id explicitly
      # when you already have the parent in scope.
      def new(id, name: nil, description: nil, parent: nil)
        Config.new(
          self,
          key: id,
          name: name || Smplkit::Helpers.key_to_display_name(id),
          description: description,
          parent_id: Smplkit::Config.resolve_parent_id(parent)
        )
      end

      # Fetch the editable +Config+ resource by id.
      #
      # Raises +NotFoundError+ if no config with that id exists.
      def get(id)
        response = ApiSupport::ErrorMapping.call { @api.get_config(id) }
        Helpers.config_from_json(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      # List configs for the authenticated account.
      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_configs(opts) }
        (response.data || []).map { |r| Helpers.config_from_json(self, ApiSupport::ResourceShim.from_model(r)) }
      end

      # Delete a config by id.
      def delete(id)
        ApiSupport::ErrorMapping.call { @api.delete_config(id) }
        nil
      end

      def _create_config(config)
        response = ApiSupport::ErrorMapping.call { @api.create_config(config_body(config)) }
        Helpers.config_from_json(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      def _update_config(config)
        response = ApiSupport::ErrorMapping.call { @api.update_config(config.key, config_body(config)) }
        Helpers.config_from_json(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      # ----------------------------------------------------------------
      # Management surface: discovery buffer (owned directly)
      # ----------------------------------------------------------------

      # Queue a configuration declaration for bulk-discovery upload.
      def register_config(config_id, service:, environment:, parent: nil, name: nil, description: nil)
        @buffer.declare(config_id, service: service, environment: environment,
                                   parent: parent, name: name, description: description)
        trigger_background_flush_if_needed
      end

      # Queue a config item declaration. +register_config+ must run first.
      def register_config_item(config_id, item_key, item_type, default, description = nil)
        @buffer.add_item(config_id, item_key, item_type, default, description)
        trigger_background_flush_if_needed
      end

      # POST pending declarations to +/api/v1/configs/bulk+.
      #
      # Per ADR-024 §2.9, bulk registration always lands rows as
      # +managed=false+ and is plan-limit-exempt — failures here never
      # propagate to customer code. Drained entries are not requeued; the SDK
      # will re-observe on the next process start.
      def flush
        batch = @buffer.drain
        return if batch.empty?

        body = build_config_bulk_request(batch)
        begin
          ApiSupport::ErrorMapping.call { @api.bulk_register_configs(body) }
        rescue StandardError => e
          # Fire-and-forget per ADR-024 §2.9.
          Smplkit.debug("registration", "config bulk register failed: #{e.class}: #{e.message}")
        end
      end

      # Number of pending config declarations awaiting flush.
      def pending_count
        @buffer.pending_count
      end

      # ----------------------------------------------------------------
      # Live surface: bind, subscribe, get_value
      # ----------------------------------------------------------------

      # Bind a Hash or Struct to a config id; return the same object back, live.
      #
      # Declarative, code-first API. Two flavors:
      #
      # * +Hash+: keys present are leaves to register, with their values as the
      #   in-code defaults. Nested Hashes flatten to dot-notation. Keys the
      #   caller wants to inherit from +parent:+ are simply omitted.
      # * +Struct+: every member is registered as an explicit override. Ruby
      #   Structs do not track which members were "explicitly set" vs defaulted,
      #   so there is no Hash-style omit-to-inherit. For omit-to-inherit, use a
      #   Hash target.
      #
      # On first boot the schema and values are registered with the server. The
      # local cache is then seeded so reads work immediately: if the config
      # already exists server-side (fetched on connect) its values are
      # authoritative and synced onto the bound object; if it is brand-new, the
      # cache entry is seeded in-memory from the bound object's values resolved
      # through its bound parent chain (no network round-trip). On every
      # WebSocket-delivered change thereafter the bound object is mutated in
      # place. Readers always see the current resolved value with no proxy
      # indirection.
      #
      # Idempotent. Repeated calls with the same +id+ return the
      # originally-bound object; the new +config+ argument is ignored.
      #
      # Connects lazily on first use — no explicit install step.
      def bind(id, config, parent: nil)
        ensure_connected
        unless config.is_a?(Hash) || config.is_a?(Struct)
          raise TypeError, "bind() requires a Hash or Struct; got #{config.class.name}"
        end

        return @bindings[id] if @bindings.key?(id)

        parent_id = register_binding_declaration(id, config, parent)

        # Register the binding BEFORE syncing so WebSocket dispatch finds it.
        @bindings[id] = config
        @bound_parents[id] = parent_id
        seed_or_sync_binding(id, config)
        config
      end

      # Return a live, dict-like +LiveConfigProxy+ for a config id.
      #
      # The proxy always reflects the latest resolved values; reads happen
      # through it (+proxy["key"]+, +proxy.get("key", default)+). Subscribing
      # registers the config declaration for code-first observability so the
      # reference appears in the smplkit console.
      #
      # Connects lazily on first use — no explicit install step. Raises
      # +NotFoundError+ if the config is unknown.
      def subscribe(id)
        ensure_connected
        observe_config_declaration(id, parent: nil, name: nil, description: nil)
        in_cache = @lock.synchronize { @config_cache.key?(id) }
        raise Smplkit::NotFoundError, "Config with id '#{id}' not found" unless in_cache

        @metrics&.record("config.resolutions", unit: "resolutions", dimensions: { "config" => id })
        cached_proxy(id)
      end

      # Read a single resolved config value (inheritance-aware).
      #
      # The value comes from the locally-cached resolved chain, so parent
      # configs are already folded in.
      #
      # Two forms:
      #
      # * +get_value(id, key)+ returns the resolved value. Raises +NotFoundError+
      #   if the config is unknown and +KeyError+ if the key is absent.
      # * +get_value(id, key, default)+ returns the resolved value, falling back
      #   to +default+ if the config or key is missing. Never raises.
      #   *Registers* the config (if new) and the key (inferred type, +default+
      #   as default) for code-first observability, so the reference appears in
      #   the smplkit console.
      #
      # For a live dict-like view use +#subscribe+; for typed access via a
      # Struct schema use +#bind+. Connects lazily on first use — no explicit
      # install step.
      def get_value(id, key, default = MISSING)
        ensure_connected
        key = key.to_s
        has_default = !default.equal?(MISSING)
        if has_default
          # Register the config + key so the reference shows up in the console
          # even if it's never been declared via bind(). The buffer is
          # idempotent at the (config_id, item_key) level.
          observe_config_declaration(id, parent: nil, name: nil, description: nil)
          observe_item_declaration(id, key, Discovery.value_to_item_type(default), default, nil)
        end

        values = @lock.synchronize { @config_cache[id]&.dup }
        if values.nil?
          return default if has_default

          raise Smplkit::NotFoundError, "Config with id '#{id}' not found"
        end
        unless values.key?(key)
          return default if has_default

          raise KeyError, "Config item '#{key}' not found in config '#{id}'"
        end
        values[key]
      end

      # Register a change listener.
      #
      # Three forms:
      #
      #   client.config.on_change { |event| ... }                          # global
      #   client.config.on_change("id") { |event| ... }                    # config-scoped
      #   client.config.on_change("id", item_key: "key") { |event| ... }   # item-scoped
      #
      # Connects lazily on first use — no explicit install step.
      def on_change(config_id = nil, item_key: nil, &block)
        ensure_connected
        raise ArgumentError, "on_change requires a block" unless block

        @listeners << [block, config_id, item_key&.to_s]
        block
      end

      # Re-fetch all configs and update resolved values, firing change
      # listeners for anything that differs from the previous state.
      #
      # Connects lazily on first use — no explicit install step.
      def refresh
        ensure_connected
        do_refresh("manual")
      end

      # Release resources — only those this client owns.
      #
      # Tears down the owned WebSocket (opened by a standalone client on first
      # live use) and the owned HTTP transport (standalone construction). A
      # wired client borrows the parent's transport and WebSocket and closes
      # neither.
      def close
        if @owns_ws && @ws_manager
          @ws_manager.stop
          @ws_manager = nil
          @owns_ws = false
        end
        nil
      end
      alias _close close

      # Construct, yield to the block, and close on exit.
      def self.open(**kwargs)
        client = new(**kwargs)
        begin
          yield client
        ensure
          client.close
        end
      end

      # Internal: return (a copy of) the resolved values for a config id.
      # Used by +LiveConfigProxy+.
      def _cached_values(config_id)
        @lock.synchronize { (@config_cache[config_id] || {}).dup }
      end

      # Internal: trigger lazy connect. Used by +Client#wait_until_ready+.
      def _ensure_connected
        ensure_connected
      end

      private

      # ----------------------------------------------------------------
      # Live surface: lazy connect + transport / WebSocket helpers
      # ----------------------------------------------------------------

      def ensure_ws
        return @parent._ensure_ws unless @parent.nil?

        if @ws_manager.nil?
          @ws_manager = SharedWebSocket.new(
            app_base_url: @app_base_url, api_key: @standalone_api_key, metrics: @metrics
          )
          @ws_manager.start
          @owns_ws = true
        end
        @ws_manager
      end

      # Open the live connection to the running Smpl Config service.
      #
      # Flushes any buffered discovery declarations, fetches and resolves every
      # config for the configured environment into the local cache, opens the
      # shared WebSocket, and subscribes to +config_changed+ / +config_deleted+
      # / +configs_changed+ events.
      #
      # Idempotent and internal — every live method calls it on first use, so
      # the live surface auto-connects with no explicit step.
      def ensure_connected
        @parent&._ensure_started
        return if @connected

        # Flush any buffered discovery declarations BEFORE the initial fetch, so
        # newly-discovered configs appear in the cache on first read.
        begin
          flush
        rescue StandardError => e
          Smplkit.debug("config", "discovery flush before connect failed: #{e.class}: #{e.message}")
        end

        # Fetch + resolve + cache + fire change listeners (against empty
        # old_cache, so any registered listeners see "initial" events).
        do_refresh("initial")
        @connected = true

        @ws_manager = ensure_ws
        @ws_manager.on("config_changed") { |data| handle_config_changed(data) }
        @ws_manager.on("config_deleted") { |data| handle_config_deleted(data) }
        @ws_manager.on("configs_changed") { |data| handle_configs_changed(data) }
      end

      # List configs directly from the API for the runtime cache.
      def fetch_all_configs
        rows = ApiSupport::PaginatedFetch.collect { |opts| @api.list_configs(opts) }
        rows.map { |r| Helpers.config_from_json(nil, ApiSupport::ResourceShim.from_model(r)) }
      end

      # Fetch a single config from the API. Returns +nil+ on missing data.
      def fetch_config(config_id)
        response = ApiSupport::ErrorMapping.call { @api.get_config(config_id) }
        Helpers.config_from_json(nil, ApiSupport::ResourceShim.from_model(response.data))
      end

      # ----------------------------------------------------------------
      # Internal: binding helpers
      # ----------------------------------------------------------------

      # Validate the parent, register the config + item declarations. Returns
      # the resolved parent config id (or +nil+).
      def register_binding_declaration(id, config, parent)
        parent_id = nil
        unless parent.nil?
          parent_id = config_id_for(parent)
          if parent_id.nil?
            raise ArgumentError,
                  "bind(): parent must be an object previously returned from client.config.bind(). " \
                  "Bind the parent first."
          end
        end

        if config.is_a?(Struct)
          class_name = config.class.name
          config_name = class_name&.split("::")&.last
        else
          # Hash bind: no class to introspect for name/description.
          config_name = nil
        end

        observe_config_declaration(id, parent: parent_id, name: config_name, description: nil)

        Discovery.iter_items(config).each do |item_key, item_type, value, description|
          observe_item_declaration(id, item_key, item_type, value, description)
        end
        parent_id
      end

      # Return the config_id this target was bound under, or nil.
      def config_id_for(target)
        @bindings.each { |cid, bound| return cid if bound.equal?(target) }
        nil
      end

      # Apply current cached values to a freshly-bound target.
      #
      # Handles the existing-config case: on restart, server-side values
      # override the in-code defaults from the constructor (or Hash).
      def sync_target_from_cache(target, config_id)
        cache = @lock.synchronize { (@config_cache[config_id] || {}).dup }
        cache.each do |dotted_key, value|
          Discovery.apply_change_to_target(target, dotted_key, value)
        end
      end

      # Seed the resolved cache for a freshly-bound config, or sync from it.
      #
      # If +config_id+ is already in the resolved cache it existed server-side
      # (fetched on connect), so server values are authoritative — sync them
      # onto the bound object. Otherwise the config is brand-new: seed
      # +config_cache[config_id]+ in-memory by resolving this object's values
      # through its bound parent chain, so +#subscribe+ / +#get_value+ work
      # immediately with no flush or refresh. Pure in-memory — no network.
      def seed_or_sync_binding(config_id, target)
        already_present = @lock.synchronize { @config_cache.key?(config_id) }
        if already_present
          sync_target_from_cache(target, config_id)
          return
        end
        seeded = resolve_bound_chain(config_id)
        @lock.synchronize { @config_cache[config_id] = seeded }
      end

      # Resolve a bound config's values through its bound parent chain.
      #
      # Walks +bound_parents+ from the child up through already-bound ancestors,
      # flattening each bound object's in-code values, then runs the same
      # deep-merge resolve used everywhere else (child wins over parent).
      # Ancestors that aren't bound objects stop the walk.
      def resolve_bound_chain(config_id)
        chain = []
        current = config_id
        seen = {}
        while !current.nil? && @bindings.key?(current) && !seen.key?(current)
          seen[current] = true
          items = bound_items_to_flat(@bindings[current])
          chain << { "items" => items, "environments" => {} }
          current = @bound_parents[current]
        end
        Helpers.resolve_chain(chain, @environment)
      end

      # Flatten a bound Struct or Hash to +{dotted_key => value}+. Mirrors the
      # discovery-declaration walk. Used to seed the local resolved cache from
      # in-memory bindings without any network round-trip.
      def bound_items_to_flat(target)
        Discovery.iter_items(target).each_with_object({}) do |(item_key, _type, value, _desc), out|
          out[item_key] = value
        end
      end

      def cached_proxy(config_id)
        @lock.synchronize { @proxies[config_id] ||= LiveConfigProxy.new(self, config_id) }
      end

      # Queue a config declaration with the owned discovery buffer.
      def observe_config_declaration(config_id, parent:, name:, description:)
        register_config(config_id, service: @service, environment: @environment,
                                   parent: parent, name: name, description: description)
      end

      # Queue a config item declaration with the owned discovery buffer.
      def observe_item_declaration(config_id, item_key, item_type, default, description)
        register_config_item(config_id, item_key, item_type, default, description)
      end

      def trigger_background_flush_if_needed
        return unless @buffer.pending_count >= CONFIG_BATCH_FLUSH_SIZE

        Thread.new do
          flush
        rescue StandardError => e
          Smplkit.debug("registration", "threshold config flush failed: #{e.class}: #{e.message}")
        end
      end

      # ----------------------------------------------------------------
      # Live surface: refresh / change listeners
      # ----------------------------------------------------------------

      # Re-apply in-memory seeds for bound configs not yet present server-side.
      #
      # A freshly-bound config lives only as a seed until it is flushed and
      # fetched; without this, any cache rebuild (a manual refresh, or a
      # WebSocket event for another config) would drop it. Server-present
      # configs are already in +new_cache+ and are authoritative — only bound
      # ids missing from it are re-seeded.
      def merge_pending_seeds(new_cache)
        @bindings.each_key do |bound_id|
          new_cache[bound_id] = resolve_bound_chain(bound_id) unless new_cache.key?(bound_id)
        end
      end

      def do_refresh(source)
        configs = fetch_all_configs
        new_cache, new_store = resolve_all(configs)
        merge_pending_seeds(new_cache)
        old_cache = nil
        @lock.synchronize do
          old_cache = @config_cache
          @config_cache = new_cache
          @raw_config_store = new_store
        end
        fire_change_listeners(old_cache, new_cache, source: source)
      end

      def resolve_all(configs)
        by_id = configs.to_h { |c| [c.id, c] }
        new_cache = {}
        new_store = {}
        configs.each do |cfg|
          chain = Helpers.build_chain(cfg, by_id)
          new_cache[cfg.id] = Helpers.resolve_chain(chain, @environment)
          new_store[cfg.id] = cfg
        end
        [new_cache, new_store]
      end

      def fire_change_listeners(old_cache, new_cache, source:)
        all_config_ids = old_cache.keys | new_cache.keys
        all_config_ids.each do |cfg_id|
          old_items = old_cache[cfg_id] || {}
          new_items = new_cache[cfg_id] || {}
          target = @bindings[cfg_id]
          fire_config_changes(cfg_id, old_items, new_items, target, source)
        end
      end

      def fire_config_changes(cfg_id, old_items, new_items, target, source)
        all_keys = old_items.keys | new_items.keys
        all_keys.each do |i_key|
          old_val = old_items[i_key]
          new_val = new_items[i_key]
          next if old_val == new_val

          # Apply to bound target first so listeners reading the object see the
          # new value.
          Discovery.apply_change_to_target(target, i_key, new_val) unless target.nil?
          @metrics&.record("config.changes", unit: "changes", dimensions: { "config" => cfg_id })
          event = ConfigChangeEvent.new(
            config_id: cfg_id, item_key: i_key,
            old_value: old_val, new_value: new_val, source: source
          )
          dispatch_event(event, cfg_id, i_key)
        end
      end

      def dispatch_event(event, cfg_id, i_key)
        @listeners.each do |callback, ck_filter, ik_filter|
          next if !ck_filter.nil? && ck_filter != cfg_id
          next if !ik_filter.nil? && ik_filter != i_key

          begin
            callback.call(event)
          rescue StandardError => e
            Smplkit.debug("config", "on_change listener raised: #{e.class}: #{e.message}")
          end
        end
      end

      # ----------------------------------------------------------------
      # Internal: event handlers (called by SharedWebSocket)
      # ----------------------------------------------------------------

      # Re-resolve every config in +store+ and fire change listeners.
      #
      # Inheritance means a single config change can shift descendants' resolved
      # values too — so whenever the raw store is mutated (config added,
      # updated, or deleted), every config gets re-resolved against the new
      # snapshot.
      def rebuild_from_store(store, source:)
        configs = store.values
        new_cache, new_store = resolve_all(configs)
        merge_pending_seeds(new_cache)
        old_cache = nil
        @lock.synchronize do
          old_cache = @config_cache
          @config_cache = new_cache
          @raw_config_store = new_store
        end
        fire_change_listeners(old_cache, new_cache, source: source)
      end

      def handle_config_changed(data)
        key = data["id"] || data["key"]
        return handle_configs_changed(data) unless key

        new_store = @lock.synchronize { @raw_config_store.dup }
        begin
          cfg = fetch_config(key)
        rescue StandardError => e
          Smplkit.debug("config", "failed to fetch config #{key.inspect} after WS event: #{e.class}: #{e.message}")
          return
        end
        return if cfg.nil?

        new_store[key] = cfg
        rebuild_from_store(new_store, source: "websocket")
      end

      def handle_config_deleted(data)
        key = data["id"] || data["key"]
        return handle_configs_changed(data) unless key

        new_store = @lock.synchronize { @raw_config_store.dup }
        return if new_store.delete(key).nil?

        rebuild_from_store(new_store, source: "websocket")
      end

      def handle_configs_changed(_data)
        do_refresh("websocket")
      rescue StandardError => e
        Smplkit.debug("config", "configs_changed refresh failed: #{e.class}: #{e.message}")
      end

      # ----------------------------------------------------------------
      # Internal: request-body construction
      # ----------------------------------------------------------------

      def config_body(config)
        SmplkitGeneratedClient::Config::ConfigResponse.new(
          data: SmplkitGeneratedClient::Config::ConfigResource.new(
            type: "config",
            id: config.key,
            attributes: SmplkitGeneratedClient::Config::Config.new(
              name: config.name,
              description: config.description,
              parent: config.parent_id,
              items: config_items_to_wire(config.items),
              environments: config_envs_to_wire(config.environments)
            )
          )
        )
      end

      def config_items_to_wire(items)
        return nil if items.nil? || items.empty?

        items.to_h do |item|
          [item.name, SmplkitGeneratedClient::Config::ConfigItemDefinition.new(
            value: item.value, type: item.type, description: item.description
          )]
        end
      end

      def config_envs_to_wire(environments)
        return nil if environments.empty?

        # Per ADR-024 §2.4 the wire shape for env overrides is a flat
        # +{env: {key: rawValue}}+ map — no envelope, no per-key type wrapper.
        environments.each_with_object({}) do |(env_key, env_obj), out|
          out[env_key] = env_obj.values
        end
      end

      def build_config_bulk_request(batch)
        items = batch.map do |entry|
          SmplkitGeneratedClient::Config::ConfigBulkItem.new(
            id: entry["id"],
            service: entry["service"],
            environment: entry["environment"],
            parent: entry["parent"],
            name: entry["name"],
            description: entry["description"],
            items: bulk_items_to_wire(entry["items"])
          )
        end
        SmplkitGeneratedClient::Config::ConfigBulkRequest.new(configs: items)
      end

      def bulk_items_to_wire(items_hash)
        return nil if items_hash.nil? || items_hash.empty?

        items_hash.transform_values do |def_hash|
          SmplkitGeneratedClient::Config::ConfigItemDefinition.new(
            value: def_hash["value"],
            type: def_hash["type"],
            description: def_hash["description"]
          )
        end
      end
    end
  end

  ConfigClient = Config::ConfigClient
end
