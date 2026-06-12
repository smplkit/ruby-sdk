# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Logging::Adapters::StdlibLoggerAdapter do
  let(:adapter) { described_class.new }

  it "exposes its name" do
    expect(adapter.name).to eq("stdlib-logger")
  end

  it "discovers tracked loggers with smpl levels" do
    logger = Logger.new($stdout)
    logger.level = Logger::WARN
    adapter.track("explicit", logger)
    rows = adapter.discover
    explicit = rows.find { |r| r[0] == "explicit" }
    expect(explicit[1]).to eq(Smplkit::LogLevel::WARN)
  end

  it "applies a level to a tracked logger" do
    logger = Logger.new($stdout)
    adapter.track("explicit", logger)
    adapter.apply_level("explicit", Smplkit::LogLevel::ERROR)
    expect(logger.level).to eq(Logger::ERROR)
  end

  it "tolerates apply_level for unknown logger" do
    expect { adapter.apply_level("missing", Smplkit::LogLevel::INFO) }.not_to raise_error
  end

  it "round-trips smpl TRACE -> DEBUG (gap acknowledged)" do
    logger = Logger.new($stdout)
    adapter.track("e", logger)
    adapter.apply_level("e", Smplkit::LogLevel::TRACE)
    expect(logger.level).to eq(Logger::DEBUG)
  end

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
  ensure
    adapter.uninstall_hook
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
    ensure
      adapter.uninstall_hook
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

RSpec.describe Smplkit::Logging::Adapters::Base do
  it "raises NotImplementedError on every contract method" do
    base = described_class.new
    expect { base.name }.to raise_error(NotImplementedError)
    expect { base.discover }.to raise_error(NotImplementedError)
    expect { base.apply_level("x", Smplkit::LogLevel::INFO) }.to raise_error(NotImplementedError)
    expect { base.install_hook {} }.to raise_error(NotImplementedError)
    expect { base.uninstall_hook }.to raise_error(NotImplementedError)
  end
end
