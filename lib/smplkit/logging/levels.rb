# frozen_string_literal: true

require "logger"
require_relative "../log_level"

module Smplkit
  module Logging
    # Bidirectional mapping between Ruby stdlib +Logger+ levels and smplkit
    # canonical levels.
    #
    # Stdlib +Logger+ has DEBUG/INFO/WARN/ERROR/FATAL/UNKNOWN — no TRACE. The
    # +stdlib-logger+ adapter maps smplkit TRACE to stdlib DEBUG when
    # applying levels, and maps stdlib DEBUG to smplkit DEBUG when
    # discovering — there is no way to distinguish smplkit-TRACE-mapped-to-
    # DEBUG from genuine DEBUG, which is consistent with how the Python
    # +stdlib-logging+ adapter handles the same gap.
    #
    # @api private
    module Levels
      STDLIB_TO_SMPL = {
        ::Logger::DEBUG => LogLevel::DEBUG,
        ::Logger::INFO => LogLevel::INFO,
        ::Logger::WARN => LogLevel::WARN,
        ::Logger::ERROR => LogLevel::ERROR,
        ::Logger::FATAL => LogLevel::FATAL,
        ::Logger::UNKNOWN => LogLevel::SILENT
      }.freeze

      SMPL_TO_STDLIB = {
        LogLevel::TRACE => ::Logger::DEBUG,
        LogLevel::DEBUG => ::Logger::DEBUG,
        LogLevel::INFO => ::Logger::INFO,
        LogLevel::WARN => ::Logger::WARN,
        LogLevel::ERROR => ::Logger::ERROR,
        LogLevel::FATAL => ::Logger::FATAL,
        LogLevel::SILENT => ::Logger::UNKNOWN
      }.freeze

      module_function

      def stdlib_level_to_smpl(level)
        return LogLevel::DEBUG if level.nil?

        STDLIB_TO_SMPL[level] || nearest_smpl_for(level)
      end

      def smpl_level_to_stdlib(level)
        coerced = LogLevel.coerce(level)
        SMPL_TO_STDLIB.fetch(coerced)
      end

      # SemanticLogger's level system natively includes TRACE — a 1-to-1 map.
      SEMANTIC_TO_SMPL = {
        trace: LogLevel::TRACE,
        debug: LogLevel::DEBUG,
        info: LogLevel::INFO,
        warn: LogLevel::WARN,
        error: LogLevel::ERROR,
        fatal: LogLevel::FATAL
      }.freeze

      SMPL_TO_SEMANTIC = SEMANTIC_TO_SMPL.invert.freeze

      def semantic_level_to_smpl(level)
        return LogLevel::INFO if level.nil?

        SEMANTIC_TO_SMPL[level.to_sym] || LogLevel::INFO
      end

      def smpl_level_to_semantic(level)
        coerced = LogLevel.coerce(level)
        # SemanticLogger has no SILENT — closest equivalent is :fatal.
        SMPL_TO_SEMANTIC[coerced] || :fatal
      end

      def nearest_smpl_for(stdlib_level)
        sorted = STDLIB_TO_SMPL.keys.sort
        best = sorted.first
        sorted.each do |bp|
          break if bp > stdlib_level

          best = bp
        end
        STDLIB_TO_SMPL[best]
      end
    end
  end
end
