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
    # Backed by the most-recent resolved Hash for a config key. +#get+ /
    # +#[]+ return the resolved value at the time of access; +#refresh+
    # rebuilds the snapshot from the underlying client.
    class LiveConfigProxy
      def initialize(client, key)
        @client = client
        @key = key
        @snapshot = client._resolve_now(key)
      end

      def get(item_key, default = nil)
        return @snapshot if item_key.nil?

        keys = item_key.to_s.split(".")
        keys.reduce(@snapshot) do |scope, k|
          break default if scope.nil?

          scope.is_a?(Hash) ? scope[k] : default
        end || default
      end

      def [](item_key)
        get(item_key)
      end

      def to_h
        @snapshot.dup
      end

      def refresh
        @snapshot = @client._resolve_now(@key)
        self
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
        @global_listeners = []
        @key_listeners = Hash.new { |h, k| h[k] = [] }
        @connected = false
        @lock = Mutex.new
      end

      def start
        return if @connected

        @environment = @parent._environment
        @ws_manager = @parent._ensure_ws
        @ws_manager.on("config_changed") { |data| handle_config_changed(data) }
        @ws_manager.on("config_deleted") { |data| handle_config_deleted(data) }
        @connected = true
      end

      def get(config_key, model_class = nil)
        start unless @connected

        snapshot = resolve(config_key)
        return snapshot if model_class.nil?

        model_class.new(snapshot)
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

        LiveConfigProxy.new(self, config_key)
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

      def refresh
        @lock.synchronize do
          @snapshots.clear
          @raw_chains.clear
        end
        fire_change_listeners_all("manual")
      end

      def _resolve_now(config_key)
        resolve(config_key)
      end

      def _close
        # No durable resources; symmetry stub.
      end

      private

      def typed_get(item_key, default, config_key)
        snapshot = config_key ? resolve(config_key) : merged_snapshot
        keys = item_key.to_s.split(".")
        value = keys.reduce(snapshot) do |scope, k|
          break default unless scope.is_a?(Hash)

          scope[k]
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
      end

      def fire_change_listeners_all(source)
        (@snapshots.keys | @key_listeners.keys).each { |key| fire_change_listeners(key, source) }
      end
    end
  end
end
