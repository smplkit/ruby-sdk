# frozen_string_literal: true

module Smplkit
  module Logging
    module Adapters
      # Contract for pluggable logging framework integration.
      #
      # Adapters bridge the smplkit logging runtime to a specific logging
      # framework (e.g., stdlib +Logger+, +semantic_logger+). Implement this
      # interface to add support for a new logging framework.
      class Base
        # Human-readable adapter name for diagnostics
        # (e.g., +"stdlib-logger"+).
        def name
          raise NotImplementedError
        end

        # Scan the runtime for existing loggers.
        #
        # Returns an Array of triples
        # +[logger_name, explicit_level_or_nil, effective_level]+ where the
        # levels are +Smplkit::LogLevel+ instances.
        #
        #   - +explicit_level_or_nil+: the level the logger was explicitly
        #     set to, or +nil+ if it inherits from parent / framework default.
        #   - +effective_level+: the resolved level the framework uses for
        #     this logger, accounting for inheritance. Always non-nil.
        def discover
          raise NotImplementedError
        end

        # Set the level on a specific logger.
        #
        # +level+ is a +Smplkit::LogLevel+ instance; the adapter converts to
        # its framework's native level representation.
        def apply_level(_logger_name, _level)
          raise NotImplementedError
        end

        # Install continuous discovery hook.
        #
        # The block is invoked with
        # +(logger_name, explicit_level_or_nil, effective_level)+ whenever a
        # new logger is created in the framework.
        #
        # May be a no-op if the framework doesn't support creation
        # interception.
        def install_hook(&)
          raise NotImplementedError
        end

        # Remove the hook installed by +install_hook+. Called on
        # +client.logging.close+.
        def uninstall_hook
          raise NotImplementedError
        end
      end
    end
  end

  # Top-level re-export.
  LoggingAdapter = Logging::Adapters::Base
end
