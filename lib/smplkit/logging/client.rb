# frozen_string_literal: true

require "concurrent"

module Smplkit
  module Logging
    # Synchronous logging runtime namespace.
    #
    # Obtained via +Smplkit::Client#logging+. Manages the discovery and level
    # application for a customer's logging frameworks via pluggable adapters.
    # CRUD has moved to +mgmt.loggers.*+ / +mgmt.log_groups.*+.
    #
    # Level resolution is client-side: the server stores raw configuration
    # and the SDK walks the chain (env override → base → group chain →
    # dot-notation ancestry) to compute each managed logger's effective
    # level. See {Smplkit::Logging::Resolution}.
    class LoggingClient
      def initialize(parent, manage:, metrics:, logging_base_url:, app_base_url:)
        @parent = parent
        @manage = manage
        @metrics = metrics
        @logging_base_url = logging_base_url
        @app_base_url = app_base_url
        @adapters = []
        @installed = false
        @global_listeners = []
        @key_listeners = Hash.new { |h, k| h[k] = [] }
        @lock = Mutex.new
        # original_name → normalized_id for every adapter-discovered logger.
        # We keep originals so adapter.apply_level receives whatever the
        # framework's registry indexes by.
        @name_map = {}
        # normalized_id → resolution-cache entry. Populated by
        # +_fetch_and_apply+ and mutated by the +logger_changed+ /
        # +logger_deleted+ WS handlers.
        @loggers_cache = {}
        # group id → resolution-cache entry. Without this, any managed
        # logger with +level=null+ that inherits from a group silently
        # keeps whatever level its adapter had at startup.
        @groups_cache = {}
        # normalized_id → resolved level (string). Used to decide whether
        # to fire change listeners on a re-resolution — a group-driven
        # change isn't visible in the raw +loggers_cache+ but moves the
        # resolved value.
        @resolved_levels = {}
      end

      # Install the logging integration.
      #
      # Auto-loads the +stdlib-logger+ adapter (always) and the
      # +semantic-logger+ adapter (when the gem is available). Customer
      # explicit registration via +register_adapter+ wins over auto-load.
      def install
        return self if @installed

        auto_load_adapters if @adapters.empty?

        @adapters.each do |adapter|
          discovered = adapter.discover
          discovered.each { |(name, _explicit, effective)| observe_logger(adapter, name, effective) }
          adapter.install_hook { |name, _explicit, effective| observe_logger(adapter, name, effective) }
        end

        flush_initial_registration
        fetch_and_apply(trigger: "install")

        @ws_manager = @parent._ensure_ws
        @ws_manager.on("logger_changed") { |data| handle_logger_changed(data) }
        @ws_manager.on("logger_deleted") { |data| handle_logger_deleted(data) }
        @ws_manager.on("group_changed") { |data| handle_group_changed(data) }
        @ws_manager.on("group_deleted") { |data| handle_group_deleted(data) }
        @ws_manager.on("loggers_changed") { |data| handle_loggers_changed(data) }
        @installed = true
        self
      end
      alias start install

      def register_adapter(adapter)
        unless adapter.is_a?(Adapters::Base)
          raise ArgumentError, "adapter must implement Smplkit::Logging::Adapters::Base"
        end

        @adapters << adapter
        self
      end

      def adapters
        @adapters.dup
      end

      def get(name)
        @manage.loggers.get(name)
      end

      def list(page_number: nil, page_size: nil)
        @manage.loggers.list(page_number: page_number, page_size: page_size)
      end

      def delete(name)
        @manage.loggers.delete(name)
      end

      # Re-fetch all loggers and groups and re-apply resolved levels. Fires
      # change listeners for any logger whose resolved level moved.
      def refresh
        fetch_and_apply(trigger: "refresh")
      end

      def on_change(name = nil, &block)
        raise ArgumentError, "on_change requires a block" unless block

        if name.nil?
          @global_listeners << block
        else
          @key_listeners[Normalize.normalize_logger_name(name)] << block
        end
        block
      end

      def _close
        @adapters.each(&:uninstall_hook) if @installed
        @installed = false
      end

      private

      def auto_load_adapters
        @adapters << Adapters::StdlibLoggerAdapter.new

        begin
          require "semantic_logger"
          require_relative "adapters/semantic_logger_adapter"
          @adapters << Adapters::SemanticLoggerAdapter.new
        rescue LoadError
          Smplkit.debug("registration", "semantic_logger gem not installed; semantic-logger adapter skipped")
        end

        return unless @adapters.empty?

        # Defensive log — unreachable in practice because stdlib +Logger+
        # is always present, so +StdlibLoggerAdapter+ is always
        # constructible.
        # :nocov:
        Smplkit.debug("registration", "no logging adapters loaded; runtime features disabled")
        # :nocov:
      end

      def observe_logger(_adapter, raw_name, level)
        normalized = Normalize.normalize_logger_name(raw_name)
        @name_map[raw_name] = normalized
        @manage.loggers.register(LoggerSource.new(
                                   name: normalized,
                                   resolved_level: level,
                                   level: nil,
                                   service: @parent._service,
                                   environment: @parent._environment
                                 ))
      end

      def flush_initial_registration
        @manage.loggers.flush
      rescue StandardError => e
        Smplkit.debug("registration", "initial logger flush failed: #{e.class}: #{e.message}")
      end

      # Full re-fetch of loggers + groups, then apply resolved levels.
      # Fires change listeners for any logger whose resolved level moved.
      def fetch_and_apply(trigger:)
        Smplkit.debug("resolution", "full resolution pass starting (trigger: #{trigger})")
        loggers = @manage.loggers.list_logger_entries
        groups = @manage.log_groups.list_group_entries
        @loggers_cache = loggers
        @groups_cache = groups
        apply_levels(source: "websocket")
      rescue StandardError => e
        Smplkit.debug("resolution", "fetch_and_apply failed (trigger: #{trigger}): #{e.class}: #{e.message}")
      end

      # Resolve the effective level for every locally-known managed logger
      # and push it to every adapter. Returns the list of normalized ids
      # whose resolved level changed.
      #
      # +source+ is the +LoggerChangeEvent#source+ for any change-listener
      # event we fire. The default reflects callers that arrived through a
      # server event (WebSocket).
      def apply_levels(source: "websocket")
        changed = []
        @name_map.each do |raw_name, normalized_id|
          entry = @loggers_cache[normalized_id]
          next if entry.nil?
          next unless entry["managed"]

          resolved_string = Resolution.resolve_level(
            normalized_id, @parent._environment, @loggers_cache, @groups_cache
          )
          coerced = LogLevel.coerce(resolved_string)
          push_to_adapters(raw_name, coerced)
          previous = @resolved_levels[normalized_id]
          if previous != resolved_string
            @resolved_levels[normalized_id] = resolved_string
            changed << [normalized_id, coerced]
          end
        end
        fire_resolved_change_events(changed, source: source)
        changed
      end

      def push_to_adapters(raw_name, coerced_level)
        @adapters.each do |a|
          a.apply_level(raw_name, coerced_level)
        rescue StandardError => e
          Smplkit.debug("logging", "adapter apply_level raised: #{e.class}: #{e.message}")
        end
      end

      def fire_resolved_change_events(changed, source:)
        changed.each do |(normalized_id, coerced_level)|
          event = LoggerChangeEvent.new(name: normalized_id, level: coerced_level, source: source)
          (@global_listeners + @key_listeners[normalized_id]).each do |cb|
            cb.call(event)
          rescue StandardError => e
            Smplkit.debug("logging", "listener raised: #{e.class}: #{e.message}")
          end
        end
      end

      def handle_logger_changed(data)
        key = data["id"] || data["name"] || ""
        normalized = Normalize.normalize_logger_name(key)
        return if normalized.empty?

        begin
          entry_id, entry = @manage.loggers.get_logger_entry(normalized)
          @loggers_cache[entry_id || normalized] = entry
        rescue StandardError => e
          Smplkit.debug("websocket", "logger_changed fetch failed for #{normalized.inspect}: #{e.class}: #{e.message}")
          return
        end

        apply_levels(source: "websocket")
      end

      def handle_logger_deleted(data)
        key = data["id"] || data["name"] || ""
        normalized = Normalize.normalize_logger_name(key)
        return if normalized.empty?

        existed = @loggers_cache.delete(normalized)
        @resolved_levels.delete(normalized)
        return unless existed

        apply_levels(source: "websocket")
        fire_deletion_event(normalized)
      end

      def handle_group_changed(data)
        key = data["id"] || data["key"] || ""
        return if key.to_s.empty?

        begin
          entry_id, entry = @manage.log_groups.get_group_entry(key)
          @groups_cache[entry_id || key] = entry
        rescue StandardError => e
          Smplkit.debug("websocket", "group_changed fetch failed for #{key.inspect}: #{e.class}: #{e.message}")
          return
        end

        apply_levels(source: "websocket")
      end

      def handle_group_deleted(data)
        key = data["id"] || data["key"] || ""
        return if key.to_s.empty?

        existed = @groups_cache.delete(key)
        return unless existed

        apply_levels(source: "websocket")
        fire_deletion_event(key)
      end

      def handle_loggers_changed(_data)
        fetch_and_apply(trigger: "loggers_changed WS event")
      end

      def fire_deletion_event(key)
        event = LoggerChangeEvent.new(name: key, level: nil, source: "websocket", deleted: true)
        (@global_listeners + @key_listeners[key]).each do |cb|
          cb.call(event)
        rescue StandardError => e
          Smplkit.debug("logging", "listener raised: #{e.class}: #{e.message}")
        end
      end
    end

    LoggerChangeEvent = Struct.new(:name, :level, :source, :deleted, keyword_init: true) do
      def initialize(name:, level:, source:, deleted: false)
        super
      end

      def ==(other)
        other.is_a?(LoggerChangeEvent) &&
          name == other.name && level == other.level &&
          source == other.source && deleted == other.deleted
      end
    end
  end
end
