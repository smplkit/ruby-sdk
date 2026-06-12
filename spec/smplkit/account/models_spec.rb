# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Account::AccountSettings do
  it "exposes the raw settings dict and the typed environment_order" do
    settings = described_class.new(nil, data: { "environment_order" => %w[production staging], "extra" => 1 })
    expect(settings.raw).to eq("environment_order" => %w[production staging], "extra" => 1)
    expect(settings.environment_order).to eq(%w[production staging])
  end

  it "defaults environment_order to an empty list when unset" do
    expect(described_class.new(nil, data: {}).environment_order).to eq([])
  end

  it "raw= replaces the underlying data" do
    settings = described_class.new(nil, data: { "a" => 1 })
    settings.raw = { "b" => 2 }
    expect(settings.raw).to eq("b" => 2)
  end

  it "environment_order= writes the key into raw" do
    settings = described_class.new(nil, data: {})
    settings.environment_order = %w[production staging]
    expect(settings.raw["environment_order"]).to eq(%w[production staging])
  end

  it "renders the data in to_s/inspect" do
    expect(described_class.new(nil, data: { "a" => 1 }).to_s).to include("a")
  end

  it "raises when saved without a client" do
    expect { described_class.new(nil).save }.to raise_error(RuntimeError, /without a client/)
  end

  it "saves through the client and applies the server response" do
    server = described_class.new(nil, data: { "environment_order" => %w[production] })
    client = instance_double(Smplkit::Account::SettingsClient, _save: server)
    settings = described_class.new(client, data: { "environment_order" => %w[staging] })
    settings.environment_order = %w[production staging]

    result = settings.save

    expect(client).to have_received(:_save).with("environment_order" => %w[production staging])
    expect(result).to equal(settings)
    expect(settings.environment_order).to eq(%w[production])
  end
end
