# frozen_string_literal: true

module Smplkit
  # Log severity levels used by the Smpl Logging service.
  #
  # Acts as a string-valued enum: each constant equals its name when used in
  # string contexts, and supports comparison via the +ordinal+. Members are
  # declared in alphabetical order; severity is encoded in {#ordinal}, not
  # in declaration order.
  class LogLevel
    NAMES = %w[DEBUG ERROR FATAL INFO SILENT TRACE WARN].freeze

    # @return [String] Canonical level name (e.g. +"INFO"+).
    attr_reader :name

    # @return [Integer] Severity ordinal — TRACE=0 (lowest) through SILENT=6 (highest).
    attr_reader :ordinal

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

    DEBUG  = new("DEBUG", 1)
    ERROR  = new("ERROR", 4)
    FATAL  = new("FATAL", 5)
    INFO   = new("INFO", 2)
    SILENT = new("SILENT", 6)
    TRACE  = new("TRACE", 0)
    WARN   = new("WARN", 3)

    ALL = [DEBUG, ERROR, FATAL, INFO, SILENT, TRACE, WARN].freeze

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
