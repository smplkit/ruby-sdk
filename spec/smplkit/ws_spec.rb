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

    it "USER_AGENT identifies the Ruby SDK with version" do
      expect(Smplkit::SharedWebSocket::USER_AGENT).to start_with("smplkit-ruby-sdk/")
    end
  end
end
