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
  subject(:client) { described_class.new(parent: parent, transport: transport, metrics: nil) }

  let(:base_url) { "https://logging.smplkit.test" }
  let(:tcfg) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:transport) { Smplkit::Transport.build_api_client(SmplkitGeneratedClient::Logging, "logging", tcfg) }
  let(:ws) { Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k") }
  let(:parent) do
    double(_service: "svc", _environment: "stg", _ensure_started: nil, _ensure_ws: ws)
  end

  after { client.close }

  # Minimal install wiring: empty loggers/groups, empty bulk.
  def stub_install
    stub_request(:post, "#{base_url}/api/v1/loggers/bulk")
      .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/vnd.api+json" })
    %w[loggers log_groups].each do |path|
      stub_request(:get, "#{base_url}/api/v1/#{path}")
        .with(query: hash_including({}))
        .to_return(status: 200,
                   body: { "data" => [], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }.to_json,
                   headers: { "Content-Type" => "application/vnd.api+json" })
    end
  end

  it "auto-loads adapters (including semantic-logger) when install runs without explicit registration" do
    stub_install
    client.install
    names = client.adapters.map(&:name)
    expect(names).to include("stdlib-logger", "semantic-logger")
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

  it "on_change (after install) captures a global listener" do
    stub_install
    client.install
    block = ->(_e) {}
    client.on_change(&block)
    expect(client.instance_variable_get(:@global_listeners)).to include(block)
  end

  it "on_change (after install) scopes a named listener to that key verbatim (no normalization)" do
    stub_install
    client.install
    client.on_change("app.database") {}
    keyed = client.instance_variable_get(:@key_listeners)
    expect(keyed.keys).to include("app.database")
  end
end
