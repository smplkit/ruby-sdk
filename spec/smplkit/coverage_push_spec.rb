# frozen_string_literal: true

require "spec_helper"

# Targeted specs that close the longest-tail coverage gaps in the
# wrapper layer. Uses direct method calls with mocks rather than going
# through the public client surface so the deeper internal branches
# are reachable without standing up live transports.

# ---------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------

RSpec.describe Smplkit::Flags::FlagChangeEvent do
  it "compares structurally" do
    a = described_class.new(id: "f", source: "ws")
    b = described_class.new(id: "f", source: "ws")
    c = described_class.new(id: "g", source: "ws")
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
    expect(a.deleted?).to be(false)
  end
end

RSpec.describe Smplkit::Flags::FlagRule do
  it "compares structurally" do
    a = described_class.new(logic: { "==" => [1, 1] }, value: true)
    b = described_class.new(logic: { "==" => [1, 1] }, value: true)
    c = described_class.new(logic: { "==" => [1, 2] }, value: false)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
  end
end

RSpec.describe Smplkit::Flags::FlagEnvironment do
  it "compares structurally" do
    rules = [Smplkit::Flags::FlagRule.new(logic: {}, value: true)]
    a = described_class.new(enabled: true, default: nil, rules: rules)
    b = described_class.new(enabled: true, default: nil, rules: rules)
    c = described_class.new(enabled: false, default: nil, rules: rules)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
  end
end

RSpec.describe Smplkit::Flags::Flag do
  let(:client) { double("FlagsNamespace") }

  it "save dispatches to _create_flag when fresh and applies the returned attrs" do
    fresh = described_class.new(client, id: "x", name: "X", type: "BOOLEAN", default: false)
    refreshed = described_class.new(client, id: "x", name: "X-Renamed",
                                            type: "BOOLEAN", default: true,
                                            created_at: "now")
    allow(client).to receive(:_create_flag).and_return(refreshed)
    fresh.save
    expect(fresh.created_at).to eq("now")
    expect(fresh.name).to eq("X-Renamed")
  end

  it "save dispatches to _update_flag when previously persisted" do
    persisted = described_class.new(client, id: "x", name: "X", type: "BOOLEAN", default: false,
                                            created_at: "now")
    allow(client).to receive(:_update_flag).and_return(persisted)
    persisted.save
    expect(client).to have_received(:_update_flag)
  end

  it "delete dispatches to the namespace" do
    flag = described_class.new(client, id: "x", name: "X", type: "BOOLEAN", default: false)
    allow(client).to receive(:delete)
    flag.delete
    expect(client).to have_received(:delete).with("x")
  end

  it "raises on save without a client" do
    bare = described_class.new(name: "x", type: "BOOLEAN", default: false)
    expect { bare.save }.to raise_error(RuntimeError, /without a client/)
    expect { bare.delete }.to raise_error(RuntimeError, /without a client or id/)
  end

  it "clear_rules wipes a single environment's rules" do
    flag = described_class.new(client, id: "x", name: "X", type: "BOOLEAN", default: false)
    flag.add_rule(Smplkit::Rule.new("staging", environment: "staging").when({ "==" => [1, 1] }).serve(true))
    flag.clear_rules(environment: "staging")
    expect(flag.environments["staging"].rules).to eq([])
  end

  it "BooleanFlag#get coerces non-bool truthy/falsy values to bool" do
    bool = Smplkit::Flags::BooleanFlag.new(client, id: "f", name: "f", type: "BOOLEAN", default: false)
    allow(client).to receive(:_evaluate_handle).and_return(1)
    expect(bool.get).to be(true)
  end

  it "NumberFlag#get returns the raw value" do
    num = Smplkit::Flags::NumberFlag.new(client, id: "n", name: "n", type: "NUMERIC", default: 1)
    allow(client).to receive(:_evaluate_handle).and_return(42)
    expect(num.get).to eq(42)
  end

  it "JsonFlag#get returns the raw value" do
    json = Smplkit::Flags::JsonFlag.new(client, id: "j", name: "j", type: "JSON", default: {})
    allow(client).to receive(:_evaluate_handle).and_return("a" => 1)
    expect(json.get).to eq("a" => 1)
  end
end

RSpec.describe Smplkit::Flags::FlagsClient do
  subject(:client) do
    described_class.new(parent, manage: management, metrics: nil,
                                flags_base_url: "https://flags.smplkit.test",
                                app_base_url: "https://app.smplkit.test")
  end

  let(:flags_ns) { instance_double(Smplkit::ManagementClient::FlagsNamespace, register: nil, flush: nil) }
  let(:contexts_ns) { instance_double(Smplkit::ManagementClient::ContextsNamespace, register: nil) }
  let(:management) { instance_double(Smplkit::ManagementClient, flags: flags_ns, contexts: contexts_ns) }
  let(:flags_transport) do
    double("flags_transport", list_flags: [], fetch_flag: nil)
  end
  let(:ws) do
    Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k")
  end
  let(:parent) do
    double(_service: "svc", _environment: "stg", _ensure_ws: ws, _flags_transport: flags_transport)
  end

  it "number_flag and json_flag construct typed handles" do
    num = client.number_flag("retries", default: 3)
    expect(num).to be_a(Smplkit::Flags::NumberFlag)
    json = client.json_flag("payload", default: { "a" => 1 })
    expect(json).to be_a(Smplkit::Flags::JsonFlag)
  end

  describe "WS event handlers" do
    it "handle_flag_changed re-fetches and fires listeners on change" do
      seen = []
      client.on_change("checkout") { |evt| seen << [evt.id, evt.source] }
      flag_def = { "id" => "checkout", "name" => "X", "type" => "BOOLEAN", "default" => false,
                   "environments" => {} }
      allow(flags_transport).to receive(:fetch_flag).and_return(flag_def)
      client.send(:handle_flag_changed, { "id" => "checkout" })
      expect(seen).to eq([%w[checkout websocket]])
    end

    it "handle_flag_changed ignores messages with no id" do
      expect { client.send(:handle_flag_changed, {}) }.not_to raise_error
    end

    it "handle_flag_deleted removes the flag and fires deleted listeners" do
      seen = []
      client.on_change("x") { |evt| seen << evt.deleted }
      client.instance_variable_get(:@flag_store)["x"] = { "id" => "x" }
      client.send(:handle_flag_deleted, { "id" => "x" })
      expect(seen).to eq([true])
    end

    it "handle_flag_deleted no-ops when key never existed" do
      expect { client.send(:handle_flag_deleted, { "id" => "nope" }) }.not_to raise_error
    end

    it "handle_flag_deleted ignores messages with no id" do
      expect { client.send(:handle_flag_deleted, {}) }.not_to raise_error
    end

    it "handle_flags_changed fires per-key events for changed keys" do
      old_def = { "id" => "x", "name" => "x", "type" => "BOOLEAN", "default" => false, "environments" => {} }
      new_def = old_def.merge("default" => true)
      client.instance_variable_get(:@flag_store)["x"] = old_def
      allow(flags_transport).to receive(:list_flags).and_return([new_def])
      seen = []
      client.on_change { |evt| seen << evt.id }
      client.send(:handle_flags_changed, {})
      expect(seen).to include("x")
    end

    it "handle_flags_changed bails out cleanly when fetch_all_flags raises" do
      allow(flags_transport).to receive(:list_flags).and_raise("boom")
      expect { client.send(:handle_flags_changed, {}) }.not_to raise_error
    end

    it "handle_flags_changed marks deleted keys" do
      client.instance_variable_get(:@flag_store)["gone"] = { "id" => "gone" }
      allow(flags_transport).to receive(:list_flags).and_return([])
      seen = []
      client.on_change("gone") { |evt| seen << evt.deleted }
      client.send(:handle_flags_changed, {})
      expect(seen).to include(true)
    end

    it "fire_change_listeners swallows exceptions raised by listeners" do
      client.on_change { raise "boom" }
      expect { client.send(:fire_change_listeners, "x", "manual") }.not_to raise_error
    end
  end

  describe "evaluate" do
    it "wraps json_logic exceptions and continues to the next rule" do
      good = Smplkit::Flags::FlagRule.new(logic: { "==" => [1, 2] }, value: true)
      flag_def = {
        "id" => "f", "default" => false,
        "environments" => {
          "stg" => Smplkit::Flags::FlagEnvironment.new(enabled: true, rules: [good])
        }
      }
      allow(Smplkit::Flags::JsonLogicEvaluator).to receive(:apply).and_raise("logic boom")
      expect(client.send(:evaluate_flag, flag_def, "stg", {})).to be(false)
    end
  end

  describe "fetch_all_flags error mapping" do
    it "wraps non-Smplkit errors as ConnectionError" do
      allow(flags_transport).to receive(:list_flags).and_raise("pipe broken")
      expect { client.send(:fetch_all_flags) }.to raise_error(Smplkit::ConnectionError, /pipe broken/)
    end

    it "passes Smplkit errors through unchanged" do
      allow(flags_transport).to receive(:list_flags).and_raise(Smplkit::NotFoundError, "nope")
      expect { client.send(:fetch_all_flags) }.to raise_error(Smplkit::NotFoundError)
    end
  end

  describe "schedule_start_retry" do
    it "sets the backoff timer and doubles the delay" do
      before_delay = client.instance_variable_get(:@start_retry_delay)
      client.send(:schedule_start_retry, StandardError.new("boom"))
      expect(client.instance_variable_get(:@next_start_attempt_at)).to be > 0
      expect(client.instance_variable_get(:@start_retry_delay)).to eq(before_delay * 2)
    end

    it "caps the delay at MAX_START_RETRY_DELAY" do
      client.instance_variable_set(:@start_retry_delay, Smplkit::Flags::FlagsClient::MAX_START_RETRY_DELAY)
      client.send(:schedule_start_retry, StandardError.new("boom"))
      expect(client.instance_variable_get(:@start_retry_delay)).to eq(Smplkit::Flags::FlagsClient::MAX_START_RETRY_DELAY)
    end
  end

  describe "JsonLogicEvaluator" do
    let(:apply) { ->(logic, data) { Smplkit::Flags::JsonLogicEvaluator.apply(logic, data) } }

    it "if returns the matching consequent" do
      expect(apply.call({ "if" => [{ "==" => [1, 1] }, "yes", "no"] }, {})).to eq("yes")
    end

    it "if returns the else branch when no consequent matches" do
      expect(apply.call({ "if" => [{ "==" => [1, 2] }, "yes", "no"] }, {})).to eq("no")
    end

    it "if returns nil when no else is provided and nothing matches" do
      expect(apply.call({ "if" => [{ "==" => [1, 2] }, "yes"] }, {})).to be_nil
    end

    it "<= and > delegate to compare correctly" do
      expect(apply.call({ "<=" => [1, 2] }, {})).to be(true)
      expect(apply.call({ ">" => [3, 2] }, {})).to be(true)
    end

    it "!= returns true when values differ" do
      expect(apply.call({ "!=" => [1, 2] }, {})).to be(true)
    end

    it "missing returns the names of missing keys" do
      expect(apply.call({ "missing" => %w[a b] }, { "a" => 1 })).to eq(["b"])
    end

    it "none returns true when no element of the array matches" do
      logic = { "none" => [{ "var" => "list" }, { ">" => [{ "var" => "" }, 10] }] }
      expect(apply.call(logic, { "list" => [1, 2, 3] })).to be(true)
    end

    it "var resolves array indices when given numeric strings" do
      expect(apply.call({ "var" => "list.0" }, { "list" => %w[a b] })).to eq("a")
    end

    it "var falls back to default when path can't be resolved" do
      expect(apply.call({ "var" => %w[missing fallback] }, {})).to eq("fallback")
    end

    it "in returns false when the haystack is nil" do
      expect(apply.call({ "in" => ["a", nil] }, {})).to be(false)
    end

    it "compare returns false when the comparison raises a TypeError" do
      expect(apply.call({ "<" => ["a", 1] }, {})).to be(false)
    end
  end

  describe "deep_sort" do
    it "deep-sorts arrays of hashes for stable hashing" do
      result = client.send(:deep_sort, { "b" => [3, 1, 2], "a" => 1 })
      expect(result.keys).to eq(%w[a b])
      expect(result["b"]).to eq([3, 1, 2])
    end
  end
end

RSpec.describe Smplkit::Context do
  it "_save invokes the bound client and applies the returned attrs" do
    client = double("ContextsNamespace")
    refreshed = described_class.new("user", "u-1", plan: "enterprise", name: "Renamed",
                                                   created_at: "now", updated_at: "now")
    allow(client).to receive(:_save_context).and_return(refreshed)
    ctx = described_class.new("user", "u-1")._bind_client(client)
    ctx.save
    expect(ctx.name).to eq("Renamed")
  end

  it "_apply mirrors all metadata from another instance" do
    a = described_class.new("user", "a")
    b = described_class.new("user", "b", plan: "enterprise", name: "B", created_at: "now",
                                         updated_at: "now")
    a._apply(b)
    expect(a.key).to eq("b")
    expect(a.attributes).to eq("plan" => "enterprise")
    expect(a.name).to eq("B")
  end

  it "delete dispatches to the bound client" do
    client = double("ContextsNamespace")
    allow(client).to receive(:delete)
    ctx = described_class.new("user", "u-1")._bind_client(client)
    ctx.delete
    expect(client).to have_received(:delete).with("user:u-1")
  end

  it "_client exposes the bound client" do
    client = double("ContextsNamespace")
    ctx = described_class.new("user", "u-1")._bind_client(client)
    expect(ctx._client).to equal(client)
  end

  it "attributes= replaces and stringifies keys" do
    ctx = described_class.new("user", "u-1", plan: "free")
    ctx.attributes = { plan: "enterprise", region: :us }
    expect(ctx.attributes).to eq("plan" => "enterprise", "region" => :us)
  end

  it "attributes= tolerates a nil assignment" do
    ctx = described_class.new("user", "u-1")
    ctx.attributes = nil
    expect(ctx.attributes).to eq({})
  end

  it "hashes/equals correctly across same-type same-key instances" do
    a = described_class.new("user", "u-1", plan: "enterprise")
    b = described_class.new("user", "u-1", plan: "enterprise")
    expect(a.hash).to eq(b.hash)
    expect(a.eql?(b)).to be(true)
  end

  it "inspect prints the canonical fields" do
    ctx = described_class.new("user", "u-1", plan: "enterprise")
    expect(ctx.inspect).to include("type=\"user\"", "key=\"u-1\"")
  end
end

RSpec.describe Smplkit::FlagDeclaration do
  it "compares structurally" do
    a = described_class.new(id: "x", type: "BOOLEAN", default: false)
    b = described_class.new(id: "x", type: "BOOLEAN", default: false)
    c = described_class.new(id: "y", type: "BOOLEAN", default: false)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
  end
end

# ---------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------

RSpec.describe Smplkit::Config::ConfigChangeEvent do
  it "compares structurally" do
    a = described_class.new(key: "k", source: "ws")
    b = described_class.new(key: "k", source: "ws")
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a.deleted?).to be(false)
  end
end

RSpec.describe Smplkit::Config::Config do
  let(:client) { double("ConfigNamespace") }

  it "save dispatches to _create_config when fresh" do
    fresh = described_class.new(client, key: "showcase", name: "Showcase")
    refreshed = described_class.new(client, key: "showcase", name: "Showcase Renamed", created_at: "now")
    allow(client).to receive(:_create_config).and_return(refreshed)
    fresh.save
    expect(fresh.name).to eq("Showcase Renamed")
  end

  it "save dispatches to _update_config when previously persisted" do
    persisted = described_class.new(client, key: "showcase", name: "Showcase", created_at: "now")
    allow(client).to receive(:_update_config).and_return(persisted)
    persisted.save
    expect(client).to have_received(:_update_config)
  end

  it "delete dispatches to the namespace" do
    cfg = described_class.new(client, key: "showcase", name: "X")
    allow(client).to receive(:delete)
    cfg.delete
    expect(client).to have_received(:delete).with("showcase")
  end

  it "raises on delete without a client" do
    expect { described_class.new(key: "x").delete }.to raise_error(RuntimeError, /without a client/)
  end

  it "set_string upgrades an existing item rather than appending" do
    cfg = described_class.new(client, key: "x")
    cfg.set_string("api.host", "x.example.com")
    cfg.set_string("api.host", "y.example.com", description: "renamed")
    expect(cfg.items.length).to eq(1)
    expect(cfg.items.first.value).to eq("y.example.com")
    expect(cfg.items.first.description).to eq("renamed")
  end

  it "set_boolean / set_json route through set_typed" do
    cfg = described_class.new(client, key: "x")
    cfg.set_boolean("feature", true)
    cfg.set_json("payload", { "a" => 1 })
    expect(cfg.items.map(&:type)).to include(Smplkit::Config::ItemType::BOOLEAN, Smplkit::Config::ItemType::JSON)
  end

  it "remove_item drops a per-environment override" do
    cfg = described_class.new(client, key: "x")
    cfg.set_string("api.host", "stg", environment: "staging")
    cfg.remove_item("api.host", environment: "staging")
    expect(cfg.environments["staging"].values).to eq({})
  end

  it "remove_item is a no-op when the environment doesn't exist" do
    cfg = described_class.new(client, key: "x")
    expect { cfg.remove_item("api.host", environment: "missing") }.not_to raise_error
  end
end

RSpec.describe Smplkit::Config::ConfigItem do
  it "to_h emits compact attribute keys" do
    item = described_class.new(name: "x", value: 1, type: "NUMBER")
    expect(item.to_h).to eq("name" => "x", "value" => 1, "type" => "NUMBER")
  end

  it "compares structurally" do
    a = described_class.new(name: "x", value: 1, type: "NUMBER")
    b = described_class.new(name: "x", value: 1, type: "NUMBER")
    c = described_class.new(name: "x", value: 2, type: "NUMBER")
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
  end
end

RSpec.describe Smplkit::Config::ConfigEnvironment do
  it "treats already-typed Hash values as wrapped overrides" do
    env = described_class.new(values: { "k" => { "value" => 1, "type" => "NUMBER" } })
    expect(env.values).to eq("k" => 1)
  end

  it "wraps raw values into the typed shape" do
    env = described_class.new(values: { "k" => "raw" })
    expect(env.values_raw["k"]).to eq("value" => "raw")
  end
end

RSpec.describe Smplkit::Config::LiveConfigProxy do
  subject(:proxy) { described_class.new(resolver, "showcase") }

  let(:resolver) { double("ConfigClient") }

  before { allow(resolver).to receive(:_resolve_now).and_return("api" => { "host" => "x.example.com" }) }

  it "[] reads values via the snapshot" do
    expect(proxy["api.host"]).to eq("x.example.com")
  end

  it "to_h returns the snapshot" do
    expect(proxy.to_h).to eq("api" => { "host" => "x.example.com" })
  end

  it "refresh re-resolves" do
    expect(proxy.refresh).to be_a(described_class)
  end

  it "get with a nil item_key returns the whole snapshot" do
    expect(proxy.get(nil)).to eq("api" => { "host" => "x.example.com" })
  end

  it "get returns the default when a path step is nil" do
    allow(resolver).to receive(:_resolve_now).and_return("api" => nil)
    proxy = described_class.new(resolver, "x")
    expect(proxy.get("api.host", "fallback")).to eq("fallback")
  end
end

RSpec.describe Smplkit::Config::ConfigClient do
  subject(:client) { described_class.new(parent, manage: nil, metrics: nil) }

  let(:transport) { double("ConfigTransport") }
  let(:ws) do
    Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k")
  end
  let(:parent) do
    double(_environment: "staging", _service: "svc", _ensure_ws: ws,
           _config_transport: transport)
  end

  before { allow(transport).to receive(:fetch_chain).and_return([]) }

  it "start subscribes to config_changed and config_deleted on the WS" do
    client.start
    client.start # idempotent
    expect(client.instance_variable_get(:@connected)).to be(true)
  end

  it "get returns a typed model when one is provided" do
    items = { "api.host" => { "value" => "x", "type" => "STRING" } }
    allow(transport).to receive(:fetch_chain).and_return([
                                                           { "id" => "svc", "items" => items, "environments" => {} }
                                                         ])
    klass = Class.new do
      def initialize(snapshot); @snapshot = snapshot; end
      attr_reader :snapshot
    end
    cfg = client.get("svc", klass)
    expect(cfg).to be_a(klass)
    expect(cfg.snapshot).to eq("api.host" => "x")
  end

  it "get without a model returns the resolved snapshot" do
    items = { "api.host" => { "value" => "x", "type" => "STRING" } }
    allow(transport).to receive(:fetch_chain).and_return([
                                                           { "id" => "svc", "items" => items, "environments" => {} }
                                                         ])
    expect(client.get("svc")).to eq("api.host" => "x")
  end

  it "get_json returns the value as-is" do
    items = { "payload" => { "value" => { "a" => 1 }, "type" => "JSON" } }
    allow(transport).to receive(:fetch_chain).and_return([
                                                           { "id" => "svc", "items" => items, "environments" => {} }
                                                         ])
    expect(client.get_json("payload", config: "svc")).to eq("a" => 1)
  end

  it "live returns a LiveConfigProxy" do
    proxy = client.live("svc")
    expect(proxy).to be_a(Smplkit::Config::LiveConfigProxy)
  end

  it "merged_snapshot deep-merges across all cached configs" do
    chain1 = [{ "id" => "a", "items" => { "x" => 1 }, "environments" => {} }]
    chain2 = [{ "id" => "b", "items" => { "y" => 2 }, "environments" => {} }]
    allow(transport).to receive(:fetch_chain).with("a").and_return(chain1)
    allow(transport).to receive(:fetch_chain).with("b").and_return(chain2)
    client.send(:resolve, "a")
    client.send(:resolve, "b")
    snapshot = client.send(:merged_snapshot)
    expect(snapshot).to eq("x" => 1, "y" => 2)
  end

  it "on_change registers global and key-scoped listeners" do
    seen_global = []
    seen_keyed = []
    client.on_change { |e| seen_global << e.key }
    client.on_change("svc") { |e| seen_keyed << e.key }
    client.send(:fire_change_listeners, "svc", "manual")
    expect(seen_global).to eq(["svc"])
    expect(seen_keyed).to eq(["svc"])
  end

  it "on_change requires a block" do
    expect { client.on_change }.to raise_error(ArgumentError, /requires a block/)
  end

  it "fire_change_listeners swallows listener exceptions" do
    client.on_change { raise "boom" }
    expect { client.send(:fire_change_listeners, "svc", "manual") }.not_to raise_error
  end

  it "refresh clears caches and fires listeners on every previously-cached key" do
    allow(transport).to receive(:fetch_chain).with("svc").and_return([
                                                                       { "id" => "svc", "items" => { "x" => 1 },
                                                                         "environments" => {} }
                                                                     ])
    client.send(:resolve, "svc")
    # On_change-only registration without prior resolution would also fire,
    # but we want to verify the cached-key path explicitly. Register the
    # listener AFTER resolving so we know the snapshot is cached.
    seen = []
    client.on_change("svc") { |e| seen << e.key }
    client.refresh
    expect(seen).to include("svc")
  end

  it "handle_config_changed clears the snapshot and fires listeners" do
    allow(transport).to receive(:fetch_chain).with("svc").and_return([
                                                                       { "id" => "svc", "items" => { "x" => 1 },
                                                                         "environments" => {} }
                                                                     ])
    client.send(:resolve, "svc")
    seen = []
    client.on_change("svc") { |e| seen << e.deleted? }
    client.send(:handle_config_changed, { "key" => "svc" })
    expect(seen).to eq([false])
  end

  it "handle_config_changed ignores messages with no key" do
    expect { client.send(:handle_config_changed, {}) }.not_to raise_error
  end

  it "handle_config_deleted marks the event deleted=true" do
    seen = []
    client.on_change("svc") { |e| seen << e.deleted? }
    client.send(:handle_config_deleted, { "id" => "svc" })
    expect(seen).to eq([true])
  end

  it "handle_config_deleted ignores messages with no key" do
    expect { client.send(:handle_config_deleted, {}) }.not_to raise_error
  end

  it "fetch_chain wraps non-Smplkit errors as ConnectionError" do
    allow(transport).to receive(:fetch_chain).and_raise("pipe broken")
    expect { client.send(:resolve, "svc") }.to raise_error(Smplkit::ConnectionError)
  end

  it "fetch_chain passes Smplkit errors through unchanged" do
    allow(transport).to receive(:fetch_chain).and_raise(Smplkit::NotFoundError, "x")
    expect { client.send(:resolve, "svc") }.to raise_error(Smplkit::NotFoundError)
  end

  it "_close is a no-op for symmetry with the other clients" do
    expect { client._close }.not_to raise_error
  end
end
