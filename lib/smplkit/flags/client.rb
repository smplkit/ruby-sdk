# frozen_string_literal: true

require "json"
require "digest"

# The Smpl Flags client — one unified +FlagsClient+.
#
# Smpl Flags has two surfaces on a single client, mirroring how the config,
# audit, and jobs clients expose their full surface from one class:
#
# * *Management surface* — pure CRUD, no live connection: +new_boolean_flag+ /
#   +new_string_flag+ / +new_number_flag+ / +new_json_flag+ constructors, +get+
#   / +list+ / +delete+ CRUD, and the flag-declaration discovery buffer
#   (+register+ / +flush+ / +flush_sync+ / +pending_count+). The client owns the
#   discovery buffer directly.
# * *Live surface* — lazily connects to your running service on first use: the
#   typed handle declarations (+boolean_flag+ / +string_flag+ / +number_flag+ /
#   +json_flag+) whose +.get+ evaluates against the cached definitions, plus
#   +refresh+ / +stats+ / +on_change+. The first live call transparently flushes
#   discovery, fetches all flag definitions into the local cache, and opens the
#   live-updates WebSocket — no explicit install step.
#
# The client supports two construction shapes:
#
# * *Wired* into +Smplkit::Client+ — borrows the parent's flags transport for
#   both runtime fetch and CRUD, the parent's shared WebSocket for the live
#   channel, and +client.platform.contexts+ for evaluation-context
#   registration. This is the common path.
# * *Standalone* — +FlagsClient.new(api_key: ..., base_url: ..., ...)+ builds
#   and owns its own flags transport and a contexts client (against its own app
#   transport), and on first live use opens and owns its own WebSocket. +close+
#   tears down only the owned transports and owned WebSocket.
module Smplkit
  module Flags
    # Describes a flag definition change. Frozen — fields are set at construction.
    class FlagChangeEvent
      attr_reader :id, :source, :deleted

      def initialize(id:, source:, deleted: false)
        @id = id
        @source = source
        @deleted = deleted
        freeze
      end

      def deleted? = @deleted

      def ==(other)
        other.is_a?(FlagChangeEvent) && id == other.id && source == other.source && deleted == other.deleted
      end
      alias eql? ==

      def hash = [id, source, deleted].hash
    end

    # Thread-safe LRU resolution cache with hit/miss stats.
    class ResolutionCache
      DEFAULT_MAX_SIZE = 10_000

      attr_reader :cache_hits, :cache_misses

      def initialize(max_size: DEFAULT_MAX_SIZE)
        @max_size = max_size
        @cache = {}
        @lock = Mutex.new
        @cache_hits = 0
        @cache_misses = 0
      end

      # Return [hit, value]. Moves the key to end on hit.
      def get(cache_key)
        @lock.synchronize do
          if @cache.key?(cache_key)
            value = @cache.delete(cache_key)
            @cache[cache_key] = value
            @cache_hits += 1
            [true, value]
          else
            @cache_misses += 1
            [false, nil]
          end
        end
      end

      def put(cache_key, value)
        @lock.synchronize do
          @cache.delete(cache_key) if @cache.key?(cache_key)
          @cache[cache_key] = value
          @cache.shift while @cache.size > @max_size
        end
      end

      def clear
        @lock.synchronize { @cache.clear }
      end
    end

    # Evaluation statistics for the flags runtime.
    FlagStats = Struct.new(:cache_hits, :cache_misses, keyword_init: true)

    # Convert a list of Context objects to the nested evaluation dict.
    def self.contexts_to_eval_dict(contexts)
      contexts.to_h { |ctx| [ctx.type, ctx.to_eval_hash] }
    end

    # Compute a stable hash for a context evaluation dict.
    def self.hash_context(eval_dict)
      Digest::MD5.hexdigest(JSON.generate(deep_sort(eval_dict)))
    end

    def self.deep_sort(value)
      case value
      when Hash
        value.keys.sort_by(&:to_s).to_h { |k| [k, deep_sort(value[k])] }
      when Array
        value.map { |v| deep_sort(v) }
      else
        value
      end
    end

    # Build standalone flags + app transports and resolve the app base URL.
    #
    # +base_url+/+api_key+ are used directly when supplied (the path a top-level
    # client takes after it has already resolved them); otherwise the management
    # config resolver fills in whatever is missing (+~/.smplkit+ / env vars /
    # defaults). The app transport backs the standalone contexts client
    # (evaluation-context registration); the app base URL is returned so a
    # standalone client can open its own WebSocket against the event gateway.
    def self.flags_transport(api_key:, base_url:, profile:, base_domain:, scheme:, debug:, extra_headers:)
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
      flags_http = Transport.build_api_client(SmplkitGeneratedClient::Flags, "flags", tcfg, base_url: base_url)
      app_http = Transport.build_api_client(SmplkitGeneratedClient::App, "app", tcfg)
      [flags_http, app_http, app_url, resolved_key]
    end

    # The Smpl Flags client (sync).
    #
    # One client exposes the full surface, reachable as +client.flags+
    # (+Smplkit::Client+) or constructed directly:
    #
    #   flags = Smplkit::FlagsClient.new(environment: "production")
    #   new_flag = flags.new_boolean_flag("beta", default: false)
    #   new_flag.save
    #   beta = flags.boolean_flag("beta", default: false)
    #   beta.get # => ...
    #
    # The management surface (+new_*+ / +get+ / +list+ / +delete+ and discovery)
    # is pure CRUD. The live surface (+boolean_flag+ / +string_flag+ /
    # +number_flag+ / +json_flag+ / +refresh+ / +stats+ / +on_change+) connects
    # lazily on first use — the first call flushes discovery, fetches all flag
    # definitions into the local cache, and opens the live-updates WebSocket. No
    # explicit install step is required.
    class FlagsClient
      def initialize(api_key = nil, environment: nil, base_url: nil, profile: nil,
                     base_domain: nil, scheme: nil, debug: nil, extra_headers: nil,
                     parent: nil, transport: nil, contexts: nil, metrics: nil)
        @parent = parent
        @metrics = metrics
        @environment = parent.nil? ? environment : parent._environment
        @service = parent&._service
        @standalone_api_key = nil
        if transport.nil?
          @flags_http, app_http, @app_base_url, @standalone_api_key = Flags.flags_transport(
            api_key: api_key, base_url: base_url, profile: profile,
            base_domain: base_domain, scheme: scheme, debug: debug, extra_headers: extra_headers
          )
          # Standalone: build our own contexts client (and own its app transport).
          @contexts = Platform::ContextsClient.new(app_http, ContextRegistrationBuffer.new)
        else
          @flags_http = transport
          @app_base_url = nil
          # Wired: borrow client.platform.contexts as the evaluation-context
          # registration seam.
          @contexts = contexts
        end
        @api = SmplkitGeneratedClient::Flags::FlagsApi.new(@flags_http)

        # Discovery buffer is owned by this client (no management delegation).
        @buffer = FlagRegistrationBuffer.new

        # Live-surface state.
        @flag_store = {}
        @connected = false
        @ws_subscribed = false
        @cache = ResolutionCache.new
        @handles = {}
        @global_listeners = []
        @key_listeners = Hash.new { |h, k| h[k] = [] }
        @ws_manager = nil
        @owns_ws = false
        @lock = Mutex.new
      end

      # ----------------------------------------------------------------
      # Management surface: CRUD (no live connection)
      # ----------------------------------------------------------------

      # Return a new unsaved boolean +BooleanFlag+. Call +save+ to persist.
      def new_boolean_flag(id, default:, name: nil, description: nil)
        BooleanFlag.new(
          self, id: id, name: name || Smplkit::Helpers.key_to_display_name(id),
                type: "BOOLEAN", default: default,
                values: [FlagValue.new(name: "True", value: true), FlagValue.new(name: "False", value: false)],
                description: description
        )
      end

      # Return a new unsaved string +StringFlag+. Call +save+ to persist.
      def new_string_flag(id, default:, name: nil, description: nil, values: nil)
        StringFlag.new(
          self, id: id, name: name || Smplkit::Helpers.key_to_display_name(id),
                type: "STRING", default: default, values: values, description: description
        )
      end

      # Return a new unsaved numeric +NumberFlag+. Call +save+ to persist.
      def new_number_flag(id, default:, name: nil, description: nil, values: nil)
        NumberFlag.new(
          self, id: id, name: name || Smplkit::Helpers.key_to_display_name(id),
                type: "NUMERIC", default: default, values: values, description: description
        )
      end

      # Return a new unsaved JSON +JsonFlag+. Call +save+ to persist.
      def new_json_flag(id, default:, name: nil, description: nil, values: nil)
        JsonFlag.new(
          self, id: id, name: name || Smplkit::Helpers.key_to_display_name(id),
                type: "JSON", default: default, values: values, description: description
        )
      end

      # Fetch the editable +Flag+ resource by id.
      def get(id)
        response = ApiSupport::ErrorMapping.call { @api.get_flag(id) }
        model_from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      # List flags for the authenticated account.
      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_flags(opts) }
        (response.data || []).map { |r| model_from_resource(ApiSupport::ResourceShim.from_model(r)) }
      end

      # Delete a flag by id.
      def delete(id)
        ApiSupport::ErrorMapping.call { @api.delete_flag(id) }
        nil
      end

      def _create_flag(flag)
        response = ApiSupport::ErrorMapping.call { @api.create_flag(flag_body(flag)) }
        model_from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def _update_flag(flag)
        response = ApiSupport::ErrorMapping.call { @api.update_flag(flag.id, flag_body(flag)) }
        model_from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      # ----------------------------------------------------------------
      # Management surface: discovery buffer (owned directly)
      # ----------------------------------------------------------------

      # Buffer flag declarations for bulk-discovery upload; optionally flush now.
      def register(items, flush: false)
        batch = items.is_a?(Array) ? items : [items]
        batch.each { |d| @buffer.add(d) }
        if flush
          self.flush
          return
        end
        return unless @buffer.pending_count >= FLAG_BATCH_FLUSH_SIZE

        Thread.new { threshold_flush }
      end

      # POST pending declarations to the flags bulk endpoint.
      #
      # Items remain in the buffer until the request succeeds, so a flush
      # against an unhealthy +flags+ service is automatically retried by the
      # next +flush+ call (periodic background flush, install retry, or final
      # flush on close).
      def flush
        batch = @buffer.peek
        return if batch.empty?

        body = build_flag_bulk_request(batch)
        ApiSupport::ErrorMapping.call { @api.bulk_register_flags(body) }
        @buffer.commit(batch.map { |b| b["id"] })
      end

      # Synchronous flush — alias of +flush+ for the periodic-flush path.
      def flush_sync
        flush
      end

      # Number of pending flag declarations awaiting flush.
      def pending_count
        @buffer.pending_count
      end

      # ----------------------------------------------------------------
      # Live surface: typed flag handles
      # ----------------------------------------------------------------

      # Declare a boolean flag handle for live evaluation. Connects lazily on first use.
      def boolean_flag(id, default:)
        ensure_connected
        handle = BooleanFlag.new(self, id: id, name: id, type: "BOOLEAN", default: default)
        @handles[id] = handle
        observe_declaration(id, "BOOLEAN", default)
        handle
      end

      # Declare a string flag handle for live evaluation. Connects lazily on first use.
      def string_flag(id, default:)
        ensure_connected
        handle = StringFlag.new(self, id: id, name: id, type: "STRING", default: default)
        @handles[id] = handle
        observe_declaration(id, "STRING", default)
        handle
      end

      # Declare a numeric flag handle for live evaluation. Connects lazily on first use.
      def number_flag(id, default:)
        ensure_connected
        handle = NumberFlag.new(self, id: id, name: id, type: "NUMERIC", default: default)
        @handles[id] = handle
        observe_declaration(id, "NUMERIC", default)
        handle
      end

      # Declare a JSON flag handle for live evaluation. Connects lazily on first use.
      def json_flag(id, default:)
        ensure_connected
        handle = JsonFlag.new(self, id: id, name: id, type: "JSON", default: default)
        @handles[id] = handle
        observe_declaration(id, "JSON", default)
        handle
      end

      # ----------------------------------------------------------------
      # Live surface: refresh / stats / change listeners
      # ----------------------------------------------------------------

      # Re-fetch all flag definitions and clear cache.
      #
      # Connects lazily on first use — no explicit install step.
      def refresh
        ensure_connected
        do_refresh("manual")
      end

      # Return evaluation statistics. Connects lazily on first use.
      def stats
        ensure_connected
        FlagStats.new(cache_hits: @cache.cache_hits, cache_misses: @cache.cache_misses)
      end

      # Register a change listener.
      #
      #   client.flags.on_change { |event| ... }            # global
      #   client.flags.on_change("checkout-v2") { |e| ... } # flag-scoped
      #
      # Connects lazily on first use — no explicit install step.
      def on_change(flag_id = nil, &block)
        ensure_connected
        raise ArgumentError, "on_change requires a block" unless block

        if flag_id.nil?
          @global_listeners << block
        else
          @key_listeners[flag_id] << block
        end
        block
      end

      # Release resources — only those this client owns.
      #
      # Tears down the owned WebSocket (standalone install). A wired client
      # borrows the parent's transport, WebSocket, and contexts client and
      # closes none of them.
      def close
        if @owns_ws && @ws_manager
          @ws_manager.stop
          @ws_manager = nil
          @owns_ws = false
        end
        # Owned flags/app transports (standalone construction) release their
        # Faraday connections on GC; there is no explicit shutdown to call.
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

      # Core evaluation used by flag handles (the +.get+ path).
      #
      # Connects lazily on first use so +flag.get+ works without an explicit
      # install step.
      def _evaluate_handle(flag_id, default, context)
        ensure_connected
        if context
          # Explicit context: register here. (Implicit set_context registers at
          # the entry point, so the request-context branch below doesn't need
          # to.)
          @contexts&.register(context)
          eval_dict = Flags.contexts_to_eval_dict(context)
        else
          contexts = Smplkit.request_context
          eval_dict = contexts.empty? ? {} : Flags.contexts_to_eval_dict(contexts)
        end

        # Auto-inject service context if set and not already provided.
        eval_dict["service"] = { "key" => @service } if @service && !eval_dict.key?("service")

        ctx_hash = Flags.hash_context(eval_dict)
        cache_key = "#{flag_id}:#{ctx_hash}"

        hit, cached_value = @cache.get(cache_key)
        if hit
          @metrics&.record("flags.cache_hits", unit: "hits")
          @metrics&.record("flags.evaluations", unit: "evaluations", dimensions: { "flag" => flag_id })
          return cached_value
        end

        flag_def = @flag_store[flag_id]
        if flag_def.nil?
          @cache.put(cache_key, default)
          return default
        end

        value = evaluate_flag(flag_def, @environment, eval_dict)
        value = default if value.nil?
        @cache.put(cache_key, value)
        @metrics&.record("flags.cache_misses", unit: "misses")
        @metrics&.record("flags.evaluations", unit: "evaluations", dimensions: { "flag" => flag_id })
        value
      end

      # Internal: trigger lazy connect. Used by +Client#wait_until_ready+.
      def _ensure_connected
        ensure_connected
      end

      private

      # Queue a declared flag with the owned discovery buffer.
      def observe_declaration(flag_id, flag_type, default)
        register(FlagDeclaration.new(
                   id: flag_id, type: flag_type, default: default,
                   service: @service, environment: @environment
                 ))
      end

      def threshold_flush
        flush
      rescue StandardError => e
        Smplkit.debug("registration", "flag registration flush failed: #{e.class}: #{e.message}")
      end

      def model_from_resource(resource)
        d = Helpers.flag_dict_from_json(resource)
        klass =
          case d["type"]
          when "BOOLEAN" then BooleanFlag
          when "STRING" then StringFlag
          when "NUMERIC" then NumberFlag
          else JsonFlag
          end
        klass.new(
          self,
          id: d["id"], name: d["name"], type: d["type"], default: d["default"],
          description: d["description"], values: d["values"], environments: d["environments"],
          created_at: (resource["attributes"] || {})["created_at"],
          updated_at: (resource["attributes"] || {})["updated_at"]
        )
      end

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

      # Open the live connection to the running Smpl Flags service.
      #
      # Flushes any buffered discovery declarations, fetches all flag
      # definitions into the local cache, opens the shared WebSocket, and
      # subscribes to +flag_changed+ / +flag_deleted+ / +flags_changed+ events.
      #
      # Idempotent and internal — every live method calls it on first use, so
      # the live surface auto-connects with no explicit step.
      def ensure_connected
        @parent&._ensure_started
        return if @connected

        # Flush discovered flags BEFORE fetching definitions so the fetch
        # reflects them. Items stay in the buffer until the POST succeeds.
        begin
          flush
        rescue StandardError => e
          Smplkit.debug("flags", "discovery flush before connect failed: #{e.class}: #{e.message}")
        end

        fetch_all_flags
        @cache.clear
        @connected = true

        @ws_manager = ensure_ws
        return if @ws_subscribed

        @ws_manager.on("flag_changed") { |data| handle_flag_changed(data) }
        @ws_manager.on("flag_deleted") { |data| handle_flag_deleted(data) }
        @ws_manager.on("flags_changed") { |data| handle_flags_changed(data) }
        @ws_subscribed = true
      end

      def do_refresh(_source)
        fetch_all_flags
        @cache.clear
        fire_change_listeners_all("manual")
      end

      # ----------------------------------------------------------------
      # Internal: flag store
      # ----------------------------------------------------------------

      def fetch_all_flags
        flags = fetch_flags_list
        @flag_store = flags.to_h { |f| [f["id"], f] }
      end

      def fetch_flags_list
        rows = ApiSupport::PaginatedFetch.collect { |opts| @api.list_flags(opts) }
        rows.map { |r| Helpers.flag_dict_from_json(ApiSupport::ResourceShim.from_model(r)) }
      end

      # Fetch a single flag by key and return a store-format dict.
      def fetch_flag_single_data(key)
        response = ApiSupport::ErrorMapping.call { @api.get_flag(key) }
        Helpers.flag_dict_from_json(ApiSupport::ResourceShim.from_model(response.data))
      end

      # ----------------------------------------------------------------
      # Internal: event handlers (called by SharedWebSocket)
      # ----------------------------------------------------------------

      def handle_flag_changed(data)
        key = data["id"]
        return unless key

        pre = @flag_store[key]&.dup || {}
        new_data = fetch_flag_single_data(key)
        @flag_store[key] = new_data
        @cache.clear
        fire_change_listeners(key, "websocket") if pre != new_data
      end

      def handle_flag_deleted(data)
        key = data["id"]
        return unless key

        existed = @flag_store.key?(key)
        @flag_store.delete(key)
        @cache.clear
        fire_change_listeners(key, "websocket", deleted: true) if existed
      end

      def handle_flags_changed(_data)
        pre_store = @flag_store.dup
        begin
          fetch_all_flags
        rescue StandardError => e
          Smplkit.debug("ws", "flags refresh after flags_changed failed: #{e.message}")
          return
        end
        @cache.clear
        post_store = @flag_store
        all_keys = pre_store.keys | post_store.keys
        changed = all_keys.reject { |k| pre_store[k] == post_store[k] }
        return if changed.empty?

        # Global listener fires once.
        first_event = FlagChangeEvent.new(id: changed.first, source: "websocket")
        @global_listeners.each do |cb|
          cb.call(first_event)
        rescue StandardError => e
          Smplkit.debug("flags", "global listener raised: #{e.class}: #{e.message}")
        end

        # Per-key listeners fire for each changed key.
        changed.each do |k|
          deleted = pre_store.key?(k) && !post_store.key?(k)
          event = FlagChangeEvent.new(id: k, source: "websocket", deleted: deleted)
          @key_listeners[k].each do |cb|
            cb.call(event)
          rescue StandardError => e
            Smplkit.debug("flags", "scoped listener raised: #{e.class}: #{e.message}")
          end
        end
      end

      def fire_change_listeners(flag_id, source, deleted: false)
        return unless flag_id

        event = FlagChangeEvent.new(id: flag_id, source: source, deleted: deleted)
        (@global_listeners + @key_listeners[flag_id]).each do |cb|
          cb.call(event)
        rescue StandardError => e
          Smplkit.debug("flags", "listener raised: #{e.class}: #{e.message}")
        end
      end

      def fire_change_listeners_all(source)
        @flag_store.each_key { |id| fire_change_listeners(id, source) }
      end

      # Evaluate a flag definition against the given context.
      #
      # Follows ADR-022 §2.6 semantics:
      #   1. Look up the environment. If missing, return flag-level default.
      #   2. If disabled, return env default or flag default.
      #   3. Iterate rules; first match wins.
      #   4. No match -> env default or flag default.
      def evaluate_flag(flag_def, environment, eval_dict)
        flag_default = flag_def["default"]
        environments = flag_def["environments"] || {}

        return flag_default if environment.nil? || !environments.key?(environment)

        env_config = environments[environment]
        fallback = env_config.default.nil? ? flag_default : env_config.default
        return fallback unless env_config.enabled

        env_config.rules.each do |rule|
          next if rule.logic.nil? || rule.logic.empty?

          begin
            result = JsonLogicEvaluator.apply(rule.logic, eval_dict)
            return rule.value if result
          rescue StandardError => e
            Smplkit.debug("flags", "json logic evaluation error for rule: #{e.class}: #{e.message}")
            next
          end
        end

        fallback
      end

      def flag_body(flag)
        SmplkitGeneratedClient::Flags::FlagResponse.new(
          data: SmplkitGeneratedClient::Flags::FlagResource.new(
            type: "flag",
            id: flag.id,
            attributes: SmplkitGeneratedClient::Flags::Flag.new(
              name: flag.name,
              type: flag.type,
              default: flag.default,
              description: flag.description,
              values: flag_values_to_wire(flag.values),
              environments: flag_envs_to_wire(flag.environments)
            )
          )
        )
      end

      def flag_values_to_wire(values)
        # The server requires +values+ to be null (unconstrained) or a
        # non-empty array (constrained) — an empty array is rejected, so an
        # empty/cleared values list is sent as null.
        return nil if values.nil? || values.empty?

        values.map do |v|
          SmplkitGeneratedClient::Flags::FlagValue.new(name: v.name, value: v.value)
        end
      end

      def flag_envs_to_wire(environments)
        return nil if environments.empty?

        environments.each_with_object({}) do |(env_key, env_obj), out|
          rules = env_obj.rules.map do |r|
            SmplkitGeneratedClient::Flags::FlagRule.new(
              logic: r.logic, value: r.value, description: r.description
            )
          end
          out[env_key] = SmplkitGeneratedClient::Flags::FlagEnvironment.new(
            enabled: env_obj.enabled, default: env_obj.default, rules: rules
          )
        end
      end

      def build_flag_bulk_request(batch)
        flag_items = batch.map do |entry|
          SmplkitGeneratedClient::Flags::FlagBulkItem.new(
            id: entry["id"], type: entry["type"], default: entry["default"],
            service: entry["service"], environment: entry["environment"]
          )
        end
        SmplkitGeneratedClient::Flags::FlagBulkRequest.new(flags: flag_items)
      end
    end

    # Vendored minimal JSON Logic evaluator covering the operators the smplkit
    # platform ships in flag rules.
    #
    # Stays in-tree so the Ruby SDK doesn't depend on the +json_logic+ gem being
    # correct — the Java SDK followed the same pattern. Operators supported:
    # +==+, +!=+, +<+, +<=+, +>+, +>=+, +in+, +var+, +and+, +or+, +!+, +if+,
    # +missing+, +none+.
    module JsonLogicEvaluator
      module_function

      def apply(logic, data)
        return logic unless logic.is_a?(Hash)
        return logic if logic.empty?

        op, values = logic.first
        values = [values] unless values.is_a?(Array)

        case op
        when "var"
          resolve_var(values[0], data, values[1])
        when "and"
          values.reduce(true) { |acc, v| acc && truthy?(apply(v, data)) }
        when "or"
          values.reduce(false) { |acc, v| acc || truthy?(apply(v, data)) }
        when "!"
          !truthy?(apply(values[0], data))
        when "if"
          eval_if(values, data)
        when "==", "==="
          apply(values[0], data) == apply(values[1], data)
        when "!=", "!=="
          apply(values[0], data) != apply(values[1], data)
        when "<"
          compare(values, data) { |a, b| a < b }
        when "<="
          compare(values, data) { |a, b| a <= b }
        when ">"
          compare(values, data) { |a, b| a > b }
        when ">="
          compare(values, data) { |a, b| a >= b }
        when "in"
          eval_in(values, data)
        when "missing"
          eval_missing(values, data)
        when "none"
          values_arr = apply(values[0], data) || []
          inner = values[1]
          values_arr.is_a?(Array) && values_arr.none? { |item| truthy?(apply(inner, item)) }
        else
          false
        end
      end

      def truthy?(value)
        return false if value.nil?
        return false if value == false
        return false if value.is_a?(Numeric) && value.zero?
        return false if value == ""
        return false if value == []

        true
      end

      def resolve_var(path, data, default = nil)
        return data if path.nil? || path == "" || path == []

        keys = path.is_a?(Array) ? path : path.to_s.split(".")
        keys.reduce(data) do |scope, key|
          break default if scope.nil?

          if scope.is_a?(Hash)
            scope[key] || scope[key.to_s] || scope[key.to_sym]
          elsif scope.is_a?(Array) && key.to_s =~ /\A\d+\z/
            scope[key.to_i]
          else
            default
          end
        end || default
      end

      def compare(values, data)
        applied = values.map { |v| apply(v, data) }
        return false if applied.any?(&:nil?)

        if applied.length == 2
          yield(applied[0], applied[1])
        elsif applied.length == 3
          yield(applied[0], applied[1]) && yield(applied[1], applied[2])
        else
          false
        end
      rescue ArgumentError, TypeError
        false
      end

      def eval_if(values, data)
        i = 0
        while i + 1 < values.length
          return apply(values[i + 1], data) if truthy?(apply(values[i], data))

          i += 2
        end
        i < values.length ? apply(values[i], data) : nil
      end

      def eval_in(values, data)
        needle = apply(values[0], data)
        haystack = apply(values[1], data)
        return false if haystack.nil?

        haystack.include?(needle)
      rescue NoMethodError, TypeError
        false
      end

      def eval_missing(values, data)
        keys = values.is_a?(Array) ? values.flatten : [values]
        keys.reject { |k| present?(resolve_var(k, data)) }
      end

      def present?(value)
        !(value.nil? || value == "")
      end
    end
  end

  FlagsClient = Flags::FlagsClient
end
