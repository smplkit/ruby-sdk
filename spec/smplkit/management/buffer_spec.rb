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

  it "peek returns a snapshot without removing items" do
    buffer.add(Smplkit::FlagDeclaration.new(id: "a", type: "BOOLEAN", default: false))
    snapshot = buffer.peek
    expect(snapshot.length).to eq(1)
    expect(buffer.pending_count).to eq(1)
  end

  it "commit removes items by id after a successful send" do
    buffer.add(Smplkit::FlagDeclaration.new(id: "a", type: "BOOLEAN", default: false))
    buffer.add(Smplkit::FlagDeclaration.new(id: "b", type: "STRING", default: "x"))
    buffer.commit(["a"])
    expect(buffer.pending_count).to eq(1)
    expect(buffer.peek.map { |i| i["id"] }).to eq(["b"])
  end

  it "commit is a no-op for an empty id list" do
    buffer.add(Smplkit::FlagDeclaration.new(id: "a", type: "BOOLEAN", default: false))
    buffer.commit([])
    expect(buffer.pending_count).to eq(1)
  end

  it "items are retained when peek is called without a subsequent commit (failed send)" do
    buffer.add(Smplkit::FlagDeclaration.new(id: "a", type: "BOOLEAN", default: false))
    buffer.peek # simulate reading before a send that will fail
    # no commit — simulates a 500 response
    expect(buffer.pending_count).to eq(1)
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
