# frozen_string_literal: true

module Smplkit
  # Log severity levels used by the Smpl Logging service.
  #
  # Acts as a string-valued enum: each constant equals its name when used in
  # string contexts, and supports comparison via the +ordinal+.
  class LogLevel
    NAMES = %w[TRACE DEBUG INFO WARN ERROR FATAL SILENT].freeze

    attr_reader :name, :ordinal

    def initialize(name, ordinal)
      @name = name.freeze
      @ordinal = ordinal
      freeze
    end

    def to_s = @name
    def to_str = @name
    def inspect = "#<Smplkit::LogLevel #{@name}>"
    def ==(other) = other.is_a?(LogLevel) ? @ordinal == other.ordinal : @name == other
    def hash = @ordinal.hash
    def eql?(other) = self == other
    def <=>(other) = other.is_a?(LogLevel) ? @ordinal <=> other.ordinal : nil

    include Comparable

    TRACE  = new("TRACE", 0)
    DEBUG  = new("DEBUG", 1)
    INFO   = new("INFO", 2)
    WARN   = new("WARN", 3)
    ERROR  = new("ERROR", 4)
    FATAL  = new("FATAL", 5)
    SILENT = new("SILENT", 6)

    ALL = [TRACE, DEBUG, INFO, WARN, ERROR, FATAL, SILENT].freeze

    BY_NAME = ALL.to_h { |lvl| [lvl.name, lvl] }.freeze

    def self.from_string(value)
      raise ArgumentError, "log level cannot be nil" if value.nil?

      key = value.to_s.upcase
      level = BY_NAME[key]
      raise ArgumentError, "unknown log level: #{value.inspect}" unless level

      level
    end

    def self.coerce(value)
      return value if value.is_a?(LogLevel)

      from_string(value)
    end
  end
end
