# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Flags::FlagsClient do
  subject(:flags_client) do
    described_class.new(parent, manage: management, metrics: nil,
                                flags_base_url: "https://flags.smplkit.com",
                                app_base_url: "https://app.smplkit.com")
  end

  let(:manage) { instance_double(Smplkit::ManagementClient::FlagsNamespace, register: nil, flush: nil) }
  let(:contexts_ns) { instance_double(Smplkit::ManagementClient::ContextsNamespace, register: nil) }
  let(:management) { instance_double(Smplkit::ManagementClient, flags: manage, contexts: contexts_ns) }
  let(:ws) { Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.com", api_key: "k") }
  let(:parent) do
    double(
      _service: "showcase",
      _environment: "staging",
      _ensure_ws: ws,
      _flags_transport: flags_transport
    )
  end
  let(:flags_transport) do
    double(list_flags: [flag_def("checkout-v2", default: false, env_default: nil, enabled: true, rules: rules)],
           fetch_flag: flag_def("checkout-v2", default: false, env_default: nil, enabled: true, rules: rules))
  end
  let(:rules) do
    [Smplkit::Flags::FlagRule.new(
      logic: { "==" => [{ "var" => "user.plan" }, "enterprise"] },
      value: true,
      description: "enterprise"
    )]
  end

  def flag_def(id, default:, env_default:, enabled:, rules:)
    {
      "id" => id, "name" => id, "type" => "BOOLEAN", "default" => default,
      "values" => nil, "description" => nil,
      "environments" => {
        "staging" => Smplkit::Flags::FlagEnvironment.new(
          enabled: enabled, default: env_default, rules: rules
        )
      }
    }
  end

  it "boolean_flag returns a typed handle and registers" do
    handle = flags_client.boolean_flag("checkout-v2", default: false)
    expect(handle).to be_a(Smplkit::Flags::BooleanFlag)
    expect(manage).to have_received(:register)
  end

  it "evaluates with explicit context (rule match -> true)" do
    handle = flags_client.boolean_flag("checkout-v2", default: false)
    ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
    expect(handle.get(context: ctx)).to be(true)
  end

  it "evaluates with implicit context via Smplkit.set_request_context" do
    handle = flags_client.boolean_flag("checkout-v2", default: false)
    Smplkit.set_request_context([Smplkit::Context.new("user", "u-1", plan: "free")])
    expect(handle.get).to be(false)
  end

  it "falls back to default when flag missing from store" do
    allow(parent).to receive(:_flags_transport).and_return(double(list_flags: []))
    handle = flags_client.boolean_flag("unknown", default: true)
    expect(handle.get).to be(true)
  end

  it "stats reports cache hits/misses" do
    allow(parent).to receive(:_flags_transport).and_return(double(list_flags: []))
    handle = flags_client.boolean_flag("missing", default: true)
    handle.get
    handle.get
    stats = flags_client.stats
    expect(stats.cache_hits + stats.cache_misses).to be >= 2
  end

  it "string_flag coerces values to String" do
    allow(parent).to receive(:_flags_transport).and_return(double(list_flags: []))
    handle = flags_client.string_flag("color", default: "red")
    expect(handle.get).to eq("red")
  end

  describe "on_change" do
    it "registers a global listener" do
      block_called = false
      flags_client.on_change { |_| block_called = true }
      flags_client.send(:fire_change_listeners, "x", "manual")
      expect(block_called).to be(true)
    end

    it "registers a flag-scoped listener" do
      seen = []
      flags_client.on_change("a") { |evt| seen << evt.id }
      flags_client.send(:fire_change_listeners, "a", "manual")
      flags_client.send(:fire_change_listeners, "b", "manual")
      expect(seen).to eq(["a"])
    end

    it "raises without a block" do
      expect { flags_client.on_change }.to raise_error(ArgumentError)
    end
  end
end

RSpec.describe Smplkit::Flags::ResolutionCache do
  it "tracks hits/misses and evicts" do
    cache = described_class.new(max_size: 2)
    expect(cache.get("k1")).to eq([false, nil])
    cache.put("k1", "v1")
    expect(cache.get("k1")).to eq([true, "v1"])
    cache.put("k2", "v2")
    cache.put("k3", "v3")
    # k1 should have been evicted (oldest)
    expect(cache.get("k1")).to eq([false, nil])
  end
end

RSpec.describe Smplkit::Flags::JsonLogicEvaluator do
  it "evaluates ==" do
    expect(described_class.apply({ "==" => [1, 1] }, {})).to be(true)
    expect(described_class.apply({ "==" => [1, 2] }, {})).to be(false)
  end

  it "evaluates var" do
    expect(described_class.apply({ "var" => "user.plan" }, "user" => { "plan" => "enterprise" })).to eq("enterprise")
  end

  it "evaluates and/or/!" do
    expect(described_class.apply({ "and" => [true, true] }, {})).to be(true)
    expect(described_class.apply({ "or" => [false, true] }, {})).to be(true)
    expect(described_class.apply({ "!" => [false] }, {})).to be(true)
  end

  it "evaluates comparisons" do
    expect(described_class.apply({ "<" => [1, 2] }, {})).to be(true)
    expect(described_class.apply({ ">=" => [2, 2] }, {})).to be(true)
  end

  it "evaluates in" do
    expect(described_class.apply({ "in" => ["a", %w[a b]] }, {})).to be(true)
    expect(described_class.apply({ "in" => ["c", %w[a b]] }, {})).to be(false)
  end

  it "returns false for unknown operators" do
    expect(described_class.apply({ "weird-op" => [] }, {})).to be(false)
  end
end
