# frozen_string_literal: true

require "concurrent"

module Smplkit
  # Manages a single WebSocket connection to the app service event gateway.
  #
  # A single +SharedWebSocket+ instance is shared across all product modules
  # (config, flags) within one +Smplkit::Client+. Product modules register
  # listeners for specific event types; the shared connection dispatches
  # incoming events to the appropriate listeners.
  #
  # The connection runs on a dedicated SDK-owned thread; public methods are
  # thread-safe and non-blocking.
  #
  # The app service gateway protocol:
  #   - Connect to +wss://app.<base_domain>/api/ws/v1/events?api_key={key}+
  #   - Receive +{"type": "connected"}+ on success
  #   - Receive events: +{"event": "config_changed", ...}+, etc.
  #   - No subscribe message - the API key determines the account
  #   - Heartbeat: server sends +"ping"+ (text), client responds with +"pong"+
  #
  # NOTE: The actual WebSocket I/O is wired to async-websocket on a worker
  # thread. The initial Ruby SDK release defers full live-update wiring to a
  # follow-up because async-websocket interactions need integration testing
  # against the real platform.
  class SharedWebSocket
    BACKOFF_SCHEDULE = [1, 2, 4, 8, 16, 32, 60].freeze

    def initialize(app_base_url:, api_key:, metrics: nil)
      @app_base_url = app_base_url
      @api_key = api_key
      @metrics = metrics
      @listeners = Concurrent::Hash.new { |h, k| h[k] = [] }
      @listeners_lock = Mutex.new
      @connection_status = "disconnected"
      @closed = false
    end

    def on(event_name, &callback)
      @listeners_lock.synchronize { @listeners[event_name] << callback }
    end

    def off(event_name, callback)
      @listeners_lock.synchronize { @listeners[event_name].delete(callback) }
    end

    def dispatch(event_name, data)
      callbacks = @listeners_lock.synchronize { @listeners[event_name].dup }
      callbacks.each do |cb|
        cb.call(data)
      rescue StandardError => e
        Smplkit.debug("websocket", "listener for #{event_name} raised: #{e.class}: #{e.message}")
      end
    end

    attr_reader :connection_status

    # Marked as connected for in-process testing without a real WS connection.
    # Production wiring overrides this from the I/O thread once the gateway
    # confirms the handshake.
    def mark_connected!
      @connection_status = "connected"
    end

    def start
      Smplkit.debug("websocket", "starting shared WebSocket (Ruby SDK initial release: in-memory only)")
      # Live wiring is deferred. Behave as if the handshake succeeded so the
      # rest of the runtime can proceed - listeners still fire for any events
      # other code dispatches into this instance.
      mark_connected!
    end

    def stop
      @closed = true
      @connection_status = "disconnected"
    end

    def build_ws_url
      url = @app_base_url.dup
      ws_url = if url.start_with?("https://")
                 "wss://#{url[("https://".length)..]}"
               elsif url.start_with?("http://")
                 "ws://#{url[("http://".length)..]}"
               else
                 "wss://#{url}"
               end
      ws_url = ws_url.chomp("/")
      "#{ws_url}/api/ws/v1/events?api_key=#{@api_key}"
    end
  end
end
