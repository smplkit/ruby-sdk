# frozen_string_literal: true

module Smplkit
  module Audit
    # Bounded in-memory queue + worker thread for fire-and-forget audit
    # emits.
    #
    # +#enqueue+ returns immediately. The worker drains on either a
    # periodic tick or once depth crosses the high-water mark, retries
    # transient failures with exponential backoff, drops permanent 4xx
    # (other than 429), and evicts the oldest item under sustained
    # back-pressure.
    #
    # @api private
    class EventBuffer
      MAX_BUFFER_SIZE = 1000
      WATERMARK = 50
      FLUSH_INTERVAL = 5.0
      MAX_ATTEMPTS = 5
      INITIAL_BACKOFF = 0.25
      MAX_BACKOFF = 8.0

      def initialize(api)
        @api = api
        @queue = []
        @mutex = Mutex.new
        @cond = ConditionVariable.new
        @closed = false
        @dropped_count = 0
        # +@in_flight+ is the number of items the worker has shifted off
        # the queue but not yet finished POSTing. +#flush+ must wait on
        # both queue empty AND in_flight == 0 — otherwise it can return
        # while a just-shifted item is still in the middle of its HTTP
        # round-trip, and an immediately following +list+ call would
        # miss the event.
        @in_flight = 0
        @worker = Thread.new { run }
        @worker.report_on_exception = false
      end

      def enqueue(body, idempotency_key)
        depth = nil
        @mutex.synchronize do
          return if @closed

          if @queue.size >= MAX_BUFFER_SIZE
            @queue.shift
            @dropped_count += 1
            warn "[smplkit.audit] buffer full (size=#{MAX_BUFFER_SIZE}); " \
                 "dropped oldest event (total dropped=#{@dropped_count})"
          end
          @queue.push(PendingEvent.new(body, idempotency_key))
          depth = @queue.size
          @cond.signal if depth >= WATERMARK
        end
      end

      def flush(timeout: 5.0)
        deadline = monotonic_now + timeout
        loop do
          idle = @mutex.synchronize { @queue.empty? && @in_flight.zero? }
          return if idle

          if monotonic_now >= deadline
            warn "[smplkit.audit] flush timed out (timeout=#{timeout}s)"
            return
          end
          @mutex.synchronize { @cond.signal }
          sleep 0.05
        end
      end

      def close(timeout: 5.0)
        flush(timeout: timeout)
        @mutex.synchronize do
          @closed = true
          @cond.broadcast
        end
        @worker.join(timeout)
      end

      private

      def run
        loop do
          drain_once
          should_exit = false
          sleep_for = FLUSH_INTERVAL
          @mutex.synchronize do
            should_exit = @closed && @queue.empty?
            unless @queue.empty?
              head = @queue.first
              if head.next_retry_at
                until_next = head.next_retry_at - monotonic_now
                sleep_for = until_next if until_next.positive? && until_next < sleep_for
              end
            end
            @cond.wait(@mutex, sleep_for) unless should_exit
          end
          break if should_exit
        end
      end

      def drain_once
        loop do
          item = nil
          @mutex.synchronize do
            return if @queue.empty?

            head = @queue.first
            return if head.next_retry_at && head.next_retry_at > monotonic_now

            item = @queue.shift
            @in_flight += 1
          end

          status = 0
          begin
            opts = item.idempotency_key ? { idempotency_key: item.idempotency_key } : {}
            @api.record_event(item.body, opts)
            status = 201
          rescue SmplkitGeneratedClient::Audit::ApiError => e
            status = e.code || 0
          rescue StandardError
            status = 0
          end

          requeue = handle_outcome(item, status)
          @mutex.synchronize do
            @in_flight -= 1
            @queue.unshift(requeue) if requeue
          end
          return if requeue
        end
      end

      def handle_outcome(item, status)
        return nil if status >= 200 && status < 300

        if status >= 400 && status < 500 && status != 429
          warn "[smplkit.audit] permanent failure status=#{status}; event dropped"
          return nil
        end

        item.attempts += 1
        if item.attempts >= MAX_ATTEMPTS
          warn "[smplkit.audit] gave up after #{item.attempts} attempts (status=#{status})"
          return nil
        end
        backoff = [MAX_BACKOFF, INITIAL_BACKOFF * (2**(item.attempts - 1))].min
        jitter = rand(0.0..(backoff * 0.25))
        item.next_retry_at = monotonic_now + backoff + jitter
        item
      end

      def monotonic_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # Holds an outbound event between attempts.
      PendingEvent = Struct.new(:body, :idempotency_key, :attempts, :next_retry_at) do
        def initialize(body, idempotency_key, attempts = 0, next_retry_at = nil)
          super
        end
      end
      private_constant :PendingEvent
    end
  end
end
