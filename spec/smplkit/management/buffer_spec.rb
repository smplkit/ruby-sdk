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

RSpec.describe Smplkit::Management::ConfigRegistrationBuffer do
  let(:buffer) { described_class.new }

  it "declare records metadata and queues a pending entry" do
    buffer.declare("billing", service: "svc", environment: "prod", name: "Billing", description: "Plan limits")
    expect(buffer.pending_count).to eq(1)
  end

  it "declare is idempotent — first writer's metadata wins" do
    buffer.declare("billing", service: "svc-a", environment: "prod", name: "Billing-A", description: "first")
    buffer.declare("billing", service: "svc-b", environment: "stg", name: "Billing-B", description: "second")
    batch = buffer.drain
    expect(batch.length).to eq(1)
    expect(batch.first["service"]).to eq("svc-a")
    expect(batch.first["name"]).to eq("Billing-A")
    expect(batch.first["description"]).to eq("first")
  end

  it "add_item without a prior declare is a no-op" do
    buffer.add_item("billing", "max_seats", "NUMBER", 5)
    expect(buffer.pending_count).to eq(0)
  end

  it "add_item after declare queues the item" do
    buffer.declare("billing", service: "svc", environment: "prod")
    buffer.add_item("billing", "max_seats", "NUMBER", 5, "Default seats.")
    batch = buffer.drain
    expect(batch.first["items"]).to eq(
      "max_seats" => { "value" => 5, "type" => "NUMBER", "description" => "Default seats." }
    )
  end

  it "add_item is a no-op when the item is already queued" do
    buffer.declare("billing", service: "svc", environment: "prod")
    buffer.add_item("billing", "max_seats", "NUMBER", 5)
    buffer.add_item("billing", "max_seats", "NUMBER", 99, "different default")
    batch = buffer.drain
    expect(batch.first["items"]["max_seats"]["value"]).to eq(5)
  end

  it "drain clears pending and records sent items" do
    buffer.declare("billing", service: "svc", environment: "prod")
    buffer.add_item("billing", "max_seats", "NUMBER", 5)
    expect(buffer.drain.length).to eq(1)
    expect(buffer.pending_count).to eq(0)
    # An already-sent item never resurfaces.
    buffer.add_item("billing", "max_seats", "NUMBER", 5)
    expect(buffer.pending_count).to eq(0)
  end

  it "post-drain, a new item creates a delta entry using retained metadata" do
    buffer.declare("billing", service: "svc", environment: "prod", name: "Billing")
    buffer.add_item("billing", "first", "STRING", "a")
    buffer.drain

    buffer.add_item("billing", "second", "NUMBER", 7, "added later")
    batch = buffer.drain
    expect(batch.length).to eq(1)
    expect(batch.first["id"]).to eq("billing")
    expect(batch.first["name"]).to eq("Billing")
    expect(batch.first["items"].keys).to eq(["second"])
  end

  it "declare with a parent retains parent on the wire row" do
    buffer.declare("billing", service: "svc", environment: "prod", parent: "common")
    expect(buffer.drain.first["parent"]).to eq("common")
  end

  it "drain of an empty buffer returns []" do
    expect(buffer.drain).to eq([])
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
