# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Management::ContextRegistrationBuffer do
  let(:buffer) { described_class.new }

  it "deduplicates by (type, key)" do
    buffer.observe([Smplkit::Context.new("user", "u-1", plan: "enterprise")])
    buffer.observe([Smplkit::Context.new("user", "u-1", plan: "free")])
    expect(buffer.pending_count).to eq(1)
  end

  it "drains and clears" do
    buffer.observe([Smplkit::Context.new("user", "u-1")])
    expect(buffer.drain.length).to eq(1)
    expect(buffer.pending_count).to eq(0)
  end
end

RSpec.describe Smplkit::Management::FlagRegistrationBuffer do
  let(:buffer) { described_class.new }

  it "deduplicates by id" do
    buffer.add(Smplkit::FlagDeclaration.new(id: "a", type: "BOOLEAN", default: false))
    buffer.add(Smplkit::FlagDeclaration.new(id: "a", type: "BOOLEAN", default: true))
    expect(buffer.pending_count).to eq(1)
  end

  it "drains and clears" do
    buffer.add(Smplkit::FlagDeclaration.new(id: "a", type: "BOOLEAN", default: false))
    expect(buffer.drain).to eq([{ "id" => "a", "type" => "BOOLEAN", "default" => false }])
  end
end

RSpec.describe Smplkit::Management::LoggerRegistrationBuffer do
  let(:buffer) { described_class.new }

  it "tracks unique logger names" do
    src = Smplkit::LoggerSource.new(name: "rails", resolved_level: Smplkit::LogLevel::INFO)
    buffer.add(src)
    buffer.add(src)
    expect(buffer.pending_count).to eq(1)
  end
end
