# frozen_string_literal: true

require "concurrent"

module Smplkit
  module Logging
    # Synchronous logging runtime namespace.
    #
    # Obtained via +Smplkit::Client#logging+. Manages the discovery and level
    # application for a customer's logging frameworks via pluggable adapters.
    # CRUD has moved to +mgmt.loggers.*+ / +mgmt.log_groups.*+.
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

        @ws_manager = @parent._ensure_ws
        @ws_manager.on("logger_changed") { |data| handle_logger_changed(data) }
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

      def list
        @manage.loggers.list
      end

      def delete(name)
        @manage.loggers.delete(name)
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

        # :nocov: defensive log — unreachable in practice because stdlib
        # +Logger+ is always present, so +StdlibLoggerAdapter+ is always
        # constructible.
        Smplkit.debug("registration", "no logging adapters loaded; runtime features disabled")
        # :nocov:
      end

      def observe_logger(_adapter, raw_name, level)
        normalized = Normalize.normalize_logger_name(raw_name)
        @manage.loggers.register(LoggerSource.new(
                                   name: normalized,
                                   resolved_level: level,
                                   level: nil,
                                   service: @parent._service,
                                   environment: @parent._environment
                                 ))
      end

      def handle_logger_changed(data)
        name = Normalize.normalize_logger_name(data["name"] || data["id"] || "")
        return if name.empty?

        level = data["resolved_level"] || data["level"]
        coerced = level && LogLevel.coerce(level)
        @adapters.each { |a| a.apply_level(name, coerced) } if coerced

        event = LoggerChangeEvent.new(name: name, level: coerced, source: "websocket")
        (@global_listeners + @key_listeners[name]).each do |cb|
          cb.call(event)
        rescue StandardError => e
          Smplkit.debug("logging", "listener raised: #{e.class}: #{e.message}")
        end
      end
    end

    LoggerChangeEvent = Struct.new(:name, :level, :source, keyword_init: true) do
      def ==(other)
        other.is_a?(LoggerChangeEvent) && name == other.name && level == other.level && source == other.source
      end
    end
  end
end
