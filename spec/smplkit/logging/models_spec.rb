# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Logging::SmplLogger do
  let(:logger) { described_class.new(name: "app.checkout", resolved_level: Smplkit::LogLevel::INFO) }

  it "managed? reflects the managed flag" do
    expect(logger.managed?).to be(true)
    unmanaged = described_class.new(name: "x", resolved_level: Smplkit::LogLevel::INFO, managed: false)
    expect(unmanaged.managed?).to be(false)
  end

  it "delete raises without a client" do
    expect { logger.delete }.to raise_error(RuntimeError, /without a client/)
    expect { logger.delete! }.to raise_error(RuntimeError, /without a client/)
  end

  it "delete routes through the bound client, preferring id over name" do
    client = double("loggers_client")
    bound = described_class.new(client, id: "log-1", name: "app.checkout", resolved_level: Smplkit::LogLevel::INFO)
    expect(client).to receive(:delete).with("log-1")
    bound.delete
  end

  it "delete falls back to the name when no id is present" do
    client = double("loggers_client")
    bound = described_class.new(client, name: "app.checkout", resolved_level: Smplkit::LogLevel::INFO)
    expect(client).to receive(:delete).with("app.checkout")
    bound.delete
  end

  it "set_level with no environment sets the base level; clear_level removes it" do
    logger.set_level(Smplkit::LogLevel::WARN)
    expect(logger.level).to eq(Smplkit::LogLevel::WARN)
    logger.clear_level
    expect(logger.level).to be_nil
  end

  it "set_level/clear_level with an environment manages per-env overrides" do
    logger.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    expect(logger.environments["production"].level).to eq(Smplkit::LogLevel::ERROR)
    logger.clear_level(environment: "production")
    expect(logger.environments).not_to have_key("production")
  end

  it "environments returns a copy that does not mutate internal state" do
    logger.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    logger.environments.delete("production")
    expect(logger.environments).to have_key("production")
  end

  it "clear_all_environment_levels drops every override" do
    logger.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    logger.set_level(Smplkit::LogLevel::DEBUG, environment: "staging")
    logger.clear_all_environment_levels
    expect(logger.environments).to eq({})
  end

  it "parses wire-shaped environments at construction" do
    built = described_class.new(name: "x", resolved_level: nil,
                                environments: { "production" => { "level" => "ERROR" } })
    expect(built.environments["production"].level).to eq(Smplkit::LogLevel::ERROR)
  end

  it "_apply copies per-environment overrides from the server response" do
    client = double("loggers_client")
    server = described_class.new(name: "x", resolved_level: nil)
    server.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    allow(client).to receive(:_update_logger).and_return(server)
    bound = described_class.new(client, id: "x", name: "x", resolved_level: nil)
    bound.save
    expect(bound.environments["production"].level).to eq(Smplkit::LogLevel::ERROR)
  end
end

RSpec.describe Smplkit::Logging::LoggerEnvironment do
  it "defaults level to nil and is frozen" do
    env = described_class.new
    expect(env.level).to be_nil
    expect(env).to be_frozen
  end
end

RSpec.describe "Smplkit::Logging environment helpers" do
  it "convert_environments returns {} for nil/empty" do
    expect(Smplkit::Logging.convert_environments(nil)).to eq({})
    expect(Smplkit::Logging.convert_environments({})).to eq({})
  end

  it "convert_environments passes through LoggerEnvironment instances" do
    env = Smplkit::Logging::LoggerEnvironment.new(level: Smplkit::LogLevel::INFO)
    expect(Smplkit::Logging.convert_environments({ "production" => env })["production"]).to equal(env)
  end

  it "convert_environments coerces wire dicts and tolerates missing/invalid levels" do
    out = Smplkit::Logging.convert_environments(
      "a" => { "level" => "ERROR" }, "b" => { "level" => nil }, "c" => { "level" => "BOGUS" }, "d" => "nope"
    )
    expect(out["a"].level).to eq(Smplkit::LogLevel::ERROR)
    expect(out["b"].level).to be_nil
    expect(out["c"].level).to be_nil
    expect(out["d"].level).to be_nil
  end

  it "environments_to_wire skips nil-level entries" do
    envs = {
      "production" => Smplkit::Logging::LoggerEnvironment.new(level: Smplkit::LogLevel::ERROR),
      "staging" => Smplkit::Logging::LoggerEnvironment.new
    }
    expect(Smplkit::Logging.environments_to_wire(envs)).to eq("production" => { "level" => "ERROR" })
  end
end

RSpec.describe Smplkit::Logging::SmplLogGroup do
  let(:group) { described_class.new(key: "app") }

  it "delete raises without a client" do
    expect { group.delete }.to raise_error(RuntimeError, /without a client/)
    expect { group.delete! }.to raise_error(RuntimeError, /without a client/)
  end

  it "delete routes through the bound client using the key" do
    client = double("log_groups_client")
    bound = described_class.new(client, key: "app")
    expect(client).to receive(:delete).with("app")
    bound.delete
  end

  it "set_level with no environment sets the base level; clear_level removes it" do
    group.set_level(Smplkit::LogLevel::WARN)
    expect(group.level).to eq(Smplkit::LogLevel::WARN)
    group.clear_level
    expect(group.level).to be_nil
  end

  it "set_level/clear_level with an environment manages per-env overrides" do
    group.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    expect(group.environments["production"].level).to eq(Smplkit::LogLevel::ERROR)
    group.clear_level(environment: "production")
    expect(group.environments).not_to have_key("production")
  end

  it "environments returns a copy that does not mutate internal state" do
    group.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    group.environments.delete("production")
    expect(group.environments).to have_key("production")
  end

  it "clear_all_environment_levels drops every override" do
    group.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    group.set_level(Smplkit::LogLevel::DEBUG, environment: "staging")
    group.clear_all_environment_levels
    expect(group.environments).to eq({})
  end

  it "parses wire-shaped environments at construction" do
    built = described_class.new(key: "app",
                                environments: { "production" => { "level" => "ERROR" } })
    expect(built.environments["production"].level).to eq(Smplkit::LogLevel::ERROR)
  end

  it "_apply copies per-environment overrides from the server response" do
    client = double("log_groups_client")
    server = described_class.new(key: "app", created_at: "x")
    server.set_level(Smplkit::LogLevel::ERROR, environment: "production")
    allow(client).to receive(:_update_log_group).and_return(server)
    bound = described_class.new(client, key: "app", created_at: "x")
    bound.save
    expect(bound.environments["production"].level).to eq(Smplkit::LogLevel::ERROR)
  end
end
