# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::SharedWebSocket do
  subject(:ws) { described_class.new(app_base_url: "https://app.smplkit.test", api_key: "k") }

  describe "#build_ws_url" do
    it "rewrites https to wss and appends the events path" do
      expect(ws.build_ws_url).to eq("wss://app.smplkit.test/api/ws/v1/events?api_key=k")
    end

    it "rewrites http to ws" do
      ws2 = described_class.new(app_base_url: "http://localhost:8080/", api_key: "abc")
      expect(ws2.build_ws_url).to eq("ws://localhost:8080/api/ws/v1/events?api_key=abc")
    end

    it "defaults to wss when scheme is missing" do
      ws2 = described_class.new(app_base_url: "app.smplkit.test", api_key: "k")
      expect(ws2.build_ws_url).to eq("wss://app.smplkit.test/api/ws/v1/events?api_key=k")
    end
  end

  describe "listener dispatch" do
    it "fires registered listeners for an event name" do
      seen = []
      ws.on("flag_changed") { |data| seen << data["id"] }
      ws.dispatch("flag_changed", "id" => "checkout-v2")
      expect(seen).to eq(["checkout-v2"])
    end

    it "swallows listener exceptions" do
      ws.on("x") { raise "boom" }
      expect { ws.dispatch("x", {}) }.not_to raise_error
    end

    it "off removes a listener" do
      cb = ->(_data) {}
      ws.on("x", &cb)
      ws.off("x", cb)
      seen = []
      ws.on("x") { |d| seen << d }
      ws.dispatch("x", "n" => 1)
      expect(seen).to eq(["n" => 1])
    end
  end

  describe "#handle_inbound" do
    it "responds to ping with pong via the supplied sender" do
      sent = []
      result = ws.handle_inbound("ping", send_pong: ->(reply) { sent << reply })
      expect(result).to eq(:ping)
      expect(sent).to eq(["pong"])
    end

    it "parses JSON events and dispatches to listeners" do
      seen = []
      ws.on("flag_changed") { |data| seen << data["id"] }
      payload = JSON.generate("event" => "flag_changed", "id" => "checkout-v2")
      result = ws.handle_inbound(payload, send_pong: ->(_) {})
      expect(result).to eq(:event)
      expect(seen).to eq(["checkout-v2"])
    end

    it "returns :no_event when JSON has no event key" do
      result = ws.handle_inbound(JSON.generate("type" => "connected"), send_pong: ->(_) {})
      expect(result).to eq(:no_event)
    end

    it "returns :unparseable for non-JSON, non-ping text" do
      result = ws.handle_inbound("not json", send_pong: ->(_) {})
      expect(result).to eq(:unparseable)
    end
  end

  describe "lifecycle without a server" do
    it "start spawns a daemon thread and stop tears it down" do
      ws.start
      expect(ws.instance_variable_get(:@ws_thread)).to be_a(Thread)
      ws.stop
      expect(ws.instance_variable_get(:@ws_thread)).to be_nil
      expect(ws.connection_status).to eq("disconnected")
    end

    it "start is idempotent on repeat calls" do
      ws.start
      original = ws.instance_variable_get(:@ws_thread)
      ws.start
      expect(ws.instance_variable_get(:@ws_thread)).to equal(original)
      ws.stop
    end
  end

  describe "constants" do
    it "exposes the canonical reconnect backoff schedule" do
      expect(Smplkit::SharedWebSocket::BACKOFF_SCHEDULE).to eq([1, 2, 4, 8, 16, 32, 60])
    end

    it "USER_AGENT identifies the Ruby SDK with the gem version" do
      expect(Smplkit::SharedWebSocket::USER_AGENT).to eq("smplkit-sdk-ruby/#{Smplkit.gem_version}")
      expect(Smplkit::SharedWebSocket::USER_AGENT).to start_with("smplkit-sdk-ruby/")
    end
  end

  describe "#message_to_string" do
    it "returns a String unchanged" do
      expect(ws.send(:message_to_string, "hello")).to eq("hello")
    end

    it "uses to_str when available" do
      msg = double("Message")
      allow(msg).to receive(:respond_to?).with(:to_str).and_return(true)
      allow(msg).to receive(:to_str).and_return("text")
      expect(ws.send(:message_to_string, msg)).to eq("text")
    end

    it "falls back to to_s for opaque types" do
      msg = double("Message")
      allow(msg).to receive(:respond_to?).with(:to_str).and_return(false)
      allow(msg).to receive(:to_s).and_return("via to_s")
      expect(ws.send(:message_to_string, msg)).to eq("via to_s")
    end
  end

  describe "#close_active_connection" do
    it "is a no-op when no connection has been established" do
      expect { ws.send(:close_active_connection) }.not_to raise_error
    end

    it "swallows exceptions raised by the underlying connection close" do
      bad_conn = double("connection")
      allow(bad_conn).to receive(:close).and_raise("boom")
      ws.instance_variable_set(:@connection, bad_conn)
      expect { ws.send(:close_active_connection) }.not_to raise_error
    end
  end

  describe "#connect" do
    let(:fake_connection) { double("AsyncWebSocket::Connection") }
    let(:task) { double("AsyncTask") }

    before do
      allow(Async::HTTP::Endpoint).to receive(:parse).and_return(:endpoint)
      allow(Async::WebSocket::Client).to receive(:connect).and_return(fake_connection)
    end

    it "completes the handshake on a connected message and enters the receive loop" do
      allow(fake_connection).to receive(:read).and_return(JSON.generate("type" => "connected"), nil)
      ws.send(:connect, task)
      expect(ws.connection_status).to eq("connected")
    end

    it "sends the SDK User-Agent on the handshake" do
      allow(fake_connection).to receive(:read).and_return(JSON.generate("type" => "connected"), nil)
      ws.send(:connect, task)
      expect(Async::WebSocket::Client).to have_received(:connect)
        .with(:endpoint, headers: { "user-agent" => "smplkit-sdk-ruby/#{Smplkit.gem_version}" })
    end

    it "is a no-op once the socket has been closed" do
      ws.instance_variable_set(:@closed, true)
      ws.send(:connect, task)
      expect(Async::WebSocket::Client).not_to have_received(:connect)
    end

    it "raises when the server sends an error frame" do
      allow(fake_connection).to receive(:read).and_return(JSON.generate("type" => "error", "message" => "no auth"))
      expect { ws.send(:connect, task) }.to raise_error(/Connection error: no auth/)
    end

    it "records the platform.websocket_connections gauge when metrics are present" do
      metrics = double("metrics", record_gauge: nil)
      ws.instance_variable_set(:@metrics, metrics)
      allow(fake_connection).to receive(:read).and_return(JSON.generate("type" => "connected"), nil)
      ws.send(:connect, task)
      expect(metrics).to have_received(:record_gauge).with("platform.websocket_connections", 1, unit: "connections")
    end
  end

  describe "#receive_loop" do
    let(:task) { double("AsyncTask") }

    it "exits when the connection returns nil" do
      conn = double("conn")
      allow(conn).to receive(:read).and_return(nil)
      expect { ws.send(:receive_loop, task, conn) }.not_to raise_error
    end

    it "dispatches inbound JSON events" do
      conn = double("conn")
      allow(conn).to receive(:read).and_return(JSON.generate("event" => "flag_changed", "id" => "x"), nil)
      seen = []
      ws.on("flag_changed") { |data| seen << data["id"] }
      ws.send(:receive_loop, task, conn)
      expect(seen).to eq(["x"])
    end

    it "responds to a ping with a pong" do
      conn = double("conn")
      allow(conn).to receive(:read).and_return("ping", nil)
      allow(conn).to receive(:write)
      ws.send(:receive_loop, task, conn)
      expect(conn).to have_received(:write).with("pong")
    end

    it "exits silently when the loop body raises and the socket has been closed" do
      conn = double("conn")
      allow(conn).to receive(:read).and_raise("boom")
      ws.instance_variable_set(:@closed, true)
      expect { ws.send(:receive_loop, task, conn) }.not_to raise_error
    end

    it "transitions to reconnecting on read errors when not yet closed" do
      conn = double("conn")
      allow(conn).to receive(:read).and_raise("boom")
      allow(ws).to receive(:reconnect)
      ws.send(:receive_loop, task, conn)
      expect(ws.connection_status).to eq("reconnecting")
      expect(ws).to have_received(:reconnect)
    end
  end

  describe "#reconnect" do
    let(:task) { double("AsyncTask", sleep: nil) }

    it "retries on connect failure and stops on success" do
      attempts = 0
      allow(ws).to receive(:connect) do
        attempts += 1
        raise "fail" if attempts < 2

        nil
      end
      ws.send(:reconnect, task)
      expect(attempts).to eq(2)
    end

    it "stops immediately if the WS has been closed by the outer thread" do
      ws.instance_variable_set(:@closed, true)
      expect { ws.send(:reconnect, task) }.not_to raise_error
    end

    it "stops between sleep and connect when @closed flips" do
      attempts = 0
      allow(task).to receive(:sleep) { ws.instance_variable_set(:@closed, true) }
      allow(ws).to receive(:connect) { attempts += 1 }
      ws.send(:reconnect, task)
      expect(attempts).to eq(0)
    end
  end

  describe "#run_reactor" do
    it "wraps Sync exceptions in a debug log instead of bubbling" do
      allow(ws).to receive(:ws_main).and_raise("boom")
      Smplkit::Debug.enabled = true
      expect { ws.send(:run_reactor) }.to output(/exited unexpectedly/).to_stderr
    ensure
      Smplkit::Debug.enabled = false
    end
  end

  describe "#ws_main" do
    let(:task) { double("AsyncTask") }

    it "calls reconnect when the initial connect raises" do
      allow(ws).to receive(:connect).and_raise("initial fail")
      allow(ws).to receive(:reconnect)
      ws.send(:ws_main, task)
      expect(ws).to have_received(:reconnect).with(task)
    end

    it "does not reconnect once @closed is set even if connect raised" do
      allow(ws).to receive(:connect).and_raise("fail")
      ws.instance_variable_set(:@closed, true)
      allow(ws).to receive(:reconnect)
      ws.send(:ws_main, task)
      expect(ws).not_to have_received(:reconnect)
    end
  end
end
