# frozen_string_literal: true

module Smplkit
  module Config
    # Module-level helpers for the runtime config client. Extracted so they
    # can be unit-tested without spinning up the full client.
    module Discovery
      module_function

      # Map a runtime value to a Config item type. Used both when binding a
      # Hash/Struct target and when supplying a default to +get(id, key,
      # default)+. +true+/+false+ are checked first because Ruby's
      # +Numeric+/+Integer+ tests would not accidentally claim them.
      def value_to_item_type(value)
        case value
        when true, false then "BOOLEAN"
        when Numeric then "NUMBER"
        else "STRING"
        end
      end

      # Walk a bound target, returning +[key, type, value, description]+
      # tuples flattened to dot-notation. Nested Hashes / Structs are
      # descended into; everything else is treated as an opaque leaf.
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
      # missing or not a supported container — the server may have items
      # that don't line up with what the bound target declared.
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
    # Returned by +ConfigClient#get(id)+ (single-arg form). Always reflects
    # the latest server-pushed state — every read sees current values.
    #
    # Supports +[]+, +key?+, +keys+, +values+, +each_pair+, +to_h+, +size+,
    # and method-style attribute access for keys that don't collide with
    # built-in method names. Use subscript (+proxy["values"]+) for keys
    # that do collide.
    #
    # For typed access via a Struct schema, use +ConfigClient#bind+ —
    # bound objects stay live on the same cache, with no proxy indirection.
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

    # Synchronous runtime client for Smpl Config.
    #
    # Obtained via +Smplkit::Client#config+. Exposes +#bind+ (the
    # recommended declarative API), +#get+ (lookup-only escape hatch),
    # +#refresh+, and +#on_change+. Management/CRUD lives on
    # +Smplkit::Client#manage.config+.
    class ConfigClient
      # Sentinel used to distinguish "argument not supplied" from "argument
      # supplied as nil" on +#get+. A frozen +Object+ is sufficient — we
      # only ever identity-compare with +equal?+.
      MISSING = Object.new.freeze
      private_constant :MISSING

      def initialize(parent, manage:, metrics:)
        @parent = parent
        @manage = manage
        @metrics = metrics
        @environment = parent._environment
        @service = parent._service

        @config_cache = {}        # config_key -> { item_key => resolved_value }
        @raw_config_store = {}    # config_key -> Smplkit::Config::Config
        @proxies = {}             # config_key -> LiveConfigProxy
        @bindings = {}            # config_key -> Hash | Struct (bound target)
        @listeners = []           # [callback, config_id_or_nil, item_key_or_nil]
        @connected = false
        @lock = Mutex.new
        @ws_manager = nil
      end

      # Eagerly initialize the runtime. Flushes any buffered discovery
      # declarations, fetches the full config list, resolves values for the
      # SDK's current environment into the local cache, and subscribes to
      # +config_changed+ / +config_deleted+ / +configs_changed+ events on
      # the shared WebSocket.
      #
      # Idempotent — safe to call multiple times. Invoked automatically on
      # the first +#get+ or +#bind+ call.
      def start
        return if @connected

        @environment = @parent._environment

        # Per ADR-037 §2.14: flush pending discovery declarations BEFORE
        # the initial fetch so newly-declared configs show up in the cache.
        begin
          @manage&.config&.flush
        rescue StandardError => e
          Smplkit.debug("config", "pre-start discovery flush failed: #{e.class}: #{e.message}")
        end

        do_refresh("initial")
        @connected = true

        @ws_manager = @parent._ensure_ws
        @ws_manager.on("config_changed") { |data| handle_config_changed(data) }
        @ws_manager.on("config_deleted") { |data| handle_config_deleted(data) }
        @ws_manager.on("configs_changed") { |data| handle_configs_changed(data) }
      end

      # Bind a Hash or Struct to a config id; return the same object back, live.
      #
      # Declarative, code-first API. Two flavors:
      #
      # * +Hash+: keys present are leaves to register, with their values as
      #   the in-code defaults. Nested Hashes flatten to dot-notation. Keys
      #   the caller wants to inherit from +parent:+ are simply omitted.
      # * +Struct+: every member is registered as an explicit override.
      #   Ruby Structs do not track which members were "explicitly set" vs
      #   defaulted, so there is no Hash-style omit-to-inherit. For
      #   omit-to-inherit, use a Hash target.
      #
      # On first call the schema and values are registered with the server.
      # After the local cache is populated, any server-side overrides for
      # this config are applied to the bound object in place. WebSocket
      # events thereafter mutate the bound object in place — readers always
      # see the current resolved value with no indirection.
      #
      # Idempotent. Repeat calls with the same +id+ return the
      # originally-bound object; the new +config+ argument is ignored.
      def bind(id, target, parent: nil)
        unless target.is_a?(Hash) || target.is_a?(Struct)
          raise TypeError, "bind() requires a Hash or Struct; got #{target.class.name}"
        end

        return @bindings[id] if @bindings.key?(id)

        parent_id = resolve_parent_id(parent)

        if target.is_a?(Struct)
          class_name = target.class.name
          config_name = class_name&.split("::")&.last
        else
          config_name = nil
        end

        _observe_config_declaration(id, parent: parent_id, name: config_name, description: nil)

        Discovery.iter_items(target).each do |item_key, item_type, value, description|
          _observe_item_declaration(id, item_key, item_type, value, description)
        end

        # Register the binding BEFORE start() so any WS dispatch that fires
        # during the initial fetch finds it.
        @bindings[id] = target

        start unless @connected
        sync_target_from_cache(target, id)
        target
      end

      # Read a config (full) or a single value within a config.
      #
      # Three forms dispatched by argument count:
      #
      #   get("id")                    # LiveConfigProxy (raises NotFoundError)
      #   get("id", "key")             # value (raises NotFoundError / KeyError)
      #   get("id", "key", default)    # value or default; auto-registers (never raises)
      def get(id, key = MISSING, default = MISSING)
        start unless @connected

        return get_full_config(id) if key.equal?(MISSING)

        get_single_value(id, key.to_s, default)
      end

      # Register a change listener.
      #
      # Three forms:
      #
      #   client.config.on_change { |event| ... }                          # global
      #   client.config.on_change("id") { |event| ... }                    # config-scoped
      #   client.config.on_change("id", item_key: "key") { |event| ... }   # item-scoped
      def on_change(config_id = nil, item_key: nil, &block)
        raise ArgumentError, "on_change requires a block" unless block

        @listeners << [block, config_id, item_key&.to_s]
        block
      end

      # Re-fetch all configs and update resolved values, firing change
      # listeners for anything that differs from the previous state.
      def refresh
        start unless @connected
        do_refresh("manual")
      end

      def _close
        # No durable resources owned by this sub-client; the parent client
        # tears down the WebSocket and management transports.
      end

      # Internal: return (a copy of) the resolved values for a config id.
      # Used by +LiveConfigProxy+.
      def _cached_values(config_id)
        @lock.synchronize do
          (@config_cache[config_id] || {}).dup
        end
      end

      # Internal: queue a config declaration with the management buffer.
      def _observe_config_declaration(config_id, parent:, name:, description:)
        @manage&.config&.register_config(
          config_id,
          service: @service,
          environment: @environment,
          parent: parent,
          name: name,
          description: description
        )
      end

      # Internal: queue a config item declaration with the management buffer.
      def _observe_item_declaration(config_id, item_key, item_type, default, description)
        @manage&.config&.register_config_item(config_id, item_key, item_type, default, description)
      end

      private

      def resolve_parent_id(parent)
        return nil if parent.nil?

        @bindings.each { |cid, bound| return cid if bound.equal?(parent) }
        raise ArgumentError,
              "bind(): parent must be an object previously returned from client.config.bind(). " \
              "Bind the parent first."
      end

      def get_full_config(id)
        @lock.synchronize do
          raise Smplkit::NotFoundError, "Config with id '#{id}' not found" unless @config_cache.key?(id)
        end
        @metrics&.record("config.resolutions", unit: "resolutions", dimensions: { "config" => id })
        cached_proxy(id)
      end

      def get_single_value(id, key, default)
        has_default = !default.equal?(MISSING)
        if has_default
          _observe_config_declaration(id, parent: nil, name: nil, description: nil)
          _observe_item_declaration(id, key, Discovery.value_to_item_type(default), default, nil)
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

      def cached_proxy(config_id)
        @lock.synchronize do
          @proxies[config_id] ||= LiveConfigProxy.new(self, config_id)
        end
      end

      def sync_target_from_cache(target, config_id)
        cache = @lock.synchronize { (@config_cache[config_id] || {}).dup }
        cache.each do |dotted_key, value|
          Discovery.apply_change_to_target(target, dotted_key, value)
        end
      end

      def do_refresh(source)
        configs = @manage.config.list
        new_cache, new_store = resolve_all(configs)
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
          new_cache[cfg.key] = Helpers.resolve_chain(chain, @environment)
          new_store[cfg.key] = cfg
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

      def handle_config_changed(data)
        key = data["key"] || data["id"]
        return unless key

        begin
          cfg = @manage.config.get(key)
        rescue Smplkit::NotFoundError
          # Treat as a deletion — the resource is gone.
          handle_config_deleted(data)
          return
        rescue StandardError => e
          Smplkit.debug("config", "failed to fetch config #{key.inspect}: #{e.class}: #{e.message}")
          return
        end

        new_store = nil
        @lock.synchronize do
          new_store = @raw_config_store.dup
          new_store[key] = cfg
        end
        rebuild_from_store(new_store, source: "websocket")
      end

      def handle_config_deleted(data)
        key = data["key"] || data["id"]
        return unless key

        new_store = nil
        @lock.synchronize do
          new_store = @raw_config_store.dup
          return unless new_store.delete(key)
        end
        rebuild_from_store(new_store, source: "websocket")
      end

      def handle_configs_changed(_data)
        do_refresh("websocket")
      rescue StandardError => e
        Smplkit.debug("config", "configs_changed refresh failed: #{e.class}: #{e.message}")
      end

      def rebuild_from_store(store, source:)
        configs = store.values
        new_cache, new_store = resolve_all(configs)
        old_cache = nil
        @lock.synchronize do
          old_cache = @config_cache
          @config_cache = new_cache
          @raw_config_store = new_store
        end
        fire_change_listeners(old_cache, new_cache, source: source)
      end
    end
  end
end
