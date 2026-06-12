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

  it "attributes= bulk-replaces and stringifies keys" do
    ctx = described_class.new("user", "u-1", plan: "free")
    ctx.attributes = { region: "eu", tier: 2 }
    expect(ctx.attributes).to eq("region" => "eu", "tier" => 2)
  end

  it "attributes= treats nil as an empty hash" do
    ctx = described_class.new("user", "u-1", plan: "free")
    ctx.attributes = nil
    expect(ctx.attributes).to eq({})
  end

  it "routes delete through the bound client" do
    client = instance_double(Smplkit::Platform::ContextsClient)
    ctx = described_class.new("user", "u-1")._bind_client(client)
    expect(client).to receive(:delete).with("user:u-1")
    ctx.delete
  end

  it "exposes the bound client via _client" do
    client = Object.new
    ctx = described_class.new("user", "u-1")._bind_client(client)
    expect(ctx._client).to be(client)
  end

  it "implements hash, eql? and == for use as a Hash key" do
    a = described_class.new("user", "u-1", plan: "x")
    b = described_class.new("user", "u-1", plan: "x")
    c = described_class.new("user", "u-2", plan: "x")
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a.eql?(b)).to be(true)
    expect(a).not_to eq(c)
    expect(a).not_to eq("not a context")
  end

  it "inspect includes type, key, name and attributes" do
    ctx = described_class.new("user", "u-1", name: "Acme", plan: "x")
    expect(ctx.inspect).to start_with('#<Smplkit::Context type="user" key="u-1" name="Acme" attributes=')
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

  it "implements value equality and a matching hash" do
    a = described_class.new(id: "f", type: "BOOLEAN", default: false, service: "svc", environment: "stg")
    b = described_class.new(id: "f", type: "BOOLEAN", default: false, service: "svc", environment: "stg")
    c = described_class.new(id: "f", type: "BOOLEAN", default: true, service: "svc", environment: "stg")
    expect(a).to eq(b)
    expect(a.eql?(b)).to be(true)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
    expect(a).not_to eq("not a declaration")
  end
end
