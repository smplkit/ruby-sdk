# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Client do
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedConfig.new(
      api_key: "k_LONGENOUGHTOMASK", base_domain: "smplkit.test", scheme: "https",
      environment: "staging", service: "showcase", debug: false, telemetry: true
    )
  end
  let(:contexts_ns) do
    instance_double(Smplkit::ManagementClient::ContextsNamespace, register: nil, flush: nil)
  end
  let(:flags_ns) { instance_double(Smplkit::ManagementClient::FlagsNamespace, register: nil, flush: nil) }
  let(:loggers_ns) { instance_double(Smplkit::ManagementClient::LoggersNamespace, flush: nil) }
  let(:mgmt) do
    instance_double(Smplkit::ManagementClient,
                    contexts: contexts_ns, flags: flags_ns, loggers: loggers_ns,
                    close: nil, _app_http: nil)
  end
  let(:fake_metrics) { instance_double(Smplkit::MetricsReporter, close: nil) }
  let(:fake_ws) do
    instance_double(Smplkit::SharedWebSocket, on: nil, start: nil, stop: nil,
                                              connection_status: "connected")
  end

  before do
    allow(Smplkit::ConfigResolution).to receive(:resolve_config).and_return(resolved)
    allow(Smplkit::ManagementClient).to receive(:from_resolved).and_return(mgmt)
    allow(Smplkit::MetricsReporter).to receive(:new).and_return(fake_metrics)
    allow(Smplkit::SharedWebSocket).to receive(:new).and_return(fake_ws)
    allow_any_instance_of(Concurrent::TimerTask).to receive(:execute).and_return(nil)
  end

  def with_client(**overrides)
    client = described_class.new(**overrides)
    client.instance_variable_get(:@init_thread)&.join(1.0)
    yield client
  ensure
    client&.close
  end

  it "wires up the four sub-clients on construction" do
    with_client do |client|
      expect(client.manage).to equal(mgmt)
      expect(client.config).to be_a(Smplkit::Config::ConfigClient)
      expect(client.flags).to be_a(Smplkit::Flags::FlagsClient)
      expect(client.logging).to be_a(Smplkit::Logging::LoggingClient)
    end
  end

  it "skips MetricsReporter when telemetry is disabled" do
    no_telemetry = Smplkit::ConfigResolution::ResolvedConfig.new(**resolved.to_h, telemetry: false)
    allow(Smplkit::ConfigResolution).to receive(:resolve_config).and_return(no_telemetry)
    with_client do |client|
      expect(client._metrics).to be_nil
    end
  end

  it "exposes _service / _environment / _api_key / _app_base_url" do
    with_client do |client|
      expect(client._service).to eq("showcase")
      expect(client._environment).to eq("staging")
      expect(client._api_key).to eq("k_LONGENOUGHTOMASK")
      expect(client._app_base_url).to eq("https://app.smplkit.test")
    end
  end

  it "_ensure_ws lazily constructs and starts the SharedWebSocket once" do
    with_client do |client|
      ws1 = client._ensure_ws
      ws2 = client._ensure_ws
      expect(ws1).to equal(ws2)
      expect(fake_ws).to have_received(:start).at_least(:once)
    end
  end

  describe "#set_context" do
    let(:user_ctx) { Smplkit::Context.new("user", "u-1") }

    it "fire-and-forget returns a ContextScope and registers the contexts" do
      with_client do |client|
        scope = client.set_context([user_ctx])
        expect(scope).to be_a(Smplkit::ContextScope)
        expect(contexts_ns).to have_received(:register).with([user_ctx])
        scope.exit
      end
    end

    it "block form runs the block then restores prior context" do
      with_client do |client|
        Smplkit.set_request_context([Smplkit::Context.new("user", "outer")])
        seen = nil
        client.set_context([Smplkit::Context.new("user", "inner")]) do |_scope|
          seen = Smplkit.request_context.first.key
        end
        expect(seen).to eq("inner")
        expect(Smplkit.request_context.first.key).to eq("outer")
      end
    end

    it "skips register when given an empty contexts list" do
      with_client do |client|
        client.set_context([])
        # The init thread's register call uses the auto-bootstrapped envs;
        # it never matches an empty array.
        expect(contexts_ns).not_to have_received(:register).with([])
      end
    end
  end

  describe "#wait_until_ready" do
    it "returns once the websocket is connected" do
      with_client do |client|
        allow(client.flags).to receive(:start)
        allow(client.config).to receive(:start)
        expect { client.wait_until_ready(timeout: 0.1) }.not_to raise_error
      end
    end

    it "raises TimeoutError when the WS never reaches connected" do
      stuck_ws = instance_double(Smplkit::SharedWebSocket, on: nil, start: nil, stop: nil,
                                                           connection_status: "connecting")
      allow(Smplkit::SharedWebSocket).to receive(:new).and_return(stuck_ws)
      with_client do |client|
        allow(client.flags).to receive(:start)
        allow(client.config).to receive(:start)
        expect { client.wait_until_ready(timeout: 0.1) }
          .to raise_error(Smplkit::TimeoutError, /did not connect/)
      end
    end
  end

  describe ".open" do
    it "yields a client and closes it after the block" do
      yielded = nil
      described_class.open(api_key: "k", environment: "p", service: "s") do |client|
        yielded = client
      end
      expect(yielded).to be_a(described_class)
    end
  end

  describe "lifecycle" do
    it "close drains every registration buffer" do
      with_client do |client|
        client.close
        expect(contexts_ns).to have_received(:flush).at_least(:once)
        expect(flags_ns).to have_received(:flush).at_least(:once)
        expect(loggers_ns).to have_received(:flush).at_least(:once)
      end
    end

    it "run_periodic_flush triggers each registration namespace" do
      with_client do |client|
        # Swap fresh spy doubles into the management namespaces so we can
        # count just this test's flush calls without colliding with the
        # init thread's calls.
        ctx_spy = double("ctx_spy", flush: nil)
        flag_spy = double("flag_spy", flush: nil)
        log_spy = double("log_spy", flush: nil)
        allow(client.manage).to receive_messages(contexts: ctx_spy, flags: flag_spy, loggers: log_spy)

        client.send(:run_periodic_flush)
        expect(ctx_spy).to have_received(:flush)
        expect(flag_spy).to have_received(:flush)
        expect(log_spy).to have_received(:flush)
      end
    end

    it "run_periodic_flush no-ops when the client is closed" do
      with_client do |client|
        ctx_spy = double("ctx_spy", flush: nil)
        allow(client.manage).to receive(:contexts).and_return(ctx_spy)
        client.instance_variable_set(:@closed, true)
        client.send(:run_periodic_flush)
        expect(ctx_spy).not_to have_received(:flush)
      end
    end

    it "run_periodic_flush swallows exceptions so the timer keeps running" do
      with_client do |client|
        boom_spy = double("ctx_spy")
        allow(boom_spy).to receive(:flush).and_raise(StandardError, "boom")
        allow(client.manage).to receive(:contexts).and_return(boom_spy)
        expect { client.send(:run_periodic_flush) }.not_to raise_error
      end
    end

    it "register_service_context tolerates a flush exception during init" do
      allow(contexts_ns).to receive(:flush).and_raise(StandardError, "boom")
      expect { with_client { |_c| } }.not_to raise_error
    end
  end

  describe "debug logging path" do
    it "enables debug when the resolved config has debug=true" do
      cfg = Smplkit::ConfigResolution::ResolvedConfig.new(**resolved.to_h, debug: true)
      allow(Smplkit::ConfigResolution).to receive(:resolve_config).and_return(cfg)
      Smplkit::Debug.enabled = false
      with_client do |_client|
        expect(Smplkit::Debug.enabled?).to be(true)
      end
    end

    it "masks short keys without truncation" do
      short = Smplkit::ConfigResolution::ResolvedConfig.new(**resolved.to_h, api_key: "abc")
      allow(Smplkit::ConfigResolution).to receive(:resolve_config).and_return(short)
      Smplkit::Debug.enabled = true
      expect { with_client { |_c| } }.to output(/api_key=abc /).to_stderr
    end
  end

  describe "schedule_periodic_flush" do
    it "constructs a TimerTask and calls execute" do
      with_client do |client|
        timer = client.instance_variable_get(:@flush_timer)
        expect(timer).to be_a(Concurrent::TimerTask)
      end
    end

    it "the timer body invokes run_periodic_flush" do
      timer_double = instance_double(Concurrent::TimerTask, execute: nil, shutdown: nil)
      captured_block = nil
      allow(Concurrent::TimerTask).to receive(:new) do |&block|
        captured_block = block
        timer_double
      end

      with_client do |client|
        expect(client).to receive(:run_periodic_flush)
        captured_block.call
      end
    end
  end
end
