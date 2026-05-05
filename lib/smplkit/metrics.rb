# frozen_string_literal: true

require "concurrent"

module Smplkit
  # Periodically flushes accumulated SDK telemetry to the platform.
  #
  # Aggregation runs on a daemon thread. Public methods are thread-safe and
  # block briefly only to enqueue metrics.
  #
  # When +telemetry+ is disabled in resolved config, +Smplkit::Client+ does
  # not construct a +MetricsReporter+ and the +metrics+ accessor on
  # sub-clients is +nil+. Sub-clients guard every call with +metrics&.+.
  class MetricsReporter
    DEFAULT_FLUSH_INTERVAL = 60.0

    def initialize(http_client:, environment:, service:, flush_interval: DEFAULT_FLUSH_INTERVAL)
      @http_client = http_client
      @environment = environment
      @service = service
      @flush_interval = flush_interval
      @counts = {}
      @gauges = {}
      @closed = Concurrent::AtomicBoolean.new(false)
      @lock = Mutex.new
      schedule_flush
    end

    def record(metric, unit:, dimensions: nil)
      return if @closed.true?

      key = [metric, unit, dimensions || {}].freeze
      @lock.synchronize { @counts[key] = (@counts[key] || 0) + 1 }
    end

    def record_gauge(metric, value, unit:, dimensions: nil)
      return if @closed.true?

      key = [metric, unit, dimensions || {}].freeze
      @lock.synchronize { @gauges[key] = value }
    end

    def flush
      counts_snap, gauges_snap = @lock.synchronize do
        c = @counts.dup
        g = @gauges.dup
        @counts.clear
        @gauges.clear
        [c, g]
      end
      send_payload(counts_snap, gauges_snap) unless counts_snap.empty? && gauges_snap.empty?
    rescue StandardError => e
      Smplkit.debug("metrics", "flush failed: #{e.class}: #{e.message}")
    end

    def close
      return if @closed.true?

      @closed.make_true
      @timer&.shutdown
      flush
    end

    private

    def schedule_flush
      @timer = Concurrent::TimerTask.new(execution_interval: @flush_interval) { flush }
      @timer.execute
    end

    def send_payload(_counts, _gauges)
      # Telemetry payload submission is a no-op stub in the initial Ruby SDK
      # release. The Python SDK posts to /api/metrics/v1; this hook is here so
      # the same wiring can be filled in once the generated client surface is
      # finalized.
    end
  end
end
