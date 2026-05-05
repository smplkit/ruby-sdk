# frozen_string_literal: true

module Smplkit
  module Logging
    # Describes a logger to register via +Smplkit::ManagementClient#loggers#register+.
    #
    # Used both for buffered runtime discovery (called by +Smplkit::Client+ as
    # adapters discover loggers) and for explicit registration from setup
    # scripts that already know the +(service, environment)+ they belong to.
    #
    # Args:
    #   - name: Logger name (e.g. +"sqlalchemy.engine"+). Normalized to
    #     lowercase with slashes and colons replaced by dots before sending to
    #     the API.
    #   - resolved_level: Effective log level for this source.
    #   - level: Explicit (configured) log level, if different from
    #     +resolved_level+. Pass +nil+ when the level is inherited.
    #   - service: Service name this source belongs to (optional).
    #   - environment: Environment name this source belongs to (optional).
    class LoggerSource
      attr_reader :name, :resolved_level, :level, :service, :environment

      def initialize(name:, resolved_level:, level: nil, service: nil, environment: nil)
        @name = name
        @resolved_level = resolved_level
        @level = level
        @service = service
        @environment = environment
        freeze
      end

      def ==(other)
        other.is_a?(LoggerSource) && name == other.name && resolved_level == other.resolved_level &&
          level == other.level && service == other.service && environment == other.environment
      end
      alias eql? ==

      def hash = [name, resolved_level, level, service, environment].hash
    end
  end

  # Top-level re-export.
  LoggerSource = Logging::LoggerSource
end
