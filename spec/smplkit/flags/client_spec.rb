# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/ExpectOutput, Layout/LineLength

# Tests for the fused +Smplkit::Flags::FlagsClient+ (one-client architecture).
#
# The client is constructed WIRED: a parent double supplies the environment,
# service, and shared (non-started) WebSocket; an injected flags transport
# points at a WebMock host; and a stubbed contexts seam stands in for
# +client.platform.contexts+. The live surface (+boolean_flag+ etc.) connects
# lazily on first use — the first call flushes discovery, fetches all flag
# definitions over HTTP, and subscribes to the WebSocket.
RSpec.describe Smplkit::Flags::FlagsClient do
  subject(:flags) do
    described_class.new(parent: parent, transport: transport, contexts: contexts, metrics: metrics)
  end

  let(:flags_host) { "https://flags.smplkit.test" }
  let(:tcfg) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:transport) { Smplkit::Transport.build_api_client(SmplkitGeneratedClient::Flags, "flags", tcfg) }
  # A non-started SharedWebSocket: dispatch() invokes registered listeners
  # synchronously without opening a socket.
  let(:ws) { Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k") }
  let(:contexts) { instance_double(Smplkit::Platform::ContextsClient, register: nil) }
  let(:parent) do
    double(
      _environment: "staging",
      _service: nil,
      _ensure_started: nil,
      _ensure_ws: ws
    )
  end
  let(:metrics) { nil }

  after { flags._close }

  # ----------------------------------------------------------------
  # Server-resource fixtures (JSON:API shape consumed by
  # Helpers.flag_dict_from_json).
  # ----------------------------------------------------------------

  def flag_resource(id, type: "BOOLEAN", default: false, values: nil, description: nil, environments: nil)
    {
      "id" => id,
      "type" => "flag",
      "attributes" => {
        "name" => Smplkit::Helpers.key_to_display_name(id),
        "type" => type,
        "default" => default,
        "values" => values,
        "description" => description,
        "environments" => environments,
        "created_at" => "2026-01-01T00:00:00Z",
        "updated_at" => "2026-01-02T00:00:00Z"
      }
    }
  end

  # The standard "checkout-v2" boolean flag: enabled in staging with a single
  # rule that serves +true+ when user.plan == "enterprise".
  def checkout_environments(enabled: true, env_default: nil)
    {
      "staging" => {
        "enabled" => enabled,
        "default" => env_default,
        "rules" => [
          {
            "logic" => { "==" => [{ "var" => "user.plan" }, "enterprise"] },
            "value" => true,
            "description" => "enterprise users"
          }
        ]
      }
    }
  end

  def list_body(resources, links: nil)
    body = {
      "data" => resources,
      "meta" => { "pagination" => { "page" => 1, "size" => Smplkit::ApiSupport::RUNTIME_PAGE_SIZE } }
    }
    body["links"] = links if links
    body.to_json
  end

  def single_body(resource)
    { "data" => resource }.to_json
  end

  # The flags bulk endpoint returns FlagBulkResponse, which requires an
  # integer +registered+ count.
  def bulk_body(registered = 0)
    { "registered" => registered }.to_json
  end

  def jsonapi_headers
    { "Content-Type" => "application/vnd.api+json" }
  end

  # Stub the runtime fetch (GET list) used by ensure_connected / refresh, plus
  # the discovery bulk POST that fires when the buffer is non-empty.
  def stub_runtime(resources)
    stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                    .to_return(status: 200, body: list_body(resources), headers: jsonapi_headers)
    stub_request(:post, "#{flags_host}/api/v1/flags/bulk")
      .to_return(status: 200, body: bulk_body, headers: jsonapi_headers)
  end

  # ----------------------------------------------------------------
  # Live surface: typed handles + evaluation
  # ----------------------------------------------------------------

  describe "typed flag handles" do
    before { stub_runtime([flag_resource("checkout-v2", environments: checkout_environments)]) }

    it "boolean_flag returns a typed handle" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      expect(handle).to be_a(Smplkit::Flags::BooleanFlag)
    end

    it "string_flag returns a typed handle and coerces to String" do
      handle = flags.string_flag("color", default: "red")
      expect(handle).to be_a(Smplkit::Flags::StringFlag)
      expect(handle.get).to eq("red")
    end

    it "number_flag returns a typed handle" do
      handle = flags.number_flag("rate", default: 5)
      expect(handle).to be_a(Smplkit::Flags::NumberFlag)
      expect(handle.get).to eq(5)
    end

    it "json_flag returns a typed handle" do
      handle = flags.json_flag("settings", default: { "a" => 1 })
      expect(handle).to be_a(Smplkit::Flags::JsonFlag)
      expect(handle.get).to eq({ "a" => 1 })
    end

    it "connects lazily and fetches definitions on first handle declaration" do
      flags.boolean_flag("checkout-v2", default: false)
      expect(a_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))).to have_been_made
      expect(parent).to have_received(:_ensure_started)
    end

    it "evaluates a matching rule to its served value with explicit context" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
      expect(handle.get(context: ctx)).to be(true)
    end

    it "registers the explicit context with the contexts seam" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
      handle.get(context: ctx)
      expect(contexts).to have_received(:register).with(ctx)
    end

    it "falls back to env/flag default when no rule matches (explicit context)" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-2", plan: "free")]
      expect(handle.get(context: ctx)).to be(false)
    end

    it "evaluates via the implicit request context" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      Smplkit.set_request_context([Smplkit::Context.new("user", "u-1", plan: "enterprise")])
      expect(handle.get).to be(true)
    end

    it "does not register implicit request contexts with the seam" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      Smplkit.set_request_context([Smplkit::Context.new("user", "u-1", plan: "enterprise")])
      handle.get
      expect(contexts).not_to have_received(:register)
    end

    it "uses an empty eval dict when there is no request context" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      # No context at all -> no rule match -> env/flag default.
      expect(handle.get).to be(false)
    end
  end

  describe "evaluation semantics (ADR-022)" do
    it "returns the flag-level default when the environment is missing" do
      stub_runtime([flag_resource("only-prod", default: true,
                                               environments: { "production" => { "enabled" => true, "default" => nil, "rules" => [] } })])
      handle = flags.boolean_flag("only-prod", default: false)
      expect(handle.get).to be(true)
    end

    it "returns the env default when the environment is disabled" do
      stub_runtime([flag_resource("checkout-v2",
                                  environments: checkout_environments(enabled: false, env_default: true))])
      handle = flags.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
      # Disabled -> rules are skipped; env default (true) wins over flag default.
      expect(handle.get(context: ctx)).to be(true)
    end

    it "returns the flag default when disabled with no env default" do
      stub_runtime([flag_resource("checkout-v2", default: false,
                                                 environments: checkout_environments(enabled: false, env_default: nil))])
      handle = flags.boolean_flag("checkout-v2", default: true)
      expect(handle.get).to be(false)
    end

    it "falls back to the handle default when the flag is absent from the store" do
      stub_runtime([])
      handle = flags.boolean_flag("unknown", default: true)
      expect(handle.get).to be(true)
    end

    it "skips a rule whose logic evaluation raises and falls back" do
      stub_runtime([flag_resource("checkout-v2", default: false,
                                                 environments: checkout_environments(enabled: true, env_default: nil))])
      # Force the JSON-logic evaluator to raise for the (only) rule so the
      # rescue branch is exercised; evaluation then falls back to the default.
      allow(Smplkit::Flags::JsonLogicEvaluator).to receive(:apply).and_raise(StandardError, "boom")
      handle = flags.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
      expect(handle.get(context: ctx)).to be(false)
    end

    it "auto-injects the service context when the parent sets a service" do
      allow(parent).to receive(:_service).and_return("checkout-svc")
      svc_flags = described_class.new(parent: parent, transport: transport, contexts: contexts, metrics: metrics)
      stub_runtime([flag_resource("svc-flag", default: false,
                                              environments: {
                                                "staging" => {
                                                  "enabled" => true, "default" => nil,
                                                  "rules" => [{
                                                    "logic" => { "==" => [{ "var" => "service.key" }, "checkout-svc"] },
                                                    "value" => true, "description" => "this service"
                                                  }]
                                                }
                                              })])
      handle = svc_flags.boolean_flag("svc-flag", default: false)
      # No explicit context, but @service is injected as {"service" => {"key" => ...}}.
      expect(handle.get).to be(true)
    ensure
      svc_flags._close
    end
  end

  describe "resolution cache" do
    before { stub_runtime([flag_resource("checkout-v2", environments: checkout_environments)]) }

    it "records a miss on the first evaluation and a hit on the second" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
      handle.get(context: ctx)
      handle.get(context: ctx)
      stats = flags.stats
      expect(stats.cache_misses).to be >= 1
      expect(stats.cache_hits).to be >= 1
    end

    it "caches the default for flags absent from the store" do
      stub_runtime([])
      missing = described_class.new(parent: parent, transport: transport, contexts: contexts, metrics: metrics)
      handle = missing.boolean_flag("missing", default: true)
      handle.get
      handle.get
      stats = missing.stats
      expect(stats.cache_hits + stats.cache_misses).to be >= 2
      expect(stats.cache_hits).to be >= 1
    ensure
      missing._close
    end
  end

  describe "metrics seam" do
    let(:metrics) { instance_double(Smplkit::MetricsReporter, record: nil) }

    before { stub_runtime([flag_resource("checkout-v2", environments: checkout_environments)]) }

    it "records evaluation + miss/hit metrics" do
      handle = flags.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
      handle.get(context: ctx)
      handle.get(context: ctx)
      expect(metrics).to have_received(:record).with("flags.cache_misses", unit: "misses")
      expect(metrics).to have_received(:record).with("flags.cache_hits", unit: "hits")
      expect(metrics).to have_received(:record)
        .with("flags.evaluations", unit: "evaluations", dimensions: { "flag" => "checkout-v2" }).at_least(:twice)
    end
  end

  # ----------------------------------------------------------------
  # refresh / stats
  # ----------------------------------------------------------------

  describe "#refresh" do
    it "re-fetches definitions, clears the cache, and fires change listeners" do
      stub_runtime([flag_resource("checkout-v2", environments: checkout_environments)])
      seen = []
      flags.on_change { |evt| seen << [evt.id, evt.source] }
      flags.refresh
      expect(seen).to include(%w[checkout-v2 manual])
    end
  end

  describe "#stats" do
    it "returns a FlagStats struct" do
      stub_runtime([])
      expect(flags.stats).to be_a(Smplkit::Flags::FlagStats)
    end
  end

  # ----------------------------------------------------------------
  # on_change + WebSocket dispatch
  # ----------------------------------------------------------------

  describe "#on_change and WebSocket dispatch" do
    before { stub_runtime([flag_resource("checkout-v2", environments: checkout_environments)]) }

    it "raises without a block" do
      flags._ensure_connected
      expect { flags.on_change }.to raise_error(ArgumentError, /requires a block/)
    end

    it "registers a global listener" do
      seen = []
      flags.on_change { |evt| seen << evt.id }
      flags.send(:fire_change_listeners, "x", "manual")
      expect(seen).to eq(["x"])
    end

    it "registers an id-scoped listener that only fires for its id" do
      seen = []
      flags.on_change("checkout-v2") { |evt| seen << evt.id }
      flags.send(:fire_change_listeners, "checkout-v2", "manual")
      flags.send(:fire_change_listeners, "other", "manual")
      expect(seen).to eq(["checkout-v2"])
    end

    it "dispatches flag_changed: re-fetches the single flag and fires listeners" do
      flags._ensure_connected
      changed = flag_resource("checkout-v2", default: true,
                                             environments: checkout_environments(enabled: false))
      stub_request(:get, "#{flags_host}/api/v1/flags/checkout-v2")
        .to_return(status: 200, body: single_body(changed), headers: jsonapi_headers)
      events = []
      flags.on_change("checkout-v2") { |evt| events << evt }
      ws.dispatch("flag_changed", { "id" => "checkout-v2" })
      expect(events.map(&:id)).to eq(["checkout-v2"])
      expect(events.first.source).to eq("websocket")
    end

    it "ignores flag_changed without an id" do
      flags._ensure_connected
      events = []
      flags.on_change { |evt| events << evt }
      ws.dispatch("flag_changed", {})
      expect(events).to be_empty
    end

    it "does not fire when the re-fetched flag is unchanged" do
      flags._ensure_connected
      same = flag_resource("checkout-v2", environments: checkout_environments)
      stub_request(:get, "#{flags_host}/api/v1/flags/checkout-v2")
        .to_return(status: 200, body: single_body(same), headers: jsonapi_headers)
      events = []
      flags.on_change { |evt| events << evt }
      ws.dispatch("flag_changed", { "id" => "checkout-v2" })
      expect(events).to be_empty
    end

    it "dispatches flag_deleted: removes the flag and fires a deleted event" do
      flags._ensure_connected
      events = []
      flags.on_change("checkout-v2") { |evt| events << evt }
      ws.dispatch("flag_deleted", { "id" => "checkout-v2" })
      expect(events.size).to eq(1)
      expect(events.first).to be_deleted
    end

    it "ignores flag_deleted for an unknown flag" do
      flags._ensure_connected
      events = []
      flags.on_change { |evt| events << evt }
      ws.dispatch("flag_deleted", { "id" => "never-existed" })
      expect(events).to be_empty
    end

    it "ignores flag_deleted without an id" do
      flags._ensure_connected
      events = []
      flags.on_change { |evt| events << evt }
      ws.dispatch("flag_deleted", {})
      expect(events).to be_empty
    end

    it "dispatches flags_changed: re-fetches the whole store and fires per changed key" do
      flags._ensure_connected
      # New store: checkout-v2 unchanged, but a new flag appears.
      new_resources = [
        flag_resource("checkout-v2", environments: checkout_environments),
        flag_resource("new-flag", default: true,
                                  environments: { "staging" => { "enabled" => true, "default" => nil, "rules" => [] } })
      ]
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200, body: list_body(new_resources), headers: jsonapi_headers)
      global = []
      scoped = []
      flags.on_change { |evt| global << evt.id }
      flags.on_change("new-flag") { |evt| scoped << evt.id }
      ws.dispatch("flags_changed", {})
      expect(global).to eq(["new-flag"])
      expect(scoped).to eq(["new-flag"])
    end

    it "flags_changed fires nothing when the store is unchanged" do
      flags._ensure_connected
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200,
                                                                 body: list_body([flag_resource("checkout-v2", environments: checkout_environments)]),
                                                                 headers: jsonapi_headers)
      global = []
      flags.on_change { |evt| global << evt.id }
      ws.dispatch("flags_changed", {})
      expect(global).to be_empty
    end

    it "flags_changed marks a removed flag as deleted for its key listener" do
      flags._ensure_connected
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200, body: list_body([]), headers: jsonapi_headers)
      events = []
      flags.on_change("checkout-v2") { |evt| events << evt }
      ws.dispatch("flags_changed", {})
      expect(events.size).to eq(1)
      expect(events.first).to be_deleted
    end

    it "flags_changed survives a re-fetch error without raising" do
      flags._ensure_connected
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 500, body: "{}", headers: jsonapi_headers)
      global = []
      flags.on_change { |evt| global << evt.id }
      expect { ws.dispatch("flags_changed", {}) }.not_to raise_error
      expect(global).to be_empty
    end

    it "swallows exceptions raised by global listeners during flags_changed" do
      flags._ensure_connected
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200,
                                                                 body: list_body([flag_resource("new-flag", environments: checkout_environments)]),
                                                                 headers: jsonapi_headers)
      flags.on_change { |_evt| raise "boom-global" }
      expect { ws.dispatch("flags_changed", {}) }.not_to raise_error
    end

    it "swallows exceptions raised by scoped listeners during flags_changed" do
      flags._ensure_connected
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200,
                                                                 body: list_body([flag_resource("new-flag", environments: checkout_environments)]),
                                                                 headers: jsonapi_headers)
      flags.on_change("new-flag") { |_evt| raise "boom-scoped" }
      expect { ws.dispatch("flags_changed", {}) }.not_to raise_error
    end

    it "swallows exceptions raised by listeners during fire_change_listeners" do
      flags.on_change { |_evt| raise "boom" }
      expect { flags.send(:fire_change_listeners, "x", "manual") }.not_to raise_error
    end

    it "fire_change_listeners is a no-op for a nil flag id" do
      seen = []
      flags.on_change { |evt| seen << evt.id }
      flags.send(:fire_change_listeners, nil, "manual")
      expect(seen).to be_empty
    end
  end

  # ----------------------------------------------------------------
  # Management surface: new_* constructors
  # ----------------------------------------------------------------

  describe "new_* constructors" do
    it "new_boolean_flag seeds True/False values and a derived name" do
      flag = flags.new_boolean_flag("beta-feature", default: false)
      expect(flag).to be_a(Smplkit::Flags::BooleanFlag)
      expect(flag.type).to eq("BOOLEAN")
      expect(flag.name).to eq("Beta Feature")
      expect(flag.values.map(&:name)).to eq(%w[True False])
      expect(flag.values.map(&:value)).to eq([true, false])
    end

    it "new_boolean_flag honors an explicit name and description" do
      flag = flags.new_boolean_flag("beta", default: true, name: "Beta", description: "the beta gate")
      expect(flag.name).to eq("Beta")
      expect(flag.description).to eq("the beta gate")
      expect(flag.default).to be(true)
    end

    it "new_string_flag builds a STRING flag with optional values" do
      vals = [Smplkit::FlagValue.new(name: "Red", value: "red")]
      flag = flags.new_string_flag("color", default: "red", values: vals)
      expect(flag).to be_a(Smplkit::Flags::StringFlag)
      expect(flag.type).to eq("STRING")
      expect(flag.values).to eq(vals)
    end

    it "new_number_flag builds a NUMERIC flag" do
      flag = flags.new_number_flag("limit", default: 10)
      expect(flag).to be_a(Smplkit::Flags::NumberFlag)
      expect(flag.type).to eq("NUMERIC")
    end

    it "new_json_flag builds a JSON flag" do
      flag = flags.new_json_flag("payload", default: { "k" => "v" })
      expect(flag).to be_a(Smplkit::Flags::JsonFlag)
      expect(flag.type).to eq("JSON")
    end
  end

  # ----------------------------------------------------------------
  # Management surface: CRUD
  # ----------------------------------------------------------------

  describe "management CRUD" do
    it "save (create) POSTs to /api/v1/flags and applies the response" do
      created = flag_resource("beta", type: "BOOLEAN", default: false, environments: {})
      stub = stub_request(:post, "#{flags_host}/api/v1/flags")
             .to_return(status: 201, body: single_body(created), headers: jsonapi_headers)
      flag = flags.new_boolean_flag("beta", default: false)
      result = flag.save
      expect(stub).to have_been_requested
      expect(result.id).to eq("beta")
      # created_at is deserialized to a Time by the generated client.
      expect(result.created_at).to eq(Time.utc(2026, 1, 1, 0, 0, 0))
    end

    it "_create_flag returns a typed model from the response" do
      created = flag_resource("rate", type: "NUMERIC", default: 3, environments: {})
      stub_request(:post, "#{flags_host}/api/v1/flags")
        .to_return(status: 201, body: single_body(created), headers: jsonapi_headers)
      model = flags._create_flag(flags.new_number_flag("rate", default: 3))
      expect(model).to be_a(Smplkit::Flags::NumberFlag)
      expect(model.default).to eq(3)
    end

    it "_update_flag PUTs to /api/v1/flags/{id}" do
      updated = flag_resource("checkout-v2", environments: checkout_environments)
      stub = stub_request(:put, "#{flags_host}/api/v1/flags/checkout-v2")
             .to_return(status: 200, body: single_body(updated), headers: jsonapi_headers)
      flag = flags.new_boolean_flag("checkout-v2", default: false)
      model = flags._update_flag(flag)
      expect(stub).to have_been_requested
      expect(model.id).to eq("checkout-v2")
      expect(model.environments).to have_key("staging")
    end

    it "_update_flag serializes environments and rules onto the wire body" do
      updated = flag_resource("checkout-v2", environments: checkout_environments)
      captured = nil
      stub_request(:put, "#{flags_host}/api/v1/flags/checkout-v2").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 200, body: single_body(updated), headers: jsonapi_headers)
      flag = flags.new_boolean_flag("checkout-v2", default: false)
      flag.add_rule(
        Smplkit::Rule.new("enterprise users", environment: "staging")
          .when("user.plan", Smplkit::Op::EQ, "enterprise")
          .serve(true)
      )
      flags._update_flag(flag)
      env = captured.dig("data", "attributes", "environments", "staging")
      expect(env["enabled"]).to be(true)
      expect(env["rules"].first["value"]).to be(true)
      expect(env["rules"].first["logic"]).to eq("==" => [{ "var" => "user.plan" }, "enterprise"])
    end

    it "save (update) round-trips through PUT once created_at is set" do
      created = flag_resource("beta", type: "BOOLEAN", default: false, environments: {})
      stub_request(:post, "#{flags_host}/api/v1/flags")
        .to_return(status: 201, body: single_body(created), headers: jsonapi_headers)
      put_stub = stub_request(:put, "#{flags_host}/api/v1/flags/beta")
                 .to_return(status: 200, body: single_body(created), headers: jsonapi_headers)
      flag = flags.new_boolean_flag("beta", default: false)
      flag.save  # POST, sets created_at
      flag.save  # PUT
      expect(put_stub).to have_been_requested
    end

    it "get fetches a single flag and maps it to a typed model" do
      resource = flag_resource("checkout-v2", environments: checkout_environments)
      stub_request(:get, "#{flags_host}/api/v1/flags/checkout-v2")
        .to_return(status: 200, body: single_body(resource), headers: jsonapi_headers)
      flag = flags.get("checkout-v2")
      expect(flag).to be_a(Smplkit::Flags::BooleanFlag)
      expect(flag.id).to eq("checkout-v2")
      # updated_at is deserialized to a Time by the generated client.
      expect(flag.updated_at).to eq(Time.utc(2026, 1, 2, 0, 0, 0))
    end

    it "get maps STRING / NUMERIC / JSON types to their handles" do
      {
        "STRING" => Smplkit::Flags::StringFlag,
        "NUMERIC" => Smplkit::Flags::NumberFlag,
        "JSON" => Smplkit::Flags::JsonFlag
      }.each do |wire_type, klass|
        resource = flag_resource("f-#{wire_type}", type: wire_type, default: nil, environments: {})
        stub_request(:get, "#{flags_host}/api/v1/flags/f-#{wire_type}")
          .to_return(status: 200, body: single_body(resource), headers: jsonapi_headers)
        expect(flags.get("f-#{wire_type}")).to be_a(klass)
      end
    end

    it "list returns every flag as a typed model" do
      resources = [
        flag_resource("checkout-v2", environments: checkout_environments),
        flag_resource("rate", type: "NUMERIC", default: 1, environments: {})
      ]
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200, body: list_body(resources), headers: jsonapi_headers)
      models = flags.list
      expect(models.map(&:id)).to contain_exactly("checkout-v2", "rate")
    end

    it "list passes page_number / page_size through as query params" do
      stub = stub_request(:get, "#{flags_host}/api/v1/flags")
             .with(query: { "page[number]" => "2", "page[size]" => "5" })
             .to_return(status: 200, body: list_body([]), headers: jsonapi_headers)
      flags.list(page_number: 2, page_size: 5)
      expect(stub).to have_been_requested
    end

    it "returns an empty array from list when the account has no flags" do
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200, body: list_body([]), headers: jsonapi_headers)
      expect(flags.list).to eq([])
    end

    it "delete issues a DELETE and returns nil" do
      stub = stub_request(:delete, "#{flags_host}/api/v1/flags/checkout-v2")
             .to_return(status: 204, body: "", headers: jsonapi_headers)
      expect(flags.delete("checkout-v2")).to be_nil
      expect(stub).to have_been_requested
    end

    it "maps a 404 from get to NotFoundError" do
      stub_request(:get, "#{flags_host}/api/v1/flags/missing")
        .to_return(status: 404, body: "{}", headers: jsonapi_headers)
      expect { flags.get("missing") }.to raise_error(Smplkit::NotFoundError)
    end
  end

  # ----------------------------------------------------------------
  # Management surface: discovery buffer
  # ----------------------------------------------------------------

  describe "discovery buffer" do
    let(:declaration) do
      Smplkit::FlagDeclaration.new(id: "discovered", type: "BOOLEAN", default: false,
                                   service: "svc", environment: "staging")
    end

    it "register buffers a single declaration" do
      flags.register(declaration)
      expect(flags.pending_count).to eq(1)
    end

    it "register accepts an array of declarations" do
      other = Smplkit::FlagDeclaration.new(id: "other", type: "STRING", default: "x")
      flags.register([declaration, other])
      expect(flags.pending_count).to eq(2)
    end

    it "register(..., flush: true) POSTs to the bulk endpoint and empties the buffer" do
      stub = stub_request(:post, "#{flags_host}/api/v1/flags/bulk")
             .to_return(status: 200, body: bulk_body, headers: jsonapi_headers)
      flags.register(declaration, flush: true)
      expect(stub).to have_been_requested
      expect(flags.pending_count).to eq(0)
    end

    it "flush POSTs pending declarations to the bulk endpoint" do
      captured = nil
      stub_request(:post, "#{flags_host}/api/v1/flags/bulk").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 200, body: bulk_body, headers: jsonapi_headers)
      flags.register(declaration)
      flags.flush
      expect(captured["flags"].first["id"]).to eq("discovered")
      expect(flags.pending_count).to eq(0)
    end

    it "flush is a no-op when the buffer is empty" do
      expect { flags.flush }.not_to raise_error
      expect(a_request(:post, "#{flags_host}/api/v1/flags/bulk")).not_to have_been_made
    end

    it "flush_sync is an alias of flush" do
      stub = stub_request(:post, "#{flags_host}/api/v1/flags/bulk")
             .to_return(status: 200, body: bulk_body, headers: jsonapi_headers)
      flags.register(declaration)
      flags.flush_sync
      expect(stub).to have_been_requested
    end

    it "register spawns a background threshold flush once the buffer hits the flush size" do
      stub = stub_request(:post, "#{flags_host}/api/v1/flags/bulk")
             .to_return(status: 200, body: bulk_body, headers: jsonapi_headers)
      decls = Array.new(Smplkit::FLAG_BATCH_FLUSH_SIZE) do |i|
        Smplkit::FlagDeclaration.new(id: "d-#{i}", type: "BOOLEAN", default: false)
      end
      flags.register(decls)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
      until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
            || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        sleep 0.01
      end
      expect(stub).to have_been_requested.at_least_once
    end

    it "a declared live handle observes a declaration into the buffer" do
      stub_runtime([])
      # boolean_flag flushes during ensure_connected, then observe_declaration
      # adds a fresh entry to the now-empty buffer.
      flags.boolean_flag("observed", default: false)
      expect(flags.pending_count).to eq(1)
    end

    it "swallows errors from the background threshold flush" do
      stub_request(:post, "#{flags_host}/api/v1/flags/bulk")
        .to_return(status: 503, body: "{}", headers: jsonapi_headers)
      original_stderr = $stderr
      $stderr = StringIO.new
      flags.register(Smplkit::FlagDeclaration.new(id: "e-1", type: "BOOLEAN", default: false))
      expect { flags.send(:threshold_flush) }.not_to raise_error
      $stderr = original_stderr
    end
  end

  # ----------------------------------------------------------------
  # Lazy connect resilience
  # ----------------------------------------------------------------

  describe "lazy connect" do
    it "subscribes WebSocket handlers exactly once across repeated connects" do
      stub_runtime([])
      events = []
      allow(ws).to receive(:on).and_wrap_original do |orig, name, &blk|
        events << name
        orig.call(name, &blk)
      end
      flags._ensure_connected
      flags._ensure_connected
      expect(events).to eq(%w[flag_changed flag_deleted flags_changed])
    end

    it "tolerates a discovery flush failure before connecting" do
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 200, body: list_body([]), headers: jsonapi_headers)
      stub_request(:post, "#{flags_host}/api/v1/flags/bulk")
        .to_return(status: 503, body: "{}", headers: jsonapi_headers)
      flags.register(Smplkit::FlagDeclaration.new(id: "x", type: "BOOLEAN", default: false))
      expect { flags._ensure_connected }.not_to raise_error
      # The failed flush leaves the declaration queued.
      expect(flags.pending_count).to eq(1)
    end

    it "raises when the runtime fetch fails on connect" do
      stub_request(:get, "#{flags_host}/api/v1/flags").with(query: hash_including({}))
                                                      .to_return(status: 500, body: "{}", headers: jsonapi_headers)
      expect { flags._ensure_connected }.to raise_error(Smplkit::Error)
    end
  end

  # ----------------------------------------------------------------
  # close
  # ----------------------------------------------------------------

  describe "#close" do
    it "is a no-op for a wired client (borrows the parent WebSocket)" do
      stub_runtime([])
      flags._ensure_connected
      expect { flags.close }.not_to raise_error
    end

    it "does not stop the borrowed parent WebSocket" do
      stub_runtime([])
      flags._ensure_connected
      expect(ws).not_to receive(:stop)
      flags.close
    end
  end

  # ----------------------------------------------------------------
  # Standalone construction
  # ----------------------------------------------------------------

  describe "standalone construction" do
    it "builds its own transport + contexts client and owns its WebSocket" do
      standalone = described_class.new(
        "sk_test", environment: "staging", base_url: "https://flags.smplkit.test"
      )
      stub_request(:get, "https://flags.smplkit.test/api/v1/flags").with(query: hash_including({}))
                                                                   .to_return(status: 200, body: list_body([flag_resource("checkout-v2", environments: checkout_environments)]),
                                                                              headers: jsonapi_headers)
      # No parent: ensure_connected builds and starts its own WebSocket. Stub
      # the WS manager so no socket opens.
      fake_ws = instance_double(Smplkit::SharedWebSocket, start: nil, on: nil, stop: nil)
      allow(Smplkit::SharedWebSocket).to receive(:new).and_return(fake_ws)
      handle = standalone.boolean_flag("checkout-v2", default: false)
      ctx = [Smplkit::Context.new("user", "u-1", plan: "enterprise")]
      expect(handle.get(context: ctx)).to be(true)
      standalone.close
      expect(fake_ws).to have_received(:stop)
    end
  end

  # ----------------------------------------------------------------
  # .open convenience constructor
  # ----------------------------------------------------------------

  describe ".open" do
    it "yields a standalone client and closes it on exit" do
      # .open forwards only keyword args, so the api_key resolves from the
      # environment rather than the positional first argument.
      stub_runtime([])
      fake_ws = instance_double(Smplkit::SharedWebSocket, start: nil, on: nil, stop: nil)
      allow(Smplkit::SharedWebSocket).to receive(:new).and_return(fake_ws)
      yielded = nil
      previous_key = ENV.fetch("SMPLKIT_API_KEY", nil)
      ENV["SMPLKIT_API_KEY"] = "sk_test"
      begin
        described_class.open(environment: "staging", base_url: "https://flags.smplkit.test") do |c|
          yielded = c
          expect(c).to be_a(described_class)
          # Force a live call so the standalone client opens (and thus owns)
          # its WebSocket; close must then stop it.
          c.refresh
        end
      ensure
        ENV["SMPLKIT_API_KEY"] = previous_key
      end
      expect(yielded).to be_a(described_class)
      expect(fake_ws).to have_received(:stop)
    end
  end
end

# ====================================================================
# ResolutionCache
# ====================================================================

RSpec.describe Smplkit::Flags::ResolutionCache do
  it "reports a miss then a hit and returns the stored value" do
    cache = described_class.new(max_size: 2)
    expect(cache.get("k1")).to eq([false, nil])
    cache.put("k1", "v1")
    expect(cache.get("k1")).to eq([true, "v1"])
    expect(cache.cache_hits).to eq(1)
    expect(cache.cache_misses).to eq(1)
  end

  it "evicts the least-recently-used entry past max_size" do
    cache = described_class.new(max_size: 2)
    cache.put("k1", "v1")
    cache.put("k2", "v2")
    cache.put("k3", "v3") # evicts k1 (oldest)
    expect(cache.get("k1")).to eq([false, nil])
    expect(cache.get("k2")).to eq([true, "v2"])
    expect(cache.get("k3")).to eq([true, "v3"])
  end

  it "refreshes recency on get, protecting a re-read key from eviction" do
    cache = described_class.new(max_size: 2)
    cache.put("k1", "v1")
    cache.put("k2", "v2")
    cache.get("k1")       # k1 becomes most-recent
    cache.put("k3", "v3") # evicts k2, not k1
    expect(cache.get("k1")).to eq([true, "v1"])
    expect(cache.get("k2")).to eq([false, nil])
  end

  it "overwrites an existing key and keeps it most-recent" do
    cache = described_class.new(max_size: 2)
    cache.put("k1", "v1")
    cache.put("k1", "v1b")
    expect(cache.get("k1")).to eq([true, "v1b"])
  end

  it "clear empties the cache" do
    cache = described_class.new(max_size: 2)
    cache.put("k1", "v1")
    cache.clear
    expect(cache.get("k1")).to eq([false, nil])
  end

  it "defaults max_size to the documented constant" do
    expect(described_class::DEFAULT_MAX_SIZE).to eq(10_000)
  end
end

# ====================================================================
# FlagChangeEvent
# ====================================================================

RSpec.describe Smplkit::Flags::FlagChangeEvent do
  it "exposes id / source / deleted and a deleted? predicate" do
    event = described_class.new(id: "f", source: "websocket", deleted: true)
    expect(event.id).to eq("f")
    expect(event.source).to eq("websocket")
    expect(event.deleted).to be(true)
    expect(event).to be_deleted
  end

  it "defaults deleted to false" do
    expect(described_class.new(id: "f", source: "manual")).not_to be_deleted
  end

  it "is value-equal and hashes equally for identical fields" do
    a = described_class.new(id: "f", source: "websocket")
    b = described_class.new(id: "f", source: "websocket")
    expect(a).to eq(b)
    expect(a).to eql(b)
    expect(a.hash).to eq(b.hash)
  end

  it "is unequal for a different id, source, or deleted flag" do
    base = described_class.new(id: "f", source: "websocket")
    expect(base).not_to eq(described_class.new(id: "g", source: "websocket"))
    expect(base).not_to eq(described_class.new(id: "f", source: "manual"))
    expect(base).not_to eq(described_class.new(id: "f", source: "websocket", deleted: true))
    expect(base).not_to eq("not an event")
  end
end

# ====================================================================
# Flags module helpers
# ====================================================================

RSpec.describe Smplkit::Flags do
  describe ".contexts_to_eval_dict" do
    it "keys the eval dict by context type" do
      contexts = [
        Smplkit::Context.new("user", "u-1", plan: "enterprise"),
        Smplkit::Context.new("account", "acme", region: "us")
      ]
      dict = described_class.contexts_to_eval_dict(contexts)
      expect(dict["user"]).to eq("key" => "u-1", "plan" => "enterprise")
      expect(dict["account"]).to eq("key" => "acme", "region" => "us")
    end
  end

  describe ".hash_context" do
    it "is stable regardless of key ordering" do
      a = { "user" => { "plan" => "x", "key" => "u" } }
      b = { "user" => { "key" => "u", "plan" => "x" } }
      expect(described_class.hash_context(a)).to eq(described_class.hash_context(b))
    end

    it "differs for different content" do
      a = { "user" => { "key" => "u-1" } }
      b = { "user" => { "key" => "u-2" } }
      expect(described_class.hash_context(a)).not_to eq(described_class.hash_context(b))
    end
  end

  describe ".deep_sort" do
    it "sorts nested hash keys and recurses into arrays" do
      sorted = described_class.deep_sort({ "b" => [{ "z" => 1, "a" => 2 }], "a" => 1 })
      expect(sorted.keys).to eq(%w[a b])
      expect(sorted["b"].first.keys).to eq(%w[a z])
    end

    it "passes scalar values through unchanged" do
      expect(described_class.deep_sort(42)).to eq(42)
      expect(described_class.deep_sort("x")).to eq("x")
    end
  end
end

# ====================================================================
# JsonLogicEvaluator
# ====================================================================

RSpec.describe Smplkit::Flags::JsonLogicEvaluator do
  describe ".apply" do
    it "returns a non-hash value unchanged" do
      expect(described_class.apply("plain", {})).to eq("plain")
      expect(described_class.apply(7, {})).to eq(7)
    end

    it "returns an empty hash unchanged" do
      expect(described_class.apply({}, {})).to eq({})
    end

    it "returns false for an unknown operator" do
      expect(described_class.apply({ "weird-op" => [] }, {})).to be(false)
    end

    it "wraps a scalar operand in a single-element array" do
      # "!" with a bare false (not wrapped in an array).
      expect(described_class.apply({ "!" => false }, {})).to be(true)
    end

    describe "var" do
      it "resolves a dotted path against nested data" do
        expect(described_class.apply({ "var" => "user.plan" }, "user" => { "plan" => "enterprise" }))
          .to eq("enterprise")
      end

      it "returns the supplied default for a missing path" do
        expect(described_class.apply({ "var" => ["user.missing", "fallback"] }, "user" => {}))
          .to eq("fallback")
      end
    end

    describe "and / or / !" do
      it "ands truthy operands" do
        expect(described_class.apply({ "and" => [true, true] }, {})).to be(true)
        expect(described_class.apply({ "and" => [true, false] }, {})).to be(false)
      end

      it "ors truthy operands" do
        expect(described_class.apply({ "or" => [false, true] }, {})).to be(true)
        expect(described_class.apply({ "or" => [false, false] }, {})).to be(false)
      end

      it "negates truthiness" do
        expect(described_class.apply({ "!" => [false] }, {})).to be(true)
        expect(described_class.apply({ "!" => [true] }, {})).to be(false)
      end
    end

    describe "if" do
      it "returns the then-branch when the condition is truthy" do
        expect(described_class.apply({ "if" => [true, "yes", "no"] }, {})).to eq("yes")
      end

      it "returns the else-branch when the condition is falsy" do
        expect(described_class.apply({ "if" => [false, "yes", "no"] }, {})).to eq("no")
      end

      it "supports elsif chains" do
        logic = { "if" => [false, "a", true, "b", "c"] }
        expect(described_class.apply(logic, {})).to eq("b")
      end

      it "returns nil when no branch matches and there is no else" do
        expect(described_class.apply({ "if" => [false, "a"] }, {})).to be_nil
      end
    end

    describe "equality" do
      it "evaluates == and ===" do
        expect(described_class.apply({ "==" => [1, 1] }, {})).to be(true)
        expect(described_class.apply({ "==" => [1, 2] }, {})).to be(false)
        expect(described_class.apply({ "===" => %w[a a] }, {})).to be(true)
      end

      it "evaluates != and !==" do
        expect(described_class.apply({ "!=" => [1, 2] }, {})).to be(true)
        expect(described_class.apply({ "!=" => [1, 1] }, {})).to be(false)
        expect(described_class.apply({ "!==" => %w[a b] }, {})).to be(true)
      end
    end

    describe "comparisons" do
      it "evaluates < <= > >=" do
        expect(described_class.apply({ "<" => [1, 2] }, {})).to be(true)
        expect(described_class.apply({ "<=" => [2, 2] }, {})).to be(true)
        expect(described_class.apply({ ">" => [3, 2] }, {})).to be(true)
        expect(described_class.apply({ ">=" => [2, 2] }, {})).to be(true)
        expect(described_class.apply({ ">" => [1, 2] }, {})).to be(false)
      end

      it "supports a three-operand between comparison" do
        expect(described_class.apply({ "<" => [1, 2, 3] }, {})).to be(true)
        expect(described_class.apply({ "<" => [1, 5, 3] }, {})).to be(false)
      end

      it "returns false when an operand resolves to nil" do
        expect(described_class.apply({ "<" => [{ "var" => "missing" }, 2] }, {})).to be(false)
      end

      it "returns false for an unsupported operand count" do
        expect(described_class.apply({ "<" => [1] }, {})).to be(false)
        expect(described_class.apply({ "<" => [1, 2, 3, 4] }, {})).to be(false)
      end

      it "returns false when operands are not comparable" do
        expect(described_class.apply({ "<" => ["a", 2] }, {})).to be(false)
      end
    end

    describe "in" do
      it "is true when the needle is present in the haystack" do
        expect(described_class.apply({ "in" => ["a", %w[a b]] }, {})).to be(true)
      end

      it "is false when the needle is absent" do
        expect(described_class.apply({ "in" => ["c", %w[a b]] }, {})).to be(false)
      end

      it "matches a substring inside a String haystack" do
        expect(described_class.apply({ "in" => %w[ell hello] }, {})).to be(true)
      end

      it "is false when the haystack is nil" do
        expect(described_class.apply({ "in" => ["a", { "var" => "missing" }] }, {})).to be(false)
      end

      it "is false when the haystack does not support include?" do
        expect(described_class.apply({ "in" => ["a", 5] }, {})).to be(false)
      end
    end

    describe "missing" do
      it "returns the subset of keys absent from data" do
        result = described_class.apply({ "missing" => %w[a b c] }, "a" => 1, "c" => 3)
        expect(result).to eq(["b"])
      end

      it "returns an empty array when every key is present" do
        expect(described_class.apply({ "missing" => ["a"] }, "a" => 1)).to eq([])
      end

      it "treats an empty-string value as missing" do
        expect(described_class.apply({ "missing" => ["a"] }, "a" => "")).to eq(["a"])
      end

      it "accepts a single non-array key argument" do
        expect(described_class.apply({ "missing" => "a" }, {})).to eq(["a"])
      end
    end

    describe "none" do
      it "is true when no element of the resolved array matches the inner test" do
        data = { "users" => [{ "plan" => "free" }, { "plan" => "basic" }] }
        logic = { "none" => [{ "var" => "users" }, { "==" => [{ "var" => "plan" }, "enterprise"] }] }
        expect(described_class.apply(logic, data)).to be(true)
      end

      it "is false when some element matches the inner test" do
        data = { "users" => [{ "plan" => "free" }, { "plan" => "enterprise" }] }
        logic = { "none" => [{ "var" => "users" }, { "==" => [{ "var" => "plan" }, "enterprise"] }] }
        expect(described_class.apply(logic, data)).to be(false)
      end

      it "treats a nil array as an empty collection (vacuously true)" do
        logic = { "none" => [{ "var" => "missing" }, { "==" => [1, 1] }] }
        expect(described_class.apply(logic, {})).to be(true)
      end

      it "is false when the resolved value is not an array" do
        logic = { "none" => [{ "var" => "scalar" }, { "==" => [1, 1] }] }
        expect(described_class.apply(logic, "scalar" => "x")).to be(false)
      end
    end
  end

  describe ".truthy?" do
    it "treats nil, false, 0, empty string, and empty array as falsy" do
      [nil, false, 0, 0.0, "", []].each do |v|
        expect(described_class.truthy?(v)).to be(false)
      end
    end

    it "treats non-empty / non-zero values as truthy" do
      [true, 1, "x", [1], { "a" => 1 }].each do |v|
        expect(described_class.truthy?(v)).to be(true)
      end
    end
  end

  describe ".resolve_var" do
    it "returns the whole data object for an empty path" do
      expect(described_class.resolve_var("", { "a" => 1 })).to eq({ "a" => 1 })
      expect(described_class.resolve_var(nil, { "a" => 1 })).to eq({ "a" => 1 })
      expect(described_class.resolve_var([], { "a" => 1 })).to eq({ "a" => 1 })
    end

    it "resolves an array path" do
      expect(described_class.resolve_var(%w[user plan], "user" => { "plan" => "pro" })).to eq("pro")
    end

    it "indexes into an array by a numeric path segment" do
      expect(described_class.resolve_var("items.1", "items" => %w[a b c])).to eq("b")
    end

    it "returns the default when traversing into a nil scope" do
      expect(described_class.resolve_var("a.b.c", { "a" => nil }, "dflt")).to eq("dflt")
    end

    it "returns the default when indexing a non-hash, non-array scope" do
      expect(described_class.resolve_var("a.b", { "a" => 5 }, "dflt")).to eq("dflt")
    end

    it "resolves symbol-keyed data" do
      expect(described_class.resolve_var("plan", { plan: "pro" })).to eq("pro")
    end

    it "returns the default when the final value is nil" do
      expect(described_class.resolve_var("a", { "a" => nil }, "dflt")).to eq("dflt")
    end
  end

  describe ".present?" do
    it "is false for nil and empty string, true otherwise" do
      expect(described_class.present?(nil)).to be(false)
      expect(described_class.present?("")).to be(false)
      expect(described_class.present?("x")).to be(true)
      expect(described_class.present?(0)).to be(true)
    end
  end
end
# rubocop:enable RSpec/ExpectOutput, Layout/LineLength, RSpec/MultipleExpectations
