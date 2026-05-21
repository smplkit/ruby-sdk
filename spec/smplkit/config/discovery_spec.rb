# frozen_string_literal: true

require "spec_helper"

# Tests for the declarative discovery API (ADR-037 §2.13/§2.14):
#   1. +ConfigClient#get_or_create+ — idempotency, parent-by-reference, observe wiring.
#   2. +LiveConfigProxy+ typed getters — happy paths, mismatch paths, default fallback.
#   3. +ConfigNamespace+ register_config / register_config_item / flush.

RSpec.describe "Smplkit::Config discovery" do
  let(:parent) do
    parent = double("Smplkit::Client",
                    _environment: "production",
                    _service: "showcase-billing",
                    _ensure_ws: double("ws", on: nil),
                    _config_transport: double("transport"))
    allow(parent._config_transport).to receive(:fetch_chain).and_return([])
    parent
  end
  let(:mgmt_config) do
    instance_double(Smplkit::ManagementClient::ConfigNamespace,
                    flush: nil,
                    register_config: nil,
                    register_config_item: nil,
                    pending_count: 0)
  end
  let(:manage) { double("ManagementClient", config: mgmt_config) }
  let(:client) { Smplkit::Config::ConfigClient.new(parent, manage: manage, metrics: nil) }

  # ------------------------------------------------------------------
  # ConfigClient#get_or_create
  # ------------------------------------------------------------------

  describe "#get_or_create" do
    it "returns a LiveConfigProxy bound to the requested id" do
      proxy = client.get_or_create("billing")
      expect(proxy).to be_a(Smplkit::Config::LiveConfigProxy)
      expect(proxy.config_id).to eq("billing")
    end

    it "is idempotent — repeat calls return the same instance" do
      a = client.get_or_create("billing")
      b = client.get_or_create("billing")
      expect(a).to equal(b)
    end

    it "accepts a parent String id" do
      expect(mgmt_config).to receive(:register_config).with(
        "billing", hash_including(parent: "common")
      )
      client.get_or_create("billing", parent: "common")
    end

    it "accepts a parent LiveConfigProxy and uses its config_id" do
      common = client.get_or_create("common")
      expect(mgmt_config).to receive(:register_config).with(
        "billing", hash_including(parent: "common")
      )
      client.get_or_create("billing", parent: common)
    end

    it "rejects an invalid parent type" do
      expect { client.get_or_create("billing", parent: 42) }
        .to raise_error(ArgumentError, /String id or LiveConfigProxy/)
    end

    it "flushes any pending discovery declarations before lazy init" do
      expect(mgmt_config).to receive(:flush)
      client.get_or_create("billing")
    end

    it "does not raise NotFoundError for an unknown id" do
      expect { client.get_or_create("brand-new") }.not_to raise_error
    end
  end

  # ------------------------------------------------------------------
  # ConfigClient#get — NotFoundError parity
  # ------------------------------------------------------------------

  describe "#get with an unknown id" do
    it "raises NotFoundError" do
      expect { client.get("missing") }.to raise_error(Smplkit::NotFoundError)
    end
  end

  # ------------------------------------------------------------------
  # LiveConfigProxy typed getters
  # ------------------------------------------------------------------

  describe Smplkit::Config::LiveConfigProxy do
    let(:proxy) { client.get_or_create("billing") }

    let(:billing_items) do
      {
        "max_seats" => { "value" => 25, "type" => "NUMBER" },
        "tier" => { "value" => "pro", "type" => "STRING" },
        "enabled" => { "value" => true, "type" => "BOOLEAN" },
        "ratio" => { "value" => 1.5, "type" => "NUMBER" },
        "payload" => { "value" => { "k" => "v" }, "type" => "JSON" }
      }
    end

    before do
      # Stub the parent's transport to return a chain so resolve() returns values.
      chain = [{ "id" => "billing", "items" => billing_items, "environments" => {} }]
      allow(parent._config_transport).to receive(:fetch_chain).and_return(chain)
    end

    it "#config_id exposes the bound id" do
      expect(proxy.config_id).to eq("billing")
    end

    it "#get_bool reads BOOLEAN values" do
      expect(proxy.get_bool("enabled", false)).to be true
    end

    it "#get_bool returns default for missing key" do
      expect(proxy.get_bool("missing", true)).to be true
    end

    it "#get_bool returns default on type mismatch" do
      expect(proxy.get_bool("tier", false)).to be false
    end

    it "#get_int reads NUMBER values" do
      expect(proxy.get_int("max_seats", 0)).to eq(25)
    end

    it "#get_int returns default for missing key" do
      expect(proxy.get_int("missing", 7)).to eq(7)
    end

    it "#get_int rejects booleans" do
      expect(proxy.get_int("enabled", 99)).to eq(99)
    end

    it "#get_int rejects strings" do
      expect(proxy.get_int("tier", 99)).to eq(99)
    end

    it "#get_int rejects fractional floats" do
      expect(proxy.get_int("ratio", 0)).to eq(0)
    end

    it "#get_float reads NUMBER values" do
      expect(proxy.get_float("ratio", 0.0)).to eq(1.5)
    end

    it "#get_float coerces integral numbers to float" do
      expect(proxy.get_float("max_seats", 0.0)).to eq(25.0)
    end

    it "#get_float returns default for missing key" do
      expect(proxy.get_float("missing", 2.5)).to eq(2.5)
    end

    it "#get_float rejects booleans" do
      expect(proxy.get_float("enabled", 9.9)).to eq(9.9)
    end

    it "#get_float rejects strings" do
      expect(proxy.get_float("tier", 3.14)).to eq(3.14)
    end

    it "#get_string reads STRING values" do
      expect(proxy.get_string("tier", "free")).to eq("pro")
    end

    it "#get_string returns default for missing key" do
      expect(proxy.get_string("missing", "fallback")).to eq("fallback")
    end

    it "#get_string returns default on type mismatch" do
      expect(proxy.get_string("max_seats", "default")).to eq("default")
    end

    it "#get_json reads any value" do
      expect(proxy.get_json("payload", nil)).to eq("k" => "v")
    end

    it "#get_json returns default for missing key" do
      expect(proxy.get_json("missing", "default")).to eq("default")
    end

    it "registers each typed-getter call on first invocation" do
      expect(mgmt_config).to receive(:register_config_item)
        .with("billing", "max_seats", "NUMBER", 5, "Default seats.")
      proxy.get_int("max_seats", 5, description: "Default seats.")
    end

    it "#on_change forwards to the client (config-scoped)" do
      called = []
      proxy.on_change { |evt| called << evt }
      client.send(:fire_change_listeners, "billing", "websocket")
      expect(called.length).to eq(1)
    end

    it "#on_change(item_key) forwards to the client (item-scoped)" do
      called = []
      proxy.on_change("max_seats") { |evt| called << evt }
      client.send(:fire_change_listeners, "billing", "websocket")
      expect(called.length).to eq(1)
    end

    it "item-scoped listener exceptions are swallowed" do
      proxy.on_change("max_seats") { raise "boom" }
      expect { client.send(:fire_change_listeners, "billing", "websocket") }.not_to raise_error
    end

    it "#refresh invalidates the cached resolution" do
      expect(client).to receive(:_invalidate).with("billing")
      proxy.refresh
    end

    it "#[] and #get traverse dotted keys" do
      dotted = [{ "id" => "billing-dotted",
                  "items" => { "db" => { "value" => { "host" => "h" }, "type" => "JSON" } } }]
      allow(parent._config_transport).to receive(:fetch_chain).with("billing-dotted").and_return(dotted)
      proxy2 = client.get_or_create("billing-dotted")
      client._invalidate("billing-dotted")
      expect(proxy2["db.host"]).to eq("h")
      expect(proxy2.get(nil)).to eq("db" => { "host" => "h" })
    end

    it "#to_h returns a copy of the snapshot" do
      h = proxy.to_h
      expect(h["tier"]).to eq("pro")
    end
  end

  # ------------------------------------------------------------------
  # ConfigClient internals — observe + _invalidate
  # ------------------------------------------------------------------

  describe "internals" do
    it "_observe_config_declaration delegates to manage.config.register_config" do
      expect(mgmt_config).to receive(:register_config).with(
        "billing", service: "showcase-billing", environment: "production",
                   parent: "common", name: "Billing", description: "Plan limits"
      )
      client.send(:_observe_config_declaration,
                  "billing", parent: "common", name: "Billing", description: "Plan limits")
    end

    it "_observe_item_declaration delegates to manage.config.register_config_item" do
      expect(mgmt_config).to receive(:register_config_item)
        .with("billing", "max_seats", "NUMBER", 5, "seats")
      client.send(:_observe_item_declaration, "billing", "max_seats", "NUMBER", 5, "seats")
    end

    it "_invalidate clears the resolved snapshot for a key" do
      chain_v1 = [{ "id" => "billing", "items" => { "k" => { "value" => "v", "type" => "STRING" } } }]
      chain_v2 = [{ "id" => "billing", "items" => { "k" => { "value" => "v2", "type" => "STRING" } } }]
      allow(parent._config_transport).to receive(:fetch_chain).with("billing").and_return(chain_v1)
      proxy = client.get_or_create("billing")
      expect(proxy["k"]).to eq("v")
      client._invalidate("billing")
      allow(parent._config_transport).to receive(:fetch_chain).with("billing").and_return(chain_v2)
      expect(proxy["k"]).to eq("v2")
    end

    it "live() returns the cached proxy for a key" do
      a = client.live("alpha")
      b = client.live("alpha")
      expect(a).to equal(b)
    end

    it "on_change_item requires a block" do
      expect { client.on_change_item("billing", "max_seats") }.to raise_error(ArgumentError)
    end
  end
end

# ------------------------------------------------------------------
# ConfigNamespace discovery (register_config / register_config_item / flush)
# ------------------------------------------------------------------

RSpec.describe Smplkit::ManagementClient::ConfigNamespace do
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:mgmt) { Smplkit::ManagementClient.from_resolved(resolved) }
  let(:api) { mgmt.config.instance_variable_get(:@api) }

  describe "#register_config" do
    it "queues a declaration on the buffer" do
      mgmt.config.register_config("billing", service: "svc", environment: "prod",
                                             parent: "common", name: "Billing", description: "Plan limits")
      expect(mgmt.config.pending_count).to eq(1)
    end
  end

  describe "#register_config_item" do
    it "queues an item declaration after declare" do
      mgmt.config.register_config("billing", service: "svc", environment: "prod")
      mgmt.config.register_config_item("billing", "max_seats", "NUMBER", 5, "seats")
      mgmt.config.register_config_item("billing", "tier", "STRING", "free")
      mgmt.config.register_config_item("billing", "enabled", "BOOLEAN", false)
      mgmt.config.register_config_item("billing", "payload", "JSON", { "k" => "v" })
      expect(mgmt.config.pending_count).to eq(1)
    end
  end

  describe "#flush" do
    it "is a no-op when nothing is pending" do
      expect(api).not_to receive(:bulk_register_configs)
      mgmt.config.flush
    end

    it "POSTs declarations to the bulk endpoint" do
      mgmt.config.register_config("billing", service: "svc", environment: "prod",
                                             name: "Billing", description: "Plan limits")
      mgmt.config.register_config_item("billing", "max_seats", "NUMBER", 5, "seats")

      received_body = nil
      allow(api).to receive(:bulk_register_configs) { |body| received_body = body }
      mgmt.config.flush
      expect(received_body).not_to be_nil
      expect(received_body.configs.first.id).to eq("billing")
      expect(received_body.configs.first.items["max_seats"].value).to eq(5)
      expect(mgmt.config.pending_count).to eq(0)
    end

    it "swallows server errors per ADR-024 §2.9" do
      mgmt.config.register_config("billing", service: "svc", environment: "prod")
      allow(api).to receive(:bulk_register_configs).and_raise(StandardError, "boom")
      expect { mgmt.config.flush }.not_to raise_error
      expect(mgmt.config.pending_count).to eq(0)
    end

    it "threshold-triggers a background flush at 50 declarations" do
      allow(api).to receive(:bulk_register_configs)
      51.times { |i| mgmt.config.register_config("cfg-#{i}", service: "svc", environment: "prod") }
      # Wait briefly for the background thread (capped at 5s).
      deadline = Time.now + 5
      sleep(0.05) while mgmt.config.pending_count > 0 && Time.now < deadline
      expect(mgmt.config.pending_count).to eq(0)
    end

    it "background-thread errors are caught and logged (do not crash the thread)" do
      # Make flush itself raise — the rescue inside the spawned Thread
      # should swallow the exception so the daemon thread exits cleanly.
      allow(mgmt.config).to receive(:flush).and_raise(StandardError, "boom in flush")
      threads_before = Thread.list.size
      51.times { |i| mgmt.config.register_config("err-#{i}", service: "svc", environment: "prod") }
      # Give the spawned thread time to run.
      sleep(0.2)
      # No exception leaks; thread count returns to (or close to) baseline.
      expect(Thread.list.size).to be <= threads_before + 1
    end
  end
end
