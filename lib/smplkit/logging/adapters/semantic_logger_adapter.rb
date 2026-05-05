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
      #
      # New-logger detection uses +Module#prepend+ on +SemanticLogger::Logger+
      # to intercept +initialize+. The hook is installed once globally and
      # shared across all adapter instances via a class-level +@adapters+ list,
      # matching the same pattern used by +StdlibLoggerAdapter+.
      class SemanticLoggerAdapter < Base
        @hook_module = nil
        @global_lock = Mutex.new

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

          self.class.global_lock.synchronize do
            unless self.class.hook_installed?
              hook = self.class.build_hook
              ::SemanticLogger::Logger.prepend(hook)
              self.class.instance_variable_set(:@hook_module, hook)
            end
            self.class.adapters << self unless self.class.adapters.include?(self)
          end
        end

        def uninstall_hook
          @uninstalled = true
          self.class.global_lock.synchronize do
            self.class.adapters.delete(self)
          end
        end

        # Called by the prepended hook when a new SemanticLogger::Logger is created.
        def on_new_logger_created(logger)
          return if @uninstalled

          name = logger.name
          return unless name

          @loggers[name] = logger
          level = logger.respond_to?(:level) ? logger.level : nil
          smpl_level = Levels.semantic_level_to_smpl(level)
          @on_new&.call(name, smpl_level, smpl_level)
        rescue StandardError
          nil
        end

        class << self
          attr_reader :global_lock, :hook_module

          def adapters
            @adapters ||= Concurrent::Array.new
          end

          def hook_installed?
            !@hook_module.nil?
          end

          # Uses define_method so the adapter_class reference is captured as a
          # closure, avoiding constant-lookup issues in anonymous modules.
          def build_hook
            adapter_class = self
            Module.new do
              define_method(:initialize) do |klass, level = nil, filter = nil|
                super(klass, level, filter)
                adapter_class.adapters.each do |adapter|
                  adapter.on_new_logger_created(self)
                rescue StandardError
                  # Don't let hook errors break logger creation.
                end
              end
            end
          end

          def reset_hook!
            @hook_module = nil
          end
        end

        private

        def all_loggers
          loggers = @loggers.dup
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
