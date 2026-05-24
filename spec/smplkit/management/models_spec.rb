# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Management::Environment do
  subject(:env) { described_class.new(client, key: "staging", name: "Staging") }

  let(:client) do
    instance_double(Smplkit::ManagementClient::EnvironmentsNamespace, _create_environment: nil,
                                                                      _update_environment: nil, delete: true)
  end

  it "carries identity and metadata" do
    expect(env.key).to eq("staging")
    expect(env.name).to eq("Staging")
    expect(env.classification).to eq(Smplkit::EnvironmentClassification::STANDARD)
  end

  it "raises on save when constructed without a client" do
    bare = described_class.new(key: "k")
    expect { bare.save }.to raise_error(RuntimeError, /without a client/)
    expect { bare.delete }.to raise_error(RuntimeError, /without a client/)
  end

  it "save calls _create_environment when never persisted" do
    fresh = described_class.new(key: "x", name: "X")
    allow(client).to receive(:_create_environment).and_return(fresh)
    env.save
    expect(client).to have_received(:_create_environment).with(env)
  end

  it "save calls _update_environment when previously persisted" do
    persisted = described_class.new(key: "staging", name: "Staging", created_at: "now")
    persisted.instance_variable_set(:@client, client)
    updated = described_class.new(key: "staging", name: "Staging Renamed", created_at: "now")
    allow(client).to receive(:_update_environment).and_return(updated)
    persisted.save
    expect(client).to have_received(:_update_environment)
  end

  it "delete dispatches to the namespace" do
    env.delete
    expect(client).to have_received(:delete).with("staging")
  end

  it "save! aliases save" do
    fresh = described_class.new(key: "x", name: "X")
    allow(client).to receive(:_create_environment).and_return(fresh)
    expect { env.save! }.not_to raise_error
  end
end

RSpec.describe Smplkit::Management::ContextType do
  subject(:ct) { described_class.new(client, key: "user", name: "User") }

  let(:client) do
    instance_double(Smplkit::ManagementClient::ContextTypesNamespace,
                    _create_context_type: nil, _update_context_type: nil, delete: true)
  end

  it "save dispatches to create when fresh" do
    allow(client).to receive(:_create_context_type).and_return(ct)
    ct.save
    expect(client).to have_received(:_create_context_type)
  end

  it "save dispatches to update when persisted" do
    persisted = described_class.new(client, key: "user", name: "User", created_at: "now")
    allow(client).to receive(:_update_context_type).and_return(persisted)
    persisted.save
    expect(client).to have_received(:_update_context_type)
  end

  it "delete dispatches to the namespace" do
    ct.delete
    expect(client).to have_received(:delete).with("user")
  end

  it "raises without a client" do
    bare = described_class.new(key: "k")
    expect { bare.save }.to raise_error(RuntimeError)
    expect { bare.delete }.to raise_error(RuntimeError)
  end
end

RSpec.describe Smplkit::Management::Service do
  subject(:svc) { described_class.new(client, key: "user_service", name: "User Service") }

  let(:client) do
    instance_double(Smplkit::ManagementClient::ServicesNamespace,
                    _create_service: nil, _update_service: nil, delete: true)
  end

  it "carries identity and metadata" do
    expect(svc.key).to eq("user_service")
    expect(svc.name).to eq("User Service")
  end

  it "raises on save when constructed without a client" do
    bare = described_class.new(key: "k")
    expect { bare.save }.to raise_error(RuntimeError, /without a client/)
    expect { bare.delete }.to raise_error(RuntimeError, /without a client/)
  end

  it "save calls _create_service when never persisted" do
    fresh = described_class.new(key: "x", name: "X")
    allow(client).to receive(:_create_service).and_return(fresh)
    svc.save
    expect(client).to have_received(:_create_service).with(svc)
  end

  it "save calls _update_service when previously persisted" do
    persisted = described_class.new(key: "user_service", name: "User Service", created_at: "now")
    persisted.instance_variable_set(:@client, client)
    updated = described_class.new(key: "user_service", name: "Renamed", created_at: "now")
    allow(client).to receive(:_update_service).and_return(updated)
    persisted.save
    expect(client).to have_received(:_update_service)
  end

  it "delete dispatches to the namespace" do
    svc.delete
    expect(client).to have_received(:delete).with("user_service")
  end

  it "save! aliases save" do
    fresh = described_class.new(key: "x", name: "X")
    allow(client).to receive(:_create_service).and_return(fresh)
    expect { svc.save! }.not_to raise_error
  end

  it "delete! aliases delete" do
    expect { svc.delete! }.not_to raise_error
    expect(client).to have_received(:delete).with("user_service")
  end
end

RSpec.describe Smplkit::Management::AccountSettings do
  subject(:settings) { described_class.new(client, environment_order: ["staging"]) }

  let(:client) { instance_double(Smplkit::ManagementClient::AccountSettingsNamespace, _update_account_settings: nil) }

  it "round-trips environment_order on save" do
    updated = described_class.new(environment_order: %w[staging production])
    allow(client).to receive(:_update_account_settings).and_return(updated)
    settings.save
    expect(settings.environment_order).to eq(%w[staging production])
  end

  it "raises without a client" do
    expect { described_class.new.save }.to raise_error(RuntimeError)
  end
end

RSpec.describe Smplkit::Logging::SmplLogger do
  subject(:lg) do
    described_class.new(client, id: "rails", name: "rails", resolved_level: Smplkit::LogLevel::INFO)
  end

  let(:client) { instance_double(Smplkit::ManagementClient::LoggersNamespace, _update_logger: nil, delete: true) }

  it "managed? mirrors the managed flag" do
    expect(lg.managed?).to be(true)
    lg.managed = false
    expect(lg.managed?).to be(false)
  end

  it "save dispatches to _update_logger" do
    updated = described_class.new(id: "rails", name: "rails", resolved_level: Smplkit::LogLevel::WARN)
    allow(client).to receive(:_update_logger).and_return(updated)
    lg.save
    expect(client).to have_received(:_update_logger).with(lg)
  end

  it "delete prefers id, falls back to name" do
    lg.delete
    expect(client).to have_received(:delete).with("rails")
    bare = described_class.new(client, name: "anon", resolved_level: Smplkit::LogLevel::INFO)
    bare.delete
    expect(client).to have_received(:delete).with("anon")
  end

  it "raises without a client" do
    expect do
      described_class.new(name: "x", resolved_level: Smplkit::LogLevel::INFO).save
    end.to raise_error(RuntimeError)
  end
end

RSpec.describe Smplkit::Logging::SmplLogGroup do
  subject(:group) { described_class.new(client, key: "app", name: "App") }

  let(:client) do
    instance_double(Smplkit::ManagementClient::LogGroupsNamespace, _create_log_group: nil, _update_log_group: nil,
                                                                   delete: true)
  end

  it "save dispatches to create when fresh" do
    allow(client).to receive(:_create_log_group).and_return(group)
    group.save
    expect(client).to have_received(:_create_log_group)
  end

  it "save dispatches to update when persisted" do
    persisted = described_class.new(client, key: "app", name: "App", created_at: "now")
    allow(client).to receive(:_update_log_group).and_return(persisted)
    persisted.save
    expect(client).to have_received(:_update_log_group)
  end

  it "delete dispatches to the namespace" do
    group.delete
    expect(client).to have_received(:delete).with("app")
  end

  it "raises without a client" do
    bare = described_class.new(key: "x")
    expect { bare.save }.to raise_error(RuntimeError)
    expect { bare.delete }.to raise_error(RuntimeError)
  end
end
