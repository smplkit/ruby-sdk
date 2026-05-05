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
