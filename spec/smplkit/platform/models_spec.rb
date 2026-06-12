# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Platform do
  describe ".coerce_color" do
    it "passes a Color through unchanged" do
      color = Smplkit::Color.new("#fff")
      expect(described_class.coerce_color(color)).to be(color)
    end

    it "wraps a hex string in a Color" do
      result = described_class.coerce_color("#ef4444")
      expect(result).to be_a(Smplkit::Color)
      expect(result.hex).to eq("#ef4444")
    end

    it "passes nil through" do
      expect(described_class.coerce_color(nil)).to be_nil
    end

    it "raises TypeError on anything else" do
      expect { described_class.coerce_color(123) }.to raise_error(TypeError, /must be a Color/)
    end
  end
end

RSpec.describe Smplkit::Platform::Environment do
  subject(:env) { described_class.new(client, id: "staging", name: "Staging") }

  let(:client) { instance_double(Smplkit::Platform::EnvironmentsClient, _create: nil, _update: nil, delete: nil) }

  it "carries identity and metadata" do
    expect(env.id).to eq("staging")
    expect(env.name).to eq("Staging")
    expect(env.classification).to eq(Smplkit::EnvironmentClassification::STANDARD)
  end

  describe "color coercion" do
    it "coerces a hex string in the constructor" do
      colored = described_class.new(client, id: "p", name: "P", color: "#ef4444")
      expect(colored.color).to be_a(Smplkit::Color)
      expect(colored.color.hex).to eq("#ef4444")
    end

    it "passes a Color through in the constructor" do
      color = Smplkit::Color.new("#fff")
      colored = described_class.new(client, id: "p", name: "P", color: color)
      expect(colored.color).to be(color)
    end

    it "leaves color nil when unset" do
      expect(env.color).to be_nil
    end

    it "raises on an invalid color type in the constructor" do
      expect { described_class.new(client, id: "p", name: "P", color: 42) }.to raise_error(TypeError)
    end

    it "coerces via the color= setter" do
      env.color = "#000000"
      expect(env.color).to be_a(Smplkit::Color)
      env.color = nil
      expect(env.color).to be_nil
    end
  end

  describe "#save" do
    it "raises when constructed without a client" do
      bare = described_class.new(id: "k", name: "K")
      expect { bare.save }.to raise_error(RuntimeError, /without a client/)
    end

    it "calls _create when never persisted, then applies the result" do
      created = described_class.new(client, id: "staging", name: "Staging", color: "#ef4444",
                                            classification: Smplkit::EnvironmentClassification::AD_HOC,
                                            created_at: "t0", updated_at: "t1")
      allow(client).to receive(:_create).and_return(created)
      expect(env.save).to be(env)
      expect(client).to have_received(:_create).with(env)
      expect(env.created_at).to eq("t0")
      expect(env.color.hex).to eq("#ef4444")
      expect(env.classification).to eq(Smplkit::EnvironmentClassification::AD_HOC)
    end

    it "calls _update when previously persisted" do
      persisted = described_class.new(client, id: "staging", name: "Staging", created_at: "now")
      updated = described_class.new(client, id: "staging", name: "Renamed", created_at: "now", updated_at: "later")
      allow(client).to receive(:_update).and_return(updated)
      persisted.save
      expect(client).to have_received(:_update).with(persisted)
      expect(persisted.name).to eq("Renamed")
    end

    it "save! aliases save" do
      allow(client).to receive(:_create).and_return(env)
      expect { env.save! }.not_to raise_error
    end
  end

  describe "#delete" do
    it "dispatches to the client" do
      env.delete
      expect(client).to have_received(:delete).with("staging")
    end

    it "delete! aliases delete" do
      env.delete!
      expect(client).to have_received(:delete).with("staging")
    end

    it "raises without a client" do
      expect { described_class.new(id: "k", name: "K").delete }.to raise_error(RuntimeError, /without a client/)
    end

    it "raises without an id" do
      expect { described_class.new(client, id: nil, name: "K").delete }.to raise_error(RuntimeError, /without/)
    end
  end

  it "to_s / inspect render identity" do
    expect(env.to_s).to eq('Environment(id="staging", name="Staging", classification="STANDARD")')
    expect(env.inspect).to eq(env.to_s)
  end
end

RSpec.describe Smplkit::Platform::Service do
  subject(:svc) { described_class.new(client, id: "user_service", name: "User Service") }

  let(:client) { instance_double(Smplkit::Platform::ServicesClient, _create: nil, _update: nil, delete: nil) }

  it "carries identity and metadata" do
    expect(svc.id).to eq("user_service")
    expect(svc.name).to eq("User Service")
  end

  it "save calls _create when never persisted" do
    fresh = described_class.new(client, id: "x", name: "X", created_at: "t0")
    allow(client).to receive(:_create).and_return(fresh)
    expect(svc.save).to be(svc)
    expect(client).to have_received(:_create).with(svc)
    expect(svc.created_at).to eq("t0")
  end

  it "save calls _update when previously persisted" do
    persisted = described_class.new(client, id: "user_service", name: "User Service", created_at: "now")
    updated = described_class.new(client, id: "user_service", name: "Renamed", created_at: "now", updated_at: "later")
    allow(client).to receive(:_update).and_return(updated)
    persisted.save
    expect(client).to have_received(:_update).with(persisted)
    expect(persisted.updated_at).to eq("later")
  end

  it "save! aliases save" do
    allow(client).to receive(:_create).and_return(svc)
    expect { svc.save! }.not_to raise_error
  end

  it "raises on save without a client" do
    expect { described_class.new(id: "k", name: "K").save }.to raise_error(RuntimeError, /without a client/)
  end

  it "delete dispatches to the client" do
    svc.delete
    expect(client).to have_received(:delete).with("user_service")
  end

  it "delete! aliases delete" do
    svc.delete!
    expect(client).to have_received(:delete).with("user_service")
  end

  it "raises on delete without a client or id" do
    expect { described_class.new(id: "k", name: "K").delete }.to raise_error(RuntimeError, /without/)
    expect { described_class.new(client, id: nil, name: "K").delete }.to raise_error(RuntimeError, /without/)
  end

  it "to_s / inspect render identity" do
    expect(svc.to_s).to eq('Service(id="user_service", name="User Service")')
    expect(svc.inspect).to eq(svc.to_s)
  end
end

RSpec.describe Smplkit::Platform::ContextType do
  subject(:ct) { described_class.new(client, id: "user", name: "User") }

  let(:client) { instance_double(Smplkit::Platform::ContextTypesClient, _create: nil, _update: nil, delete: nil) }

  it "defaults attributes to an empty hash" do
    expect(ct.attributes).to eq({})
  end

  it "deep-dups and stringifies attributes given at construction" do
    typed = described_class.new(client, id: "user", name: "User",
                                        attributes: { plan: { type: "string", required: true }, tier: "gold" })
    expect(typed.attributes).to eq(
      "plan" => { "type" => "string", "required" => true },
      "tier" => "gold"
    )
  end

  describe "attribute mutation" do
    it "add_attribute stringifies metadata keys" do
      ct.add_attribute("plan", type: "string", required: true)
      expect(ct.attributes).to eq("plan" => { "type" => "string", "required" => true })
    end

    it "update_attribute replaces the slot" do
      ct.add_attribute("plan", type: "string")
      ct.update_attribute("plan", type: "number")
      expect(ct.attributes["plan"]).to eq("type" => "number")
    end

    it "remove_attribute deletes the slot" do
      ct.add_attribute("plan", type: "string")
      ct.remove_attribute("plan")
      expect(ct.attributes).to eq({})
    end
  end

  it "save dispatches to create when fresh" do
    fresh = described_class.new(client, id: "user", name: "User", attributes: { "x" => 1 }, created_at: "t0")
    allow(client).to receive(:_create).and_return(fresh)
    ct.save
    expect(client).to have_received(:_create).with(ct)
    expect(ct.attributes).to eq("x" => 1)
    expect(ct.created_at).to eq("t0")
  end

  it "save dispatches to update when persisted" do
    persisted = described_class.new(client, id: "user", name: "User", created_at: "now")
    updated = described_class.new(client, id: "user", name: "Renamed", created_at: "now")
    allow(client).to receive(:_update).and_return(updated)
    persisted.save
    expect(client).to have_received(:_update).with(persisted)
    expect(persisted.name).to eq("Renamed")
  end

  it "save! aliases save" do
    allow(client).to receive(:_create).and_return(ct)
    expect { ct.save! }.not_to raise_error
  end

  it "raises on save without a client" do
    expect { described_class.new(id: "k", name: "K").save }.to raise_error(RuntimeError, /without a client/)
  end

  it "delete dispatches to the client" do
    ct.delete
    expect(client).to have_received(:delete).with("user")
  end

  it "delete! aliases delete" do
    ct.delete!
    expect(client).to have_received(:delete).with("user")
  end

  it "raises on delete without a client or id" do
    expect { described_class.new(id: "k", name: "K").delete }.to raise_error(RuntimeError, /without/)
    expect { described_class.new(client, id: nil, name: "K").delete }.to raise_error(RuntimeError, /without/)
  end

  it "to_s / inspect render identity" do
    expect(ct.to_s).to eq('ContextType(id="user", name="User")')
    expect(ct.inspect).to eq(ct.to_s)
  end
end

# rubocop:enable RSpec/MultipleExpectations
