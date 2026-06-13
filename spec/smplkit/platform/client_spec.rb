# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength

RSpec.describe Smplkit::Platform do
  describe ".split_context_id" do
    it "returns [type, key] when both args are given" do
      expect(described_class.split_context_id("user", "u-1")).to eq(%w[user u-1])
    end

    it "splits a composite 'type:key' string when key is nil" do
      expect(described_class.split_context_id("user:u-1", nil)).to eq(%w[user u-1])
    end

    it "splits only on the first colon" do
      expect(described_class.split_context_id("user:a:b", nil)).to eq(["user", "a:b"])
    end

    it "raises ArgumentError on a non-composite single arg" do
      expect { described_class.split_context_id("user-only", nil) }.to raise_error(ArgumentError, /type:key/)
    end
  end

  describe ".app_transport" do
    it "builds an app ApiClient from base_domain/scheme when base_url is nil" do
      http = described_class.app_transport(
        api_key: "k", base_url: nil, profile: nil,
        base_domain: "smplkit.test", scheme: "https", debug: false, extra_headers: nil
      )
      expect(http).to be_a(SmplkitGeneratedClient::App::ApiClient)
      expect(http.config.host).to eq("app.smplkit.test")
      expect(http.config.scheme).to eq("https")
      expect(http.config.access_token).to eq("k")
    end

    it "honours an explicit base_url and merged extra headers" do
      http = described_class.app_transport(
        api_key: "k", base_url: "https://app.smplkit.test:9000", profile: nil,
        base_domain: "smplkit.test", scheme: "https", debug: false, extra_headers: { "X-Custom" => "yes" }
      )
      expect(http.config.host).to eq("app.smplkit.test:9000")
      expect(http.default_headers["X-Custom"]).to eq("yes")
    end
  end
end

RSpec.describe Smplkit::Platform::PlatformClient do
  subject(:platform) { described_class.new(app_transport: app_http, context_buffer: buffer) }

  let(:tcfg) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:app_http) { Smplkit::Transport.build_api_client(SmplkitGeneratedClient::App, "app", tcfg) }
  let(:buffer) { Smplkit::ContextRegistrationBuffer.new }
  let(:host) { "https://app.smplkit.test" }
  let(:jsonapi) { { "Content-Type" => "application/vnd.api+json" } }

  def env_resource(id: "production", name: "Production", color: "#ef4444", classification: "STANDARD")
    {
      "id" => id, "type" => "environment",
      "attributes" => {
        "name" => name, "color" => color, "classification" => classification,
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-02T00:00:00Z"
      }
    }
  end

  def service_resource(id: "billing", name: "Billing")
    {
      "id" => id, "type" => "service",
      "attributes" => {
        "name" => name, "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-02T00:00:00Z"
      }
    }
  end

  def context_type_resource(id: "user", name: "User", attributes: {})
    {
      "id" => id, "type" => "context_type",
      "attributes" => {
        "name" => name, "attributes" => attributes,
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-02T00:00:00Z"
      }
    }
  end

  def context_resource(type: "user", key: "u-1", attributes: { "plan" => "gold" }, name: "u-1")
    {
      "id" => "#{type}:#{key}", "type" => "context",
      "attributes" => {
        "context_type" => type, "key" => key, "name" => name, "attributes" => attributes,
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-02T00:00:00Z"
      }
    }
  end

  # The generated *ListResponse models require a non-nil meta block.
  def list_body(data)
    JSON.generate("data" => data, "meta" => { "pagination" => { "page" => 1, "size" => 1000 } })
  end

  # -----------------------------------------------------------------------
  # EnvironmentsClient
  # -----------------------------------------------------------------------
  describe "#environments" do
    it "new builds an unsaved Environment with defaults" do
      env = platform.environments.new("staging", name: "Staging")
      expect(env).to be_a(Smplkit::Platform::Environment)
      expect(env.id).to eq("staging")
      expect(env.classification).to eq(Smplkit::EnvironmentClassification::STANDARD)
      expect(env.color).to be_nil
    end

    it "list maps resources (with page params)" do
      stub_request(:get, "#{host}/api/v1/environments")
        .with(query: { "page[number]" => "2", "page[size]" => "10" })
        .to_return(status: 200, body: list_body([env_resource]), headers: jsonapi)
      envs = platform.environments.list(page_number: 2, page_size: 10)
      expect(envs.length).to eq(1)
      expect(envs.first.id).to eq("production")
      expect(envs.first.color).to be_a(Smplkit::Color)
      expect(envs.first.classification).to eq(Smplkit::EnvironmentClassification::STANDARD)
    end

    it "list tolerates a nil data array" do
      stub_request(:get, "#{host}/api/v1/environments")
        .to_return(status: 200, body: list_body(nil), headers: jsonapi)
      expect(platform.environments.list).to eq([])
    end

    it "get maps an AD_HOC environment with a nil color" do
      stub_request(:get, "#{host}/api/v1/environments/preview")
        .to_return(status: 200, body: JSON.generate("data" => env_resource(id: "preview", color: nil, classification: "AD_HOC")), headers: jsonapi)
      env = platform.environments.get("preview")
      expect(env.classification).to eq(Smplkit::EnvironmentClassification::AD_HOC)
      expect(env.color).to be_nil
    end

    it "delete sends DELETE and returns nil" do
      stub_request(:delete, "#{host}/api/v1/environments/staging").to_return(status: 204, body: "")
      expect(platform.environments.delete("staging")).to be_nil
    end

    it "Environment#save creates then updates via the client" do
      create_stub = stub_request(:post, "#{host}/api/v1/environments")
                    .to_return(status: 201, body: JSON.generate("data" => env_resource), headers: jsonapi)
      env = platform.environments.new("production", name: "Production", color: "#ef4444")
      env.save
      expect(env.created_at).to be_a(Time)
      expect(create_stub).to have_been_requested

      update_stub = stub_request(:put, "#{host}/api/v1/environments/production")
                    .to_return(status: 200, body: JSON.generate("data" => env_resource(name: "Prod")), headers: jsonapi)
      env.name = "Prod"
      env.save
      expect(env.name).to eq("Prod")
      expect(update_stub).to have_been_requested
    end

    it "_update raises when the id is nil" do
      env = Smplkit::Platform::Environment.new(platform.environments, id: nil, name: "X")
      expect { platform.environments._update(env) }.to raise_error(RuntimeError, /no id/)
    end
  end

  # -----------------------------------------------------------------------
  # ServicesClient
  # -----------------------------------------------------------------------
  describe "#services" do
    it "new builds an unsaved Service" do
      svc = platform.services.new("billing", name: "Billing")
      expect(svc).to be_a(Smplkit::Platform::Service)
      expect(svc.id).to eq("billing")
    end

    it "list maps resources" do
      stub_request(:get, "#{host}/api/v1/services")
        .to_return(status: 200, body: list_body([service_resource]), headers: jsonapi)
      svcs = platform.services.list
      expect(svcs.length).to eq(1)
      expect(svcs.first.name).to eq("Billing")
    end

    it "list tolerates nil data" do
      stub_request(:get, "#{host}/api/v1/services")
        .with(query: { "page[number]" => "1", "page[size]" => "5" })
        .to_return(status: 200, body: list_body(nil), headers: jsonapi)
      expect(platform.services.list(page_number: 1, page_size: 5)).to eq([])
    end

    it "get maps a single resource" do
      stub_request(:get, "#{host}/api/v1/services/billing")
        .to_return(status: 200, body: JSON.generate("data" => service_resource), headers: jsonapi)
      expect(platform.services.get("billing").id).to eq("billing")
    end

    it "delete sends DELETE and returns nil" do
      stub_request(:delete, "#{host}/api/v1/services/billing").to_return(status: 204, body: "")
      expect(platform.services.delete("billing")).to be_nil
    end

    it "Service#save uses ServiceCreateRequest on create and ServiceRequest on update" do
      stub_request(:post, "#{host}/api/v1/services")
        .to_return(status: 201, body: JSON.generate("data" => service_resource), headers: jsonapi)
      svc = platform.services.new("billing", name: "Billing")
      svc.save
      expect(svc.created_at).to be_a(Time)

      update_stub = stub_request(:put, "#{host}/api/v1/services/billing")
                    .to_return(status: 200, body: JSON.generate("data" => service_resource(name: "Bill")), headers: jsonapi)
      svc.name = "Bill"
      svc.save
      expect(svc.name).to eq("Bill")
      expect(update_stub).to have_been_requested
    end

    it "_update raises when the id is nil" do
      svc = Smplkit::Platform::Service.new(platform.services, id: nil, name: "X")
      expect { platform.services._update(svc) }.to raise_error(RuntimeError, /no id/)
    end
  end

  # -----------------------------------------------------------------------
  # ContextTypesClient
  # -----------------------------------------------------------------------
  describe "#context_types" do
    it "new derives the name from the id by default" do
      ct = platform.context_types.new("user")
      expect(ct).to be_a(Smplkit::Platform::ContextType)
      expect(ct.name).to eq("user")
      expect(ct.attributes).to eq({})
    end

    it "new accepts an explicit name and attributes" do
      ct = platform.context_types.new("user", name: "User", attributes: { "plan" => { "type" => "string" } })
      expect(ct.name).to eq("User")
      expect(ct.attributes).to eq("plan" => { "type" => "string" })
    end

    it "list maps resources, coercing non-hash attribute metadata to {}" do
      stub_request(:get, "#{host}/api/v1/context_types")
        .to_return(status: 200, body: list_body([context_type_resource(attributes: nil)]), headers: jsonapi)
      types = platform.context_types.list
      expect(types.length).to eq(1)
      expect(types.first.attributes).to eq({})
    end

    it "list tolerates nil data" do
      stub_request(:get, "#{host}/api/v1/context_types")
        .to_return(status: 200, body: list_body(nil), headers: jsonapi)
      expect(platform.context_types.list).to eq([])
    end

    it "get maps a single resource with attribute metadata" do
      stub_request(:get, "#{host}/api/v1/context_types/user")
        .to_return(status: 200, body: JSON.generate("data" => context_type_resource(attributes: { "plan" => { "type" => "string" } })), headers: jsonapi)
      ct = platform.context_types.get("user")
      expect(ct.attributes).to eq("plan" => { "type" => "string" })
    end

    it "delete sends DELETE and returns nil" do
      stub_request(:delete, "#{host}/api/v1/context_types/user").to_return(status: 204, body: "")
      expect(platform.context_types.delete("user")).to be_nil
    end

    it "round-trips attribute mutations through save (create then update)" do
      create_stub = stub_request(:post, "#{host}/api/v1/context_types")
                    .with(body: hash_including("data" => hash_including("attributes" => hash_including("attributes" => { "plan" => { "type" => "string" } }))))
                    .to_return(status: 201, body: JSON.generate("data" => context_type_resource(attributes: { "plan" => { "type" => "string" } })), headers: jsonapi)
      ct = platform.context_types.new("user", name: "User")
      ct.add_attribute("plan", type: "string")
      ct.save
      expect(create_stub).to have_been_requested
      expect(ct.attributes).to eq("plan" => { "type" => "string" })

      update_stub = stub_request(:put, "#{host}/api/v1/context_types/user")
                    .with(body: hash_including("data" => hash_including("attributes" => hash_including("attributes" => { "tier" => { "type" => "number" } }))))
                    .to_return(status: 200, body: JSON.generate("data" => context_type_resource(attributes: { "tier" => { "type" => "number" } })), headers: jsonapi)
      ct.remove_attribute("plan")
      ct.update_attribute("tier", type: "number")
      ct.save
      expect(update_stub).to have_been_requested
      expect(ct.attributes).to eq("tier" => { "type" => "number" })
    end

    it "_update raises when the id is nil" do
      ct = Smplkit::Platform::ContextType.new(platform.context_types, id: nil, name: "X")
      expect { platform.context_types._update(ct) }.to raise_error(RuntimeError, /no id/)
    end
  end

  # -----------------------------------------------------------------------
  # ContextsClient
  # -----------------------------------------------------------------------
  describe "#contexts" do
    it "register buffers a single context and reports pending_count" do
      platform.contexts.register(Smplkit::Context.new("user", "u-1", plan: "gold"))
      expect(platform.contexts.pending_count).to eq(1)
      expect(WebMock).not_to have_requested(:any, /smplkit.test/)
    end

    it "register buffers an array of contexts" do
      platform.contexts.register([
                                   Smplkit::Context.new("user", "u-1"),
                                   Smplkit::Context.new("user", "u-2")
                                 ])
      expect(platform.contexts.pending_count).to eq(2)
    end

    it "register with flush:true posts the bulk batch immediately" do
      stub = stub_request(:post, "#{host}/api/v1/contexts/bulk")
             .with { |req| JSON.parse(req.body)["contexts"].first.values_at("type", "key") == %w[user u-1] }
             .to_return(status: 200, body: JSON.generate("registered" => 1), headers: jsonapi)
      platform.contexts.register(Smplkit::Context.new("user", "u-1", plan: "gold"), flush: true)
      expect(stub).to have_been_requested
      expect(platform.contexts.pending_count).to eq(0)
    end

    it "flush no-ops when the buffer is empty" do
      platform.contexts.flush
      expect(WebMock).not_to have_requested(:post, "#{host}/api/v1/contexts/bulk")
    end

    it "flush drains the buffer to the bulk endpoint" do
      stub = stub_request(:post, "#{host}/api/v1/contexts/bulk")
             .to_return(status: 200, body: JSON.generate("registered" => 1), headers: jsonapi)
      platform.contexts.register(Smplkit::Context.new("account", "acme"))
      platform.contexts.flush
      expect(stub).to have_been_requested
      expect(platform.contexts.pending_count).to eq(0)
    end

    it "register spawns a background threshold flush once the batch size is reached" do
      stub = stub_request(:post, "#{host}/api/v1/contexts/bulk")
             .to_return(status: 200, body: JSON.generate("registered" => 100), headers: jsonapi)
      batch = (0...Smplkit::CONTEXT_BATCH_FLUSH_SIZE).map { |i| Smplkit::Context.new("user", "u-#{i}") }
      platform.contexts.register(batch)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
      until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? ||
            Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        sleep 0.02
      end
      expect(stub).to have_been_requested
    end

    it "list filters by context type" do
      stub_request(:get, "#{host}/api/v1/contexts")
        .with(query: { "filter[context_type]" => "user" })
        .to_return(status: 200, body: list_body([context_resource]), headers: jsonapi)
      contexts = platform.contexts.list("user")
      expect(contexts.length).to eq(1)
      expect(contexts.first).to be_a(Smplkit::Context)
      expect(contexts.first.type).to eq("user")
      expect(contexts.first.key).to eq("u-1")
    end

    it "list tolerates nil data and forwards page params" do
      stub_request(:get, "#{host}/api/v1/contexts")
        .with(query: { "filter[context_type]" => "user", "page[number]" => "1", "page[size]" => "5" })
        .to_return(status: 200, body: list_body(nil), headers: jsonapi)
      expect(platform.contexts.list("user", page_number: 1, page_size: 5)).to eq([])
    end

    it "get accepts a composite id" do
      stub_request(:get, "#{host}/api/v1/contexts/user:u-1")
        .to_return(status: 200, body: JSON.generate("data" => context_resource), headers: jsonapi)
      ctx = platform.contexts.get("user:u-1")
      expect(ctx.type).to eq("user")
      expect(ctx.key).to eq("u-1")
    end

    it "get accepts a two-arg type/key" do
      stub_request(:get, "#{host}/api/v1/contexts/user:u-1")
        .to_return(status: 200, body: JSON.generate("data" => context_resource), headers: jsonapi)
      ctx = platform.contexts.get("user", "u-1")
      expect(ctx.id).to eq("user:u-1")
    end

    it "delete accepts a two-arg type/key and returns nil" do
      stub_request(:delete, "#{host}/api/v1/contexts/user:u-1").to_return(status: 204, body: "")
      expect(platform.contexts.delete("user", "u-1")).to be_nil
    end

    it "context_from_resource derives type/key from the id when attributes omit them" do
      # The generated Context model requires context_type, so this defensive
      # id-split fallback is only reachable by calling the builder directly.
      ctx = platform.contexts.send(:context_from_resource, { "id" => "account:acme", "attributes" => {} })
      expect(ctx.type).to eq("account")
      expect(ctx.key).to eq("acme")
    end

    it "Context#save round-trips through _save_context" do
      stub = stub_request(:put, "#{host}/api/v1/contexts/user:u-1")
             .to_return(status: 200, body: JSON.generate("data" => context_resource(name: "Renamed")), headers: jsonapi)
      # placeholder to satisfy lints
      get_stub = stub_request(:get, "#{host}/api/v1/contexts/user:u-1")
                 .to_return(status: 200, body: JSON.generate("data" => context_resource), headers: jsonapi)
      ctx = platform.contexts.get("user:u-1")
      expect(get_stub).to have_been_requested
      ctx.name = "Renamed"
      ctx.save
      expect(stub).to have_been_requested
      expect(ctx.name).to eq("Renamed")
    end
  end

  # -----------------------------------------------------------------------
  # error mapping
  # -----------------------------------------------------------------------
  describe "error mapping" do
    it "maps a 404 to NotFoundError" do
      body = JSON.generate("errors" => [{ "status" => "404", "detail" => "missing" }])
      stub_request(:get, "#{host}/api/v1/environments/missing")
        .to_return(status: 404, body: body, headers: jsonapi)
      expect { platform.environments.get("missing") }.to raise_error(Smplkit::NotFoundError)
    end
  end

  # -----------------------------------------------------------------------
  # construction / lifecycle
  # -----------------------------------------------------------------------
  describe "construction" do
    it "wired construction borrows the transport and close is a near no-op" do
      expect(platform.close).to be_nil
    end

    it "wires sub-clients" do
      expect(platform.environments).to be_a(Smplkit::Platform::EnvironmentsClient)
      expect(platform.services).to be_a(Smplkit::Platform::ServicesClient)
      expect(platform.contexts).to be_a(Smplkit::Platform::ContextsClient)
      expect(platform.context_types).to be_a(Smplkit::Platform::ContextTypesClient)
    end

    it "defaults its own context buffer when none is supplied" do
      wired = described_class.new(app_transport: app_http)
      expect(wired.contexts.pending_count).to eq(0)
      wired.close
    end

    it "standalone construction builds and owns its own transport; close returns nil" do
      standalone = described_class.new(api_key: "k", base_domain: "smplkit.test", scheme: "https")
      expect(standalone.environments).to be_a(Smplkit::Platform::EnvironmentsClient)
      expect(standalone.close).to be_nil
    end

    it "self.open yields the client and closes it" do
      yielded = nil
      result = described_class.open(api_key: "k", base_domain: "smplkit.test", scheme: "https") do |client|
        yielded = client
        :done
      end
      expect(yielded).to be_a(described_class)
      expect(result).to eq(:done)
    end

    it "is reachable as Smplkit::PlatformClient" do
      expect(Smplkit::PlatformClient).to be(described_class)
    end
  end
end

# rubocop:enable RSpec/MultipleExpectations, Layout/LineLength
