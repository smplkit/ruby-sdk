# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/ExampleLength
#
# Wire-body shape tests for the audit wrapper.
#
# Asserts on the actual JSON the SDK posts. Guards against the failure
# mode that shipped smplkit-sdk@3.2.21 / @smplkit/sdk@3.0.19: the
# generated client compiled cleanly after the spec dropped a field,
# but the wrapper kept emitting it, and CI was none the wiser because
# no test inspected the bytes.
#
# The whitelists below come from the audit service's OpenAPI spec
# (openapi/audit.json: components.schemas.Event / .Forwarder), not
# from the generated client (which is itself a projection of the spec).

# POST /api/v1/events accepts only these attribute keys. The rest
# (created_at, actor_*, idempotency_key) are readOnly.
AUDIT_EVENT_POST_ATTRS = %w[
  action resource_type resource_id
  occurred_at data do_not_forward
].freeze

# POST/PUT /api/v1/forwarders accepts only these attribute keys. slug
# is x-immutable; created_at/updated_at/deleted_at/version are readOnly.
AUDIT_FORWARDER_POST_ATTRS = %w[
  name forwarder_type http
  enabled filter transform data
].freeze

RSpec.describe "Audit wire-body shape" do
  let(:base_url) { "https://audit.example.com" }
  let(:api_key) { "sk_api_test" }
  let(:fwd_id) { "11111111-2222-3333-4444-555555555555" }
  let(:event_response_body) do
    {
      data: {
        id: "00000000-0000-0000-0000-000000000001",
        type: "event",
        attributes: {
          action: "invoice.created",
          resource_type: "invoice",
          resource_id: "inv-1",
          occurred_at: "2026-05-06T12:00:00Z",
          created_at: "2026-05-06T12:00:01Z",
          actor_type: "API_KEY",
          actor_id: nil,
          actor_label: "",
          data: {},
          idempotency_key: "k-1"
        }
      }
    }.to_json
  end
  let(:forwarder_response_body) do
    {
      data: {
        id: fwd_id,
        type: "forwarder",
        attributes: {
          name: "Datadog production",
          slug: "datadog_production",
          forwarder_type: "datadog",
          enabled: true,
          filter: nil,
          transform: nil,
          http: {
            method: "POST",
            url: "https://siem.example.com/in",
            headers: [{ name: "DD-API-KEY", value: "<redacted>" }],
            body: nil,
            success_status: "2xx"
          },
          data: {},
          created_at: "2026-05-07T12:00:00Z",
          updated_at: "2026-05-07T12:00:00Z",
          deleted_at: nil,
          version: 1
        }
      }
    }.to_json
  end

  # WebMock-based capture: stash the parsed body the SDK posts, plus
  # the request method, headers, and URL.
  def capture_request(method, path, response_status, response_body)
    captured = {}
    stub_request(method, "#{base_url}#{path}").with do |req|
      captured[:method] = req.method.to_s.upcase
      captured[:url] = req.uri.to_s
      captured[:headers] = req.headers
      captured[:body] = JSON.parse(req.body) unless req.body.to_s.empty?
      true
    end.to_return(
      status: response_status,
      body: response_body,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    captured
  end

  def wait_for_post(stub_count: 1)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
    until WebMock::RequestRegistry.instance.requested_signatures.hash.values.sum >= stub_count \
          || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.02
    end
  end

  # ----------------------------------------------------------------------
  # events.record — wire body
  # ----------------------------------------------------------------------

  describe "#events.record" do
    it "serializes all parameters into the documented shape" do
      captured = capture_request(:post, "/api/v1/events", 201, event_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(
          action: "invoice.created",
          resource_type: "invoice",
          resource_id: "inv-1",
          occurred_at: Time.utc(2026, 5, 6, 12, 0, 0),
          data: { "snapshot" => { "total_cents" => 4900 }, "req_id" => "abc" },
          idempotency_key: "k-1",
          do_not_forward: true
        )
        client.events.flush(timeout: 2.0)
        wait_for_post
      ensure
        client._close
      end

      expect(captured[:body].keys).to eq(["data"])
      expect(captured[:body]["data"]["type"]).to eq("event")
      # POST: server assigns id; wrapper sends "".
      expect(captured[:body]["data"]["id"]).to eq("")

      attrs = captured[:body]["data"]["attributes"]
      expect(attrs["action"]).to eq("invoice.created")
      expect(attrs["resource_type"]).to eq("invoice")
      expect(attrs["resource_id"]).to eq("inv-1")
      expect(attrs["occurred_at"]).to start_with("2026-05-06T12:00:00")
      expect(attrs["data"]).to eq("snapshot" => { "total_cents" => 4900 }, "req_id" => "abc")
      expect(attrs["do_not_forward"]).to be true

      # Idempotency-Key is a HEADER, not a body attribute.
      expect(attrs).not_to have_key("idempotency_key")
      expect(captured[:headers]["Idempotency-Key"]).to eq("k-1")
    end

    it "minimal call stays within the documented whitelist" do
      # Ruby's generated client emits the model's defaulted nil/false
      # fields verbatim; the no-extra-keys gate is what blocks the next
      # snapshot-style regression.
      captured = capture_request(:post, "/api/v1/events", 201, event_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(action: "invoice.created", resource_type: "invoice", resource_id: "inv-1")
        client.events.flush(timeout: 2.0)
        wait_for_post
      ensure
        client._close
      end

      attrs = captured[:body]["data"]["attributes"]
      expect(attrs).to include("action" => "invoice.created", "resource_type" => "invoice", "resource_id" => "inv-1")
      unexpected = attrs.keys - AUDIT_EVENT_POST_ATTRS
      expect(unexpected).to be_empty,
                            "minimal call must stay within documented whitelist; extras: #{unexpected.inspect}"
    end

    it "serializes do_not_forward as boolean false when caller passes false" do
      # The Ruby generated model emits do_not_forward verbatim; we don't
      # require the wrapper to omit it on default-false. The test guards
      # the value (boolean false, not flipped or coerced).
      captured = capture_request(:post, "/api/v1/events", 201, event_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(action: "x", resource_type: "y", resource_id: "z", do_not_forward: false)
        client.events.flush(timeout: 2.0)
        wait_for_post
      ensure
        client._close
      end

      attrs = captured[:body]["data"]["attributes"]
      expect(attrs["do_not_forward"]).to be(false) if attrs.key?("do_not_forward")
    end

    it "does NOT lift snapshot to the top level when nested in data" do
      # Regression guard for the smplkit-sdk@3.2.21 incident.
      captured = capture_request(:post, "/api/v1/events", 201, event_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(
          action: "invoice.created",
          resource_type: "invoice",
          resource_id: "inv-1",
          data: { "snapshot" => { "total_cents" => 4900 } }
        )
        client.events.flush(timeout: 2.0)
        wait_for_post
      ensure
        client._close
      end

      attrs = captured[:body]["data"]["attributes"]
      expect(attrs).not_to have_key("snapshot")
      expect(attrs.dig("data", "snapshot")).to eq("total_cents" => 4900)
    end

    it "emits no fields outside the documented POST schema" do
      captured = capture_request(:post, "/api/v1/events", 201, event_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(
          action: "invoice.created",
          resource_type: "invoice",
          resource_id: "inv-1",
          occurred_at: Time.utc(2026, 5, 6, 12, 0, 0),
          data: { "k" => "v" },
          idempotency_key: "k-1",
          do_not_forward: true
        )
        client.events.flush(timeout: 2.0)
        wait_for_post
      ensure
        client._close
      end

      attrs = captured[:body]["data"]["attributes"]
      unexpected = attrs.keys - AUDIT_EVENT_POST_ATTRS
      expect(unexpected).to be_empty,
                            "wire body has undocumented fields: #{unexpected.inspect}"
    end
  end

  # ----------------------------------------------------------------------
  # forwarders.create — wire body
  # ----------------------------------------------------------------------

  describe "#forwarders.create" do
    it "serializes all parameters into the documented shape" do
      captured = capture_request(:post, "/api/v1/forwarders", 201, forwarder_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.forwarders.create(
          name: "Datadog production",
          forwarder_type: "datadog",
          http: Smplkit::Audit::ForwarderHttp.new(
            url: "https://siem.example.com/in",
            headers: [Smplkit::Audit::HttpHeader.new(name: "DD-API-KEY", value: "real-secret")]
          ),
          enabled: false,
          filter: { "==" => [{ "var" => "action" }, "user.created"] },
          transform: "$",
          data: { "team" => "platform" }
        )
      ensure
        client._close
      end

      expect(captured[:method]).to eq("POST")
      expect(captured[:body]["data"]["type"]).to eq("forwarder")
      # POST: server assigns id; wrapper sends "".
      expect(captured[:body]["data"]["id"]).to eq("")

      attrs = captured[:body]["data"]["attributes"]
      expect(attrs["name"]).to eq("Datadog production")
      expect(attrs["forwarder_type"]).to eq("datadog")
      expect(attrs["enabled"]).to be false
      expect(attrs["transform"]).to eq("$")
      expect(attrs["data"]).to eq("team" => "platform")
      expect(attrs["http"]["url"]).to eq("https://siem.example.com/in")
      expect(attrs["http"]["headers"]).to eq([{ "name" => "DD-API-KEY", "value" => "real-secret" }])

      # Read-only / immutable fields MUST NOT appear on the wire.
      %w[slug created_at updated_at deleted_at version].each do |ro|
        expect(attrs).not_to have_key(ro), "read-only field #{ro.inspect} should not appear on the wire"
      end
    end

    it "emits no fields outside the documented POST schema" do
      captured = capture_request(:post, "/api/v1/forwarders", 201, forwarder_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.forwarders.create(
          name: "Datadog production",
          forwarder_type: "datadog",
          http: Smplkit::Audit::ForwarderHttp.new(url: "https://x"),
          enabled: true,
          filter: { "x" => 1 },
          transform: "$",
          data: { "k" => "v" }
        )
      ensure
        client._close
      end

      attrs = captured[:body]["data"]["attributes"]
      unexpected = attrs.keys - AUDIT_FORWARDER_POST_ATTRS
      expect(unexpected).to be_empty,
                            "wire body has undocumented fields: #{unexpected.inspect}"
    end
  end

  # ----------------------------------------------------------------------
  # forwarders.update — wire body
  # ----------------------------------------------------------------------

  describe "#forwarders.update" do
    it "serializes all parameters into the documented shape" do
      captured = capture_request(:put, "/api/v1/forwarders/#{fwd_id}", 200, forwarder_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.forwarders.update(
          fwd_id,
          name: "Renamed",
          forwarder_type: "datadog",
          http: Smplkit::Audit::ForwarderHttp.new(
            url: "https://siem.example.com/in",
            headers: [Smplkit::Audit::HttpHeader.new(name: "X-K", value: "real-secret")]
          ),
          enabled: false,
          filter: { "==" => [1, 1] },
          transform: "$",
          data: { "k" => "v" }
        )
      ensure
        client._close
      end

      expect(captured[:method]).to eq("PUT")
      # On PUT, the wrapper echoes the path id into the envelope id.
      expect(captured[:body]["data"]["id"]).to eq(fwd_id)

      attrs = captured[:body]["data"]["attributes"]
      expect(attrs["name"]).to eq("Renamed")
      expect(attrs["enabled"]).to be false
      # Headers carry the real plaintext value the caller supplied — the
      # wrapper does NOT round-trip the redacted GET response.
      expect(attrs["http"]["headers"][0]["value"]).to eq("real-secret")

      %w[slug created_at updated_at deleted_at version].each do |ro|
        expect(attrs).not_to have_key(ro), "read-only field #{ro.inspect} should not appear on the wire"
      end
    end

    it "emits no fields outside the documented POST schema" do
      captured = capture_request(:put, "/api/v1/forwarders/#{fwd_id}", 200, forwarder_response_body)
      client = Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url)
      begin
        client.forwarders.update(
          fwd_id,
          name: "x",
          forwarder_type: "http",
          http: Smplkit::Audit::ForwarderHttp.new(url: "https://x"),
          enabled: true,
          filter: { "x" => 1 },
          transform: "$",
          data: { "k" => "v" }
        )
      ensure
        client._close
      end

      attrs = captured[:body]["data"]["attributes"]
      unexpected = attrs.keys - AUDIT_FORWARDER_POST_ATTRS
      expect(unexpected).to be_empty,
                            "wire body has undocumented fields: #{unexpected.inspect}"
    end
  end
end
# rubocop:enable RSpec/ExampleLength
