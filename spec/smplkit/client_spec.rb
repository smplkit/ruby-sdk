# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Smplkit::Client do
  # Default construction args: a fake base_domain so no transport ever reaches a
  # real host, telemetry off so @metrics is nil unless a test opts in.
  let(:base_args) do
    {
      api_key: "sk_LONGENOUGHTOMASK", environment: "staging", service: "showcase",
      base_domain: "smplkit.test", telemetry: false
    }
  end

  # A websocket stand-in with a controllable connection_status. The real
  # SharedWebSocket is never constructed in these tests.
  def ws_double(status: "connected")
    instance_double(Smplkit::SharedWebSocket, start: nil, stop: nil, connection_status: status)
  end

  # Build a client and ensure its (possibly spawned) init thread has settled
  # before assertions and teardown run. +base_domain+ keeps every transport off
  # any real host; +home_dir+ points the config resolver at an empty temp dir so
  # the developer's own +~/.smplkit+ never leaks values (e.g. a [common]
  # environment) into these tests.
  def with_client(**overrides)
    Dir.mktmpdir do |empty_home|
      allow(Dir).to receive(:home).and_return(empty_home)
      client = described_class.new(**base_args, **overrides)
      client.instance_variable_get(:@init_thread)&.join(1.0)
      begin
        yield client
      ensure
        client&.close
      end
    end
  end

  describe "construction" do
    it "wires up every sub-client and exposes the right classes" do
      with_client do |client|
        expect(client.platform).to be_a(Smplkit::Platform::PlatformClient)
        expect(client.account).to be_a(Smplkit::Account::AccountClient)
        expect(client.config).to be_a(Smplkit::Config::ConfigClient)
        expect(client.flags).to be_a(Smplkit::Flags::FlagsClient)
        expect(client.logging).to be_a(Smplkit::Logging::LoggingClient)
        expect(client.audit).to be_a(Smplkit::Audit::AuditClient)
        expect(client.jobs).to be_a(Smplkit::Jobs::JobsClient)
      end
    end

    it "is side-effect-free: no background machinery and no HTTP at construction" do
      # WebMock disables net connect, so any real request would raise. Reaching
      # the assertions proves construction touched no network.
      client = described_class.new(**base_args)
      expect(client.instance_variable_get(:@started)).to be(false)
      expect(client.instance_variable_get(:@flush_timer)).to be_nil
      expect(client.instance_variable_get(:@init_thread)).to be_nil
      client.close
    end

    it "wires the resolved environment into the runtime audit sub-clients (ADR-055)" do
      with_client do |client|
        # Body-driven scoping: the env travels on the record body and as the
        # default filter[environment] on reads, not as a transport header.
        api_client = client.audit.events.instance_variable_get(:@api).api_client
        expect(api_client.default_headers).not_to have_key("X-Smplkit-Environment")
        expect(client.audit.events.instance_variable_get(:@environment)).to eq("staging")
        expect(client.audit.resource_types.instance_variable_get(:@environment)).to eq("staging")
        expect(client.audit.event_types.instance_variable_get(:@environment)).to eq("staging")
        expect(client.audit.categories.instance_variable_get(:@environment)).to eq("staging")
      end
    end

    it "exposes _service / _environment / _api_key / _app_base_url" do
      with_client do |client|
        expect(client._service).to eq("showcase")
        expect(client._environment).to eq("staging")
        expect(client._api_key).to eq("sk_LONGENOUGHTOMASK")
        expect(client._app_base_url).to eq("https://app.smplkit.test")
      end
    end

    it "stores and exposes extra_headers via _extra_headers" do
      with_client(extra_headers: { "X-Custom" => "hello" }) do |client|
        expect(client._extra_headers).to eq({ "X-Custom" => "hello" })
      end
    end

    it "_extra_headers is nil when none supplied" do
      with_client do |client|
        expect(client._extra_headers).to be_nil
      end
    end
  end

  describe "metrics / telemetry" do
    it "leaves _metrics nil when telemetry is disabled" do
      with_client(telemetry: false) do |client|
        expect(client._metrics).to be_nil
      end
    end

    it "builds a MetricsReporter when telemetry is enabled" do
      fake_metrics = instance_double(Smplkit::MetricsReporter, close: nil)
      allow(Smplkit::MetricsReporter).to receive(:new).and_return(fake_metrics)
      with_client(telemetry: true) do |client|
        expect(client._metrics).to equal(fake_metrics)
        expect(Smplkit::MetricsReporter).to have_received(:new)
      end
    end
  end

  describe "debug logging path" do
    around do |example|
      previous = Smplkit::Debug.enabled?
      example.run
      Smplkit::Debug.enabled = previous
    end

    it "enables debug when constructed with debug: true" do
      Smplkit::Debug.enabled = false
      with_client(debug: true) do |_client|
        expect(Smplkit::Debug.enabled?).to be(true)
      end
    end

    it "masks a long api_key down to its first 10 chars plus an ellipsis" do
      Smplkit::Debug.enabled = true
      expect { with_client(api_key: "sk_LONGENOUGHTOMASK", debug: true) { |_c| } }
        .to output(/api_key=sk_LONGENO\.\.\. /).to_stderr
    end

    it "masks a short api_key without truncation" do
      Smplkit::Debug.enabled = true
      expect { with_client(api_key: "abc", debug: true) { |_c| } }
        .to output(/api_key=abc /).to_stderr
    end
  end

  describe ".open" do
    it "yields a client and closes it after the block" do
      yielded = nil
      described_class.open(**base_args) do |client|
        yielded = client
        expect(client).to be_a(described_class)
      end
      expect(yielded).to be_a(described_class)
      expect(yielded.instance_variable_get(:@closed)).to be(true)
    end

    it "closes the client even when the block raises" do
      captured = nil
      expect do
        described_class.open(**base_args) do |client|
          captured = client
          raise "boom"
        end
      end.to raise_error("boom")
      expect(captured.instance_variable_get(:@closed)).to be(true)
    end
  end

  describe "#_ensure_started" do
    it "starts the periodic flush timer and spawns the init thread exactly once" do
      with_client do |client|
        # Stub the registration seam so the spawned thread does no network.
        allow(client.platform.contexts).to receive(:register)
        client._ensure_started
        first_timer = client.instance_variable_get(:@flush_timer)
        expect(first_timer).to be_a(Concurrent::TimerTask)
        expect(client.instance_variable_get(:@started)).to be(true)

        # Idempotent: a second call does not replace the timer.
        client._ensure_started
        expect(client.instance_variable_get(:@flush_timer)).to equal(first_timer)
      end
    end

    it "is a no-op after close" do
      with_client do |client|
        client.close
        client.instance_variable_set(:@flush_timer, nil)
        client._ensure_started
        expect(client.instance_variable_get(:@flush_timer)).to be_nil
      end
    end
  end

  describe "#_ensure_ws" do
    it "lazily constructs and starts the SharedWebSocket once" do
      ws = ws_double
      allow(Smplkit::SharedWebSocket).to receive(:new).and_return(ws)
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        ws1 = client._ensure_ws
        ws2 = client._ensure_ws
        expect(ws1).to equal(ws)
        expect(ws2).to equal(ws)
        expect(ws).to have_received(:start).once
        expect(Smplkit::SharedWebSocket).to have_received(:new).once
      end
    end

    it "starts the deferred machinery via _ensure_started" do
      ws = ws_double
      allow(Smplkit::SharedWebSocket).to receive(:new).and_return(ws)
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        client._ensure_ws
        expect(client.instance_variable_get(:@started)).to be(true)
      end
    end
  end

  describe "#set_context" do
    let(:user_ctx) { Smplkit::Context.new("user", "u-1") }

    it "registers the contexts and returns a ContextScope (fire-and-forget)" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        scope = client.set_context([user_ctx])
        expect(scope).to be_a(Smplkit::ContextScope)
        expect(client.platform.contexts).to have_received(:register).with([user_ctx])
        scope.exit
      end
    end

    it "exposes the set contexts via Smplkit.request_context until the scope exits" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        scope = client.set_context([user_ctx])
        expect(Smplkit.request_context.map(&:key)).to eq(["u-1"])
        scope.exit
      end
    end

    it "block form runs the block then restores the prior context" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        Smplkit.set_request_context([Smplkit::Context.new("user", "outer")])
        seen = nil
        client.set_context([Smplkit::Context.new("user", "inner")]) do |_scope|
          seen = Smplkit.request_context.first.key
        end
        expect(seen).to eq("inner")
        expect(Smplkit.request_context.first.key).to eq("outer")
      end
    end

    it "skips registration when given an empty contexts list" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        scope = client.set_context([])
        expect(client.platform.contexts).not_to have_received(:register)
        expect(scope).to be_a(Smplkit::ContextScope)
      end
    end

    it "skips registration when given nil and still sets an empty context" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        client.set_context(nil)
        expect(client.platform.contexts).not_to have_received(:register)
        expect(Smplkit.request_context).to eq([])
      end
    end

    it "starts the deferred machinery" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        client.set_context([user_ctx]).exit
        expect(client.instance_variable_get(:@started)).to be(true)
      end
    end
  end

  describe "#wait_until_ready" do
    it "connects flags + config, opens the ws, and returns once connected" do
      ws = ws_double(status: "connected")
      with_client do |client|
        allow(client.flags).to receive(:_ensure_connected)
        allow(client.config).to receive(:_ensure_connected)
        allow(client).to receive(:_ensure_ws).and_return(ws)
        expect { client.wait_until_ready(timeout: 0.5) }.not_to raise_error
        expect(client.flags).to have_received(:_ensure_connected)
        expect(client.config).to have_received(:_ensure_connected)
      end
    end

    it "polls until the websocket transitions to connected" do
      statuses = %w[connecting connecting connected]
      ws = instance_double(Smplkit::SharedWebSocket, start: nil, stop: nil)
      allow(ws).to receive(:connection_status) { statuses.shift || "connected" }
      with_client do |client|
        allow(client.flags).to receive(:_ensure_connected)
        allow(client.config).to receive(:_ensure_connected)
        allow(client).to receive(:_ensure_ws).and_return(ws)
        expect { client.wait_until_ready(timeout: 1.0) }.not_to raise_error
      end
    end

    it "raises TimeoutError when the websocket never connects" do
      ws = ws_double(status: "connecting")
      with_client do |client|
        allow(client.flags).to receive(:_ensure_connected)
        allow(client.config).to receive(:_ensure_connected)
        allow(client).to receive(:_ensure_ws).and_return(ws)
        expect { client.wait_until_ready(timeout: 0.05) }
          .to raise_error(Smplkit::TimeoutError, /did not connect within 0.05s/)
      end
    end
  end

  describe "#close" do
    it "tears everything down in order and is no-raise" do
      fake_metrics = instance_double(Smplkit::MetricsReporter, close: nil)
      allow(Smplkit::MetricsReporter).to receive(:new).and_return(fake_metrics)
      ws = ws_double
      allow(Smplkit::SharedWebSocket).to receive(:new).and_return(ws)

      with_client(telemetry: true) do |client|
        allow(client.platform.contexts).to receive_messages(register: nil, flush: nil)
        allow(client.flags).to receive_messages(flush: nil, _close: nil)
        allow(client.logging.loggers).to receive(:flush)
        allow(client.logging).to receive(:_close)
        allow(client.config).to receive(:flush)
        allow(client.audit).to receive(:_close)
        client._ensure_ws # so there is a ws_manager to stop

        expect { client.close }.not_to raise_error

        expect(client.instance_variable_get(:@closed)).to be(true)
        expect(fake_metrics).to have_received(:close)
        expect(client.logging).to have_received(:_close)
        expect(client.flags).to have_received(:_close)
        expect(client.audit).to have_received(:_close)
        expect(ws).to have_received(:stop)
        expect(client.instance_variable_get(:@ws_manager)).to be_nil
      end
    end

    it "shuts down the flush timer when one was scheduled" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        client._ensure_started
        timer = client.instance_variable_get(:@flush_timer)
        allow(timer).to receive(:shutdown)
        client.close
        expect(timer).to have_received(:shutdown)
        expect(client.instance_variable_get(:@flush_timer)).to be_nil
      end
    end

    it "does not call config._close (config transport is shared)" do
      with_client do |client|
        allow(client.config).to receive_messages(flush: nil, _close: nil)
        client.close
        expect(client.config).not_to have_received(:_close)
      end
    end

    it "drains every registration buffer through final_flush" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:flush)
        allow(client.flags).to receive(:flush)
        allow(client.logging.loggers).to receive(:flush)
        allow(client.config).to receive(:flush)
        client.close
        expect(client.platform.contexts).to have_received(:flush)
        expect(client.flags).to have_received(:flush)
        expect(client.logging.loggers).to have_received(:flush)
        expect(client.config).to have_received(:flush)
      end
    end
  end

  describe "#run_periodic_flush (private)" do
    it "flushes contexts, flags, loggers, and config on the happy path" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:flush)
        allow(client.flags).to receive(:flush)
        allow(client.logging.loggers).to receive(:flush)
        allow(client.config).to receive(:flush)
        client.send(:run_periodic_flush)
        expect(client.platform.contexts).to have_received(:flush)
        expect(client.flags).to have_received(:flush)
        expect(client.logging.loggers).to have_received(:flush)
        expect(client.config).to have_received(:flush)
      end
    end

    it "no-ops when the client is already closed" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:flush)
        client.instance_variable_set(:@closed, true)
        client.send(:run_periodic_flush)
        expect(client.platform.contexts).not_to have_received(:flush)
      end
    end

    it "swallows exceptions so the timer keeps running" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:flush).and_raise(StandardError, "boom")
        expect { client.send(:run_periodic_flush) }.not_to raise_error
      end
    end
  end

  describe "#final_flush (private)" do
    it "swallows a per-target exception and continues flushing the rest" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:flush).and_raise(StandardError, "boom")
        allow(client.flags).to receive(:flush)
        allow(client.logging.loggers).to receive(:flush)
        allow(client.config).to receive(:flush)
        expect { client.send(:final_flush) }.not_to raise_error
        # Later targets are still flushed despite the earlier raise.
        expect(client.config).to have_received(:flush)
      end
    end
  end

  describe "#register_service_context (private)" do
    it "registers both environment and service contexts with flush: true" do
      with_client do |client|
        captured = nil
        allow(client.platform.contexts).to receive(:register) { |ctxs, **_| captured = ctxs }
        client.send(:register_service_context)
        expect(client.platform.contexts).to have_received(:register).with(anything, flush: true)
        expect(captured.map { |c| [c.type, c.key] })
          .to contain_exactly(%w[environment staging], %w[service showcase])
      end
    end

    it "registers only the environment when service is absent" do
      with_client(service: nil) do |client|
        captured = nil
        allow(client.platform.contexts).to receive(:register) { |ctxs, **_| captured = ctxs }
        client.send(:register_service_context)
        expect(captured.map(&:type)).to eq(["environment"])
      end
    end

    it "skips registration entirely when neither environment nor service is set" do
      with_client(environment: nil, service: nil) do |client|
        allow(client.platform.contexts).to receive(:register)
        client.send(:register_service_context)
        expect(client.platform.contexts).not_to have_received(:register)
      end
    end

    it "swallows a registration exception raised while registering" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register).and_raise(StandardError, "boom")
        expect { client.send(:register_service_context) }.not_to raise_error
        expect(client.platform.contexts).to have_received(:register)
      end
    end
  end

  describe "#schedule_periodic_flush (private)" do
    it "constructs a TimerTask and executes it" do
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        client._ensure_started
        expect(client.instance_variable_get(:@flush_timer)).to be_a(Concurrent::TimerTask)
      end
    end

    it "wires the timer body to run_periodic_flush" do
      timer_double = instance_double(Concurrent::TimerTask, execute: nil, shutdown: nil)
      captured_block = nil
      allow(Concurrent::TimerTask).to receive(:new) do |&block|
        captured_block = block
        timer_double
      end
      with_client do |client|
        allow(client.platform.contexts).to receive(:register)
        client._ensure_started
        expect(client).to receive(:run_periodic_flush)
        captured_block.call
      end
    end
  end

  describe "#monotonic_now (private)" do
    it "returns a monotonically non-decreasing float" do
      with_client do |client|
        t1 = client.send(:monotonic_now)
        t2 = client.send(:monotonic_now)
        expect(t1).to be_a(Float)
        expect(t2).to be >= t1
      end
    end
  end
end
