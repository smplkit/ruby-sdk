# frozen_string_literal: true

# This file is loaded conditionally by the LoggingClient — only when the
# customer's app has +require "semantic_logger"+. The +require+ at the top is
# safe because the file itself is only loaded after a successful
# +require "semantic_logger"+ elsewhere.
require "semantic_logger"
require "concurrent"

module Smplkit
  module Logging
    module Adapters
      # Adapter for the +semantic_logger+ gem.
      #
      # SemanticLogger has its own internal logger registry and its own level
      # system that natively includes TRACE — a 1-to-1 map across all seven
      # smplkit canonical levels.
      class SemanticLoggerAdapter < Base
        def initialize
          super
          @loggers = Concurrent::Hash.new
          @on_new = nil
          @uninstalled = false
        end

        def name
          "semantic-logger"
        end

        def track(name, logger)
          @loggers[name] = logger
        end

        def discover
          rows = []
          # Default named loggers SemanticLogger creates: itself + the global
          # one. Customers add more via +SemanticLogger[ClassOrName]+.
          all_loggers.each do |name, logger|
            level = logger.respond_to?(:level) ? logger.level : nil
            smpl_level = Levels.semantic_level_to_smpl(level)
            rows << [name, smpl_level, smpl_level]
          end

          rows.uniq { |row| row[0] }
        end

        def apply_level(logger_name, level)
          logger = @loggers[logger_name]
          return unless logger
          return unless logger.respond_to?(:level=)

          logger.level = Levels.smpl_level_to_semantic(level)
        end

        def install_hook(&on_new_logger)
          @on_new = on_new_logger
          @uninstalled = false
          # SemanticLogger's API for new-logger interception varies across
          # versions. The Ruby SDK initial release relies on +discover+ being
          # called periodically — full prepend-based interception will be
          # filled in once tested against the targeted +semantic_logger+
          # version pinned in dev deps. (See ISSUES.md.)
        end

        def uninstall_hook
          @uninstalled = true
        end

        private

        def all_loggers
          loggers = @loggers.dup
          if defined?(::SemanticLogger::Logger) && ::SemanticLogger::Logger.respond_to?(:processors)
            # No-op probe to keep this method tolerant of the live API.
          end

          if defined?(::SemanticLogger) &&
             ::SemanticLogger.respond_to?(:default_level) &&
             ::SemanticLogger.respond_to?(:[])
            loggers["root"] ||= ::SemanticLogger["root"]
          end

          loggers
        end
      end
    end
  end
end
