# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Management::ForwardersNamespace do
  subject(:forwarders) { mgmt.audit.forwarders }

  let(:mgmt) { Smplkit::ManagementClient.from_resolved(resolved) }
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:base_url) { "https://audit.smplkit.test" }
  let(:fwd_id) { "11111111-2222-3333-4444-555555555555" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def forwarder_resource(name: "Datadog production", description: nil,
                         enabled: true, forwarder_type: "DATADOG",
                         filter: nil, transform_type: nil, transform: nil)
    {
      id: fwd_id,
      type: "forwarder",
      attributes: {
        name: name, description: description, forwarder_type: forwarder_type, enabled: enabled,
        filter: filter, transform_type: transform_type, transform: transform,
        configuration: {
          method: "POST", url: "https://siem.example.com/in",
          headers: [{ name: "DD-API-KEY", value: "<redacted>" }],
          success_status: "2xx"
        },
        created_at: "2026-05-07T12:00:00Z",
        updated_at: "2026-05-07T12:00:00Z",
        deleted_at: nil, version: 1
      }
    }
  end

  describe "#new_forwarder + Forwarder#save" do
    it "POSTs and refreshes the local instance with the server response" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 201, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      fwd = forwarders.new_forwarder(
        name: "Datadog production", forwarder_type: "DATADOG",
        configuration: Smplkit::Audit::HttpConfiguration.new(
          method: "POST", url: "https://siem.example.com/in",
          headers: [Smplkit::Audit::HttpHeader.new(name: "DD-API-KEY", value: "real-secret")]
        ),
        filter: { "==" => [1, 1] }, transform_type: "JSONATA", transform: "$"
      )
      fwd.save
      expect(fwd.id).to eq(fwd_id)
      expect(fwd.name).to eq("Datadog production")
      expect(fwd.configuration.headers.first.value).to eq("<redacted>")
    end

    it "passes transform_type and transform through verbatim" do
      fwd = forwarders.new_forwarder(
        name: "x", forwarder_type: "HTTP",
        configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
        transform_type: Smplkit::Audit::TransformType::JSONATA,
        transform: "{ \"event\": $.action }"
      )
      expect(fwd.transform_type).to eq("JSONATA")
      expect(fwd.transform).to eq("{ \"event\": $.action }")
    end

    it "leaves transform and transform_type nil when neither is provided" do
      fwd = forwarders.new_forwarder(
        name: "x", forwarder_type: "HTTP",
        configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect(fwd.transform).to be_nil
      expect(fwd.transform_type).to be_nil
    end

    it "raises when transform is provided without transform_type" do
      expect do
        forwarders.new_forwarder(
          name: "x", forwarder_type: "HTTP",
          configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
          transform: "$"
        )
      end.to raise_error(ArgumentError, /both nil or both set/)
    end

    it "raises when transform_type is provided without transform" do
      expect do
        forwarders.new_forwarder(
          name: "x", forwarder_type: "HTTP",
          configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
          transform_type: Smplkit::Audit::TransformType::JSONATA
        )
      end.to raise_error(ArgumentError, /both nil or both set/)
    end

    it "raises when transform_type is JSONATA and transform is not a String" do
      expect do
        forwarders.new_forwarder(
          name: "x", forwarder_type: "HTTP",
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
      fwd = forwarders.new_forwarder(
        name: "x", forwarder_type: "HTTP",
        configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      fwd.transform_type = Smplkit::Audit::TransformType::JSONATA
      expect { fwd.save }.to raise_error(ArgumentError, /both nil or both set/)
    end

    it "raises when transform_type is not a known enum value" do
      expect do
        forwarders.new_forwarder(
          name: "x", forwarder_type: "HTTP",
          configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x"),
          transform: "$", transform_type: "JQ"
        )
      end.to raise_error(ArgumentError, /Unknown TransformType/)
    end

    it "raises Smplkit::ConnectionError when the generated layer reports no status code" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_raise(Errno::ECONNREFUSED)
      expect do
        forwarders.new_forwarder(
          name: "x", forwarder_type: "HTTP",
          configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
        ).save
      end.to raise_error(Smplkit::ConnectionError)
    end

    it "raises when the Forwarder has no client" do
      detached = Smplkit::Audit::Forwarder.new(
        name: "x", forwarder_type: "HTTP",
        configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect { detached.save }.to raise_error(/cannot save/)
    end
  end

  describe "#list" do
    it "forwards offset params and surfaces pagination metadata" do
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
      page = forwarders.list(forwarder_type: "DATADOG", enabled: true,
                             page_number: 2, page_size: 1, meta_total: true)
      expect(captured_uri).to include("page%5Bnumber%5D=2")
      expect(captured_uri).to include("page%5Bsize%5D=1")
      expect(captured_uri).to include("meta%5Btotal%5D=true")
      expect(page.pagination).to eq(page: 2, size: 1, total: 3, total_pages: 3)
    end

    it "passes filter[forwarder_type] and filter[enabled] through to the generated client" do
      captured_uri = nil
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(status: 200,
                   body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
                   headers: json_api)
      forwarders.list(forwarder_type: "DATADOG", enabled: false)
      expect(captured_uri).to include("filter%5Bforwarder_type%5D=DATADOG")
      expect(captured_uri).to include("filter%5Benabled%5D=false")
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
    it "returns a Forwarder on get bound to the namespace" do
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
        forwarders, name: "x", forwarder_type: "HTTP",
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
        name: "x", forwarder_type: "HTTP", id: fwd_id,
        configuration: Smplkit::Audit::HttpConfiguration.new(url: "https://x")
      )
      expect { detached.delete }.to raise_error(/cannot delete/)
    end

    it "namespace #delete still works by id" do
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

  describe "HttpConfiguration helpers" do
    it "round-trips via to_wire and from_wire" do
      h = Smplkit::Audit::HttpConfiguration.new(
        url: "https://x", headers: [Smplkit::Audit::HttpHeader.new(name: "A", value: "1")],
        success_status: "200"
      )
      wire = Smplkit::Audit::HttpConfiguration.to_wire(h)
      back = Smplkit::Audit::HttpConfiguration.from_wire(wire)
      expect(back.url).to eq("https://x")
      expect(back.headers.first.name).to eq("A")
    end

    it "from_wire with nil returns a default object" do
      out = Smplkit::Audit::HttpConfiguration.from_wire(nil)
      expect(out.method).to eq("POST")
      expect(out.headers).to be_empty
    end

    it "to_wire accepts a Hash" do
      wire = Smplkit::Audit::HttpConfiguration.to_wire(
        url: "https://x", headers: [{ name: "h", value: "v" }]
      )
      expect(wire.url).to eq("https://x")
    end
  end
end

RSpec.describe Smplkit::Audit::ForwarderType do
  it "lists every spec value in VALUES in alphabetical order" do
    expect(described_class::VALUES).to eq(%w[DATADOG ELASTIC HONEYCOMB HTTP NEW_RELIC SPLUNK_HEC SUMO_LOGIC])
  end

  it "exposes each value as a SCREAMING_SNAKE_CASE constant" do
    expect(described_class::HTTP).to eq("HTTP")
    expect(described_class::DATADOG).to eq("DATADOG")
    expect(described_class::SPLUNK_HEC).to eq("SPLUNK_HEC")
    expect(described_class::SUMO_LOGIC).to eq("SUMO_LOGIC")
    expect(described_class::NEW_RELIC).to eq("NEW_RELIC")
    expect(described_class::HONEYCOMB).to eq("HONEYCOMB")
    expect(described_class::ELASTIC).to eq("ELASTIC")
  end

  describe ".coerce" do
    it "passes through valid wire-format strings" do
      expect(described_class.coerce("HTTP")).to eq("HTTP")
      expect(described_class.coerce("DATADOG")).to eq("DATADOG")
    end

    it "passes through the published constants (which are strings)" do
      expect(described_class.coerce(described_class::SPLUNK_HEC)).to eq("SPLUNK_HEC")
    end

    it "preserves nil so optional params remain optional" do
      expect(described_class.coerce(nil)).to be_nil
    end

    it "raises ArgumentError on an unknown value" do
      expect { described_class.coerce("s3") }
        .to raise_error(ArgumentError, /Unknown ForwarderType/)
    end

    it "raises ArgumentError on a lowercase value" do
      expect { described_class.coerce("http") }
        .to raise_error(ArgumentError, /Unknown ForwarderType/)
    end
  end
end

RSpec.describe Smplkit::Audit::HttpMethod do
  it "lists every verb in VALUES in alphabetical order" do
    expect(described_class::VALUES).to eq(%w[DELETE GET PATCH POST PUT])
  end

  describe ".coerce" do
    it "passes through valid verb strings" do
      expect(described_class.coerce("POST")).to eq("POST")
      expect(described_class.coerce(described_class::PUT)).to eq("PUT")
    end

    it "preserves nil" do
      expect(described_class.coerce(nil)).to be_nil
    end

    it "raises on an unknown verb" do
      expect { described_class.coerce("HEAD") }.to raise_error(ArgumentError, /Unknown HttpMethod/)
    end
  end
end

RSpec.describe Smplkit::Audit::HttpConfiguration do
  it "rejects an invalid method at construction" do
    expect { described_class.new(method: "HEAD", url: "https://x") }
      .to raise_error(ArgumentError, /Unknown HttpMethod/)
  end

  it "defaults method to POST when omitted" do
    expect(described_class.new(url: "https://x").method).to eq("POST")
  end
end

RSpec.describe Smplkit::Audit::TransformType do
  it "lists every transform engine in VALUES" do
    expect(described_class::VALUES).to eq(%w[JSONATA])
  end

  describe ".coerce" do
    it "passes through known values" do
      expect(described_class.coerce("JSONATA")).to eq("JSONATA")
      expect(described_class.coerce(described_class::JSONATA)).to eq("JSONATA")
    end

    it "preserves nil so optional params stay optional" do
      expect(described_class.coerce(nil)).to be_nil
    end

    it "raises on an unknown engine" do
      expect { described_class.coerce("JQ") }.to raise_error(ArgumentError, /Unknown TransformType/)
    end
  end
end

RSpec.describe "Smplkit::Audit.call_api" do
  it "re-raises a generated ApiError that somehow survived raise_for_status" do
    # Defensive: +raise_for_status+ only raises on non-2xx, so a generated
    # ApiError that reports a 2xx code (which shouldn't happen in
    # practice) falls through and the original exception is re-raised.
    err = SmplkitGeneratedClient::Audit::ApiError.new(code: 200, response_body: "")
    expect { Smplkit::Audit.call_api { raise err } }
      .to raise_error(SmplkitGeneratedClient::Audit::ApiError)
  end
end

RSpec.describe "Smplkit::Audit module helpers" do
  describe ".next_cursor" do
    it "returns nil for non-string input" do
      expect(Smplkit::Audit.next_cursor(nil)).to be_nil
    end

    it "returns nil when the link has no page[after]" do
      expect(Smplkit::Audit.next_cursor("/api/v1/forwarders?other=v")).to be_nil
    end

    it "stops at the first ampersand" do
      expect(Smplkit::Audit.next_cursor("/x?page[after]=abc&size=5")).to eq("abc")
    end

    it "returns the cursor when no trailing ampersand is present" do
      expect(Smplkit::Audit.next_cursor("/x?page[after]=abc")).to eq("abc")
    end
  end
end
