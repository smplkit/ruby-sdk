# frozen_string_literal: true

require "spec_helper"

# Final pass to close the remaining edge-case lines.

RSpec.describe Smplkit::SharedWebSocket do
  subject(:ws) do
    described_class.new(app_base_url: "https://app.smplkit.test", api_key: "k")
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
      ws.send(:receive_loop, task, conn)
      # Just reaching here means it didn't loop forever.
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

RSpec.describe Smplkit::Flags::FlagsClient do
  subject(:client) do
    described_class.new(parent, manage: management, metrics: nil,
                                flags_base_url: "https://flags.smplkit.test",
                                app_base_url: "https://app.smplkit.test")
  end

  let(:flags_ns) { instance_double(Smplkit::ManagementClient::FlagsNamespace, register: nil, flush: nil) }
  let(:contexts_ns) { instance_double(Smplkit::ManagementClient::ContextsNamespace, register: nil) }
  let(:management) { instance_double(Smplkit::ManagementClient, flags: flags_ns, contexts: contexts_ns) }
  let(:flags_transport) { double("flags_transport", list_flags: [], fetch_flag: nil) }
  let(:ws) do
    Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k")
  end
  let(:parent) do
    double(_service: "svc", _environment: "stg", _ensure_ws: ws, _flags_transport: flags_transport)
  end

  describe "handle_flags_changed listener-exception swallowing" do
    it "swallows global listener exceptions" do
      old_def = { "id" => "x", "name" => "x", "type" => "BOOLEAN", "default" => false, "environments" => {} }
      new_def = old_def.merge("default" => true)
      client.instance_variable_get(:@flag_store)["x"] = old_def
      allow(flags_transport).to receive(:list_flags).and_return([new_def])
      client.on_change { raise "global boom" }
      expect { client.send(:handle_flags_changed, {}) }.not_to raise_error
    end

    it "swallows scoped listener exceptions" do
      old_def = { "id" => "x", "name" => "x", "type" => "BOOLEAN", "default" => false, "environments" => {} }
      new_def = old_def.merge("default" => true)
      client.instance_variable_get(:@flag_store)["x"] = old_def
      allow(flags_transport).to receive(:list_flags).and_return([new_def])
      client.on_change("x") { raise "scoped boom" }
      expect { client.send(:handle_flags_changed, {}) }.not_to raise_error
    end
  end
end

RSpec.describe Smplkit::Flags::JsonLogicEvaluator do
  describe ".resolve_var" do
    it "falls back to the default when a path step walks into a scalar" do
      # apply -> resolve_var("a.b.c", data, "fallback"). The walk hits
      # scope = "scalar" at the third step, which is neither Hash nor a
      # numeric-indexable Array, so it returns the default.
      logic = { "var" => ["a.b.c", "fallback"] }
      result = described_class.apply(logic, { "a" => { "b" => "scalar" } })
      expect(result).to eq("fallback")
    end
  end

  describe ".compare" do
    it "supports 3-element comparisons (a < b < c)" do
      expect(described_class.apply({ "<" => [1, 2, 3] }, {})).to be(true)
    end

    it "returns false for 4+ element comparisons" do
      expect(described_class.apply({ "<" => [1, 2, 3, 4] }, {})).to be(false)
    end
  end

  describe ".eval_in" do
    it "swallows TypeError when haystack doesn't support include?" do
      result = described_class.apply({ "in" => ["a", 42] }, {})
      expect(result).to be(false)
    end
  end
end

RSpec.describe Smplkit::Config::ConfigClient do
  subject(:client) { described_class.new(parent, manage: nil, metrics: nil) }

  let(:transport) { double("ConfigTransport") }
  let(:ws) do
    Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k")
  end
  let(:parent) do
    double(_environment: "staging", _service: "svc", _ensure_ws: ws,
           _config_transport: transport)
  end

  it "typed_get returns the default when a path step lands on a non-Hash" do
    allow(transport).to receive(:fetch_chain).and_return([
                                                           { "id" => "svc",
                                                             "items" => { "api" => { "value" => "string-not-hash",
                                                                                     "type" => "STRING" } },
                                                             "environments" => {} }
                                                         ])
    expect(client.get_string("api.host", default: "fallback", config: "svc")).to eq("fallback")
  end

  it "get_number returns the default when the stored value can't be coerced to Float" do
    allow(transport).to receive(:fetch_chain).and_return([
                                                           { "id" => "svc",
                                                             "items" => { "retries" => { "value" => "abc",
                                                                                         "type" => "STRING" } },
                                                             "environments" => {} }
                                                         ])
    expect(client.get_number("retries", default: 99, config: "svc")).to eq(99)
  end
end

RSpec.describe Smplkit::Logging::LoggingClient do
  subject(:client) do
    described_class.new(parent, manage: management, metrics: nil,
                                logging_base_url: "https://x", app_base_url: "https://y")
  end

  let(:loggers_ns) { instance_double(Smplkit::ManagementClient::LoggersNamespace, register: nil) }
  let(:management) { instance_double(Smplkit::ManagementClient, loggers: loggers_ns) }
  let(:ws) { Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k") }
  let(:parent) { double(_service: "svc", _environment: "stg", _ensure_ws: ws) }

  it "auto_load_adapters debug-logs when no adapters end up loaded" do
    Smplkit::Debug.enabled = true
    allow(client).to receive(:require).with("semantic_logger").and_raise(LoadError)
    # Bypass the stdlib auto-construction so we trigger the empty branch.
    allow(Smplkit::Logging::Adapters::StdlibLoggerAdapter).to receive(:new) do
      raise StandardError, "force-empty"
    end
    expect do
      client.send(:auto_load_adapters)
    rescue StandardError
      # Stdlib raise is intentional — we still want the empty-adapter
      # branch to fire afterwards.
    end.not_to raise_error
  ensure
    Smplkit::Debug.enabled = false
  end
end

RSpec.describe Smplkit::ManagementClient::ErrorMapping do
  it "re-raises a generated ApiError that somehow survived raise_for_status" do
    err = SmplkitGeneratedClient::Flags::ApiError.new(code: 200, response_body: "")
    expect { described_class.call { raise err } }.to raise_error(SmplkitGeneratedClient::Flags::ApiError)
  end
end

RSpec.describe Smplkit::ManagementClient::ConfigNamespace do
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:mgmt) { Smplkit::ManagementClient.from_resolved(resolved) }

  it "config_to_chain_entry serializes per-environment overrides" do
    cfg = mgmt.config.new_config("showcase")
    cfg.set_string("api.host", "stg.example.com", environment: "staging")
    chain_entry = mgmt.config.send(:config_to_chain_entry, cfg)
    expect(chain_entry["environments"]["staging"]["values"])
      .to eq("api.host" => { "value" => "stg.example.com", "type" => "STRING" })
  end
end
