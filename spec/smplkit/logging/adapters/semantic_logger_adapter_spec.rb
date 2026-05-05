# frozen_string_literal: true

require "spec_helper"
require "semantic_logger"
require "smplkit/logging/adapters/semantic_logger_adapter"

RSpec.describe Smplkit::Logging::Adapters::SemanticLoggerAdapter do
  let(:adapter) { described_class.new }

  it "exposes its name" do
    expect(adapter.name).to eq("semantic-logger")
  end

  it "discovers tracked loggers and translates levels" do
    fake = instance_double(SemanticLogger::Logger, level: :warn)
    adapter.track("svc.payments", fake)
    rows = adapter.discover
    row = rows.find { |r| r[0] == "svc.payments" }
    expect(row[1]).to eq(Smplkit::LogLevel::WARN)
  end

  it "applies a smpl level by translating to the semantic-logger level symbol" do
    fake = double("SemanticLogger::Logger")
    expect(fake).to receive(:level=).with(:trace)
    expect(fake).to receive(:respond_to?).with(:level=).and_return(true)
    adapter.track("svc.x", fake)
    adapter.apply_level("svc.x", Smplkit::LogLevel::TRACE)
  end

  it "tolerates a logger that doesn't expose level=" do
    fake = double("SemanticLogger::Logger")
    expect(fake).to receive(:respond_to?).with(:level=).and_return(false)
    adapter.track("svc.y", fake)
    expect { adapter.apply_level("svc.y", Smplkit::LogLevel::INFO) }.not_to raise_error
  end

  it "no-ops apply_level for an unknown logger" do
    expect { adapter.apply_level("nope", Smplkit::LogLevel::DEBUG) }.not_to raise_error
  end

  it "install_hook registers the adapter and marks it active" do
    adapter.install_hook { |_name, _e, _eff| }
    expect(adapter.instance_variable_get(:@uninstalled)).to be(false)
    expect(described_class.adapters).to include(adapter)
  ensure
    adapter.uninstall_hook
  end

  it "uninstall_hook marks the adapter inactive and removes it from the registry" do
    adapter.install_hook { |_name, _e, _eff| }
    adapter.uninstall_hook
    expect(adapter.instance_variable_get(:@uninstalled)).to be(true)
    expect(described_class.adapters).not_to include(adapter)
  end

  it "install_hook intercepts new SemanticLogger::Logger creation" do
    seen = []
    adapter.install_hook { |name, _e, _eff| seen << name }

    SemanticLogger::Logger.new("hook.test.semantic")

    expect(seen).to include("hook.test.semantic")
  ensure
    adapter.uninstall_hook
  end

  it "hook does not fire after uninstall_hook" do
    seen = []
    adapter.install_hook { |name, _e, _eff| seen << name }
    adapter.uninstall_hook

    SemanticLogger::Logger.new("hook.test.after.uninstall")

    expect(seen).to be_empty
  end
end

RSpec.describe Smplkit::Logging::LoggingClient do
  subject(:client) do
    described_class.new(parent, manage: management, metrics: nil,
                                logging_base_url: "https://logging.smplkit.test",
                                app_base_url: "https://app.smplkit.test")
  end

  let(:loggers_ns) do
    instance_double(Smplkit::ManagementClient::LoggersNamespace, register: nil, get: nil, list: [], delete: true)
  end
  let(:management) { instance_double(Smplkit::ManagementClient, loggers: loggers_ns) }
  let(:ws) { Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k") }
  let(:parent) { double(_service: "svc", _environment: "stg", _ensure_ws: ws) }

  it "auto-loads adapters when install runs without explicit registration" do
    client.install
    names = client.adapters.map(&:name)
    expect(names).to include("stdlib-logger")
  end

  it "register_adapter appends a custom adapter" do
    custom = Class.new(Smplkit::Logging::Adapters::Base) do
      def name = "custom"
      def discover = []
      def apply_level(_, _); end
      def install_hook(&); end
      def uninstall_hook; end
    end.new

    client.register_adapter(custom)
    expect(client.adapters.map(&:name)).to include("custom")
  end

  it "register_adapter rejects a non-Base instance" do
    expect { client.register_adapter(Object.new) }.to raise_error(ArgumentError)
  end

  it "on_change captures a global listener" do
    block = ->(_e) {}
    client.on_change(&block)
    expect(client.instance_variable_get(:@global_listeners)).to include(block)
  end

  it "on_change with a name normalizes and scopes to that key" do
    client.on_change("App/Database") {}
    keyed = client.instance_variable_get(:@key_listeners)
    expect(keyed.keys).to include("app.database")
  end
end
