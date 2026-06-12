# frozen_string_literal: true

module Smplkit
  module Platform
    # Whether an environment participates in the canonical ordering.
    #
    # +STANDARD+ environments are the customer's deploy targets — production,
    # staging, development, etc. They participate in
    # +account.settings.environment_order+ and appear in the standard Console
    # environment columns.
    #
    # +AD_HOC+ environments are transient targets (preview branches, individual
    # developer sandboxes) that should not appear in the standard ordering.
    module EnvironmentClassification
      AD_HOC = "AD_HOC"
      STANDARD = "STANDARD"

      ALL = [AD_HOC, STANDARD].freeze
    end

    HEX_RE = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\z/

    # A color, expressed as a CSS hex string.
    #
    #   Smplkit::Color.new("#ef4444")        # 6-digit hex
    #   Smplkit::Color.new("#fff")           # 3-digit shorthand
    #   Smplkit::Color.new("#ef4444aa")      # 8-digit with alpha
    #   Smplkit::Color.rgb(239, 68, 68)      # RGB components
    #
    # Frozen — construct a fresh +Color+ to change a value.
    class Color
      attr_reader :hex

      def initialize(hex)
        raise TypeError, "Color hex must be a String, got #{hex.class}: #{hex.inspect}" unless hex.is_a?(String)
        unless HEX_RE.match?(hex)
          raise ArgumentError,
                "Invalid color #{hex.inspect}: must be a CSS hex string like '#RGB', '#RRGGBB', or '#RRGGBBAA'"
        end

        @hex = hex.downcase.freeze
        freeze
      end

      def self.rgb(red, green, blue)
        [%w[red green blue], [red, green, blue]].transpose.each do |name, val|
          unless val.is_a?(Integer) && !val.is_a?(TrueClass) && !val.is_a?(FalseClass)
            raise TypeError,
                  "Color.rgb #{name} must be an Integer, got #{val.class}"
          end
          raise ArgumentError, "Color.rgb #{name} must be in range 0-255, got #{val.inspect}" unless val.between?(0,
                                                                                                                  255)
        end

        new("##{red.to_s(16).rjust(2, "0")}#{green.to_s(16).rjust(2, "0")}#{blue.to_s(16).rjust(2, "0")}")
      end

      def to_s = @hex
      def to_str = @hex
      def ==(other) = other.is_a?(Color) && other.hex == @hex
      alias eql? ==
      def hash = @hex.hash
    end
  end

  Color = Platform::Color
  EnvironmentClassification = Platform::EnvironmentClassification
end
