# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Audit::ForwardersClient do
  subject(:forwarders) { described_class.new(api) }

  let(:api) { SmplkitGeneratedClient::Audit::ForwardersApi.new(audit_api_client) }
  let(:audit_api_client) do
    cfg = SmplkitGeneratedClient::Audit::Configuration.new
    cfg.host = "audit.smplkit.test"
    cfg.scheme = "https"
    cfg.access_token = "k"
    Smplkit::HttpPool.configure(cfg)
    SmplkitGeneratedClient::Audit::ApiClient.new(cfg)
  end
  let(:base_url) { "https://audit.smplkit.test" }
  let(:fwd_id) { "datadog-prod" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def forwarder_resource(name: "Datadog production", description: nil,
                         forwarder_type: "datadog",
                         forward_smplkit_events: false,
                         filter: nil, transform_type: nil, transform: nil,
                         environments: {})
    {
      id: fwd_id,
      type: "forwarder",
      attributes: {
        name: name, description: description, forwarder_type: forwarder_type,
        forward_smplkit_events: forward_smplkit_events,
        filter: filter, transform_type: transform_type, transform: transform,
        environments: environments,
        configuration: {
          method: "POST", url: "https://siem.example.com/in",
          headers: { "DD-API-KEY" => "<redacted>" },
          success_status: "2xx"
        },
        created_at: "2026-05-07T12:00:00Z",
        updated_at: "2026-05-07T12:00:00Z",
        deleted_at: nil, version: 1
      }
    }
  end

  describe "#new + Forwarder#save" do
    it "POSTs and refreshes the local instance with the server response" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 201, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      fwd = forwarders.new(
        fwd_id,
        name: "Datadog production", forwarder_type: "datadog",
        configuration: Smplkit::Audit::HttpConfiguration.new(
          method: "POST", url: "https://siem.example.com/in",
          headers: { "DD-API-KEY" => "real-secret" }
        ),
        filter: { "==" => [1, 1] }, transform_type: "JSONATA", transform: "$"
      )
      fwd.save
      expect(fwd.id).to eq(fwd_id)
      expect(fwd.name).to eq("Datadog production")
      expect(fwd.configuration.get_header("DD-API-KEY")).to eq("<redacted>")
    end

    it "serializes the base configuration headers as a name→value object" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/forwarders").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: forwarder_resource }.to_json, headers: json_api)
      forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(
                  url: "https://x", headers: { "X-Api-Key" => "real" }
                )
      ).save
      headers = captured.dig("data", "attributes", "configuration", "headers")
      expect(headers).to eq("X-Api-Key" => "real")
    end

    it "defaults the display name to the id when name is omitted" do
      fwd = forwarders.new(
        fwd_id, forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect(fwd.name).to eq(fwd_id)
    end

    it "passes transform_type and transform through verbatim" do
      fwd = forwarders.new(
        fwd_id, name: "x", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
                transform_type: Smplkit::Audit::TransformType::JSONATA,
                transform: "{ \"event\": $.action }"
      )
      expect(fwd.transform_type).to eq("JSONATA")
      expect(fwd.transform).to eq("{ \"event\": $.action }")
    end

    it "raises ArgumentError when save() is called on a forwarder without an id" do
      fwd = forwarders.new(
        "", name: "x", forwarder_type: "http",
            configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect { fwd.save }.to raise_error(ArgumentError, /id is required/)
    end

    it "leaves transform and transform_type nil when neither is provided" do
      fwd = forwarders.new(
        fwd_id, name: "x", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect(fwd.transform).to be_nil
      expect(fwd.transform_type).to be_nil
    end

    it "raises when transform is provided without transform_type" do
      expect do
        forwarders.new(
          fwd_id, name: "x", forwarder_type: "http",
                  configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
                  transform: "$"
        )
      end.to raise_error(ArgumentError, /both nil or both set/)
    end

    it "raises when transform_type is provided without transform" do
      expect do
        forwarders.new(
          fwd_id, name: "x", forwarder_type: "http",
                  configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
                  transform_type: Smplkit::Audit::TransformType::JSONATA
        )
      end.to raise_error(ArgumentError, /both nil or both set/)
    end

    it "raises when transform_type is JSONATA and transform is not a String" do
      expect do
        forwarders.new(
          fwd_id, name: "x", forwarder_type: "http",
                  configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
                  transform_type: Smplkit::Audit::TransformType::JSONATA,
                  transform: { "event" => "$.action" }
        )
      end.to raise_error(ArgumentError, /must be a String when transform_type is JSONATA/)
    end

    it "raises on save when transform_type is mutated to be unpaired" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 201, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      fwd = forwarders.new(
        fwd_id, name: "x", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      fwd.transform_type = Smplkit::Audit::TransformType::JSONATA
      expect { fwd.save }.to raise_error(ArgumentError, /both nil or both set/)
    end

    it "raises when transform_type is not a known enum value" do
      expect do
        forwarders.new(
          fwd_id, name: "x", forwarder_type: "http",
                  configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
                  transform: "$", transform_type: "JQ"
        )
      end.to raise_error(ArgumentError, /Unknown TransformType/)
    end

    it "raises Smplkit::ConnectionError when the generated layer reports no status code" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_raise(Errno::ECONNREFUSED)
      expect do
        forwarders.new(
          fwd_id, name: "x", forwarder_type: "http",
                  configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
        ).save
      end.to raise_error(Smplkit::ConnectionError)
    end

    it "raises when the Forwarder has no client" do
      detached = Smplkit::Audit::Forwarder.new(
        name: "x", forwarder_type: "http",
        configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect { detached.save }.to raise_error(/cannot save/)
    end
  end

  describe "per-environment sparse overrides (ADR-056)" do
    it "sends a flat overlay on create: enabled + only overridden leaves + headers.<name>" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/forwarders").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(
        status: 201,
        body: { data: forwarder_resource(environments: { "production" => { enabled: true } }) }.to_json,
        headers: json_api
      )
      fwd = forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://base")
      )
      prod = fwd.environment("production")
      prod.enabled = true
      prod.url = "https://prod-override"
      prod.set_header("X-Prod", "real")
      fwd.save
      envs = captured.dig("data", "attributes", "environments")
      expect(envs["production"]).to eq(
        "enabled" => true,
        "url" => "https://prod-override",
        "headers.X-Prod" => "real"
      )
    end

    it "accepts a plain Hash environment entry (lightweight form) of flat leaves" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/forwarders").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(
        status: 201,
        body: { data: forwarder_resource(environments: { "production" => { enabled: true } }) }.to_json,
        headers: json_api
      )
      fwd = forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://base"),
                environments: { "production" => { enabled: true, url: "https://prod" } }
      )
      fwd.save
      envs = captured.dig("data", "attributes", "environments")
      expect(envs["production"]).to eq("enabled" => true, "url" => "https://prod")
    end

    it "defaults a plain Hash entry's enabled to false when omitted (string-keyed)" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/forwarders").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: forwarder_resource }.to_json, headers: json_api)
      fwd = forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://base"),
                environments: { "production" => { "enabled" => true } }
      )
      fwd.save
      envs = captured.dig("data", "attributes", "environments")
      expect(envs["production"]).to eq("enabled" => true)
    end

    it "defaults environments to an empty map and never sends a base enabled" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/forwarders").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: forwarder_resource }.to_json, headers: json_api)
      fwd = forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://base")
      )
      expect(fwd.environments).to eq({})
      fwd.save
      attrs = captured.dig("data", "attributes")
      expect(attrs["environments"]).to eq({})
      expect(attrs).not_to have_key("enabled")
    end

    it "reads the flat overlay back from a get (pure-override null reads, redacted headers)" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(
          environments: {
            "production" => {
              enabled: true, url: "https://prod-override",
              "headers.X-Prod": "<redacted>"
            },
            "staging" => { enabled: false }
          }
        ) }.to_json,
        headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.environments.keys).to contain_exactly("production", "staging")
      prod = fwd.environments["production"]
      expect(prod).to be_a(Smplkit::Audit::ForwarderEnvironment)
      expect(prod.enabled).to be(true)
      expect(prod.url).to eq("https://prod-override")
      expect(prod.get_header("X-Prod")).to eq("<redacted>")
      expect(prod.success_status).to be_nil # un-overridden leaf reads as nil (no base merge)
      stg = fwd.environments["staging"]
      expect(stg.enabled).to be(false)
      expect(stg.url).to be_nil
    end

    it "exposes enabled as a derived roll-up: true when any environment is enabled" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(environments: { "production" => { enabled: true } }) }.to_json,
        headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.enabled).to be(true)
    end

    it "exposes enabled as false when no environment is enabled" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(environments: { "production" => { enabled: false } }) }.to_json,
        headers: json_api
      )
      expect(forwarders.get(fwd_id).enabled).to be(false)
    end

    it "round-trips the overlay through Forwarder#save (PUT)" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(environments: { "production" => { enabled: true } }) }.to_json,
        headers: json_api
      )
      captured = nil
      stub_request(:put, "#{base_url}/api/v1/forwarders/#{fwd_id}").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(
        status: 200,
        body: { data: forwarder_resource(environments: { "production" => { enabled: false } }) }.to_json,
        headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      fwd.environment("production").enabled = false
      fwd.save
      expect(captured.dig("data", "attributes", "environments", "production", "enabled")).to be(false)
      expect(fwd.environments["production"].enabled).to be(false)
    end

    it "defaults a wire overlay with absent enabled to false" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(environments: { "production" => {} }) }.to_json,
        headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.environments["production"].enabled).to be(false)
      expect(fwd.environments["production"].url).to be_nil
    end
  end

  describe "Forwarder#environment" do
    let(:fwd) do
      forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://base")
      )
    end

    it "creates the override entry on first access and sets leaves directly" do
      fwd.environment("production").enabled = true
      fwd.environment("production").url = "https://prod"
      override = fwd.environments["production"]
      expect(override.enabled).to be(true)
      expect(override.url).to eq("https://prod")
    end

    it "returns the same override object on repeated access" do
      first = fwd.environment("production")
      second = fwd.environment("production")
      expect(second).to be(first)
    end
  end

  describe "forward_smplkit_events" do
    it "sends forward_smplkit_events=true on the wire when opted in at create" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/forwarders").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(
        status: 201,
        body: { data: forwarder_resource(forward_smplkit_events: true) }.to_json,
        headers: json_api
      )
      fwd = forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://base"),
                forward_smplkit_events: true
      )
      fwd.save
      expect(captured.dig("data", "attributes", "forward_smplkit_events")).to be(true)
      expect(fwd.forward_smplkit_events).to be(true)
    end

    it "omits forward_smplkit_events from the wire when not opted in at create" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/forwarders").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(
        status: 201,
        body: { data: forwarder_resource }.to_json,
        headers: json_api
      )
      fwd = forwarders.new(
        fwd_id, name: "n", forwarder_type: "http",
                configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://base")
      )
      fwd.save
      # Minimal-body intent: a non-opted-in forwarder sends no
      # forward_smplkit_events key at all (server default is false).
      expect(captured.dig("data", "attributes")).not_to have_key("forward_smplkit_events")
      expect(fwd.forward_smplkit_events).to be(false)
    end

    it "surfaces forward_smplkit_events on read" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(forward_smplkit_events: true) }.to_json,
        headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.forward_smplkit_events).to be(true)
    end

    it "defaults forward_smplkit_events to false when the wire omits it" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: {
          data: {
            id: fwd_id, type: "forwarder",
            attributes: {
              name: "n", forwarder_type: "http",
              configuration: { method: "POST", url: "https://x", headers: {}, success_status: "2xx" },
              created_at: "2026-05-07T12:00:00Z", updated_at: "2026-05-07T12:00:00Z", version: 1
            }
          }
        }.to_json,
        headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.forward_smplkit_events).to be(false)
    end
  end

  describe "#list" do
    it "forwards offset params and surfaces pagination metadata, returning a ForwarderListPage" do
      captured_uri = nil
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(
          status: 200,
          body: {
            data: [forwarder_resource(name: "A")],
            meta: { pagination: { page: 2, size: 1, total: 3, total_pages: 3 } }
          }.to_json,
          headers: json_api
        )
      page = forwarders.list(forwarder_type: "datadog",
                             page_number: 2, page_size: 1, meta_total: true)
      expect(page).to be_a(Smplkit::Audit::ForwarderListPage)
      expect(captured_uri).to include("page%5Bnumber%5D=2")
      expect(captured_uri).to include("page%5Bsize%5D=1")
      expect(captured_uri).to include("meta%5Btotal%5D=true")
      expect(page.pagination).to eq(page: 2, size: 1, total: 3, total_pages: 3)
    end

    it "is Enumerable: each / size / length walk the forwarders" do
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b}).to_return(
        status: 200,
        body: {
          data: [forwarder_resource(name: "A"), forwarder_resource(name: "B")],
          meta: { pagination: { page: 1, size: 1000 } }
        }.to_json,
        headers: json_api
      )
      page = forwarders.list
      expect(page.size).to eq(2)
      expect(page.length).to eq(2)
      expect(page.map(&:name)).to eq(%w[A B])
    end

    it "passes filter[forwarder_type] through to the generated client" do
      captured_uri = nil
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(status: 200,
                   body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
                   headers: json_api)
      forwarders.list(forwarder_type: "datadog")
      expect(captured_uri).to include("filter%5Bforwarder_type%5D=datadog")
    end

    it "returns empty list and bare pagination on empty data" do
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b}).to_return(
        status: 200,
        body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
        headers: json_api
      )
      page = forwarders.list
      expect(page.forwarders).to be_empty
      expect(page.pagination).to eq(page: 1, size: 1000)
    end

    it "rejects an invalid forwarder_type at the wrapper before any HTTP" do
      expect do
        forwarders.list(forwarder_type: "definitely-not-a-real-type")
      end.to raise_error(ArgumentError, /Unknown ForwarderType/)
    end
  end

  describe "#get / save (update) / delete" do
    it "returns a Forwarder on get bound to the client" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.name).to eq("Datadog production")
      expect(fwd.instance_variable_get(:@client)).to be(forwarders)
    end

    it "returns forwarder filter with string keys at every depth" do
      resource = forwarder_resource(
        filter: { "==" => [{ "var" => "resource_type" }, "invoice"] }
      )
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: resource }.to_json, headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.filter.keys).to all(be_a(String))
      expect(fwd.filter["=="].first.keys).to all(be_a(String))
      expect(fwd.filter["=="].first["var"]).to eq("resource_type")
    end

    it "Forwarder#save issues PUT once created_at is present" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      put_stub = stub_request(:put, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(name: "Renamed") }.to_json,
        headers: json_api
      )
      fetched = forwarders.get(fwd_id)
      fetched.name = "Renamed"
      fetched.save
      expect(put_stub).to have_been_requested
      expect(fetched.name).to eq("Renamed")
    end

    it "_update_forwarder rejects a Forwarder with no id" do
      detached = Smplkit::Audit::Forwarder.new(
        forwarders, name: "x", forwarder_type: "http",
                    configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect { forwarders._update_forwarder(detached) }.to raise_error(ArgumentError, /no id/)
    end

    it "Forwarder#delete issues DELETE" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      del_stub = stub_request(:delete, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(status: 204)
      fetched = forwarders.get(fwd_id)
      fetched.delete
      expect(del_stub).to have_been_requested
    end

    it "Forwarder#delete raises when constructed without a client" do
      detached = Smplkit::Audit::Forwarder.new(
        name: "x", forwarder_type: "http", id: fwd_id,
        configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect { detached.delete }.to raise_error(/cannot delete/)
    end

    it "client #delete returns nil and issues DELETE by id" do
      del_stub = stub_request(:delete, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(status: 204)
      expect(forwarders.delete(fwd_id)).to be_nil
      expect(del_stub).to have_been_requested
    end

    it "raises NotFoundError on a 404" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 404, body: { errors: [{ status: "404" }] }.to_json, headers: json_api
      )
      expect { forwarders.get(fwd_id) }.to raise_error(Smplkit::NotFoundError)
    end
  end
end
