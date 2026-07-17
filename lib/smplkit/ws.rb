# frozen_string_literal: true

require "json"
require "async"
require "async/http/endpoint"
require "async/http/protocol/http1"
require "async/websocket/client"
require "concurrent"

module Smplkit
  # Manages a single WebSocket connection to the app service event gateway.
  #
  # A single +SharedWebSocket+ instance is shared across all product modules
  # (config, flags, logging) within one +Smplkit::Client+. Product modules
  # register listeners for specific event types; the shared connection
  # dispatches incoming events to the appropriate listeners.
  #
  # The connection runs on a dedicated SDK-owned thread that hosts the
  # +Async+ reactor and the underlying +async-websocket+ I/O. Public
  # methods are thread-safe and non-blocking.
  #
  # Gateway protocol:
  #
  #   - Connect to +wss://app.<base_domain>/api/ws/v1/events?api_key={key}+
  #   - Receive +{"type": "connected"}+ on success
  #   - Receive events: +{"event": "config_changed", ...}+, etc.
  #   - No subscribe message — the API key determines the account
  #   - Heartbeat: server sends +"ping"+ (text), client responds with +"pong"+
  #
  # On disconnect the reactor reconnects with exponential backoff
  # (1, 2, 4, 8, 16, 32, 60 seconds, then capped). +stop+ closes the
  # connection from the outer thread; the reader exits and the daemon
  # thread terminates.
  class SharedWebSocket
    BACKOFF_SCHEDULE = [1, 2, 4, 8, 16, 32, 60].freeze

    # Sent on the WebSocket upgrade request — the platform WAF rejects
    # handshakes that carry no User-Agent. There is no caller-supplied
    # header surface on the WebSocket, so the SDK default always applies.
    USER_AGENT = Smplkit.user_agent.freeze

    def initialize(app_base_url:, api_key:, metrics: nil)
      @app_base_url = app_base_url
      @api_key = api_key
      @metrics = metrics
      @listeners = Hash.new { |h, k| h[k] = [] }
      @listeners_lock = Mutex.new
      @connection_status = "disconnected"
      @closed = false
      @ws_thread = nil
      @connection = nil
      @connection_lock = Mutex.new
    end

    # ----- Listener registration ------------------------------------

    def on(event_name, &callback)
      @listeners_lock.synchronize { @listeners[event_name] << callback }
    end

    def off(event_name, callback)
      @listeners_lock.synchronize { @listeners[event_name].delete(callback) }
    end

    # Dispatch +data+ to every listener registered for +event_name+.
    # Listener exceptions are caught and logged; one bad listener never
    # blocks the rest.
    def dispatch(event_name, data)
      callbacks = @listeners_lock.synchronize { @listeners[event_name].dup }
      callbacks.each do |cb|
        cb.call(data)
      rescue StandardError => e
        Smplkit.debug("websocket", "listener for #{event_name} raised: #{e.class}: #{e.message}")
      end
    end

    # ----- Connection status ----------------------------------------

    attr_reader :connection_status

    # ----- Lifecycle ------------------------------------------------

    def start
      return if @ws_thread&.alive?

      Smplkit.debug("websocket", "starting shared WebSocket background thread")
      @closed = false
      @connection_status = "connecting"
      @ws_thread = Thread.new { run_reactor }
      @ws_thread.name = "smplkit-shared-ws" if @ws_thread.respond_to?(:name=)
    end

    def stop
      Smplkit.debug("websocket", "stopping shared WebSocket")
      @closed = true
      close_active_connection
      thread = @ws_thread
      @ws_thread = nil
      if thread
        thread.join(2.0)
        thread.kill if thread.alive?
      end
      # Set authoritatively after the thread is dead so a racing connect
      # call (which also sets "connecting") cannot clobber this value.
      @connection_status = "disconnected"
    end

    # ----- URL builder ----------------------------------------------

    def build_ws_url
      url = @app_base_url.dup
      ws_url =
        if url.start_with?("https://")
          "wss://#{url[("https://".length)..]}"
        elsif url.start_with?("http://")
          "ws://#{url[("http://".length)..]}"
        else
          "wss://#{url}"
        end
      ws_url = ws_url.chomp("/")
      "#{ws_url}/api/ws/v1/events?api_key=#{@api_key}"
    end

    # ----- Inbound message handling (extracted for tests) -----------

    # Process a single inbound text frame the way the live reactor does:
    # +"ping"+ → call +send_pong+ with +"pong"+; otherwise parse JSON and,
    # if a +"event"+ key is present, dispatch to listeners.
    #
    # Returns one of +:ping+, +:event+, +:no_event+, +:unparseable+ for the
    # caller to log/observe; the live reactor ignores the return value.
    def handle_inbound(text, send_pong:)
      if text == "ping"
        send_pong.call("pong")
        return :ping
      end

      data =
        begin
          JSON.parse(text)
        rescue JSON::ParserError
          return :unparseable
        end

      event = data["event"]
      if event
        dispatch(event, data)
        :event
      else
        :no_event
      end
    end

    private

    def run_reactor
      Sync do |task|
        ws_main(task)
      end
    rescue StandardError => e
      Smplkit.debug("websocket", "shared WebSocket thread exited unexpectedly: #{e.class}: #{e.message}")
    end

    def ws_main(task)
      connect(task)
    rescue StandardError => e
      return if @closed

      Smplkit.debug(
        "websocket",
        "connection failed on startup (url: #{safe_url}): #{e.class}: #{e.message}"
      )
      reconnect(task)
    end

    def connect(task)
      return if @closed

      url = build_ws_url
      @connection_status = "connecting"
      Smplkit.debug("websocket", "connecting to #{safe_url}")

      # Force HTTP/1.1 for the WebSocket upgrade. async-http defaults to
      # HTTP/2 on TLS endpoints, but the smplkit event gateway speaks the
      # classic RFC 6455 upgrade over HTTP/1.1, not the HTTP/2-tunneled
      # variant from RFC 8441 — without this override the upgrade returns
      # a Protocol::HTTP2::StreamError before any frame is exchanged.
      endpoint = Async::HTTP::Endpoint.parse(url, protocol: Async::HTTP::Protocol::HTTP1)
      headers = { "user-agent" => USER_AGENT }
      connection = Async::WebSocket::Client.connect(endpoint, headers: headers)
      @connection_lock.synchronize { @connection = connection }
      Smplkit.debug("websocket", "WebSocket connected, waiting for confirmation")

      raw = connection.read
      data = JSON.parse(message_to_string(raw))
      if data["type"] == "error"
        err = data["message"]
        Smplkit.debug("websocket", "connection error from server: #{err.inspect}")
        raise "Connection error: #{err}"
      end

      @connection_status = "connected"
      @metrics&.record_gauge("platform.websocket_connections", 1, unit: "connections")
      receive_loop(task, connection)
    end

    def receive_loop(task, connection)
      until @closed
        message = connection.read
        break if message.nil?

        text = message_to_string(message)
        handle_inbound(text, send_pong: ->(reply) { connection.write(reply) })
      end
    rescue StandardError => e
      return if @closed

      Smplkit.debug("websocket", "receive loop error: #{e.class}: #{e.message}")
      @connection_status = "reconnecting"
      @metrics&.record_gauge("platform.websocket_connections", 0, unit: "connections")
      reconnect(task)
    end

    def reconnect(task)
      attempt = 0
      until @closed
        delay = BACKOFF_SCHEDULE[[attempt, BACKOFF_SCHEDULE.length - 1].min]
        Smplkit.debug("websocket", "reconnecting in #{delay}s (attempt #{attempt + 1})")
        task.sleep(delay)
        return if @closed

        begin
          connect(task)
          return
        rescue StandardError => e
          Smplkit.debug("websocket", "reconnect attempt #{attempt + 1} failed: #{e.class}: #{e.message}")
          attempt += 1
        end
      end
    end

    def message_to_string(message)
      return message if message.is_a?(String)
      return message.to_str if message.respond_to?(:to_str)

      message.to_s
    end

    def close_active_connection
      conn = @connection_lock.synchronize do
        c = @connection
        @connection = nil
        c
      end
      return unless conn

      begin
        conn.close
      rescue StandardError => e
        Smplkit.debug("websocket", "close raised: #{e.class}: #{e.message}")
      end
    end

    def safe_url
      build_ws_url.split("?", 2).first
    end
  end
end
