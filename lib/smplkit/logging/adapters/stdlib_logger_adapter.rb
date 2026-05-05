# frozen_string_literal: true

require "logger"
require "concurrent"

module Smplkit
  module Logging
    module Adapters
      # Adapter for Ruby stdlib +Logger+ (which +ActiveSupport::Logger+
      # subclasses, so Rails is covered automatically).
      #
      # Ruby has no global logger registry like Python's
      # +logging.Logger.manager.loggerDict+. Instead this adapter:
      #
      #   1. Always reports +"root"+ at the framework default level.
      #   2. Reports +"rails"+ if +Rails.logger+ is defined.
      #   3. Reports any logger explicitly registered via +track+.
      #   4. Uses +Module#prepend+ on +::Logger+ to catch new logger
      #      creation. The hook fires on every +Logger.new+ call.
      class StdlibLoggerAdapter < Base
        @hook_module = nil
        @global_lock = Mutex.new

        class << self
          attr_reader :hook_module
        end

        def initialize
          super
          @loggers = Concurrent::Hash.new
          track_root!
          @on_new = nil
          @uninstalled = false
        end

        def name
          "stdlib-logger"
        end

        # Register an additional logger with the adapter so its level can be
        # discovered and applied.
        def track(logger_name, logger)
          @loggers[logger_name] = logger
        end

        def discover
          rows = []
          @loggers.each_pair do |logger_name, logger|
            level = logger.level
            smpl_level = Levels.stdlib_level_to_smpl(level)
            rows << [logger_name, smpl_level, smpl_level]
          end

          if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
            track("rails", ::Rails.logger) unless @loggers.key?("rails")
            level = ::Rails.logger.level
            smpl_level = Levels.stdlib_level_to_smpl(level)
            rows << ["rails", smpl_level, smpl_level]
          end

          rows.uniq { |row| row[0] }
        end

        def apply_level(logger_name, level)
          logger = @loggers[logger_name]
          return unless logger

          native = Levels.smpl_level_to_stdlib(level)
          logger.level = native
        end

        def install_hook(&on_new_logger)
          @on_new = on_new_logger
          @uninstalled = false

          self.class.global_lock.synchronize do
            unless self.class.hook_installed?
              hook = self.class.build_hook
              ::Logger.prepend(hook)
              self.class.instance_variable_set(:@hook_module, hook)
            end
            self.class.adapters << self
          end
        end

        def uninstall_hook
          @uninstalled = true
          self.class.global_lock.synchronize do
            self.class.adapters.delete(self)
          end
        end

        # Called by the prepended hook when a new Logger is created.
        def on_new_logger_created(logger, name)
          return if @uninstalled

          track(name, logger)
          smpl_level = Levels.stdlib_level_to_smpl(logger.level)
          @on_new&.call(name, smpl_level, smpl_level)
        end

        class << self
          def adapters
            @adapters ||= Concurrent::Array.new
          end

          def global_lock
            @global_lock ||= Mutex.new
          end

          def hook_installed?
            !@hook_module.nil?
          end

          def build_hook
            Module.new do
              def initialize(*args, **kwargs)
                super
                StdlibLoggerAdapter.adapters.each do |adapter|
                  adapter.on_new_logger_created(self, "logger.#{object_id}")
                rescue StandardError
                  # Swallow to keep Logger.new robust under the hook.
                end
              end
            end
          end

          def reset_hook!
            @hook_module = nil
          end
        end

        private

        def track_root!
          @loggers["root"] ||= ::Logger.new($stdout)
        end
      end
    end
  end

  StdlibLoggerAdapter = Logging::Adapters::StdlibLoggerAdapter
end
