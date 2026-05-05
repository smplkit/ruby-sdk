# frozen_string_literal: true

require "time"

module Smplkit
  # Internal debug logging for the smplkit SDK.
  #
  # Controlled by the +SMPLKIT_DEBUG+ environment variable. When enabled
  # (+SMPLKIT_DEBUG=1+, +true+, or +yes+, case-insensitive), the SDK emits
  # timestamped diagnostic lines to stderr covering every meaningful internal
  # operation.
  #
  # Debug output goes directly to +$stderr.write+ — never through Ruby's
  # +Logger+ — to avoid interfering with the managed logging framework the SDK
  # controls.
  module Debug
    TRUTHY = %w[1 true yes].freeze

    @enabled = TRUTHY.include?(ENV.fetch("SMPLKIT_DEBUG", "").strip.downcase)

    class << self
      attr_accessor :enabled

      def enable!
        @enabled = true
      end

      def enabled?
        @enabled
      end

      def emit(subsystem, message)
        return unless @enabled

        ts = Time.now.utc.iso8601(6)
        $stderr.write("[smplkit:#{subsystem}] #{ts} #{message}\n")
      end
    end
  end

  module_function

  def debug(subsystem, message)
    Debug.emit(subsystem, message)
  end

  def enable_debug
    Debug.enable!
  end
end
