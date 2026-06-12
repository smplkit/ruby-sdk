# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Flags::Flag do
  let(:flag) do
    described_class.new(
      id: "checkout-v2", name: "Checkout V2", type: "BOOLEAN", default: false
    )
  end

  it "starts with empty environments and no values" do
    expect(flag.environments).to eq({})
    expect(flag.values).to be_nil
  end

  describe "#add_rule" do
    it "appends a rule to the named environment" do
      built = Smplkit::Rule.new("Enterprise", environment: "staging")
                           .when("user.plan", Smplkit::Op::EQ, "enterprise")
                           .serve(true)
      flag.add_rule(built)
      env = flag.environments["staging"]
      expect(env.rules.length).to eq(1)
      expect(env.rules.first.value).to be(true)
    end

    it "raises if environment is missing" do
      built = { "logic" => {}, "value" => true }
      expect { flag.add_rule(built) }.to raise_error(ArgumentError)
    end
  end

  describe "#enable_rules / #disable_rules" do
    it "scopes to a single environment when specified" do
      flag.enable_rules(environment: "staging")
      expect(flag.environments["staging"].enabled).to be(true)
    end

    it "applies across all known environments when omitted" do
      flag.enable_rules(environment: "staging")
      flag.enable_rules(environment: "production")
      flag.disable_rules
      expect(flag.environments.values.map(&:enabled)).to all(be(false))
    end
  end

  describe "#set_default / #clear_default" do
    it "writes per-environment defaults" do
      flag.set_default("blue", environment: "production")
      expect(flag.environments["production"].default).to eq("blue")
      flag.clear_default(environment: "production")
      expect(flag.environments["production"].default).to be_nil
    end
  end

  describe "#add_value / #remove_value / #clear_values" do
    it "manages values" do
      flag.add_value(Smplkit::FlagValue.new(name: "Red", value: "red"))
      flag.add_value(Smplkit::FlagValue.new(name: "Blue", value: "blue"))
      expect(flag.values.map(&:name)).to eq(%w[Red Blue])
      flag.remove_value("Red")
      expect(flag.values.map(&:name)).to eq(["Blue"])
      flag.clear_values
      expect(flag.values).to eq([])
    end
  end

  it "save raises without a client" do
    expect { flag.save }.to raise_error(RuntimeError, /without a client/)
    expect { flag.save! }.to raise_error(RuntimeError, /without a client/)
  end

  it "delete raises without an id" do
    expect { flag.delete }.to raise_error(RuntimeError)
  end

  it "delete routes through the bound client when an id is present" do
    client = double("flags_client")
    bound = described_class.new(client, id: "checkout-v2", name: "Checkout V2", type: "BOOLEAN", default: false)
    expect(client).to receive(:delete).with("checkout-v2")
    bound.delete
  end

  describe "#clear_rules" do
    it "clears rules in a single environment when specified" do
      flag.add_rule(Smplkit::Rule.new("Enterprise", environment: "staging")
                                 .when("user.plan", Smplkit::Op::EQ, "enterprise").serve(true))
      flag.clear_rules(environment: "staging")
      expect(flag.environments["staging"].rules).to eq([])
    end

    it "clears rules across all known environments when omitted" do
      flag.add_rule(Smplkit::Rule.new("a", environment: "staging").serve(true))
      flag.add_rule(Smplkit::Rule.new("b", environment: "production").serve(false))
      flag.clear_rules
      expect(flag.environments.values.map(&:rules)).to all(eq([]))
    end
  end
end

RSpec.describe Smplkit::Flags::FlagEnvironment do
  it "is a Data type with predicate alias" do
    env = described_class.new(enabled: true)
    expect(env.enabled?).to be(true)
    expect(env.with(enabled: false).enabled).to be(false)
  end
end

RSpec.describe Smplkit::Flags::FlagValue do
  it "exposes name and value" do
    v = described_class.new(name: "Red", value: "red")
    expect(v.name).to eq("Red")
    expect(v.value).to eq("red")
  end
end

RSpec.describe Smplkit::Flags::FlagRule do
  it "defaults value and description to nil" do
    r = described_class.new(logic: {})
    expect(r.value).to be_nil
    expect(r.description).to be_nil
  end
end
