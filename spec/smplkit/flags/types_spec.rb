# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Context do
  it "requires String type and key" do
    expect { described_class.new(:user, "u-1") }.to raise_error(TypeError)
    expect { described_class.new("user", 123) }.to raise_error(TypeError)
  end

  it "merges attributes hash and kwargs and stringifies keys" do
    ctx = described_class.new("user", "u-1", { region: "us" }, plan: "enterprise")
    expect(ctx.attributes).to eq("region" => "us", "plan" => "enterprise")
  end

  it "exposes a composite id" do
    ctx = described_class.new("user", "u-1")
    expect(ctx.id).to eq("user:u-1")
  end

  it "to_eval_hash includes key + attrs" do
    ctx = described_class.new("user", "u-1", plan: "enterprise")
    expect(ctx.to_eval_hash).to eq("key" => "u-1", "plan" => "enterprise")
  end

  it "raises on save without a client" do
    expect { described_class.new("user", "u-1").save }.to raise_error(RuntimeError, /without a client/)
    expect { described_class.new("user", "u-1").delete }.to raise_error(RuntimeError, /without a client/)
  end
end

RSpec.describe Smplkit::Op do
  it "exposes the canonical operator strings" do
    expect(described_class::EQ).to eq("==")
    expect(described_class::CONTAINS).to eq("contains")
    expect(described_class::ALL).to include("==", "in", "contains")
  end
end

RSpec.describe Smplkit::Rule do
  it "builds a single-condition serve" do
    built = described_class.new("when enterprise", environment: "staging")
                           .when("user.plan", Smplkit::Op::EQ, "enterprise")
                           .serve(true)
    expect(built["environment"]).to eq("staging")
    expect(built["value"]).to be(true)
    expect(built["logic"]).to eq("==" => [{ "var" => "user.plan" }, "enterprise"])
  end

  it "ANDs multiple conditions" do
    built = described_class.new("composite", environment: "staging")
                           .when("user.plan", Smplkit::Op::EQ, "enterprise")
                           .when("account.region", "==", "us")
                           .serve(true)
    expect(built["logic"].keys).to eq(["and"])
    expect(built["logic"]["and"].length).to eq(2)
  end

  it "supports raw JSON Logic via single-arg when" do
    built = described_class.new("raw", environment: "p")
                           .when("or" => [{ "==" => [{ "var" => "user.beta" }, true] }])
                           .serve(false)
    expect(built["logic"]).to eq("or" => [{ "==" => [{ "var" => "user.beta" }, true] }])
  end

  it "uses 'in' with reversed operands for contains" do
    built = described_class.new("in", environment: "p")
                           .when("user.tags", Smplkit::Op::CONTAINS, "beta")
                           .serve(true)
    expect(built["logic"]).to eq("in" => ["beta", { "var" => "user.tags" }])
  end

  it "raises on bad arity" do
    rule = described_class.new("bad", environment: "p")
    expect { rule.when("a", "b") }.to raise_error(ArgumentError)
    expect { rule.when }.to raise_error(ArgumentError)
  end

  it "serves an empty logic Hash when no conditions" do
    built = described_class.new("none", environment: "p").serve(true)
    expect(built["logic"]).to eq({})
  end
end

RSpec.describe Smplkit::FlagDeclaration do
  it "constructs with required keyword args" do
    decl = described_class.new(id: "checkout-v2", type: "BOOLEAN", default: false)
    expect(decl.id).to eq("checkout-v2")
    expect(decl.service).to be_nil
  end
end
