# frozen_string_literal: true

require "json"
require "async"
require "async/http/client"
require "async/http/endpoint"

module Smplkit
  # Manages the single live-updates event stream to the app service.
  #
  # A single +EventStream+ instance is shared across all product modules
  # (config, flags, logging) within one +Smplkit::Client+. Product modules
  # register listeners for specific event names; the shared stream dispatches
  # incoming events to the appropriate listeners. Modules also register
  # refetch callbacks, invoked after every successful *re*connect so their
  # caches recover anything the server published while the stream was down.
  #
  # The stream runs on a dedicated SDK-owned thread that hosts the +Async+
  # reactor and the underlying +async-http+ I/O. Public methods are
  # thread-safe and non-blocking.
  #
  # Wire protocol — Server-Sent Events (SSE) over plain HTTPS:
  #
  #   - +GET <app_base_url>/api/v1/events+ with +Accept: text/event-stream+
  #     and +Authorization: Bearer <api_key>+.
  #   - A 200 response with a +text/event-stream+ content type is a
  #     successful connect; auth failure is a plain HTTP 401.
  #   - Each SSE frame carries the event name in the +event:+ field and a
  #     JSON object in +data:+ (+{"id": "<key>"}+ for single-resource
  #     events, +{}+ for bulk refreshes and the initial +connected+ event).
  #   - The server emits a +: keepalive+ comment frame every 30 seconds when
  #     idle; any received bytes count as liveness. Reads that stall past
  #     +READ_TIMEOUT+ seconds tear the connection down for a reconnect.
  #   - The server's +retry:+ field seeds the reconnect backoff base.
  #
  # On disconnect the reactor reconnects with exponential backoff (base
  # delay doubling up to +MAX_BACKOFF+ seconds), resetting to the base on
  # every successful connect. +stop+ flips +@closed+ and waits; the reader
  # re-checks the flag at least every +POLL_INTERVAL+, tears its own
  # connection down in-reactor, and the daemon thread terminates.
  class EventStream
    # Seconds without any bytes from the server (events or keepalive
    # comments) before the connection is considered dead — two missed
    # 30-second server keepalives.
    READ_TIMEOUT = 45

    # How long a single blocking read may park the reactor before it wakes
    # to re-check +@closed+. Liveness is tracked as a deadline across
    # polls (see +read_loop+), so this changes nothing on the wire — it
    # exists so +stop+ never has to interrupt the reactor from a foreign
    # thread: a cross-thread close cannot wake a fiber blocked in
    # +body.read+, which left teardown hanging until the next keepalive.
    POLL_INTERVAL = 1.0

    # Ceiling for the exponential reconnect backoff, in seconds.
    MAX_BACKOFF = 60

    # Initial reconnect backoff base, in seconds, used until the server
    # supplies its own via the SSE +retry:+ field.
    DEFAULT_RETRY = 1.0

    # Sent on the stream request — the platform WAF rejects requests that
    # carry no User-Agent. There is no caller-supplied header surface on the
    # event stream, so the SDK default always applies.
    USER_AGENT = Smplkit.user_agent.freeze

    # Incremental parser for a +text/event-stream+ byte stream.
    #
    # Feed it raw chunks as they arrive; it returns the events completed by
    # each chunk. Implements the SSE wire format: +\n+, +\r\n+, and +\r+
    # line terminators (including a CRLF split across chunks), a leading
    # UTF-8 BOM, comment lines (leading +:+), field values split across
    # chunk boundaries, multiple +data:+ lines joined with +\n+, and the
    # numeric +retry:+ field. Unknown fields are ignored.
    class Parser
      # One complete SSE event: +name+ is the event name (from the +event:+
      # field, defaulting to +"message"+), +data+ the joined data payload.
      Event = Struct.new(:name, :data, keyword_init: true)

      UTF8_BOM = String.new("\xEF\xBB\xBF", encoding: Encoding::BINARY).freeze

      # Milliseconds from the most recent valid +retry:+ field, or +nil+.
      attr_reader :retry_ms

      def initialize
        @buffer = String.new(encoding: Encoding::BINARY)
        @bom_pending = true
        @event_type = ""
        @data_lines = []
        @retry_ms = nil
      end

      # Consume one chunk of the stream. Returns the (possibly empty) array
      # of +Event+s completed by this chunk.
      def feed(chunk)
        @buffer << chunk.dup.force_encoding(Encoding::BINARY)
        strip_bom if @bom_pending
        events = []
        while (line = next_line)
          handle_line(line, events)
        end
        events
      end

      private

      # Drop a UTF-8 BOM at the very start of the stream. The BOM is three
      # bytes and may itself arrive split across chunks, so stay pending
      # while the buffer is still a strict prefix of it.
      def strip_bom
        if @buffer.bytesize >= UTF8_BOM.bytesize
          @buffer = @buffer.byteslice(UTF8_BOM.bytesize..) if @buffer.start_with?(UTF8_BOM)
          @bom_pending = false
        elsif !UTF8_BOM.start_with?(@buffer)
          @bom_pending = false
        end
      end

      # Extract the next complete line (terminator: +\n+, +\r\n+, or bare
      # +\r+), or +nil+ if the buffer holds none. A CR as the final buffered
      # byte is held back — it may be the first half of a CRLF whose LF is
      # still in flight. Line splitting happens on the raw bytes (0x0A/0x0D
      # never appear inside a UTF-8 multi-byte sequence); the completed line
      # is re-tagged UTF-8.
      def next_line
        cr = @buffer.index("\r")
        lf = @buffer.index("\n")
        return nil if cr.nil? && lf.nil?

        if cr && (lf.nil? || cr < lf)
          return nil if cr == @buffer.bytesize - 1

          line = @buffer.byteslice(0, cr)
          skip = @buffer.getbyte(cr + 1) == 0x0A ? 2 : 1
          @buffer = @buffer.byteslice(cr + skip, @buffer.bytesize - cr - skip)
        else
          line = @buffer.byteslice(0, lf)
          @buffer = @buffer.byteslice(lf + 1, @buffer.bytesize - lf - 1)
        end
        line.force_encoding(Encoding::UTF_8)
      end

      # A blank line dispatches the accumulated event; a leading +:+ marks a
      # comment (the server's keepalive frame) — ignored here, since mere
      # receipt of its bytes already counted as liveness at the read layer.
      def handle_line(line, events)
        if line.empty?
          flush_pending(events)
        elsif !line.start_with?(":")
          apply_field(*split_field(line))
        end
      end

      # Split +"field: value"+ on the first colon, stripping at most one
      # leading space from the value. A line with no colon is a field with
      # an empty value.
      def split_field(line)
        sep = line.index(":")
        return [line, ""] if sep.nil?

        value = line[(sep + 1)..]
        value = value[1..] if value.start_with?(" ")
        [line[0...sep], value]
      end

      # +id:+ is deliberately ignored along with unknown fields — the SDK
      # never resumes with +Last-Event-ID+.
      def apply_field(field, value)
        case field
        when "event"
          @event_type = value
        when "data"
          @data_lines << value
        when "retry"
          @retry_ms = Integer(value, 10) if value.match?(/\A\d+\z/)
        end
      end

      # Blank line: emit the accumulated event. Per the SSE spec an event
      # with an empty data buffer is discarded (the event type still
      # resets); multiple +data:+ lines join with +\n+.
      def flush_pending(events)
        unless @data_lines.empty?
          name = @event_type.empty? ? "message" : @event_type
          events << Event.new(name: name, data: @data_lines.join("\n"))
        end
        @event_type = ""
        @data_lines = []
      end
    end

    def initialize(app_base_url:, api_key:, metrics: nil)
      @app_base_url = app_base_url
      @api_key = api_key
      @metrics = metrics
      @listeners = Hash.new { |h, k| h[k] = [] }
      @refetch_callbacks = []
      @listeners_lock = Mutex.new
      @connection_status = "disconnected"
      @closed = false
      @stream_thread = nil
      @client = nil
      @response = nil
      @connection_lock = Mutex.new
      @retry_base = DEFAULT_RETRY
      @attempt = 0
      @ever_connected = false
    end

    # ----- Listener registration ------------------------------------

    def on(event_name, &callback)
      @listeners_lock.synchronize { @listeners[event_name] << callback }
    end

    def off(event_name, callback)
      @listeners_lock.synchronize { @listeners[event_name].delete(callback) }
    end

    # Register a refetch callback, invoked (with no arguments) after every
    # successful *re*connect — never on the initial connect. Product modules
    # use this to run their bulk-refresh path so caches recover events
    # missed while the stream was down.
    def on_reconnect(callback = nil, &block)
      cb = callback || block
      @listeners_lock.synchronize { @refetch_callbacks << cb }
      cb
    end

    def off_reconnect(callback)
      @listeners_lock.synchronize { @refetch_callbacks.delete(callback) }
    end

    # Dispatch +payload+ to every listener registered for +event_name+.
    # Event names nothing subscribed to dispatch to zero listeners — unknown
    # events are ignored by construction. Listener exceptions are caught and
    # logged; one bad listener never blocks the rest.
    def dispatch(event_name, payload)
      callbacks = @listeners_lock.synchronize { @listeners[event_name].dup }
      callbacks.each do |cb|
        cb.call(payload)
      rescue StandardError => e
        Smplkit.debug("events", "listener for #{event_name} raised: #{e.class}: #{e.message}")
      end
    end

    # ----- Connection status ----------------------------------------

    attr_reader :connection_status

    # ----- Lifecycle ------------------------------------------------

    def start
      return if @stream_thread&.alive?

      Smplkit.debug("events", "starting shared event stream background thread")
      @closed = false
      @connection_status = "connecting"
      @stream_thread = Thread.new { run_reactor }
      @stream_thread.name = "smplkit-events" if @stream_thread.respond_to?(:name=)
    end

    def stop
      Smplkit.debug("events", "stopping shared event stream")
      @closed = true
      thread = @stream_thread
      @stream_thread = nil
      if thread
        # The reactor re-checks +@closed+ at least every POLL_INTERVAL and
        # closes its own connection in-reactor on the way out — closing it
        # from this thread instead would race the reactor and cannot wake
        # a blocked read.
        thread.join(POLL_INTERVAL + 1.0)
        if thread.alive?
          # Last resort: a connect attempt wedged before the read loop.
          thread.kill
          close_active_connection
        end
      end
      # Set authoritatively after the thread is dead so a racing connect
      # call (which also sets "connecting") cannot clobber this value.
      @connection_status = "disconnected"
    end

    # ----- URL builder ----------------------------------------------

    def build_events_url
      url = @app_base_url.dup
      url = "https://#{url}" unless url.start_with?("https://", "http://")
      "#{url.chomp("/")}/api/v1/events"
    end

    # ----- Inbound event handling (extracted for tests) -------------

    # Process one parsed SSE event the way the live read loop does: parse
    # the JSON payload and dispatch it to the listeners registered for the
    # event name.
    #
    # Returns +:dispatched+ or +:unparseable+ for the caller to log/observe;
    # the live read loop ignores the return value.
    def handle_event(event_name, data)
      payload =
        begin
          JSON.parse(data)
        rescue JSON::ParserError
          nil
        end
      unless payload.is_a?(Hash)
        Smplkit.debug("events", "ignoring #{event_name.inspect} event with non-object payload")
        return :unparseable
      end

      dispatch(event_name, payload)
      :dispatched
    end

    private

    def run_reactor
      Sync do |task|
        stream_main(task)
      end
    rescue StandardError => e
      Smplkit.debug("events", "event stream thread exited unexpectedly: #{e.class}: #{e.message}")
    end

    # Connect/read/reconnect forever until +stop+. Every pass either ends
    # with a clean server EOF or an exception (connect failure, read error,
    # liveness timeout) — both funnel into the same backoff + retry.
    def stream_main(task)
      until @closed
        begin
          connect_and_stream(task)
        rescue StandardError => e
          return if @closed

          Smplkit.debug("events", "stream error (url: #{build_events_url}): #{e.class}: #{e.message}")
        end
        return if @closed

        @connection_status = "reconnecting"
        delay = next_backoff_delay
        Smplkit.debug("events", "reconnecting in #{delay}s")
        task.sleep(delay)
      end
    end

    # One connection lifetime: open the request, verify the SSE handshake,
    # then read frames until EOF/error. The response and client are always
    # torn down on the way out.
    def connect_and_stream(task)
      @connection_status = "connecting"
      Smplkit.debug("events", "connecting to #{build_events_url}")
      endpoint = Async::HTTP::Endpoint.parse(build_events_url)
      client = Async::HTTP::Client.new(endpoint)
      @connection_lock.synchronize { @client = client }
      response = nil
      begin
        response = client.get(endpoint.path, request_headers)
        @connection_lock.synchronize { @response = response }
        verify_response!(response)
        mark_connected
        read_loop(task, response.body)
      ensure
        mark_disconnected
        close_quietly(response)
        close_quietly(client)
        @connection_lock.synchronize do
          @response = nil
          @client = nil
        end
      end
    end

    def request_headers
      [
        ["accept", "text/event-stream"],
        ["authorization", "Bearer #{@api_key}"],
        ["user-agent", USER_AGENT]
      ]
    end

    # A successful connect is exactly: HTTP 200 with a text/event-stream
    # content type. Anything else (401 on bad auth, proxies serving HTML,
    # ...) tears down and backs off.
    def verify_response!(response)
      status = response.status
      content_type = response.headers["content-type"].to_s
      return if status == 200 && content_type.start_with?("text/event-stream")

      raise ConnectionError, "event stream connect failed: HTTP #{status} " \
                             "(content-type: #{content_type.inspect})"
    end

    def mark_connected
      reconnected = @ever_connected
      @ever_connected = true
      @attempt = 0
      @connection_status = "connected"
      @metrics&.record_gauge("platform.event_connections", 1, unit: "connections")
      Smplkit.debug("events", reconnected ? "event stream reconnected" : "event stream connected")
      run_refetch_callbacks if reconnected
    end

    # Leaving the connected state (only): flip the gauge and status. A
    # connect attempt that never completed the handshake records nothing.
    def mark_disconnected
      return unless @connection_status == "connected"

      @connection_status = "reconnecting"
      @metrics&.record_gauge("platform.event_connections", 0, unit: "connections")
    end

    def run_refetch_callbacks
      callbacks = @listeners_lock.synchronize { @refetch_callbacks.dup }
      callbacks.each do |cb|
        cb.call
      rescue StandardError => e
        Smplkit.debug("events", "refetch callback raised: #{e.class}: #{e.message}")
      end
    end

    # Read chunks until EOF, feeding the SSE parser and dispatching the
    # events it completes. Reads park for at most POLL_INTERVAL at a time
    # so +stop+ is honored promptly; liveness is a rolling deadline — any
    # received bytes, including keepalive comment frames, push it out by
    # READ_TIMEOUT. A deadline breach raises into the reconnect path.
    def read_loop(task, body)
      parser = Parser.new
      deadline = monotonic_now + READ_TIMEOUT
      until @closed
        begin
          chunk = task.with_timeout(POLL_INTERVAL) { body.read }
        rescue Async::TimeoutError
          raise Async::TimeoutError, "no data for #{READ_TIMEOUT}s" if monotonic_now >= deadline

          next
        end
        break if chunk.nil?

        deadline = monotonic_now + READ_TIMEOUT
        process_chunk(parser, chunk)
      end
    end

    # Seam for specs; the liveness deadline math needs a controllable clock.
    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def process_chunk(parser, chunk)
      parser.feed(chunk).each { |event| handle_event(event.name, event.data) }
      @retry_base = parser.retry_ms / 1000.0 unless parser.retry_ms.nil?
    end

    # Exponential backoff: base, 2x, 4x, ... capped at MAX_BACKOFF. The
    # base comes from the server's +retry:+ field (DEFAULT_RETRY until one
    # arrives); +mark_connected+ resets the exponent on every successful
    # connect. No jitter.
    def next_backoff_delay
      delay = [@retry_base * (2**@attempt), MAX_BACKOFF].min
      @attempt += 1 if delay < MAX_BACKOFF
      delay
    end

    def close_active_connection
      response, client = @connection_lock.synchronize do
        pair = [@response, @client]
        @response = nil
        @client = nil
        pair
      end
      close_quietly(response)
      close_quietly(client)
    end

    def close_quietly(resource)
      resource&.close
    rescue StandardError => e
      Smplkit.debug("events", "close raised: #{e.class}: #{e.message}")
    end
  end
end
