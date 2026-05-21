# frozen_string_literal: true

module Smplkit
  module Config
    # Describes a config change event delivered to +on_change+ listeners.
    class ConfigChangeEvent
      attr_reader :key, :source, :deleted

      def initialize(key:, source:, deleted: false)
        @key = key
        @source = source
        @deleted = deleted
        freeze
      end

      def deleted? = @deleted

      def ==(other)
        other.is_a?(ConfigChangeEvent) && key == other.key && source == other.source && deleted == other.deleted
      end
      alias eql? ==

      def hash = [key, source, deleted].hash
    end

    # A live, dot-accessible view over a resolved configuration.
    #
    # Identity-stable per config key (the same instance is returned by
    # repeat +client.config.get+ / +get_or_create+ calls). Every read goes
    # through the underlying client's resolved-config cache, so WebSocket
    # updates are picked up automatically — there is no +subscribe+ step.
    class LiveConfigProxy
      def initialize(client, key)
        @client = client
        @key = key
      end

      def config_id = @key

      def get(item_key, default = nil)
        snapshot = current_values
        return snapshot if item_key.nil?

        keys = item_key.to_s.split(".")
        keys.reduce(snapshot) do |scope, k|
          break default if scope.nil?

          scope.is_a?(Hash) ? scope[k] : default
        end || default
      end

      def [](item_key)
        get(item_key)
      end

      def to_h
        current_values.dup
      end

      def refresh
        # The cache is fully invalidated for this key — the next read
        # re-resolves from the parent client.
        @client._invalidate(@key)
        self
      end

      # ------------------------------------------------------------------
      # Typed getters (ADR-037 §2.13)
      #
      # Each registers the item (key, type, default, description) on first
      # call within the process, then returns the resolved value. When the
      # resolved value can't be coerced to the getter's type — including
      # the "not yet set on the server" case — the in-code default is
      # returned and a debug message is logged.
      # ------------------------------------------------------------------

      def get_bool(item_key, default, description: nil)
        register_item(item_key, "BOOLEAN", default, description)
        value = current_values[item_key.to_s]
        return default unless value.is_a?(TrueClass) || value.is_a?(FalseClass)

        value
      end

      def get_int(item_key, default, description: nil)
        register_item(item_key, "NUMBER", default, description)
        value = current_values[item_key.to_s]
        return default if value.is_a?(TrueClass) || value.is_a?(FalseClass)
        return value if value.is_a?(Integer)
        return value.to_i if value.is_a?(Float) && value == value.floor

        default
      end

      def get_float(item_key, default, description: nil)
        register_item(item_key, "NUMBER", default, description)
        value = current_values[item_key.to_s]
        return default if value.is_a?(TrueClass) || value.is_a?(FalseClass)
        return value.to_f if value.is_a?(Numeric)

        default
      end

      def get_string(item_key, default, description: nil)
        register_item(item_key, "STRING", default, description)
        value = current_values[item_key.to_s]
        value.is_a?(String) ? value : default
      end

      def get_json(item_key, default, description: nil)
        register_item(item_key, "JSON", default, description)
        snap = current_values
        snap.key?(item_key.to_s) ? snap[item_key.to_s] : default
      end

      def on_change(item_key = nil, &)
        if item_key.nil?
          @client.on_change(@key, &)
        else
          @client.on_change_item(@key, item_key.to_s, &)
        end
      end

      private

      def current_values
        @client._resolve_now(@key)
      end

      def register_item(item_key, item_type, default, description)
        @client._observe_item_declaration(@key, item_key.to_s, item_type, default, description)
      end
    end

    # Synchronous config runtime namespace.
    #
    # Obtained via +Smplkit::Client#config+. Exposes typed accessors
    # (+get_string+, +get_number+, +get_boolean+, +get_json+) and runtime
    # control (+refresh+, +on_change+).
    class ConfigClient
      def initialize(parent, manage:, metrics:)
        @parent = parent
        @manage = manage
        @metrics = metrics
        @environment = parent._environment
        @service = parent._service

        @snapshots = {}
        @raw_chains = {}
        @proxies = {}
        @global_listeners = []
        @key_listeners = Hash.new { |h, k| h[k] = [] }
        @item_listeners = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }
        @connected = false
        @lock = Mutex.new
      end

      def start
        return if @connected

        @environment = @parent._environment

        # Per ADR-037 §2.14: flush any buffered discovery declarations
        # BEFORE the lazy init touches the runtime so newly-declared
        # configs are visible to the very first +get+. The flush itself
        # swallows server/network failures.
        @manage&.config&.flush

        @ws_manager = @parent._ensure_ws
        @ws_manager.on("config_changed") { |data| handle_config_changed(data) }
        @ws_manager.on("config_deleted") { |data| handle_config_deleted(data) }
        @connected = true
      end

      def get(config_key, model_class = nil)
        start unless @connected

        snapshot = resolve(config_key)
        raise Smplkit::NotFoundError, "Config #{config_key.inspect} not found" if snapshot.nil?
        return snapshot if model_class.nil?

        model_class.new(snapshot)
      end

      # Declare a configuration from code; return a live, dict-like view.
      #
      # Idempotent — repeat calls with the same +id+ return the same
      # +LiveConfigProxy+ instance. The first call queues a discovery
      # payload (the config and any items declared via typed getters on
      # the returned handle) for upload to +POST /api/v1/configs/bulk+ on
      # next flush. Unlike +#get+, this method does not raise +NotFoundError+
      # when the id is absent — discovery handles that case.
      def get_or_create(config_id, parent: nil, name: nil, description: nil)
        parent_id =
          case parent
          when nil then nil
          when String then parent
          when LiveConfigProxy then parent.config_id
          else
            raise ArgumentError,
                  "parent must be a String id or LiveConfigProxy; got #{parent.class.name}"
          end
        _observe_config_declaration(config_id, parent: parent_id, name: name, description: description)
        start unless @connected
        cached_proxy(config_id)
      end

      def get_string(item_key, default: nil, config: nil)
        typed_get(item_key, default, config) { |v| v.is_a?(String) ? v : v.to_s }
      end

      def get_number(item_key, default: nil, config: nil)
        typed_get(item_key, default, config) do |v|
          v.is_a?(Numeric) ? v : Float(v)
        rescue StandardError
          default
        end
      end

      def get_boolean(item_key, default: nil, config: nil)
        typed_get(item_key, default, config) { |v| !!v }
      end

      def get_json(item_key, default: nil, config: nil)
        typed_get(item_key, default, config) { |v| v }
      end

      def live(config_key)
        start unless @connected

        cached_proxy(config_key)
      end

      def on_change(config_key = nil, &block)
        raise ArgumentError, "on_change requires a block" unless block

        if config_key.nil?
          @global_listeners << block
        else
          @key_listeners[config_key] << block
        end
        block
      end

      def on_change_item(config_key, item_key, &block)
        raise ArgumentError, "on_change_item requires a block" unless block

        @item_listeners[config_key][item_key.to_s] << block
        block
      end

      def refresh
        @lock.synchronize do
          @snapshots.clear
          @raw_chains.clear
        end
        fire_change_listeners_all("manual")
      end

      def _resolve_now(config_key)
        resolve(config_key) || {}
      end

      def _close
        # No durable resources; symmetry stub.
      end

      # Discard cached state for +config_key+; the next resolve will refetch.
      def _invalidate(config_key)
        @lock.synchronize do
          @snapshots.delete(config_key)
          @raw_chains.delete(config_key)
        end
      end

      # Internal: queue a config declaration with the management buffer.
      def _observe_config_declaration(config_id, parent:, name:, description:)
        @manage.config.register_config(
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
        @manage.config.register_config_item(config_id, item_key, item_type, default, description)
      end

      private

      def cached_proxy(config_key)
        @lock.synchronize do
          @proxies[config_key] ||= LiveConfigProxy.new(self, config_key)
        end
      end

      def typed_get(item_key, default, config_key)
        snapshot = config_key ? resolve(config_key) : merged_snapshot
        key = item_key.to_s
        # Items live under flat dotted keys (e.g. +"api.host"+ — not nested
        # +api → host+). Match Python's +current_values.get(key)+ behavior.
        value = snapshot[key]
        if value.nil? && snapshot.is_a?(Hash)
          # Fallback: support callers that constructed an explicitly-nested
          # snapshot (rare — typed model bindings only).
          parts = key.split(".")
          if parts.length > 1
            value = parts.reduce(snapshot) do |scope, k|
              break nil unless scope.is_a?(Hash)

              scope[k]
            end
          end
        end
        return default if value.nil?

        block_given? ? yield(value) : value
      end

      def merged_snapshot
        @lock.synchronize do
          @snapshots.values.reduce({}) { |acc, snap| Helpers.deep_merge(acc, snap) }
        end
      end

      def resolve(config_key)
        @lock.synchronize do
          return @snapshots[config_key].dup if @snapshots.key?(config_key)
        end

        chain = fetch_chain(config_key)
        # An empty chain means the config does not exist on the server.
        # Callers that hit +get(key)+ must raise +NotFoundError+; callers
        # that hold a +LiveConfigProxy+ get an empty Hash from
        # +_resolve_now+ so typed getters fall back to defaults.
        return nil if chain.nil? || chain.empty?

        snapshot = Helpers.resolve_chain(chain, @environment)
        @lock.synchronize do
          @raw_chains[config_key] = chain
          @snapshots[config_key] = snapshot
        end
        snapshot.dup
      end

      def fetch_chain(config_key)
        # Stub: in the absence of a generated client, the runtime returns an
        # empty chain. ManagementClient wires this up properly once the
        # generated layer is committed.
        @parent._config_transport.fetch_chain(config_key)
      rescue Smplkit::Error
        raise
      rescue StandardError => e
        raise Smplkit::ConnectionError, "Failed to fetch config #{config_key.inspect}: #{e.message}"
      end

      def handle_config_changed(data)
        key = data["key"] || data["id"]
        return unless key

        @lock.synchronize do
          @snapshots.delete(key)
          @raw_chains.delete(key)
        end
        fire_change_listeners(key, "websocket")
      end

      def handle_config_deleted(data)
        key = data["key"] || data["id"]
        return unless key

        @lock.synchronize do
          @snapshots.delete(key)
          @raw_chains.delete(key)
        end
        fire_change_listeners(key, "websocket", deleted: true)
      end

      def fire_change_listeners(config_key, source, deleted: false)
        event = ConfigChangeEvent.new(key: config_key, source: source, deleted: deleted)
        (@global_listeners + @key_listeners[config_key]).each do |cb|
          cb.call(event)
        rescue StandardError => e
          Smplkit.debug("config", "listener raised: #{e.class}: #{e.message}")
        end
        # Item-scoped listeners — fire for every registered item on the
        # changed config. We don't diff old vs new values here because
        # the Ruby cache is invalidated wholesale per config; item-scoped
        # listeners on this SDK fire on the "any change to this config"
        # signal, mirroring the +LiveConfigProxy.on_change(item_key)+
        # contract.
        @item_listeners[config_key].each_value do |listeners|
          listeners.each do |cb|
            cb.call(event)
          rescue StandardError => e
            Smplkit.debug("config", "item listener raised: #{e.class}: #{e.message}")
          end
        end
      end

      def fire_change_listeners_all(source)
        (@snapshots.keys | @key_listeners.keys).each { |key| fire_change_listeners(key, source) }
      end
    end
  end
end
