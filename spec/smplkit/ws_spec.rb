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

  it "start marks the in-process status as connected" do
    ws.start
    expect(ws.connection_status).to eq("connected")
  end
end
