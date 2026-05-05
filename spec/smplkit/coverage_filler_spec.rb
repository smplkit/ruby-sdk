# frozen_string_literal: true

require "spec_helper"
require "semantic_logger"
require "smplkit/logging/adapters/semantic_logger_adapter"

# Tight per-file specs that fill the small remaining gaps the rest of
# the suite doesn't naturally cover.

RSpec.describe Smplkit::Logging::Levels do
  describe ".stdlib_level_to_smpl" do
    it "returns the nearest-lower-breakpoint smpl level for a non-standard stdlib level" do
      # Logger::DEBUG is 0, INFO is 1, WARN is 2 in stdlib. A level of 99
      # is above every breakpoint so it falls to the highest breakpoint
      # (UNKNOWN -> SILENT).
      expect(described_class.stdlib_level_to_smpl(99)).to eq(Smplkit::LogLevel::SILENT)
      # A level of 1 is INFO; 2 is WARN; -1 is below every breakpoint so
      # it falls to the lowest (DEBUG) per the +best = sorted.first+ guard.
      expect(described_class.stdlib_level_to_smpl(-1)).to eq(Smplkit::LogLevel::DEBUG)
    end
  end
end

RSpec.describe Smplkit::Logging::LoggingClient do
  subject(:client) do
    described_class.new(parent, manage: management, metrics: nil,
                                logging_base_url: "https://logging.smplkit.test",
                                app_base_url: "https://app.smplkit.test")
  end

  let(:loggers_ns) do
    instance_double(Smplkit::ManagementClient::LoggersNamespace, register: nil, get: :logger,
                                                                 list: %i[a b], delete: true)
  end
  let(:management) { instance_double(Smplkit::ManagementClient, loggers: loggers_ns) }
  let(:ws) do
    Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k")
  end
  let(:parent) do
    double(_service: "svc", _environment: "stg", _ensure_ws: ws)
  end

  it "delegates get/list/delete to the loggers namespace" do
    expect(client.get("rails")).to eq(:logger)
    expect(client.list).to eq(%i[a b])
    expect(client.delete("rails")).to be(true)
  end

  it "handle_logger_changed normalizes the incoming name and applies levels" do
    adapter = instance_double(Smplkit::Logging::Adapters::Base, apply_level: nil)
    client.instance_variable_set(:@adapters, [adapter])
    seen = []
    client.on_change { |event| seen << [event.name, event.level&.name] }
    client.send(:handle_logger_changed, { "id" => "Rails/Middleware", "resolved_level" => "WARN" })
    expect(seen.first).to eq(["rails.middleware", "WARN"])
    expect(adapter).to have_received(:apply_level).with("rails.middleware", Smplkit::LogLevel::WARN)
  end

  it "handle_logger_changed ignores empty names" do
    expect { client.send(:handle_logger_changed, {}) }.not_to raise_error
  end

  it "handle_logger_changed survives a listener that raises" do
    client.on_change("rails") { raise "boom" }
    expect do
      client.send(:handle_logger_changed, { "id" => "rails", "resolved_level" => "INFO" })
    end.not_to raise_error
  end

  it "auto-load adapters debug-logs when semantic_logger is missing" do
    Smplkit::Debug.enabled = true
    fresh = described_class.new(parent, manage: management, metrics: nil,
                                        logging_base_url: "https://x", app_base_url: "https://y")
    allow(fresh).to receive(:require).with("semantic_logger").and_raise(LoadError)
    expect { fresh.send(:auto_load_adapters) }
      .to output(/semantic_logger gem not installed/).to_stderr
  ensure
    Smplkit::Debug.enabled = false
  end

  describe "LoggerChangeEvent" do
    it "compares by name/level/source" do
      a = Smplkit::Logging::LoggerChangeEvent.new(name: "x", level: Smplkit::LogLevel::INFO, source: "ws")
      b = Smplkit::Logging::LoggerChangeEvent.new(name: "x", level: Smplkit::LogLevel::INFO, source: "ws")
      c = Smplkit::Logging::LoggerChangeEvent.new(name: "y", level: Smplkit::LogLevel::INFO, source: "ws")
      expect(a).to eq(b)
      expect(a).not_to eq(c)
    end
  end
end

RSpec.describe Smplkit::Logging::Adapters::StdlibLoggerAdapter do
  subject(:adapter) { described_class.new }

  it "discover surfaces Rails.logger when defined" do
    rails = Module.new
    allow(rails).to receive(:respond_to?).with(:logger).and_return(true)
    fake_logger = Logger.new($stdout)
    fake_logger.level = Logger::WARN
    allow(rails).to receive(:logger).and_return(fake_logger)
    stub_const("::Rails", rails)
    rows = adapter.discover
    rails_row = rows.find { |r| r[0] == "rails" }
    expect(rails_row[1]).to eq(Smplkit::LogLevel::WARN)
  end

  it "uninstall_hook removes the adapter from the global list" do
    adapter.install_hook { |_n, _e, _l| nil }
    expect(described_class.adapters).to include(adapter)
    adapter.uninstall_hook
    expect(described_class.adapters).not_to include(adapter)
  end

  it "on_new_logger_created tracks new loggers and forwards to the on_new callback" do
    seen = []
    adapter.install_hook { |name, _e, level| seen << [name, level] }
    fake = Logger.new($stdout)
    fake.level = Logger::ERROR
    seen.clear # the prepend hook may fire on the Logger.new above
    adapter.send(:on_new_logger_created, fake, "logger.123")
    expect(seen).to include(["logger.123", Smplkit::LogLevel::ERROR])
  end

  it "on_new_logger_created no-ops once the adapter has been uninstalled" do
    seen = []
    adapter.install_hook { |name, _e, _l| seen << name }
    adapter.uninstall_hook
    fake = Logger.new($stdout)
    adapter.send(:on_new_logger_created, fake, "logger.123")
    expect(seen).to eq([])
  end

  describe ".reset_hook!" do
    after do
      # Re-install for any other specs that depend on the hook state.
      described_class.instance_variable_set(:@hook_module, nil)
    end

    it "clears the per-class hook module" do
      adapter.install_hook { |_n, _e, _l| nil }
      described_class.reset_hook!
      expect(described_class.send(:hook_installed?)).to be(false)
    end
  end

  describe ".build_hook" do
    it "rescues errors raised by an adapter's on_new_logger_created" do
      hook = described_class.build_hook
      bad_adapter = double("adapter")
      allow(bad_adapter).to receive(:on_new_logger_created).and_raise("boom")
      described_class.adapters << bad_adapter
      Logger.prepend(hook)
      expect { Logger.new($stdout) }.not_to raise_error
    ensure
      described_class.adapters.delete(bad_adapter)
    end
  end
end

RSpec.describe Smplkit::Logging::Adapters::SemanticLoggerAdapter do
  subject(:adapter) { described_class.new }

  it "on_new_logger_created rescues errors silently" do
    adapter.install_hook { |_n, _e, _l| raise "boom" }
    fake = double("SemanticLogger::Logger")
    allow(fake).to receive(:name).and_return("x")
    allow(fake).to receive(:respond_to?).with(:level).and_return(false)
    expect { adapter.send(:on_new_logger_created, fake) }.not_to raise_error
  end

  describe ".reset_hook!" do
    it "clears the per-class hook module" do
      described_class.reset_hook!
      expect(described_class.send(:hook_installed?)).to be(false)
    end
  end
end

RSpec.describe Smplkit::MetricsReporter do
  subject(:reporter) do
    described_class.new(http_client: http, environment: "staging", service: "svc", flush_interval: 60)
  end

  let(:http) { instance_double(Faraday::Connection) }

  after { reporter.close }

  it "logs a debug line when send_payload raises" do
    Smplkit::Debug.enabled = true
    allow(reporter).to receive(:send_payload).and_raise("boom")
    reporter.record("x", unit: "ev")
    expect { reporter.flush }.to output(/flush failed/).to_stderr
  ensure
    Smplkit::Debug.enabled = false
  end
end

RSpec.describe Smplkit::ConfigResolution do
  around do |ex|
    saved = ENV.to_h.slice("SMPLKIT_DEBUG", "SMPLKIT_API_KEY", "SMPLKIT_BASE_DOMAIN")
    %w[SMPLKIT_DEBUG SMPLKIT_API_KEY SMPLKIT_BASE_DOMAIN SMPLKIT_SCHEME SMPLKIT_PROFILE].each do |k|
      ENV.delete(k)
    end
    Dir.mktmpdir do |dir|
      @home_dir = dir
      ex.run
    end
  ensure
    saved.each { |k, v| ENV[k] = v }
  end

  it "tolerates a malformed ~/.smplkit by silently returning empty values" do
    File.write(File.join(@home_dir, ".smplkit"), "\xc3\x28") # invalid UTF-8
    expect(described_class.read_config_file("default", home_dir: @home_dir)).to eq({})
  end

  it "resolve_management_config reads debug from the config file" do
    File.write(File.join(@home_dir, ".smplkit"), <<~INI)
      [default]
      api_key = abc
      debug = true
    INI
    cfg = described_class.resolve_management_config(home_dir: @home_dir)
    expect(cfg.debug).to be(true)
  end
end

RSpec.describe Smplkit::Config::Helpers do
  describe ".config_from_json" do
    it "treats raw item values as JSON-typed when no value/type wrapper exists" do
      resource = { "id" => "cfg", "type" => "config",
                   "attributes" => { "items" => { "feature.beta" => true }, "environments" => {} } }
      cfg = described_class.config_from_json(:client, resource)
      item = cfg.items.first
      expect(item.value).to be(true)
      expect(item.type).to eq(Smplkit::Config::ItemType::JSON)
    end

    it "tolerates non-Hash environment overrides by ignoring them" do
      resource = { "id" => "cfg", "attributes" => { "environments" => { "staging" => "weird" } } }
      cfg = described_class.config_from_json(:client, resource)
      expect(cfg.environments["staging"].values).to eq({})
    end
  end
end
