# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Audit::Forwarders do
  let(:base_url) { "https://audit.example.com" }
  let(:api_key) { "sk_api_test" }
  let(:fwd_id) { "11111111-2222-3333-4444-555555555555" }
  let(:delivery_id) { "22222222-3333-4444-5555-666666666666" }

  let(:client) { Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url) }

  after { client._close }

  def forwarder_resource(name: "Datadog production", slug: "datadog_production", enabled: true)
    {
      id: fwd_id,
      type: "forwarder",
      attributes: {
        name: name, slug: slug, forwarder_type: "DATADOG", enabled: enabled,
        filter: nil, transform: nil,
        http: {
          method: "POST", url: "https://siem.example.com/in",
          headers: [{ name: "DD-API-KEY", value: "<redacted>" }],
          body: nil, success_status: "2xx"
        },
        data: {}, created_at: "2026-05-07T12:00:00Z",
        updated_at: "2026-05-07T12:00:00Z", deleted_at: nil, version: 1
      }
    }
  end

  def delivery_resource(status: "SUCCEEDED")
    {
      id: delivery_id,
      type: "forwarder_delivery",
      attributes: {
        forwarder_id: fwd_id,
        event_id: "33333333-4444-5555-6666-777777777777",
        attempt_number: 1, status: status,
        request: { method: "POST", url: "https://x", headers: [{ name: "X-K", value: "<redacted>" }] },
        response_status: 202, response_body: "ok",
        latency_ms: 42, error: nil,
        created_at: "2026-05-07T12:00:01Z"
      }
    }
  end

  describe "#create" do
    it "wraps the input in a JSON:API resource and returns a Forwarder" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 201, body: { data: forwarder_resource }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      fwd = client.forwarders.create(
        name: "Datadog production", forwarder_type: "DATADOG",
        http: { url: "https://siem.example.com/in",
                headers: [{ name: "DD-API-KEY", value: "real-secret" }] },
        filter: { "==" => [1, 1] }, transform: "$",
        data: { "team" => "platform" }
      )
      expect(fwd.slug).to eq("datadog_production")
      expect(fwd.http.headers.first.value).to eq("<redacted>")
    end

    it "raises ApiError on 402" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 402, body: { errors: [{ status: "402" }] }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      expect do
        client.forwarders.create(
          name: "x", forwarder_type: "HTTP",
          http: Smplkit::Audit::ForwarderHttp.new(url: "https://x")
        )
      end.to raise_error(SmplkitGeneratedClient::Audit::ApiError)
    end
  end

  describe "#list" do
    it "paginates and extracts the cursor from links.next" do
      page1 = {
        data: [forwarder_resource(name: "A", slug: "a")],
        links: { next: "/api/v1/forwarders?page[size]=1&page[after]=tok-2" },
        meta: { page_size: 1 }
      }.to_json
      page2 = {
        data: [forwarder_resource(name: "B", slug: "b")],
        meta: { page_size: 1 }
      }.to_json
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b}).to_return(
        { status: 200, body: page1, headers: { "Content-Type" => "application/vnd.api+json" } },
        { status: 200, body: page2, headers: { "Content-Type" => "application/vnd.api+json" } }
      )
      first = client.forwarders.list(forwarder_type: "DATADOG", enabled: true, page_size: 1)
      expect(first.next_cursor).to eq("tok-2")
      second = client.forwarders.list(page_after: first.next_cursor)
      expect(second.next_cursor).to be_nil
    end

    it "returns empty list and nil cursor on empty data" do
      stub_request(:get, %r{#{base_url}/api/v1/forwarders\b}).to_return(
        status: 200, body: { data: [], meta: { page_size: 1 } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      page = client.forwarders.list
      expect(page.forwarders).to be_empty
      expect(page.next_cursor).to be_nil
    end
  end

  describe "#get / #update / #delete" do
    it "returns a Forwarder on get" do
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: forwarder_resource }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      fwd = client.forwarders.get(fwd_id)
      expect(fwd.name).to eq("Datadog production")
    end

    it "returns forwarder filter and data with string keys at every depth" do
      # Regression: same symbolize_names issue as Event.data; Forwarder.filter
      # and Forwarder.data are also Hash<String, Object> fields.
      resource = forwarder_resource.merge(
        attributes: forwarder_resource[:attributes].merge(
          filter: { "==" => [{ "var" => "resource_type" }, "invoice"] },
          data: { "team" => { "name" => "platform" } }
        )
      )
      stub_request(:get, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: resource }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      fwd = client.forwarders.get(fwd_id)
      expect(fwd.filter.keys).to all(be_a(String))
      expect(fwd.filter["=="].first.keys).to all(be_a(String))
      expect(fwd.filter["=="].first["var"]).to eq("resource_type")
      expect(fwd.data["team"]["name"]).to eq("platform")
    end

    it "issues PUT on update" do
      put_stub = stub_request(:put, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(
        status: 200, body: { data: forwarder_resource(name: "Renamed", slug: "renamed") }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      fwd = client.forwarders.update(
        fwd_id, name: "Renamed", forwarder_type: "DATADOG",
                http: Smplkit::Audit::ForwarderHttp.new(url: "https://x")
      )
      expect(put_stub).to have_been_requested
      expect(fwd.name).to eq("Renamed")
    end

    it "issues DELETE on delete" do
      del_stub = stub_request(:delete, "#{base_url}/api/v1/forwarders/#{fwd_id}").to_return(status: 204)
      client.forwarders.delete(fwd_id)
      expect(del_stub).to have_been_requested
    end
  end

  describe "deliveries" do
    it "lists deliveries with status filter" do
      stub_request(:get, %r{#{base_url}/api/v1/forwarders/#{fwd_id}/deliveries\b}).to_return(
        status: 200,
        body: { data: [delivery_resource], meta: { page_size: 1 } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      page = client.forwarders.deliveries.list(
        fwd_id, status: "SUCCEEDED",
                created_at_range: "[2020-01-01T00:00:00Z,*)", page_size: 1
      )
      expect(page.deliveries.first.status).to eq("SUCCEEDED")
    end

    it "passes filter[event_id] to the generated client" do
      captured_uri = nil
      stub_request(:get, %r{#{base_url}/api/v1/forwarders/#{fwd_id}/deliveries\b})
        .with { |req| captured_uri = req.uri.to_s; true }
        .to_return(
          status: 200,
          body: { data: [], meta: { page_size: 50 } }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
      client.forwarders.deliveries.list(fwd_id, event_id: "33333333-4444-5555-6666-777777777777")
      expect(captured_uri).to include("filter%5Bevent_id%5D=33333333")
    end

    it "returns delivery request with string keys at every depth" do
      # Regression: ForwarderDelivery.request is Hash<String, Object>; nested
      # objects were symbol-keyed before the deep_stringify_keys fix.
      resource = delivery_resource.merge(
        attributes: delivery_resource[:attributes].merge(
          request: { "method" => "POST", "headers" => [{ "name" => "X-K", "value" => "v" }] }
        )
      )
      stub_request(:get, %r{#{base_url}/api/v1/forwarders/#{fwd_id}/deliveries\b}).to_return(
        status: 200,
        body: { data: [resource], meta: { page_size: 1 } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      page = client.forwarders.deliveries.list(fwd_id)
      req = page.deliveries.first.request
      expect(req.keys).to all(be_a(String))
      expect(req["method"]).to eq("POST")
      expect(req["headers"].first.keys).to all(be_a(String))
      expect(req["headers"].first["name"]).to eq("X-K")
    end

    it "returns empty list when no deliveries" do
      stub_request(:get, %r{#{base_url}/api/v1/forwarders/#{fwd_id}/deliveries\b}).to_return(
        status: 200, body: { data: [], meta: { page_size: 1 } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      page = client.forwarders.deliveries.list(fwd_id)
      expect(page.deliveries).to be_empty
    end

    it "retries a single delivery and returns the new row" do
      stub_request(
        :post,
        "#{base_url}/api/v1/forwarders/#{fwd_id}/deliveries/#{delivery_id}/actions/retry"
      ).to_return(
        status: 200, body: { data: delivery_resource(status: "SUCCEEDED") }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      row = client.forwarders.deliveries.actions.retry(fwd_id, delivery_id)
      expect(row.status).to eq("SUCCEEDED")
    end
  end

  describe "actions.retry_failed_deliveries" do
    it "returns a summary" do
      stub_request(
        :post,
        "#{base_url}/api/v1/forwarders/#{fwd_id}/actions/retry_failed_deliveries"
      ).to_return(
        status: 200, body: { attempted: 3, succeeded: 2, failed: 1 }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      summary = client.forwarders.actions.retry_failed_deliveries(fwd_id)
      expect(summary.attempted).to eq(3)
      expect(summary.succeeded).to eq(2)
      expect(summary.failed).to eq(1)
    end
  end

  describe "next_cursor extraction" do
    it "returns nil for non-string input" do
      expect(described_class.next_cursor(nil)).to be_nil
    end

    it "returns nil when link has no page[after]" do
      expect(described_class.next_cursor("/api/v1/forwarders?other=v")).to be_nil
    end

    it "stops at the first ampersand" do
      expect(described_class.next_cursor("/x?page[after]=abc&size=5")).to eq("abc")
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

RSpec.describe Smplkit::Audit::Functions do
  let(:base_url) { "https://audit.example.com" }
  let(:client) { Smplkit::Audit::AuditClient.new(api_key: "sk_api_test", base_url: base_url) }

  after { client._close }

  describe "test_forwarder.actions.execute" do
    it "returns the proxied response" do
      stub_request(:post, "#{base_url}/api/v1/functions/test_forwarder/actions/execute").to_return(
        status: 200, body: {
          succeeded: true, response_status: 202,
          response_headers: { "X-Echo" => "y" },
          response_body: "accepted",
          latency_ms: 12, error: nil
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      r = client.functions.test_forwarder.actions.execute(
        url: "https://siem.example.com/in",
        headers: [Smplkit::Audit::HttpHeader.new(name: "X-K", value: "v")],
        body: '{"hello":"world"}', timeout_ms: 5000
      )
      expect(r.succeeded).to be(true)
      expect(r.response_status).to eq(202)
      expect(r.response_body).to eq("accepted")
      expect(r.response_headers).to eq({ "X-Echo" => "y" })
    end

    it "accepts hash-style headers" do
      stub_request(:post, "#{base_url}/api/v1/functions/test_forwarder/actions/execute").to_return(
        status: 200, body: { succeeded: false, response_status: nil, response_headers: {},
                             response_body: nil, latency_ms: nil, error: "x" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      r = client.functions.test_forwarder.actions.execute(
        url: "https://x", headers: [{ name: "h", value: "v" }]
      )
      expect(r.succeeded).to be(false)
      expect(r.response_body).to eq("")
    end
  end
end

RSpec.describe "Smplkit::Audit::Events do_not_forward kwarg" do
  let(:base_url) { "https://audit.example.com" }

  it "passes the do_not_forward flag in the request body" do
    captured = nil
    stub_request(:post, "#{base_url}/api/v1/events").with do |req|
      captured = req.body
      true
    end.to_return(
      status: 201,
      body: {
        data: { id: "33333333-4444-5555-6666-777777777777", type: "event", attributes: {
          action: "x", resource_type: "x", resource_id: "1",
          do_not_forward: true,
          occurred_at: "2026-05-07T12:00:00Z", created_at: "2026-05-07T12:00:01Z",
          actor_type: "API_KEY", actor_label: "", snapshot: nil, data: {}, idempotency_key: ""
        } }
      }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    client = Smplkit::Audit::AuditClient.new(api_key: "sk_api_test", base_url: base_url)
    begin
      client.events.record(
        action: "x", resource_type: "x", resource_id: "1",
        do_not_forward: true
      )
      client.events.flush(timeout: 2.0)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
      sleep 0.02 until captured || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
    ensure
      client._close
    end
    expect(captured).to include('"do_not_forward":true')
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

  describe "wrapper integration" do
    let(:base_url) { "https://audit.example.com" }
    let(:client) { Smplkit::Audit::AuditClient.new(api_key: "sk_api_test", base_url: base_url) }

    it "rejects an invalid forwarder_type at the wrapper before any HTTP" do
      # No stub — if the wrapper made a request, WebMock would raise a
      # very different error. ArgumentError = the validation fired first.
      expect do
        client.forwarders.create(
          name: "x", forwarder_type: "definitely-not-a-real-type",
          http: Smplkit::Audit::ForwarderHttp.new(url: "https://x")
        )
      end.to raise_error(ArgumentError, /Unknown ForwarderType/)
    end

    it "rejects an invalid forwarder_type on list before any HTTP" do
      expect do
        client.forwarders.list(forwarder_type: "definitely-not-a-real-type")
      end.to raise_error(ArgumentError, /Unknown ForwarderType/)
    end

    it "accepts a valid published constant on create" do
      stub_request(:post, "#{base_url}/api/v1/forwarders").to_return(
        status: 201,
        body: {
          data: {
            id: SecureRandom.uuid, type: "forwarder",
            attributes: {
              name: "n", slug: "n", forwarder_type: "DATADOG", enabled: true,
              filter: nil, transform: nil,
              http: { method: "POST", url: "u",
                      headers: [], body: nil, success_status: "2xx" },
              data: {}, created_at: Time.now.utc.iso8601,
              updated_at: Time.now.utc.iso8601, deleted_at: nil, version: 1
            }
          }
        }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
      fwd = client.forwarders.create(
        name: "n", forwarder_type: Smplkit::Audit::ForwarderType::DATADOG,
        http: Smplkit::Audit::ForwarderHttp.new(url: "u")
      )
      expect(fwd.forwarder_type).to eq("DATADOG")
    end
  end
end
