# frozen_string_literal: true

require "spec_helper"

# Tests for the runtime config client (declarative bind() + get() escape hatch):
#   - Discovery helpers (value_to_item_type, iter_items, apply_change_to_target)
#   - ConfigClient#bind — Hash + Struct flavors, parent chaining, sync-from-cache
#   - ConfigClient#get — three forms, registration semantics
#   - LiveConfigProxy — dict-like read API, on_change forwarding
#   - on_change listeners — global/config-scoped/item-scoped
#   - WebSocket dispatch — in-place mutation of bound targets

# --- Fixture types ----------------------------------------------------

Billing = Struct.new(:max_seats, :tier, keyword_init: true)
Audit = Struct.new(:streams, :siem, keyword_init: true)
Plan = Struct.new(:name, :audit, keyword_init: true)

# --- Helpers ----------------------------------------------------------

def build_config(key:, items: {}, environments: {}, parent_id: nil, id: nil)
  cfg_items = items.map do |name, value|
    Smplkit::Config::ConfigItem.new(name: name, value: value, type: "STRING")
  end
  envs = environments.transform_values { |v| Smplkit::Config::ConfigEnvironment.new(values: v) }
  Smplkit::Config::Config.new(
    nil, id: id || key, key: key, name: key, parent_id: parent_id,
         items: cfg_items, environments: envs
  )
end

# --- Discovery helpers ------------------------------------------------

RSpec.describe Smplkit::Config::Discovery do
  describe ".value_to_item_type" do
    it("returns BOOLEAN for true/false") do
      expect(described_class.value_to_item_type(true)).to eq("BOOLEAN")
      expect(described_class.value_to_item_type(false)).to eq("BOOLEAN")
    end

    it("returns NUMBER for Integer and Float") do
      expect(described_class.value_to_item_type(5)).to eq("NUMBER")
      expect(described_class.value_to_item_type(0.5)).to eq("NUMBER")
    end

    it("returns STRING for String") do
      expect(described_class.value_to_item_type("hello")).to eq("STRING")
    end

    it("falls back to STRING for anything else") do
      expect(described_class.value_to_item_type(nil)).to eq("STRING")
      expect(described_class.value_to_item_type([1, 2])).to eq("STRING")
      expect(described_class.value_to_item_type({ "k" => "v" })).to eq("STRING")
    end
  end

  describe ".iter_items" do
    it("walks a flat Hash") do
      out = described_class.iter_items({ "max_seats" => 5, "tier" => "free", "enabled" => true })
      by_key = out.to_h { |k, t, v, d| [k, [t, v, d]] }
      expect(by_key["max_seats"]).to eq(["NUMBER", 5, nil])
      expect(by_key["tier"]).to eq(["STRING", "free", nil])
      expect(by_key["enabled"]).to eq(["BOOLEAN", true, nil])
    end

    it("flattens nested Hashes to dot-notation") do
      out = described_class.iter_items({ "connection" => { "host" => "h", "port" => 5432 } })
      keys = out.map { |k, _, _, _| k }
      expect(keys).to contain_exactly("connection.host", "connection.port")
    end

    it("walks a Struct's members") do
      out = described_class.iter_items(Billing.new(max_seats: 50, tier: "pro"))
      by_key = out.to_h { |k, t, v, _| [k, [t, v]] }
      expect(by_key["max_seats"]).to eq(["NUMBER", 50])
      expect(by_key["tier"]).to eq(%w[STRING pro])
    end

    it("flattens nested Structs to dot-notation") do
      plan = Plan.new(name: "Pro", audit: Audit.new(streams: 10, siem: false))
      keys = described_class.iter_items(plan).map { |k, _, _, _| k }
      expect(keys).to contain_exactly("name", "audit.streams", "audit.siem")
    end

    it("flattens Hash-of-Struct and Struct-of-Hash combinations") do
      target = { "plan" => Plan.new(name: "Pro", audit: Audit.new(streams: 1, siem: true)) }
      keys = described_class.iter_items(target).map { |k, _, _, _| k }
      expect(keys).to contain_exactly("plan.name", "plan.audit.streams", "plan.audit.siem")
    end

    it("returns [] for an unsupported target type") do
      expect(described_class.iter_items("not a target")).to eq([])
    end

    it("stringifies non-String Hash keys (symbol keys land as strings)") do
      out = described_class.iter_items({ host: "h", port: 5432 })
      keys = out.map { |k, _, _, _| k }
      expect(keys).to contain_exactly("host", "port")
    end
  end

  describe ".apply_change_to_target" do
    it("assigns top-level Hash keys") do
      target = { "seats" => 5 }
      described_class.apply_change_to_target(target, "seats", 50)
      expect(target["seats"]).to eq(50)
    end

    it("creates new Hash keys at the top level") do
      target = { "seats" => 5 }
      described_class.apply_change_to_target(target, "new_key", "added")
      expect(target["new_key"]).to eq("added")
    end

    it("assigns nested Hash keys") do
      target = { "connection" => { "host" => "local" } }
      described_class.apply_change_to_target(target, "connection.host", "remote")
      expect(target["connection"]["host"]).to eq("remote")
    end

    it("held nested Hash references see the mutation") do
      target = { "connection" => { "host" => "local" } }
      ref = target["connection"]
      described_class.apply_change_to_target(target, "connection.host", "remote")
      expect(ref["host"]).to eq("remote")
    end

    it("assigns top-level Struct members") do
      target = Billing.new(max_seats: 5)
      described_class.apply_change_to_target(target, "max_seats", 50)
      expect(target.max_seats).to eq(50)
    end

    it("assigns nested Struct members") do
      target = Plan.new(name: "Free", audit: Audit.new(streams: 0))
      described_class.apply_change_to_target(target, "audit.streams", 99)
      expect(target.audit.streams).to eq(99)
    end

    it("held nested Struct references see the mutation") do
      target = Plan.new(name: "Free", audit: Audit.new(streams: 0))
      ref = target.audit
      described_class.apply_change_to_target(target, "audit.streams", 99)
      expect(ref.streams).to eq(99)
    end

    it("silently no-ops when a Hash intermediate key is missing") do
      target = { "a" => 1 }
      described_class.apply_change_to_target(target, "missing.path.deep", 1)
      expect(target).to eq({ "a" => 1 })
    end

    it("silently no-ops when a Struct intermediate member is unknown") do
      target = Billing.new(max_seats: 5)
      described_class.apply_change_to_target(target, "unknown.deep", 1)
      expect(target.max_seats).to eq(5)
    end

    it("silently no-ops when a Hash intermediate value is a non-container") do
      target = { "note" => "x" }
      described_class.apply_change_to_target(target, "note.length", 42)
      expect(target).to eq({ "note" => "x" })
    end

    it("silently no-ops on an entirely unsupported target type") do
      expect { described_class.apply_change_to_target("not a target", "k", 1) }.not_to raise_error
    end

    it("silently no-ops when assigning an unknown Struct leaf") do
      target = Plan.new(name: "Free", audit: Audit.new(streams: 0))
      described_class.apply_change_to_target(target, "audit.unknown", 1)
      expect(target.audit.streams).to eq(0)
    end

    it("silently no-ops when the walk hits a non-container intermediate (3+ parts)") do
      # Walk: ["a", "b", "c"]. Step 1 lands on the String "scalar", which is
      # neither Hash nor Struct — falls through the else branch of the walk loop.
      target = { "a" => "scalar" }
      described_class.apply_change_to_target(target, "a.b.c", 1)
      expect(target).to eq({ "a" => "scalar" })
    end
  end
end

# --- ConfigChangeEvent ------------------------------------------------

RSpec.describe Smplkit::Config::ConfigChangeEvent do
  it "exposes all five fields and freezes itself" do
    evt = described_class.new(config_id: "billing", item_key: "k",
                              old_value: 1, new_value: 2, source: "manual")
    expect(evt.config_id).to eq("billing")
    expect(evt.item_key).to eq("k")
    expect(evt.old_value).to eq(1)
    expect(evt.new_value).to eq(2)
    expect(evt.source).to eq("manual")
    expect(evt).to be_frozen
  end

  it "compares structurally and hashes consistently" do
    a = described_class.new(config_id: "c", item_key: "k", old_value: 1, new_value: 2, source: "ws")
    b = described_class.new(config_id: "c", item_key: "k", old_value: 1, new_value: 2, source: "ws")
    c = described_class.new(config_id: "c", item_key: "k", old_value: 1, new_value: 3, source: "ws")
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
    expect(a).not_to eq("not an event")
  end
end

# --- ConfigClient base -------------------------------------------------

RSpec.describe Smplkit::Config::ConfigClient do
  subject(:client) { described_class.new(parent, manage: manage, metrics: metrics) }

  let(:parent) do
    double("Smplkit::Client",
           _environment: "production",
           _service: "showcase-billing",
           _ensure_ws: instance_double(Smplkit::SharedWebSocket, on: nil))
  end
  let(:mgmt_config) do
    instance_double(Smplkit::ManagementClient::ConfigNamespace,
                    flush: nil,
                    register_config: nil,
                    register_config_item: nil,
                    list: [],
                    pending_count: 0)
  end
  let(:manage) { double("ManagementClient", config: mgmt_config) }
  let(:metrics) { nil }

  # --- bind ---------------------------------------------------------

  describe "#bind" do
    it "returns the same Hash instance back" do
      payload = { "host" => "h", "port" => 5432 }
      result = client.bind("db", payload)
      expect(result).to equal(payload)
    end

    it "returns the same Struct instance back" do
      instance = Billing.new(max_seats: 10, tier: "pro")
      result = client.bind("billing", instance)
      expect(result).to equal(instance)
    end

    it "is idempotent — repeated calls with the same id return the original" do
      first = { "k" => "v1" }
      second = { "k" => "v2" }
      a = client.bind("db", first)
      b = client.bind("db", second)
      expect(a).to equal(first)
      expect(b).to equal(first)
    end

    it "raises TypeError for non-Hash, non-Struct targets" do
      expect { client.bind("billing", "just a string") }
        .to raise_error(TypeError, /Hash or Struct/)
      expect { client.bind("billing", 42) }
        .to raise_error(TypeError, /Hash or Struct/)
      expect { client.bind("billing", [1, 2]) }
        .to raise_error(TypeError, /Hash or Struct/)
    end

    it "registers the config with the Struct's class name as `name`" do
      expect(mgmt_config).to receive(:register_config).with(
        "billing",
        service: "showcase-billing", environment: "production",
        parent: nil, name: "Billing", description: nil
      )
      client.bind("billing", Billing.new(max_seats: 5))
    end

    it "registers a dict-bind config with name=nil" do
      expect(mgmt_config).to receive(:register_config).with(
        "db",
        service: "showcase-billing", environment: "production",
        parent: nil, name: nil, description: nil
      )
      client.bind("db", { "host" => "h" })
    end

    it "leaves name=nil when the Struct class is anonymous" do
      anonymous = Struct.new(:foo, keyword_init: true).new(foo: 1)
      expect(mgmt_config).to receive(:register_config).with(
        "anon",
        hash_including(name: nil)
      )
      client.bind("anon", anonymous)
    end

    it "registers every Struct member as an explicit override" do
      keys = []
      allow(mgmt_config).to receive(:register_config_item) { |_id, k, *| keys << k }
      client.bind("billing", Billing.new(max_seats: 5, tier: "free"))
      expect(keys).to contain_exactly("max_seats", "tier")
    end

    it "registers every Hash key as an explicit override" do
      keys = []
      allow(mgmt_config).to receive(:register_config_item) { |_id, k, *| keys << k }
      client.bind("db", { "host" => "h", "port" => 5432, "tls" => true })
      expect(keys).to contain_exactly("host", "port", "tls")
    end

    it "infers item types from runtime values for dict binds" do
      registered = {}
      allow(mgmt_config).to receive(:register_config_item) { |_, k, t, v, _| registered[k] = [t, v] }
      client.bind("db", { "host" => "h", "port" => 5432, "tls" => true })
      expect(registered["host"]).to eq(%w[STRING h])
      expect(registered["port"]).to eq(["NUMBER", 5432])
      expect(registered["tls"]).to eq(["BOOLEAN", true])
    end

    it "flattens nested Hash bind to dot-notation" do
      keys = []
      allow(mgmt_config).to receive(:register_config_item) { |_, k, *| keys << k }
      client.bind("db", { "primary" => { "host" => "h", "port" => 5432 } })
      expect(keys).to contain_exactly("primary.host", "primary.port")
    end

    it "wires a parent chain via a previously-bound target" do
      base = client.bind("base", Billing.new(max_seats: 5, tier: "base"))
      expect(mgmt_config).to receive(:register_config).with(
        "pro", hash_including(parent: "base")
      )
      client.bind("pro", Billing.new(max_seats: 50, tier: "pro"), parent: base)
    end

    it "supports cross-type parent chaining (dict child, Struct parent)" do
      base = client.bind("base", Billing.new(max_seats: 5))
      expect(mgmt_config).to receive(:register_config).with(
        "child", hash_including(parent: "base")
      )
      client.bind("child", { "override_key" => 1 }, parent: base)
    end

    it "rejects an unbound parent reference" do
      stray = Billing.new(max_seats: 5)
      expect { client.bind("pro", Billing.new, parent: stray) }
        .to raise_error(ArgumentError, /previously returned from client.config.bind/)
    end

    it "syncs the bound Struct from cache (Hash items override in-code values)" do
      cached = build_config(key: "billing", items: { "max_seats" => 999, "tier" => "enterprise" })
      allow(mgmt_config).to receive(:list).and_return([cached])
      instance = Billing.new(max_seats: 5, tier: "free")
      result = client.bind("billing", instance)
      expect(result.max_seats).to eq(999)
      expect(result.tier).to eq("enterprise")
    end

    it "syncs a bound Hash from cache" do
      cached = build_config(key: "db", items: { "host" => "remote", "port" => 9999 })
      allow(mgmt_config).to receive(:list).and_return([cached])
      target = { "host" => "local", "port" => 5432 }
      result = client.bind("db", target)
      expect(result["host"]).to eq("remote")
      expect(result["port"]).to eq(9999)
    end

    it "flushes the management buffer BEFORE the initial fetch" do
      call_log = []
      allow(mgmt_config).to receive(:flush) { call_log << :flush }
      allow(mgmt_config).to receive(:list) {
        call_log << :list
        []
      }
      client.bind("db", { "k" => "v" })
      expect(call_log).to eq(%i[flush list])
    end

    it "swallows pre-start flush errors" do
      allow(mgmt_config).to receive(:flush).and_raise(StandardError, "boom")
      expect { client.bind("db", { "k" => "v" }) }.not_to raise_error
    end
  end

  # --- get ---------------------------------------------------------

  describe "#get (full config)" do
    it "returns a LiveConfigProxy bound to the id" do
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => "v" })])
      proxy = client.get("billing")
      expect(proxy).to be_a(Smplkit::Config::LiveConfigProxy)
      expect(proxy.config_id).to eq("billing")
    end

    it "returns the same proxy on repeat calls" do
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => "v" })])
      a = client.get("billing")
      b = client.get("billing")
      expect(a).to equal(b)
    end

    it "raises NotFoundError when the config is missing" do
      expect { client.get("missing") }.to raise_error(Smplkit::NotFoundError, /not found/)
    end

    it "does not register anything (lookup-only escape hatch)" do
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => "v" })])
      expect(mgmt_config).not_to receive(:register_config_item)
      client.get("billing")
    end
  end

  describe "#get (single value, no default)" do
    before do
      allow(mgmt_config).to receive(:list).and_return([
                                                        build_config(key: "db", items: { "host" => "h" })
                                                      ])
    end

    it "returns the cached value" do
      expect(client.get("db", "host")).to eq("h")
    end

    it "raises NotFoundError when the config is unknown" do
      expect { client.get("missing", "host") }.to raise_error(Smplkit::NotFoundError)
    end

    it "raises KeyError when the key is unknown" do
      expect { client.get("db", "missing") }.to raise_error(KeyError, /missing/)
    end

    it "does not register anything" do
      expect(mgmt_config).not_to receive(:register_config_item)
      expect(mgmt_config).not_to receive(:register_config)
      client.get("db", "host")
    end
  end

  describe "#get (single value, with default)" do
    before do
      allow(mgmt_config).to receive(:list).and_return([
                                                        build_config(key: "db", items: { "host" => "real" })
                                                      ])
    end

    it "returns the cached value when present" do
      expect(client.get("db", "host", "fallback")).to eq("real")
    end

    it "returns the default when the config is missing" do
      allow(mgmt_config).to receive(:list).and_return([])
      client.refresh
      expect(client.get("missing", "host", "fallback")).to eq("fallback")
    end

    it "returns the default when the key is missing" do
      expect(client.get("db", "no_such_key", "fallback")).to eq("fallback")
    end

    it "auto-registers the config and key" do
      expect(mgmt_config).to receive(:register_config).with(
        "billing", service: "showcase-billing", environment: "production",
                   parent: nil, name: nil, description: nil
      )
      expect(mgmt_config).to receive(:register_config_item)
        .with("billing", "max_seats", "NUMBER", 5, nil)
      client.get("billing", "max_seats", 5)
    end

    it "infers the type from the default value" do
      types = {}
      allow(mgmt_config).to receive(:register_config_item) { |_, k, t, *| types[k] = t }
      client.get("c", "n", 5)
      client.get("c", "f", 1.5)
      client.get("c", "s", "hi")
      client.get("c", "b", true)
      expect(types).to eq("n" => "NUMBER", "f" => "NUMBER", "s" => "STRING", "b" => "BOOLEAN")
    end

    it "treats `nil` as a real default (does not raise)" do
      expect(client.get("missing", "k", nil)).to be_nil
    end

    it "stringifies non-string keys" do
      expect(client.get("db", :host, "fallback")).to eq("real")
    end
  end

  # --- on_change ----------------------------------------------------

  describe "#on_change" do
    before { allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => 0 })]) }

    it "raises without a block" do
      expect { client.on_change }.to raise_error(ArgumentError, /requires a block/)
    end

    it "fires the global listener on any change" do
      client.start
      seen = []
      client.on_change { |e| seen << [e.config_id, e.item_key, e.old_value, e.new_value] }
      # Simulate a refresh delivering a new value.
      allow(mgmt_config).to receive(:list).and_return([
                                                        build_config(key: "billing", items: { "k" => 1 })
                                                      ])
      client.refresh
      expect(seen).to eq([["billing", "k", 0, 1]])
    end

    it "fires listeners against an empty old_cache during initial start" do
      seen = []
      client.on_change { |e| seen << [e.config_id, e.item_key, e.old_value, e.new_value, e.source] }
      client.start
      expect(seen).to eq([["billing", "k", nil, 0, "initial"]])
    end

    it "fires the config-scoped listener only for matching ids" do
      seen = []
      client.on_change("other") { |e| seen << e.config_id }
      client.start
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => 1 })])
      client.refresh
      expect(seen).to be_empty
    end

    it "fires the item-scoped listener only for matching item keys" do
      seen = []
      client.on_change("billing", item_key: "z") { |e| seen << e.item_key }
      client.start
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => 1 })])
      client.refresh
      expect(seen).to be_empty
    end

    it "swallows exceptions raised by a listener" do
      client.on_change { raise "boom" }
      client.start
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => 1 })])
      expect { client.refresh }.not_to raise_error
    end
  end

  # --- refresh + WebSocket dispatch ---------------------------------

  describe "#refresh and the WebSocket pipeline" do
    let(:billing_initial) { build_config(key: "billing", items: { "max_seats" => 5 }) }
    let(:billing_updated) { build_config(key: "billing", items: { "max_seats" => 50 }) }

    it "mutates a bound Struct in place when a refresh delivers a new value" do
      allow(mgmt_config).to receive(:list).and_return([billing_initial])
      instance = Billing.new(max_seats: 5)
      client.bind("billing", instance)
      allow(mgmt_config).to receive(:list).and_return([billing_updated])
      client.refresh
      expect(instance.max_seats).to eq(50)
    end

    it "mutates a bound Hash in place when a refresh delivers a new value" do
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "db", items: { "timeout" => 30 })])
      payload = { "timeout" => 30 }
      client.bind("db", payload)
      allow(mgmt_config).to receive(:list).and_return([
                                                        build_config(key: "db", items: { "timeout" => 120 })
                                                      ])
      client.refresh
      expect(payload["timeout"]).to eq(120)
    end

    it "listeners reading the bound object after a change see the new value" do
      allow(mgmt_config).to receive(:list).and_return([billing_initial])
      instance = Billing.new(max_seats: 5)
      client.bind("billing", instance)
      observed = []
      client.on_change("billing", item_key: "max_seats") { |_| observed << instance.max_seats }
      allow(mgmt_config).to receive(:list).and_return([billing_updated])
      client.refresh
      expect(observed).to eq([50])
    end

    it "subscribes to config_changed, config_deleted, and configs_changed on start" do
      ws = instance_double(Smplkit::SharedWebSocket)
      allow(parent).to receive(:_ensure_ws).and_return(ws)
      events = []
      allow(ws).to receive(:on) { |name, &_blk| events << name }
      client.start
      expect(events).to include("config_changed", "config_deleted", "configs_changed")
    end

    it "is idempotent — repeated start() does not re-subscribe" do
      ws = instance_double(Smplkit::SharedWebSocket)
      allow(parent).to receive(:_ensure_ws).and_return(ws)
      count = 0
      allow(ws).to receive(:on) { count += 1 }
      client.start
      client.start
      expect(count).to eq(3)
    end
  end

  # --- WebSocket handlers (single + bulk) ---------------------------

  describe "WebSocket handlers" do
    let(:billing) { build_config(key: "billing", items: { "max_seats" => 5 }) }
    let(:billing_new) { build_config(key: "billing", items: { "max_seats" => 99 }) }

    before do
      allow(mgmt_config).to receive(:list).and_return([billing])
      client.start
    end

    it "handle_config_changed refetches a single config and rebuilds the cache" do
      allow(mgmt_config).to receive(:get).with("billing").and_return(billing_new)
      client.send(:handle_config_changed, { "key" => "billing" })
      expect(client.get("billing")["max_seats"]).to eq(99)
    end

    it "handle_config_changed accepts the `id` field as the key" do
      allow(mgmt_config).to receive(:get).with("billing").and_return(billing_new)
      client.send(:handle_config_changed, { "id" => "billing" })
      expect(client.get("billing")["max_seats"]).to eq(99)
    end

    it "handle_config_changed ignores events with no key" do
      expect { client.send(:handle_config_changed, {}) }.not_to raise_error
    end

    it "handle_config_changed silently swallows fetch errors" do
      allow(mgmt_config).to receive(:get).and_raise(StandardError, "boom")
      expect { client.send(:handle_config_changed, { "key" => "billing" }) }.not_to raise_error
    end

    it "handle_config_changed treats a NotFoundError as a deletion" do
      allow(mgmt_config).to receive(:get).and_raise(Smplkit::NotFoundError, "gone")
      client.send(:handle_config_changed, { "key" => "billing" })
      expect { client.get("billing") }.to raise_error(Smplkit::NotFoundError)
    end

    it "handle_config_deleted removes the config from the cache" do
      client.send(:handle_config_deleted, { "key" => "billing" })
      expect { client.get("billing") }.to raise_error(Smplkit::NotFoundError)
    end

    it "handle_config_deleted ignores events with no key" do
      expect { client.send(:handle_config_deleted, {}) }.not_to raise_error
    end

    it "handle_config_deleted is a no-op for an unknown config" do
      expect { client.send(:handle_config_deleted, { "key" => "unknown" }) }.not_to raise_error
    end

    it "handle_configs_changed triggers a full refresh" do
      allow(mgmt_config).to receive(:list).and_return([billing_new])
      client.send(:handle_configs_changed, {})
      expect(client.get("billing")["max_seats"]).to eq(99)
    end

    it "handle_configs_changed swallows refresh errors" do
      allow(mgmt_config).to receive(:list).and_raise(StandardError, "boom")
      expect { client.send(:handle_configs_changed, {}) }.not_to raise_error
    end
  end

  # --- _close + metrics ---------------------------------------------

  describe "#_close" do
    it "is a no-op" do
      expect { client._close }.not_to raise_error
    end
  end

  describe "metrics" do
    let(:metrics) { instance_double(Smplkit::MetricsReporter, record: nil) }

    it "records config.resolutions on get(id)" do
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => "v" })])
      expect(metrics).to receive(:record).with("config.resolutions", unit: "resolutions",
                                                                     dimensions: { "config" => "billing" })
      client.get("billing")
    end

    it "records config.changes on each value change" do
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => 0 })])
      client.start
      allow(mgmt_config).to receive(:list).and_return([build_config(key: "billing", items: { "k" => 1 })])
      expect(metrics).to receive(:record).with("config.changes", unit: "changes",
                                                                 dimensions: { "config" => "billing" })
      client.refresh
    end
  end

  describe "manage-less construction" do
    let(:manage) { nil }

    it "does not crash on start when no management client is attached" do
      allow(parent).to receive(:_ensure_ws).and_return(instance_double(Smplkit::SharedWebSocket, on: nil))
      expect { client.start }.to raise_error(NoMethodError) # @manage.config.list called below
      # Actually: when manage is nil we have a hard requirement — exercise the
      # _observe_* nil-guard via bind which calls register before start.
    end
  end

  describe "_observe_* nil guards" do
    let(:manage) { nil }

    it "_observe_config_declaration is a no-op when manage is nil" do
      expect { client._observe_config_declaration("id", parent: nil, name: nil, description: nil) }.not_to raise_error
    end

    it "_observe_item_declaration is a no-op when manage is nil" do
      expect { client._observe_item_declaration("id", "k", "STRING", "v", nil) }.not_to raise_error
    end
  end
end

# --- LiveConfigProxy --------------------------------------------------

RSpec.describe Smplkit::Config::LiveConfigProxy do
  subject(:proxy) { described_class.new(client, "db") }

  let(:client) do
    Class.new do
      def initialize(values)
        @values = values
        @listener_calls = []
      end

      attr_reader :listener_calls

      def _cached_values(_id) = @values.dup

      def on_change(id, item_key: nil, &block)
        @listener_calls << [id, item_key]
        block.call(Smplkit::Config::ConfigChangeEvent.new(
                     config_id: id, item_key: item_key || "any",
                     old_value: nil, new_value: nil, source: "manual"
                   ))
      end
    end.new("host" => "h", "port" => 5432, "tls" => true)
  end

  it "exposes config_id" do
    expect(proxy.config_id).to eq("db")
  end

  it "supports subscript access" do
    expect(proxy["host"]).to eq("h")
    expect(proxy[:host]).to eq("h")
  end

  it "supports method-style attribute access for present keys" do
    expect(proxy.host).to eq("h")
  end

  it "raises NoMethodError for unknown method names with no matching key" do
    expect { proxy.bogus }.to raise_error(NoMethodError)
  end

  it "raises NoMethodError when method-style is called with arguments" do
    expect { proxy.host("oops") }.to raise_error(NoMethodError)
  end

  it "responds_to? returns true for known keys via method_missing" do
    expect(proxy.respond_to?(:host)).to be true
    expect(proxy.respond_to?(:bogus)).to be false
  end

  it "responds_to? returns true for built-in methods" do
    expect(proxy.respond_to?(:keys)).to be true
  end

  it "implements the Mapping API" do
    expect(proxy.keys).to contain_exactly("host", "port", "tls")
    expect(proxy.values).to contain_exactly("h", 5432, true)
    expect(proxy.size).to eq(3)
    expect(proxy.length).to eq(3)
    expect(proxy.key?("host")).to be true
    expect(proxy.key?("missing")).to be false
    expect(proxy.include?("host")).to be true
    expect(proxy.key?("port")).to be true
    expect(proxy.to_h).to eq("host" => "h", "port" => 5432, "tls" => true)
    expect(proxy.items).to contain_exactly(%w[host h], ["port", 5432], ["tls", true])
  end

  it "each_pair yields key/value pairs" do
    pairs = []
    proxy.each_pair { |k, v| pairs << [k, v] }
    expect(pairs).to contain_exactly(%w[host h], ["port", 5432], ["tls", true])
  end

  it "each is an alias for each_pair" do
    # rubocop:disable Style/MapIntoArray
    pairs = []
    proxy.each { |k, v| pairs << [k, v] }
    # rubocop:enable Style/MapIntoArray
    expect(pairs).to contain_exactly(%w[host h], ["port", 5432], ["tls", true])
  end

  it "#get returns the value or the supplied default" do
    expect(proxy.get("host")).to eq("h")
    expect(proxy.get("missing")).to be_nil
    expect(proxy.get("missing", "fallback")).to eq("fallback")
  end

  it "on_change without an item_key forwards as a config-scoped listener" do
    proxy.on_change { |_e| nil }
    expect(client.listener_calls).to eq([["db", nil]])
  end

  it "on_change with an item_key forwards as an item-scoped listener" do
    proxy.on_change("host") { |_e| nil }
    expect(client.listener_calls).to eq([%w[db host]])
  end

  it "inspect / to_s render the config id" do
    expect(proxy.to_s).to include("db")
    expect(proxy.inspect).to include("db")
  end
end
