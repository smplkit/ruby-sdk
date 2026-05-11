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

  def forwarder_resource(name: "Datadog production", slug: "datadog_production",
                         enabled: true, forwarder_type: "DATADOG",
                         filter: nil, transform: nil)
    {
      id: fwd_id,
      type: "forwarder",
      attributes: {
        name: name, slug: slug, forwarder_type: forwarder_type, enabled: enabled,
        filter: filter, transform: transform,
        http: {
          method: "POST", url: "https://siem.example.com/in",
          headers: [{ name: "DD-API-KEY", value: "<redacted>" }],
          body: nil, success_status: "2xx"
        },
        created_at: "2026-05-07T12:00:00Z",
        updated_at: "2026-05-07T12:00:00Z",
        deleted_at: nil, version: 1
      }
    }
  end

  describe "#create" do
    it "wraps the input in a JSON:API resource and returns a Forwarder" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 201, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      fwd = forwarders.create(
        name: "Datadog production", forwarder_type: "DATADOG",
        http: { url: "https://siem.example.com/in",
                headers: [{ name: "DD-API-KEY", value: "real-secret" }] },
        filter: { "==" => [1, 1] }, transform: "$"
      )
      expect(fwd.slug).to eq("datadog_production")
      expect(fwd.http.headers.first.value).to eq("<redacted>")
    end

    it "raises Smplkit::PaymentRequiredError on 402" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 402, body: { errors: [{ status: "402", detail: "Pro plan required" }] }.to_json,
        headers: json_api
      )
      expect do
        forwarders.create(
          name: "x", forwarder_type: "HTTP",
          http: Smplkit::Audit::ForwarderHttp.new(url: "https://x")
        )
      end.to raise_error(Smplkit::PaymentRequiredError, /Pro plan required/)
    end

    it "raises Smplkit::ConnectionError when the generated layer reports no status code" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_raise(Errno::ECONNREFUSED)
      expect do
        forwarders.create(
          name: "x", forwarder_type: "HTTP",
          http: Smplkit::Audit::ForwarderHttp.new(url: "https://x")
        )
      end.to raise_error(Smplkit::ConnectionError)
    end
  end

  describe "#list" do
    it "paginates and extracts the cursor from links.next" do
      page1 = {
        data: [forwarder_resource(name: "A", slug: "a")],
        links: { next: "/api/v1/forwarders?page[size]=1&page[after]=tok-2" },
        meta: { page_size: 1 }
      }.to_json
      page2 = { data: [forwarder_resource(name: "B", slug: "b")], meta: { page_size: 1 } }.to_json
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b}).to_return(
        { status: 200, body: page1, headers: json_api },
        { status: 200, body: page2, headers: json_api }
      )
      first = forwarders.list(forwarder_type: "DATADOG", enabled: true, page_size: 1)
      expect(first.next_cursor).to eq("tok-2")
      second = forwarders.list(page_after: first.next_cursor)
      expect(second.next_cursor).to be_nil
    end

    it "passes filter[forwarder_type] and filter[enabled] through to the generated client" do
      captured_uri = nil
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(status: 200, body: { data: [], meta: { page_size: 50 } }.to_json, headers: json_api)
      forwarders.list(forwarder_type: "DATADOG", enabled: false)
      expect(captured_uri).to include("filter%5Bforwarder_type%5D=DATADOG")
      expect(captured_uri).to include("filter%5Benabled%5D=false")
    end

    it "returns empty list and nil cursor on empty data" do
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b}).to_return(
        status: 200, body: { data: [], meta: { page_size: 1 } }.to_json, headers: json_api
      )
      page = forwarders.list
      expect(page.forwarders).to be_empty
      expect(page.next_cursor).to be_nil
    end

    it "rejects an invalid forwarder_type at the wrapper before any HTTP" do
      expect do
        forwarders.list(forwarder_type: "definitely-not-a-real-type")
      end.to raise_error(ArgumentError, /Unknown ForwarderType/)
    end
  end

  describe "#get / #update / #delete" do
    it "returns a Forwarder on get" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: forwarder_resource }.to_json, headers: json_api
      )
      fwd = forwarders.get(fwd_id)
      expect(fwd.name).to eq("Datadog production")
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

    it "issues PUT on update" do
      put_stub = stub_request(:put, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200,
        body: { data: forwarder_resource(name: "Renamed", slug: "renamed") }.to_json,
        headers: json_api
      )
      fwd = forwarders.update(
        fwd_id, name: "Renamed", forwarder_type: "DATADOG",
                http: Smplkit::Audit::ForwarderHttp.new(url: "https://x")
      )
      expect(put_stub).to have_been_requested
      expect(fwd.name).to eq("Renamed")
    end

    it "issues DELETE on delete and returns nil" do
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

  describe "ForwarderHttp helpers" do
    it "round-trips via to_wire and from_wire" do
      h = Smplkit::Audit::ForwarderHttp.new(
        url: "https://x", headers: [Smplkit::Audit::HttpHeader.new(name: "A", value: "1")],
        body: '{"k":"v"}', success_status: "200"
      )
      wire = Smplkit::Audit::ForwarderHttp.to_wire(h)
      back = Smplkit::Audit::ForwarderHttp.from_wire(wire)
      expect(back.url).to eq("https://x")
      expect(back.headers.first.name).to eq("A")
    end

    it "from_wire with nil returns a default object" do
      out = Smplkit::Audit::ForwarderHttp.from_wire(nil)
      expect(out.method).to eq("POST")
      expect(out.headers).to be_empty
    end

    it "to_wire accepts a Hash" do
      wire = Smplkit::Audit::ForwarderHttp.to_wire(
        url: "https://x", headers: [{ name: "h", value: "v" }]
      )
      expect(wire.url).to eq("https://x")
    end
  end
end

RSpec.describe Smplkit::Audit::ForwarderType do
  it "lists every spec value in VALUES" do
    expect(described_class::VALUES).to eq(%w[
                                            HTTP DATADOG SPLUNK_HEC SUMO_LOGIC NEW_RELIC HONEYCOMB ELASTIC
                                          ])
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
