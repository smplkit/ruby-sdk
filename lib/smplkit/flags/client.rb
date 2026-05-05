# frozen_string_literal: true

require "concurrent"
require "json"
require "digest"

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

    # Synchronous flags runtime namespace.
    #
    # Obtained via +Smplkit::Client#flags+. Exposes typed handles
    # (+boolean_flag+/+string_flag+/+number_flag+/+json_flag+) and runtime
    # control (+refresh+, +stats+, +on_change+). CRUD has moved to
    # +mgmt.flags.*+. Per-request context is set via
    # +client.set_context([...])+.
    class FlagsClient
      def initialize(parent, manage:, metrics:, flags_base_url:, app_base_url:)
        @parent = parent
        @manage = manage
        @metrics = metrics
        @service = parent._service
        @environment = parent._environment
        @flags_base_url = flags_base_url
        @app_base_url = app_base_url

        @flag_store = {}
        @connected = false
        @cache = ResolutionCache.new
        @handles = {}
        @global_listeners = []
        @key_listeners = Hash.new { |h, k| h[k] = [] }
        @ws_manager = nil
        @lock = Mutex.new
      end

      def boolean_flag(id, default:)
        register_handle(BooleanFlag, id, "BOOLEAN", default)
      end

      def string_flag(id, default:)
        register_handle(StringFlag, id, "STRING", default)
      end

      def number_flag(id, default:)
        register_handle(NumberFlag, id, "NUMERIC", default)
      end

      def json_flag(id, default:)
        register_handle(JsonFlag, id, "JSON", default)
      end

      # Eagerly initialize the flags subclient.
      #
      # Drains any pending flag-declaration buffer, fetches all flag
      # definitions, opens the shared WebSocket and subscribes to
      # +flag_changed+ / +flag_deleted+ / +flags_changed+ events.
      #
      # Idempotent — safe to call multiple times. Called automatically on
      # first +flag.get+ evaluation if not invoked manually.
      def start
        return if @connected

        @environment = @parent._environment
        flush_flags_safely
        refresh
        @connected = true

        @ws_manager = @parent._ensure_ws
        @ws_manager.on("flag_changed") { |data| handle_flag_changed(data) }
        @ws_manager.on("flag_deleted") { |data| handle_flag_deleted(data) }
        @ws_manager.on("flags_changed") { |data| handle_flags_changed(data) }
      end

      def refresh
        fetch_all_flags
        @cache.clear
        fire_change_listeners_all("manual")
      end

      def stats
        FlagStats.new(cache_hits: @cache.cache_hits, cache_misses: @cache.cache_misses)
      end

      # Register a change listener.
      #
      #   client.flags.on_change { |event| ... }            # global
      #   client.flags.on_change("checkout-v2") { |e| ... } # flag-scoped
      def on_change(flag_id = nil, &block)
        raise ArgumentError, "on_change requires a block" unless block

        if flag_id.nil?
          @global_listeners << block
        else
          @key_listeners[flag_id] << block
        end
        block
      end

      def _close
        # No durable resources here — kept for symmetry with Python SDK.
      end

      def _evaluate_handle(flag_id, default, context)
        start unless @connected

        eval_dict =
          if context
            @manage.contexts.register(context) if @manage.respond_to?(:contexts)
            contexts_to_eval_dict(context)
          else
            current = Smplkit.request_context
            current.empty? ? {} : contexts_to_eval_dict(current)
          end

        eval_dict["service"] = { "key" => @service } if @service && !eval_dict.key?("service")

        ctx_hash = hash_context(eval_dict)
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

      private

      def register_handle(klass, id, type_name, default)
        handle = klass.new(self, id: id, name: id, type: type_name, default: default)
        @handles[id] = handle
        if @manage.respond_to?(:flags)
          @manage.flags.register(FlagDeclaration.new(
                                   id: id, type: type_name, default: default,
                                   service: @service, environment: @environment
                                 ))
        end
        handle
      end

      def flush_flags_safely
        @manage.flags.flush
      rescue StandardError => e
        Smplkit.debug("registration", "bulk flag registration failed: #{e.class}: #{e.message}")
      end

      def fetch_all_flags
        flags = @parent._flags_transport.list_flags
        @flag_store = flags.to_h { |f| [f["id"], f] }
      rescue Smplkit::Error
        raise
      rescue StandardError => e
        raise Smplkit::ConnectionError, "Failed to fetch flags: #{e.message}"
      end

      def contexts_to_eval_dict(contexts)
        contexts.to_h { |ctx| [ctx.type, ctx.to_eval_hash] }
      end

      def hash_context(eval_dict)
        Digest::MD5.hexdigest(JSON.generate(deep_sort(eval_dict)))
      end

      def deep_sort(value)
        case value
        when Hash
          value.keys.sort_by(&:to_s).to_h { |k| [k, deep_sort(value[k])] }
        when Array
          value.map { |v| deep_sort(v) }
        else
          value
        end
      end

      def handle_flag_changed(data)
        key = data["id"]
        return unless key

        pre = @flag_store[key]&.dup || {}
        new_data = @parent._flags_transport.fetch_flag(key)
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

        first_event = FlagChangeEvent.new(id: changed.first, source: "websocket")
        @global_listeners.each do |cb|
          cb.call(first_event)
        rescue StandardError => e
          Smplkit.debug("flags", "global listener raised: #{e.class}: #{e.message}")
        end

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
    end

    # Vendored minimal JSON Logic evaluator covering the operators the smplkit
    # platform ships in flag rules.
    #
    # Stays in-tree so the Ruby SDK doesn't depend on the +json_logic+ gem
    # being correct — the Java SDK followed the same pattern. Operators
    # supported: +==+, +!=+, +<+, +<=+, +>+, +>=+, +in+, +var+, +and+, +or+,
    # +!+, +if+, +missing+, +none+.
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
end
