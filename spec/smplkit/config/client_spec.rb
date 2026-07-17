# frozen_string_literal: true

require "spec_helper"

# Tests for the fused +ConfigClient+ (one client, two surfaces):
#   - Discovery helpers (value_to_item_type, iter_items, apply_change_to_target)
#   - ConfigChangeEvent value semantics
#   - LiveConfigProxy — dict-like read API, on_change forwarding
#   - ConfigClient management surface — new / get / list / delete, Config#save,
#     discovery buffer (register_config / register_config_item / flush /
#     pending_count)
#   - ConfigClient live surface — lazy connect, subscribe, get_value, bind,
#     on_change, refresh, the WebSocket dispatch pipeline, and close
#
# The live surface makes real HTTP through the generated
# +SmplkitGeneratedClient::Config::ConfigsApi+, so the client is wired with a
# parent double plus an injected transport pointed at a WebMock host. The
# parent's shared WebSocket is constructed but never +start+ed — dispatch is
# driven directly via +SharedWebSocket#dispatch+, so no real socket opens.

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
    expect(a.eql?(b)).to be true
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
    expect(a).not_to eq("not an event")
  end
end

# --- Config.resolve_parent_id -----------------------------------------

RSpec.describe "Smplkit::Config.resolve_parent_id" do
  it "passes nil through" do
    expect(Smplkit::Config.resolve_parent_id(nil)).to be_nil
  end

  it "passes a String id through" do
    expect(Smplkit::Config.resolve_parent_id("billing")).to eq("billing")
  end

  it "reads the id off a saved Config" do
    parent = Smplkit::Config::Config.new(nil, key: "billing", id: "billing")
    expect(Smplkit::Config.resolve_parent_id(parent)).to eq("billing")
  end

  it "raises when the Config has no id" do
    parent = Smplkit::Config::Config.new(nil, key: "billing", id: nil)
    expect { Smplkit::Config.resolve_parent_id(parent) }
      .to raise_error(ArgumentError, /must be saved/)
  end

  it "raises when the Config id is empty" do
    parent = Smplkit::Config::Config.new(nil, key: "billing", id: "")
    expect { Smplkit::Config.resolve_parent_id(parent) }
      .to raise_error(ArgumentError, /must be saved/)
  end
end

# --- ConfigClient -----------------------------------------------------

RSpec.describe Smplkit::Config::ConfigClient do
  subject(:config) { described_class.new(parent: parent, transport: transport, metrics: metrics) }

  let(:base_url) { "https://config.smplkit.test" }
  let(:tcfg) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:transport) { Smplkit::Transport.build_api_client(SmplkitGeneratedClient::Config, "config", tcfg) }
  let(:ws) { Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k") }
  let(:parent) do
    double("Smplkit::Client",
           _environment: "staging", _service: "svc",
           _ensure_started: nil, _ensure_ws: ws)
  end
  let(:metrics) { nil }

  # Always release the (never-started) WebSocket / transport so no background
  # thread leaks between examples.
  after { config.close }

  # JSON:API config resource Hash for response bodies.
  def cfg_resource(id, items: {}, environments: {}, parent: nil, name: nil, description: nil)
    {
      "id" => id, "type" => "config",
      "attributes" => {
        "name" => name || id, "description" => description, "parent" => parent,
        "items" => items.transform_values { |v| { "value" => v, "type" => "STRING" } },
        "environments" => environments,
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-01T00:00:00Z"
      }
    }
  end

  def list_body(*resources)
    { "data" => resources, "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }.to_json
  end

  def jsonapi_headers
    { "Content-Type" => "application/vnd.api+json" }
  end

  # Stub the paginated list endpoint with a single page of resources.
  def stub_list(*resources)
    stub_request(:get, "#{base_url}/api/v1/configs")
      .with(query: hash_including({}))
      .to_return(status: 200, body: list_body(*resources), headers: jsonapi_headers)
  end

  # Stub a single-config GET (200 with a resource, or a 404).
  def stub_get(id, resource, status: 200)
    body = status == 200 ? { "data" => resource }.to_json : %({"errors":[{"status":"404"}]})
    stub_request(:get, "#{base_url}/api/v1/configs/#{id}")
      .to_return(status: status, body: body, headers: jsonapi_headers)
  end

  # ----------------------------------------------------------------
  # Management surface: CRUD
  # ----------------------------------------------------------------

  describe "#new" do
    it "returns an unsaved Config with a defaulted display name" do
      cfg = config.new("billing_plan")
      expect(cfg).to be_a(Smplkit::Config::Config)
      expect(cfg.key).to eq("billing_plan")
      expect(cfg.name).to eq("Billing Plan")
      expect(cfg.parent_id).to be_nil
    end

    it "honours an explicit name, description, and string parent" do
      cfg = config.new("pro", name: "Pro Tier", description: "the pro plan", parent: "base")
      expect(cfg.name).to eq("Pro Tier")
      expect(cfg.description).to eq("the pro plan")
      expect(cfg.parent_id).to eq("base")
    end

    it "resolves a Config instance passed as parent to its id" do
      base = config.new("base")
      base.instance_variable_set(:@id, "base")
      child = config.new("child", parent: base)
      expect(child.parent_id).to eq("base")
    end
  end

  describe "#get" do
    it "fetches the editable Config by id" do
      stub_get("billing", cfg_resource("billing", items: { "max_seats" => 5 }, name: "Billing"))
      cfg = config.get("billing")
      expect(cfg).to be_a(Smplkit::Config::Config)
      expect(cfg.key).to eq("billing")
      expect(cfg.name).to eq("Billing")
      expect(cfg.items.map(&:name)).to contain_exactly("max_seats")
    end

    it "raises NotFoundError on a 404" do
      stub_get("missing", nil, status: 404)
      expect { config.get("missing") }.to raise_error(Smplkit::NotFoundError)
    end
  end

  describe "#list" do
    it "maps every returned resource to a Config" do
      stub_request(:get, "#{base_url}/api/v1/configs")
        .with(query: hash_including({}))
        .to_return(status: 200,
                   body: list_body(cfg_resource("a"), cfg_resource("b")),
                   headers: jsonapi_headers)
      configs = config.list
      expect(configs.map(&:key)).to contain_exactly("a", "b")
    end

    it "forwards page_number and page_size as query params" do
      stub = stub_request(:get, "#{base_url}/api/v1/configs")
             .with(query: { "page[number]" => "2", "page[size]" => "10" })
             .to_return(status: 200, body: list_body, headers: jsonapi_headers)
      config.list(page_number: 2, page_size: 10)
      expect(stub).to have_been_requested
    end

    it "returns an empty array when data is empty" do
      stub_request(:get, "#{base_url}/api/v1/configs")
        .with(query: hash_including({}))
        .to_return(status: 200, body: list_body, headers: jsonapi_headers)
      expect(config.list).to eq([])
    end
  end

  describe "#delete" do
    it "issues a DELETE and returns nil" do
      stub = stub_request(:delete, "#{base_url}/api/v1/configs/billing")
             .to_return(status: 204, body: "")
      expect(config.delete("billing")).to be_nil
      expect(stub).to have_been_requested
    end
  end

  describe "Config#save (via _create_config / _update_config)" do
    it "POSTs a brand-new config (no created_at)" do
      stub = stub_request(:post, "#{base_url}/api/v1/configs")
             .to_return(status: 201,
                        body: { "data" => cfg_resource("billing", items: { "max_seats" => 5 }) }.to_json,
                        headers: jsonapi_headers)
      cfg = config.new("billing")
      cfg.set_number("max_seats", 5)
      cfg.save
      expect(stub).to have_been_requested
      expect(cfg.created_at).not_to be_nil
    end

    it "PUTs an existing config (created_at present)" do
      stub_get("billing", cfg_resource("billing", items: { "max_seats" => 5 }))
      cfg = config.get("billing")
      put = stub_request(:put, "#{base_url}/api/v1/configs/billing")
            .to_return(status: 200,
                       body: { "data" => cfg_resource("billing", items: { "max_seats" => 9 }) }.to_json,
                       headers: jsonapi_headers)
      cfg.set_number("max_seats", 9)
      cfg.save
      expect(put).to have_been_requested
      expect(cfg.items.find { |i| i.name == "max_seats" }.value).to eq(9)
    end

    it "serializes items and environment overrides into the request body" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/configs")
        .to_return do |req|
          captured = JSON.parse(req.body)
          { status: 201, body: { "data" => cfg_resource("billing") }.to_json, headers: jsonapi_headers }
        end
      cfg = config.new("billing", description: "desc")
      cfg.set_number("max_seats", 5)
      cfg.set_number("max_seats", 25, environment: "production")
      cfg.save
      attrs = captured["data"]["attributes"]
      expect(attrs["items"]["max_seats"]).to include("value" => 5, "type" => "NUMBER")
      expect(attrs["environments"]).to eq("production" => { "max_seats" => 25 })
    end
  end

  # ----------------------------------------------------------------
  # Management surface: discovery buffer
  # ----------------------------------------------------------------

  describe "discovery buffer" do
    it "register_config queues a declaration and bumps pending_count" do
      expect { config.register_config("billing", service: "svc", environment: "staging") }
        .to change(config, :pending_count).from(0).to(1)
    end

    it "register_config_item adds an item under a declared config" do
      config.register_config("billing", service: "svc", environment: "staging")
      expect { config.register_config_item("billing", "max_seats", "NUMBER", 5) }
        .not_to(change(config, :pending_count))
    end

    it "flush POSTs the bulk batch and clears pending" do
      bulk = stub_request(:post, "#{base_url}/api/v1/configs/bulk")
             .to_return(status: 200, body: { "registered" => 1 }.to_json, headers: jsonapi_headers)
      config.register_config("billing", service: "svc", environment: "staging")
      config.register_config_item("billing", "max_seats", "NUMBER", 5)
      config.flush
      expect(bulk).to have_been_requested
      expect(config.pending_count).to eq(0)
    end

    it "flush is a no-op when nothing is pending" do
      config.flush
      expect(a_request(:post, "#{base_url}/api/v1/configs/bulk")).not_to have_been_made
    end

    it "flush swallows bulk-register errors (fire-and-forget)" do
      stub_request(:post, "#{base_url}/api/v1/configs/bulk").to_return(status: 500, body: "boom")
      config.register_config("billing", service: "svc", environment: "staging")
      expect { config.flush }.not_to raise_error
    end

    it "kicks off a background flush once the pending threshold is crossed" do
      bulk = stub_request(:post, "#{base_url}/api/v1/configs/bulk")
             .to_return(status: 200, body: { "registered" => 1 }.to_json, headers: jsonapi_headers)
      # Run the spawned flush synchronously so coverage of the flush body never
      # depends on background-thread timing (which flakes under CI).
      allow(Thread).to receive(:new) { |*a, &blk|
        blk.call(*a)
        nil
      }
      # CONFIG_BATCH_FLUSH_SIZE distinct config declarations cross the threshold
      # and spawn the background-flush thread.
      Smplkit::CONFIG_BATCH_FLUSH_SIZE.times do |i|
        config.register_config("cfg#{i}", service: "svc", environment: "staging")
      end
      expect(bulk).to have_been_requested
    end

    it "threshold_flush delegates to flush on the happy path" do
      allow(config).to receive(:flush)
      config.send(:threshold_flush)
      expect(config).to have_received(:flush)
    end

    it "threshold_flush swallows an error raised by the flush" do
      # The spawned flush raises; the rescue must keep the thread from crashing.
      allow(config).to receive(:flush).and_raise(StandardError, "threshold boom")
      expect { config.send(:threshold_flush) }.not_to raise_error
    end
  end

  # ----------------------------------------------------------------
  # Live surface: lazy connect + subscribe
  # ----------------------------------------------------------------

  describe "#subscribe and lazy connect" do
    it "connects on first use, flushing discovery before the initial fetch" do
      bulk = stub_request(:post, "#{base_url}/api/v1/configs/bulk")
             .to_return(status: 200, body: { "registered" => 1 }.to_json, headers: jsonapi_headers)
      list = stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      # Queue a discovery declaration so the connect-time flush has work to do.
      config.register_config("seed", service: "svc", environment: "staging")
      config.register_config_item("seed", "k", "STRING", "v")

      proxy = config.subscribe("billing")
      expect(proxy).to be_a(Smplkit::Config::LiveConfigProxy)
      expect(proxy.config_id).to eq("billing")
      expect(bulk).to have_been_requested
      expect(list).to have_been_requested
    end

    it "swallows a connect-time discovery-flush error and still connects" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      # Make the pre-connect flush raise; ensure_connected must catch it and
      # carry on to the initial fetch.
      allow(config).to receive(:flush).and_raise(StandardError, "flush boom")
      expect { config.subscribe("billing") }.not_to raise_error
      expect(config.get_value("billing", "max_seats")).to eq(5)
    end

    it "returns a proxy whose reads reflect the resolved cache" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      proxy = config.subscribe("billing")
      expect(proxy["max_seats"]).to eq(5)
    end

    it "returns the same proxy instance on repeat subscribe" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      a = config.subscribe("billing")
      b = config.subscribe("billing")
      expect(a).to equal(b)
    end

    it "raises NotFoundError for an unknown config" do
      stub_list
      expect { config.subscribe("missing") }.to raise_error(Smplkit::NotFoundError, /not found/)
    end

    it "registers the config declaration for code-first observability" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config.subscribe("billing")
      # The "billing" declaration is queued in the discovery buffer.
      expect(config.pending_count).to be >= 1
    end

    it "resolves parent chains and folds env overrides into the cache" do
      base = cfg_resource("base", items: { "max_seats" => 5, "tier" => "base" })
      pro = cfg_resource("pro", items: { "max_seats" => 50 }, parent: "base",
                                environments: { "staging" => { "max_seats" => 99 } })
      stub_list(base, pro)
      proxy = config.subscribe("pro")
      expect(proxy["max_seats"]).to eq(99)  # env override wins
      expect(proxy["tier"]).to eq("base")   # inherited from parent
    end
  end

  # ----------------------------------------------------------------
  # Live surface: get_value
  # ----------------------------------------------------------------

  describe "#get_value (no default)" do
    before { stub_list(cfg_resource("db", items: { "host" => "h" })) }

    it "returns the resolved value" do
      expect(config.get_value("db", "host")).to eq("h")
    end

    it "stringifies a symbol key" do
      expect(config.get_value("db", :host)).to eq("h")
    end

    it "raises NotFoundError when the config is unknown" do
      expect { config.get_value("missing", "host") }.to raise_error(Smplkit::NotFoundError)
    end

    it "raises KeyError when the key is unknown" do
      expect { config.get_value("db", "missing") }.to raise_error(KeyError, /missing/)
    end

    it "does not register anything" do
      config.get_value("db", "host")
      expect(config.pending_count).to eq(0)
    end
  end

  describe "#get_value (with default)" do
    before { stub_list(cfg_resource("db", items: { "host" => "real" })) }

    it "returns the cached value when present" do
      expect(config.get_value("db", "host", "fallback")).to eq("real")
    end

    it "returns the default when the config is missing, without raising" do
      expect(config.get_value("missing", "host", "fallback")).to eq("fallback")
    end

    it "returns the default when the key is missing, without raising" do
      expect(config.get_value("db", "no_such_key", "fallback")).to eq("fallback")
    end

    it "treats an explicit nil default as a real default (does not raise)" do
      expect(config.get_value("missing", "k", nil)).to be_nil
    end

    it "registers the config and the inferred-type key for observability" do
      config.get_value("billing", "max_seats", 5)
      expect(config.pending_count).to be >= 1
    end
  end

  # ----------------------------------------------------------------
  # Live surface: bind
  # ----------------------------------------------------------------

  describe "#bind" do
    it "returns the same Hash instance back" do
      stub_list
      payload = { "host" => "h", "port" => 5432 }
      expect(config.bind("db", payload)).to equal(payload)
    end

    it "returns the same Struct instance back" do
      stub_list
      instance = Billing.new(max_seats: 10, tier: "pro")
      expect(config.bind("billing", instance)).to equal(instance)
    end

    it "is idempotent — repeated calls with the same id return the original" do
      stub_list
      first = { "k" => "v1" }
      second = { "k" => "v2" }
      expect(config.bind("db", first)).to equal(first)
      expect(config.bind("db", second)).to equal(first)
    end

    it "raises TypeError for non-Hash, non-Struct targets" do
      stub_list
      expect { config.bind("billing", "just a string") }.to raise_error(TypeError, /Hash or Struct/)
      expect { config.bind("billing", 42) }.to raise_error(TypeError, /Hash or Struct/)
      expect { config.bind("billing", [1, 2]) }.to raise_error(TypeError, /Hash or Struct/)
    end

    it "seeds the cache in-memory for a brand-new config (no network beyond connect)" do
      stub_list
      config.bind("db", { "host" => "h", "port" => 5432 })
      expect(config.get_value("db", "host")).to eq("h")
      expect(config.get_value("db", "port")).to eq(5432)
    end

    it "syncs a bound Struct from cache when the config exists server-side" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 999, "tier" => "enterprise" }))
      instance = Billing.new(max_seats: 5, tier: "free")
      result = config.bind("billing", instance)
      expect(result.max_seats).to eq(999)
      expect(result.tier).to eq("enterprise")
    end

    it "syncs a bound Hash from cache when the config exists server-side" do
      stub_list(cfg_resource("db", items: { "host" => "remote", "port" => 9999 }))
      target = { "host" => "local", "port" => 5432 }
      result = config.bind("db", target)
      expect(result["host"]).to eq("remote")
      expect(result["port"]).to eq(9999)
    end

    it "wires a parent chain through a previously-bound target" do
      stub_list
      base = config.bind("base", Billing.new(max_seats: 5, tier: "base"))
      config.bind("child", { "max_seats" => 50 }, parent: base)
      # Child seed resolves through the bound parent chain — tier inherited.
      expect(config.get_value("child", "tier")).to eq("base")
      expect(config.get_value("child", "max_seats")).to eq(50)
    end

    it "rejects an unbound parent reference" do
      stub_list
      stray = Billing.new(max_seats: 5)
      expect { config.bind("pro", Billing.new, parent: stray) }
        .to raise_error(ArgumentError, /previously returned from client.config.bind/)
    end

    it "keeps a brand-new seed alive across a refresh that omits it (merge_pending_seeds)" do
      stub_list # initial connect: empty server
      config.bind("db", { "host" => "h", "port" => 5432 })
      expect(config.get_value("db", "host")).to eq("h")
      # A refresh that still does not include "db" must NOT drop the seed.
      config.refresh
      expect(config.get_value("db", "host")).to eq("h")
    end
  end

  # ----------------------------------------------------------------
  # Live surface: on_change + refresh
  # ----------------------------------------------------------------

  describe "#on_change and #refresh" do
    it "raises without a block" do
      stub_list
      expect { config.on_change }.to raise_error(ArgumentError, /requires a block/)
    end

    it "returns the registered block" do
      stub_list
      seen = []
      block = proc { |e| seen << e }
      expect(config.on_change(&block)).to equal(block)
    end

    it "does not replay the initial load to a freshly-registered listener" do
      # on_change auto-connects, so the initial do_refresh("initial") fires
      # before the listener is recorded — the listener only sees later changes.
      stub_list(cfg_resource("billing", items: { "k" => 0 }))
      seen = []
      config.on_change { |e| seen << e.source }
      expect(seen).to be_empty
    end

    it "fires the global listener on any change delivered by refresh" do
      stub_list(cfg_resource("billing", items: { "k" => 0 }))
      config._ensure_connected
      seen = []
      config.on_change { |e| seen << [e.config_id, e.item_key, e.old_value, e.new_value] }
      stub_list(cfg_resource("billing", items: { "k" => 1 }))
      config.refresh
      expect(seen).to eq([["billing", "k", 0, 1]])
    end

    it "fires a config-scoped listener only for matching ids" do
      stub_list(cfg_resource("billing", items: { "k" => 0 }))
      config._ensure_connected
      seen = []
      config.on_change("other") { |e| seen << e.config_id }
      stub_list(cfg_resource("billing", items: { "k" => 1 }))
      config.refresh
      expect(seen).to be_empty
    end

    it "fires an item-scoped listener only for matching item keys" do
      stub_list(cfg_resource("billing", items: { "k" => 0 }))
      config._ensure_connected
      seen = []
      config.on_change("billing", item_key: "z") { |e| seen << e.item_key }
      stub_list(cfg_resource("billing", items: { "k" => 1 }))
      config.refresh
      expect(seen).to be_empty
    end

    it "fires an item-scoped listener for the matching item key" do
      stub_list(cfg_resource("billing", items: { "k" => 0 }))
      config._ensure_connected
      seen = []
      config.on_change("billing", item_key: "k") { |e| seen << e.new_value }
      stub_list(cfg_resource("billing", items: { "k" => 7 }))
      config.refresh
      expect(seen).to eq([7])
    end

    it "swallows exceptions raised by a listener" do
      stub_list(cfg_resource("billing", items: { "k" => 0 }))
      config._ensure_connected
      config.on_change { raise "boom" }
      stub_list(cfg_resource("billing", items: { "k" => 1 }))
      expect { config.refresh }.not_to raise_error
    end

    it "mutates a bound Struct in place when refresh delivers a new value" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      instance = Billing.new(max_seats: 5)
      config.bind("billing", instance)
      stub_list(cfg_resource("billing", items: { "max_seats" => 50 }))
      config.refresh
      expect(instance.max_seats).to eq(50)
    end

    it "mutates a bound Hash in place when refresh delivers a new value" do
      stub_list(cfg_resource("db", items: { "timeout" => 30 }))
      payload = { "timeout" => 30 }
      config.bind("db", payload)
      stub_list(cfg_resource("db", items: { "timeout" => 120 }))
      config.refresh
      expect(payload["timeout"]).to eq(120)
    end

    it "listeners reading a bound object after a change see the new value" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      instance = Billing.new(max_seats: 5)
      config.bind("billing", instance)
      observed = []
      config.on_change("billing", item_key: "max_seats") { |_| observed << instance.max_seats }
      stub_list(cfg_resource("billing", items: { "max_seats" => 50 }))
      config.refresh
      expect(observed).to eq([50])
    end
  end

  # ----------------------------------------------------------------
  # Live surface: WebSocket dispatch pipeline
  # ----------------------------------------------------------------

  describe "WebSocket dispatch" do
    it "registers config_changed / config_deleted / configs_changed handlers on connect" do
      stub_list
      config._ensure_connected
      registered = ws.instance_variable_get(:@listeners)
      expect(registered.keys).to include("config_changed", "config_deleted", "configs_changed")
    end

    it "config_changed refetches a single config and updates the cache + bound object" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      instance = Billing.new(max_seats: 5)
      config.bind("billing", instance)
      stub_get("billing", cfg_resource("billing", items: { "max_seats" => 99 }))
      ws.dispatch("config_changed", { "id" => "billing" })
      expect(config.get_value("billing", "max_seats")).to eq(99)
      expect(instance.max_seats).to eq(99)
    end

    it "config_changed accepts the `key` field as the id" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      stub_get("billing", cfg_resource("billing", items: { "max_seats" => 42 }))
      ws.dispatch("config_changed", { "key" => "billing" })
      expect(config.get_value("billing", "max_seats")).to eq(42)
    end

    it "config_changed with no id falls back to a full refresh" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      stub_list(cfg_resource("billing", items: { "max_seats" => 7 }))
      ws.dispatch("config_changed", {})
      expect(config.get_value("billing", "max_seats")).to eq(7)
    end

    it "config_changed swallows a fetch error and leaves the cache intact" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      stub_request(:get, "#{base_url}/api/v1/configs/billing").to_return(status: 500, body: "boom")
      ws.dispatch("config_changed", { "id" => "billing" })
      expect(config.get_value("billing", "max_seats")).to eq(5)
    end

    it "config_changed treats a 404 (nil config) as no change" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      # fetch_config raises NotFoundError -> rescued -> cache unchanged.
      stub_get("billing", nil, status: 404)
      ws.dispatch("config_changed", { "id" => "billing" })
      expect(config.get_value("billing", "max_seats")).to eq(5)
    end

    it "config_changed fetches an uncached parent so the child keeps inherited values" do
      # Initial connect sees only the child; its parent "base" was created via
      # discovery after connect and never broadcast its own event, so it is
      # absent from the raw store. Without transitive ancestor-fetch the child
      # would re-resolve missing "region".
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }, parent: "base"))
      config._ensure_connected
      expect { config.get_value("billing", "region") }.to raise_error(KeyError)

      stub_get("billing", cfg_resource("billing", items: { "max_seats" => 5 }, parent: "base"))
      stub_get("base", cfg_resource("base", items: { "region" => "us-east" }))
      ws.dispatch("config_changed", { "id" => "billing" })

      expect(config.get_value("billing", "region")).to eq("us-east")
      expect(config.get_value("billing", "max_seats")).to eq(5)
    end

    it "config_changed walks a multi-level ancestor chain and guards already-cached parents" do
      # child -> mid -> root. root is already cached from the initial connect;
      # mid is uncached and must be fetched, and the walk must not re-fetch the
      # already-present root.
      stub_list(cfg_resource("root", items: { "region" => "us-east" }))
      config._ensure_connected

      stub_get("child", cfg_resource("child", items: { "max_seats" => 9 }, parent: "mid"))
      stub_get("mid", cfg_resource("mid", items: { "tier" => "pro" }, parent: "root"))
      ws.dispatch("config_changed", { "id" => "child" })

      expect(config.get_value("child", "max_seats")).to eq(9)
      expect(config.get_value("child", "tier")).to eq("pro")
      expect(config.get_value("child", "region")).to eq("us-east")
    end

    it "config_deleted removes the config from the cache" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      ws.dispatch("config_deleted", { "id" => "billing" })
      expect { config.get_value("billing", "max_seats") }.to raise_error(Smplkit::NotFoundError)
    end

    it "config_deleted with no id falls back to a full refresh" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      stub_list # refresh: now empty
      ws.dispatch("config_deleted", {})
      expect { config.get_value("billing", "max_seats") }.to raise_error(Smplkit::NotFoundError)
    end

    it "config_deleted is a no-op for an unknown config id" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      expect { ws.dispatch("config_deleted", { "id" => "unknown" }) }.not_to raise_error
      expect(config.get_value("billing", "max_seats")).to eq(5)
    end

    it "configs_changed triggers a full refresh" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      stub_list(cfg_resource("billing", items: { "max_seats" => 88 }))
      ws.dispatch("configs_changed", {})
      expect(config.get_value("billing", "max_seats")).to eq(88)
    end

    it "configs_changed swallows refresh errors" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      stub_request(:get, "#{base_url}/api/v1/configs")
        .with(query: hash_including({}))
        .to_return(status: 500, body: "boom")
      expect { ws.dispatch("configs_changed", {}) }.not_to raise_error
    end
  end

  # ----------------------------------------------------------------
  # close + metrics + _ensure_connected idempotency
  # ----------------------------------------------------------------

  describe "lifecycle" do
    it "_ensure_connected is idempotent — a second call does not refetch" do
      list = stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      config._ensure_connected
      expect(list).to have_been_requested.once
    end

    it "#close is a near no-op for a wired client (does not close the parent's WS)" do
      stub_list
      config._ensure_connected
      expect { config.close }.not_to raise_error
      expect(ws.connection_status).to eq("disconnected")
    end

    it "_close aliases close" do
      expect { config._close }.not_to raise_error
    end

    it "_cached_values returns a copy of the resolved values" do
      stub_list(cfg_resource("billing", items: { "max_seats" => 5 }))
      config._ensure_connected
      values = config._cached_values("billing")
      expect(values).to eq("max_seats" => 5)
      values["max_seats"] = 999
      expect(config._cached_values("billing")).to eq("max_seats" => 5)
    end

    it "_cached_values returns {} for an unknown config" do
      stub_list
      config._ensure_connected
      expect(config._cached_values("nope")).to eq({})
    end
  end

  describe "metrics" do
    let(:metrics) { instance_double(Smplkit::MetricsReporter, record: nil) }

    it "records config.resolutions on subscribe" do
      stub_list(cfg_resource("billing", items: { "k" => "v" }))
      expect(metrics).to receive(:record).with(
        "config.resolutions", unit: "resolutions", dimensions: { "config" => "billing" }
      )
      config.subscribe("billing")
    end

    it "records config.changes on each value change" do
      stub_list(cfg_resource("billing", items: { "k" => 0 }))
      config._ensure_connected
      stub_list(cfg_resource("billing", items: { "k" => 1 }))
      expect(metrics).to receive(:record).with(
        "config.changes", unit: "changes", dimensions: { "config" => "billing" }
      )
      config.refresh
    end
  end
end

# --- ConfigClient standalone construction -----------------------------

RSpec.describe "Smplkit::Config::ConfigClient (standalone)" do
  subject(:config) do
    Smplkit::Config::ConfigClient.new(
      "sk_standalone", environment: "staging",
                       base_url: "https://config.smplkit.test", base_domain: "smplkit.test"
    )
  end

  after { config.close }

  it "builds and owns its own transport, reaching the resolved base URL" do
    stub = stub_request(:get, "https://config.smplkit.test/api/v1/configs/billing")
           .to_return(
             status: 200,
             body: {
               "data" => {
                 "id" => "billing", "type" => "config",
                 "attributes" => { "name" => "Billing", "items" => {}, "environments" => {} }
               }
             }.to_json,
             headers: { "Content-Type" => "application/vnd.api+json" }
           )
    cfg = config.get("billing")
    expect(cfg.key).to eq("billing")
    expect(stub).to have_been_requested
  end

  it "#close on a standalone client that never connected is a no-op" do
    expect { config.close }.not_to raise_error
  end

  it "opens and owns its WebSocket on first live use, then tears it down on close" do
    # Replace the real socket with a double so ensure_ws can build + start it
    # (and close can stop it) without opening a network connection.
    fake_ws = instance_double(Smplkit::SharedWebSocket, start: nil, stop: nil, on: nil)
    allow(Smplkit::SharedWebSocket).to receive(:new).and_return(fake_ws)
    stub_request(:get, "https://config.smplkit.test/api/v1/configs")
      .with(query: hash_including({}))
      .to_return(
        status: 200,
        body: { "data" => [], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )

    config._ensure_connected
    expect(fake_ws).to have_received(:start)
    expect(fake_ws).to have_received(:on).with("config_changed")
    expect(fake_ws).to have_received(:on).with("config_deleted")
    expect(fake_ws).to have_received(:on).with("configs_changed")

    config.close
    expect(fake_ws).to have_received(:stop)
  end
end

# --- ConfigClient stateless mode (streaming: false) --------------------

RSpec.describe "Smplkit::Config::ConfigClient (stateless, streaming: false)" do
  subject(:config) do
    Smplkit::Config::ConfigClient.new(
      "sk_stateless", environment: "staging", streaming: false,
                      base_url: "https://config.smplkit.test", base_domain: "smplkit.test"
    )
  end

  after { config.close }

  def jsonapi_headers
    { "Content-Type" => "application/vnd.api+json" }
  end

  def cfg_resource(id, items: {})
    {
      "id" => id, "type" => "config",
      "attributes" => {
        "name" => id, "description" => nil, "parent" => nil,
        "items" => items.transform_values { |v| { "value" => v, "type" => "STRING" } },
        "environments" => {},
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-01T00:00:00Z"
      }
    }
  end

  def list_body(*resources)
    { "data" => resources, "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }.to_json
  end

  def stub_list(*resources)
    stub_request(:get, "https://config.smplkit.test/api/v1/configs")
      .with(query: hash_including({}))
      .to_return(status: 200, body: list_body(*resources), headers: jsonapi_headers)
  end

  it "connects without ever creating a WebSocket and serves reads from the one-shot fetch" do
    expect(Smplkit::SharedWebSocket).not_to receive(:new)
    stub_list(cfg_resource("billing", items: { "max_seats" => 50 }))
    expect(config.get_value("billing", "max_seats")).to eq(50)
    expect(config.subscribe("billing")["max_seats"]).to eq(50)
  end

  it "refresh re-fetches on demand and fires change listeners from deltas" do
    expect(Smplkit::SharedWebSocket).not_to receive(:new)
    stub_request(:get, "https://config.smplkit.test/api/v1/configs")
      .with(query: hash_including({}))
      .to_return(
        { status: 200, body: list_body(cfg_resource("billing", items: { "max_seats" => 50 })),
          headers: jsonapi_headers },
        { status: 200, body: list_body(cfg_resource("billing", items: { "max_seats" => 99 })),
          headers: jsonapi_headers }
      )
    expect(config.get_value("billing", "max_seats")).to eq(50)
    events = []
    config.on_change("billing") { |e| events << e }
    config.refresh
    expect(config.get_value("billing", "max_seats")).to eq(99)
    expect(events.size).to eq(1)
    expect(events.first.item_key).to eq("max_seats")
    expect(events.first.old_value).to eq(50)
    expect(events.first.new_value).to eq(99)
    expect(events.first.source).to eq("manual")
  end

  it "runs threshold flushes inline instead of spawning a background thread" do
    expect(Thread).not_to receive(:new)
    bulk = stub_request(:post, "https://config.smplkit.test/api/v1/configs/bulk")
           .to_return(status: 200, body: "{}", headers: jsonapi_headers)
    Smplkit::CONFIG_BATCH_FLUSH_SIZE.times do |i|
      config.register_config("cfg-#{i}", service: nil, environment: nil)
    end
    # The threshold flush ran synchronously inside the crossing register call.
    expect(bulk).to have_been_requested.once
    expect(config.pending_count).to eq(0)
  end
end

# --- ConfigClient environment/service resolution ------------------------

RSpec.describe "Smplkit::Config::ConfigClient (environment/service resolution)" do
  around do |ex|
    saved = ENV.to_h.slice("SMPLKIT_ENVIRONMENT", "SMPLKIT_SERVICE")
    %w[SMPLKIT_ENVIRONMENT SMPLKIT_SERVICE].each { |k| ENV.delete(k) }
    ex.run
  ensure
    %w[SMPLKIT_ENVIRONMENT SMPLKIT_SERVICE].each { |k| saved.key?(k) ? ENV[k] = saved[k] : ENV.delete(k) }
  end

  def standalone(**kwargs)
    Smplkit::Config::ConfigClient.new(
      "sk_resolution", base_url: "https://config.smplkit.test", base_domain: "smplkit.test", **kwargs
    )
  end

  it "resolves environment and service from SMPLKIT_* env vars" do
    ENV["SMPLKIT_ENVIRONMENT"] = "stg"
    ENV["SMPLKIT_SERVICE"] = "svc-env"
    client = standalone
    expect(client.instance_variable_get(:@environment)).to eq("stg")
    expect(client.instance_variable_get(:@service)).to eq("svc-env")
    client.close
  end

  it "prefers explicit environment/service kwargs over env vars" do
    ENV["SMPLKIT_ENVIRONMENT"] = "stg"
    ENV["SMPLKIT_SERVICE"] = "svc-env"
    client = standalone(environment: "ctor-env", service: "ctor-svc")
    expect(client.instance_variable_get(:@environment)).to eq("ctor-env")
    expect(client.instance_variable_get(:@service)).to eq("ctor-svc")
    client.close
  end

  it "attaches the resolved service and environment to discovery declarations" do
    ENV["SMPLKIT_SERVICE"] = "svc-wire"
    # streaming: false so the live call below never opens a real WebSocket.
    client = standalone(environment: "env-wire", streaming: false)
    captured = nil
    stub_request(:post, "https://config.smplkit.test/api/v1/configs/bulk")
      .with { |req| captured = JSON.parse(req.body) }
      .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/vnd.api+json" })
    stub_request(:get, "https://config.smplkit.test/api/v1/configs")
      .with(query: hash_including({}))
      .to_return(status: 200,
                 body: { "data" => [], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }.to_json,
                 headers: { "Content-Type" => "application/vnd.api+json" })
    # The default form of get_value registers the config + item declaration.
    expect(client.get_value("observed", "k", 1)).to eq(1)
    client.flush
    declared = captured["configs"].first
    expect(declared["service"]).to eq("svc-wire")
    expect(declared["environment"]).to eq("env-wire")
    client.close
  end
end

# --- ConfigClient.open ------------------------------------------------

RSpec.describe "Smplkit::Config::ConfigClient.open" do
  # +.open+ forwards only keyword args to +new+, whose +api_key+ is positional;
  # supply the key through the environment so resolution succeeds without it.
  around do |example|
    original = ENV.fetch("SMPLKIT_API_KEY", nil)
    ENV["SMPLKIT_API_KEY"] = "sk_open"
    example.run
  ensure
    ENV["SMPLKIT_API_KEY"] = original
  end

  it "yields a client and closes it on exit" do
    yielded = nil
    Smplkit::Config::ConfigClient.open(
      base_url: "https://config.smplkit.test", base_domain: "smplkit.test"
    ) do |client|
      expect(client).to be_a(Smplkit::Config::ConfigClient)
      yielded = client
    end
    # No connection was opened, so close just no-ops; assert the block ran.
    expect(yielded).to be_a(Smplkit::Config::ConfigClient)
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
    expect(proxy.has_key?("port")).to be true # rubocop:disable Style/PreferredHashMethods
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
