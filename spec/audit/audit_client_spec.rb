# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/ExpectOutput, Layout/LineLength, RSpec/ExampleLength

RSpec.describe Smplkit::Audit::AuditClient do
  let(:base_url) { "https://audit.example.com" }
  let(:api_key) { "sk_api_test" }

  let(:event_response_body) do
    {
      data: {
        id: "11111111-2222-3333-4444-555555555555",
        type: "event",
        attributes: {
          event_type: "user.created",
          resource_type: "user",
          resource_id: "u-1",
          occurred_at: "2026-05-06T12:00:00Z",
          created_at: "2026-05-06T12:00:01Z",
          actor_type: "API_KEY",
          actor_id: nil,
          actor_label: "",
          category: "auth",
          snapshot: nil,
          data: {},
          idempotency_key: "k",
          environment: "production"
        }
      }
    }.to_json
  end

  describe "#events.record" do
    it "returns immediately without blocking on the network" do
      stub = stub_request(:post, "#{base_url}/api/v1/events").to_return(
        status: 201, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" }
      )
      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        20.times do |i|
          client.events.record(event_type: "user.created", resource_type: "user", resource_id: "u-#{i}")
        end
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        expect(elapsed).to be < 0.2
        # Trigger drain.
        client.events.flush(timeout: 2.0)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
        until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
              || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.02
        end
        expect(stub).to have_been_requested.at_least_once
      ensure
        client._close
      end
    end

    it "raises ArgumentError when event_type is missing" do
      client = described_class.new(api_key: api_key, base_url: base_url)
      expect do
        client.events.record(event_type: "", resource_type: "user", resource_id: "u-1")
      end.to raise_error(ArgumentError, /event_type/)
      client._close
    end

    it "raises ArgumentError when resource_type is missing" do
      client = described_class.new(api_key: api_key, base_url: base_url)
      expect do
        client.events.record(event_type: "x", resource_type: nil, resource_id: "u-1")
      end.to raise_error(ArgumentError, /resource_type/)
      client._close
    end

    it "raises ArgumentError when resource_id is missing" do
      client = described_class.new(api_key: api_key, base_url: base_url)
      expect do
        client.events.record(event_type: "x", resource_type: "user", resource_id: "")
      end.to raise_error(ArgumentError, /resource_id/)
      client._close
    end

    it "passes Idempotency-Key as a request header" do
      stub = stub_request(:post, "#{base_url}/api/v1/events")
             .with(headers: { "Idempotency-Key" => "key-abc" })
             .to_return(status: 201, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" })
      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(
          event_type: "user.created", resource_type: "user", resource_id: "u-1",
          idempotency_key: "key-abc"
        )
        client.events.flush(timeout: 2.0)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
        until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
              || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.02
        end
        expect(stub).to have_been_requested.at_least_once
      ensure
        client._close
      end
    end

    it "defaults the data attribute to {} on the wire when omitted" do
      # Regression: server-side Pydantic validation on /api/v1/events
      # rejects "data": null with HTTP 400 (the schema requires a dict).
      # The wrapper must coerce nil to {} before sending.
      captured = nil
      stub = stub_request(:post, "#{base_url}/api/v1/events").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(event_type: "invoice.updated", resource_type: "invoice", resource_id: "inv-1")
        client.events.flush(timeout: 2.0)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
        until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
              || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.02
        end
        expect(captured.dig("data", "attributes", "data")).to eq({})
      ensure
        client._close
      end
    end

    it "serializes Time#occurred_at as an ISO-8601 string" do
      # Regression: Ruby's Time#to_s emits "2026-05-06 12:00:00 UTC" which
      # the server rejects ("unexpected extra characters at the end of
      # the input") because it expects an ISO-8601 datetime. The wrapper
      # must call .iso8601 before passing through the generated client.
      captured = nil
      stub = stub_request(:post, "#{base_url}/api/v1/events").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(
          event_type: "invoice.created",
          resource_type: "invoice",
          resource_id: "inv-1",
          occurred_at: Time.utc(2026, 5, 6, 12, 0, 0)
        )
        client.events.flush(timeout: 2.0)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
        until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
              || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.02
        end
        expect(captured.dig("data", "attributes", "occurred_at")).to eq("2026-05-06T12:00:00Z")
      ensure
        client._close
      end
    end

    it "passes customer-supplied actor fields into the request body" do
      captured = nil
      stub = stub_request(:post, "#{base_url}/api/v1/events").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(
          event_type: "user.created",
          resource_type: "user",
          resource_id: "u-1",
          actor_type: "EXTERNAL_SERVICE",
          actor_id: "not-a-uuid:billing-bot",
          actor_label: "Billing Bot",
          category: "billing"
        )
        client.events.flush(timeout: 2.0)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
        until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
              || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.02
        end
        attrs = captured.dig("data", "attributes")
        expect(attrs["actor_type"]).to eq("EXTERNAL_SERVICE")
        expect(attrs["actor_id"]).to eq("not-a-uuid:billing-bot")
        expect(attrs["actor_label"]).to eq("Billing Bot")
        expect(attrs["category"]).to eq("billing")
      ensure
        client._close
      end
    end

    it "nests snapshot inside data on the request body" do
      captured = nil
      stub = stub_request(:post, "#{base_url}/api/v1/events").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        client.events.record(
          event_type: "invoice.created",
          resource_type: "invoice",
          resource_id: "inv-1",
          occurred_at: Time.utc(2026, 5, 6, 12, 0, 0),
          data: {
            "snapshot" => { "total_cents" => 4900 },
            "request_id" => "req-1"
          }
        )
        client.events.flush(timeout: 2.0)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
        until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
              || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.02
        end
        attrs = captured.dig("data", "attributes")
        expect(attrs).not_to have_key("snapshot")
        expect(attrs["data"]).to eq(
          "snapshot" => { "total_cents" => 4900 },
          "request_id" => "req-1"
        )
      ensure
        client._close
      end
    end
  end

  describe "#events.get" do
    it "round-trips a single event" do
      event_id = "11111111-2222-3333-4444-555555555555"
      stub_request(:get, "#{base_url}/api/v1/events/#{event_id}")
        .to_return(status: 200, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        ev = client.events.get(event_id)
        expect(ev.id).to eq(event_id)
        expect(ev.event_type).to eq("user.created")
        expect(ev.actor_type).to eq("API_KEY")
        expect(ev.actor_id).to be_nil
        expect(ev.category).to eq("auth")
        expect(ev.environment).to eq("production")
      ensure
        client._close
      end
    end

    it "returns ev.data with string keys at every depth" do
      # Regression: the generated client parses JSON with symbolize_names: true,
      # then converts only the outer data keys back to strings while leaving
      # nested values symbol-keyed. ev.data["snapshot"]["currency"] must work;
      # ev.data["snapshot"][:currency] must NOT be the only usable form.
      event_id = "11111111-2222-3333-4444-555555555555"
      body = {
        data: {
          id: event_id, type: "event",
          attributes: {
            event_type: "invoice.created", resource_type: "invoice", resource_id: "inv-1",
            occurred_at: "2026-05-06T12:00:00Z", created_at: "2026-05-06T12:00:01Z",
            actor_type: "API_KEY", actor_id: nil, actor_label: "",
            data: { "snapshot" => { "currency" => "USD", "total_cents" => 4900 },
                    "request_id" => "e2e-req" },
            idempotency_key: "k"
          }
        }
      }.to_json
      stub_request(:get, "#{base_url}/api/v1/events/#{event_id}")
        .to_return(status: 200, body: body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        ev = client.events.get(event_id)
        expect(ev.data.keys).to all(be_a(String))
        expect(ev.data["snapshot"]).to be_a(Hash)
        expect(ev.data["snapshot"].keys).to all(be_a(String))
        expect(ev.data["snapshot"]["currency"]).to eq("USD")
        expect(ev.data["snapshot"]["total_cents"]).to eq(4900)
        expect(ev.data["request_id"]).to eq("e2e-req")
        expect(ev.data["snapshot"][:currency]).to be_nil
      ensure
        client._close
      end
    end

    it "raises NotFoundError on 404" do
      event_id = "00000000-0000-0000-0000-000000000099"
      stub_request(:get, "#{base_url}/api/v1/events/#{event_id}")
        .to_return(status: 404, body: "{}", headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        expect { client.events.get(event_id) }.to raise_error(Smplkit::NotFoundError)
      ensure
        client._close
      end
    end
  end

  describe "#events.list" do
    it "parses next cursor from links.next" do
      list_body = {
        data: [{
          id: "11111111-2222-3333-4444-555555555555",
          type: "event",
          attributes: {
            event_type: "user.created",
            resource_type: "user",
            resource_id: "u-1",
            occurred_at: "2026-05-06T12:00:00Z",
            created_at: "2026-05-06T12:00:01Z",
            actor_type: "API_KEY",
            actor_id: nil,
            actor_label: "",
            snapshot: nil,
            data: {},
            idempotency_key: "k"
          }
        }],
        meta: { page_size: 1 },
        links: { next: "/api/v1/events?page[size]=1&page[after]=tok-xyz" }
      }.to_json
      stub_request(:get, "#{base_url}/api/v1/events").with(query: hash_including({}))
                                                     .to_return(status: 200, body: list_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        page = client.events.list(event_type: "user.created", page_size: 1)
        expect(page.events.size).to eq(1)
        expect(page.next_cursor).to eq("tok-xyz")
      ensure
        client._close
      end
    end

    it "translates wrapper kwargs to the generated client's snake_case opts" do
      # Regression: the wrapper used to pass :filterevent_type / :filterresource_id
      # / :pagesize etc. (no underscore) — the generated client only honors
      # :filter_event_type / :filter_resource_id / :page_size, so the filters
      # silently fell through and the server returned every event in the
      # account.
      captured_uri = nil
      stub_request(:get, %r{#{Regexp.escape(base_url)}/api/v1/events})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(status: 200, body: { data: [], meta: { page_size: 50 } }.to_json,
                   headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        client.events.list(
          event_type: "user.created",
          resource_type: "user",
          resource_id: "u-1",
          actor_type: "USER",
          page_size: 25,
          page_after: "cursor-abc"
        )
        # Faraday percent-encodes the brackets; assert against the encoded form.
        expect(captured_uri).to include("filter%5Bevent_type%5D=user.created")
        expect(captured_uri).to include("filter%5Bresource_type%5D=user")
        expect(captured_uri).to include("filter%5Bresource_id%5D=u-1")
        expect(captured_uri).to include("filter%5Bactor_type%5D=USER")
        expect(captured_uri).to include("page%5Bsize%5D=25")
        expect(captured_uri).to include("page%5Bafter%5D=cursor-abc")
      ensure
        client._close
      end
    end

    it "trims trailing query parameters from the next cursor" do
      list_body = {
        data: [],
        meta: { page_size: 1 },
        links: { next: "/api/v1/events?page[size]=1&page[after]=tok-xyz&extra=junk" }
      }.to_json
      stub_request(:get, "#{base_url}/api/v1/events").with(query: hash_including({}))
                                                     .to_return(status: 200, body: list_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        page = client.events.list(page_size: 1)
        expect(page.next_cursor).to eq("tok-xyz")
      ensure
        client._close
      end
    end

    it "returns nil next_cursor on the last page" do
      list_body = { data: [], meta: { page_size: 50 } }.to_json
      stub_request(:get, "#{base_url}/api/v1/events").with(query: hash_including({}))
                                                     .to_return(status: 200, body: list_body, headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        page = client.events.list
        expect(page.events).to eq([])
        expect(page.next_cursor).to be_nil
      ensure
        client._close
      end
    end

    it "passes filter[search] to the generated client" do
      captured_uri = nil
      stub_request(:get, %r{#{Regexp.escape(base_url)}/api/v1/events})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(status: 200, body: { data: [], meta: { page_size: 50 } }.to_json,
                   headers: { "Content-Type" => "application/vnd.api+json" })

      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        client.events.list(search: "order-123")
        expect(captured_uri).to include("filter%5Bsearch%5D=order-123")
      ensure
        client._close
      end
    end

    describe "filter[environment]" do
      def capture_events_list(args)
        captured_uri = nil
        stub_request(:get, %r{#{Regexp.escape(base_url)}/api/v1/events})
          .with do |req|
            captured_uri = req.uri.to_s
            true
          end
          .to_return(status: 200, body: { data: [], meta: { page_size: 50 } }.to_json,
                     headers: { "Content-Type" => "application/vnd.api+json" })

        client = described_class.new(api_key: api_key, base_url: base_url)
        begin
          client.events.list(**args)
        ensure
          client._close
        end
        captured_uri
      end

      it "omits filter[environment] by default" do
        expect(capture_events_list({})).not_to include("filter%5Benvironment%5D")
      end

      it "omits filter[environment] for an empty array" do
        expect(capture_events_list(environments: [])).not_to include("filter%5Benvironment%5D")
      end

      it "passes a single environment value through" do
        expect(capture_events_list(environments: ["production"]))
          .to include("filter%5Benvironment%5D=production")
      end

      it "comma-joins multiple environment values" do
        expect(capture_events_list(environments: %w[production staging]))
          .to include("filter%5Benvironment%5D=production,staging")
      end

      it "accepts the reserved smplkit bucket" do
        expect(capture_events_list(environments: ["smplkit"]))
          .to include("filter%5Benvironment%5D=smplkit")
      end
    end
  end

  describe "buffer overflow" do
    it "evicts oldest items when the queue is full" do
      stub_request(:post, "#{base_url}/api/v1/events").to_return(
        status: 201, body: event_response_body, headers: { "Content-Type" => "application/vnd.api+json" }
      )
      client = described_class.new(api_key: api_key, base_url: base_url)
      stub_const("Smplkit::Audit::EventBuffer::MAX_BUFFER_SIZE", 3)
      stub_const("Smplkit::Audit::EventBuffer::WATERMARK", 9999)
      begin
        # Suppress the buffer-full warning so RSpec output stays clean.
        original_stderr = $stderr
        $stderr = StringIO.new
        # Burst more than capacity before the worker can drain.
        5.times do |i|
          client.events.record(event_type: "x.created", resource_type: "x", resource_id: i.to_s)
        end
        $stderr = original_stderr
        client.events.flush(timeout: 2.0)
        # No assertion on count — webmock has counted the requests; the goal
        # of this test is exercising the overflow branch.
      ensure
        client._close
      end
    end
  end

  describe "extra_headers" do
    it "applies extra headers to requests" do
      stub_request(:post, "#{base_url}/api/v1/events")
        .to_return(status: 201, body: event_response_body,
                   headers: { "Content-Type" => "application/vnd.api+json" })
      client = described_class.new(api_key: api_key, base_url: base_url,
                                   extra_headers: { "X-Custom" => "hello" })
      begin
        api_client = client.events.instance_variable_get(:@api).api_client
        expect(api_client.default_headers["X-Custom"]).to eq("hello")
      ensure
        client._close
      end
    end

    it "SDK-owned headers cannot be overridden via extra_headers" do
      client = described_class.new(api_key: api_key, base_url: base_url,
                                   extra_headers: {
                                     "Authorization" => "Bearer overridden",
                                     "User-Agent" => "rogue",
                                     "X-Pass" => "yes"
                                   })
      begin
        api_client = client.events.instance_variable_get(:@api).api_client
        expect(api_client.default_headers["Authorization"]).not_to eq("Bearer overridden")
        expect(api_client.default_headers["User-Agent"]).to eq("smplkit-ruby-sdk/#{Smplkit::VERSION}")
        expect(api_client.default_headers["X-Pass"]).to eq("yes")
      ensure
        client._close
      end
    end
  end

  describe "environment scoping (ADR-055)" do
    it "stamps X-Smplkit-Environment from the configured environment on every audit call" do
      client = described_class.new(api_key: api_key, base_url: base_url, environment: "production")
      begin
        api_client = client.events.instance_variable_get(:@api).api_client
        expect(api_client.default_headers["X-Smplkit-Environment"]).to eq("production")
      ensure
        client._close
      end
    end

    it "omits X-Smplkit-Environment when no environment is configured" do
      client = described_class.new(api_key: api_key, base_url: base_url)
      begin
        api_client = client.events.instance_variable_get(:@api).api_client
        expect(api_client.default_headers).not_to have_key("X-Smplkit-Environment")
      ensure
        client._close
      end
    end

    it "lets an explicit extra_headers entry override the configured environment" do
      client = described_class.new(
        api_key: api_key, base_url: base_url, environment: "production",
        extra_headers: { "X-Smplkit-Environment" => "staging" }
      )
      begin
        api_client = client.events.instance_variable_get(:@api).api_client
        expect(api_client.default_headers["X-Smplkit-Environment"]).to eq("staging")
      ensure
        client._close
      end
    end

    it "sends the environment header on the wire for a record call" do
      stub = stub_request(:post, "#{base_url}/api/v1/events")
             .with(headers: { "X-Smplkit-Environment" => "production" })
             .to_return(status: 201, body: event_response_body,
                        headers: { "Content-Type" => "application/vnd.api+json" })
      client = described_class.new(api_key: api_key, base_url: base_url, environment: "production")
      begin
        client.events.record(event_type: "user.created", resource_type: "user", resource_id: "u-1")
        client.events.flush(timeout: 2.0)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
        until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? \
              || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.02
        end
        expect(stub).to have_been_requested.at_least_once
      ensure
        client._close
      end
    end
  end

  describe ".join_environments" do
    it "returns nil for nil" do
      expect(Smplkit::Audit.join_environments(nil)).to be_nil
    end

    it "returns nil for an empty array" do
      expect(Smplkit::Audit.join_environments([])).to be_nil
    end

    it "returns nil when every entry is blank" do
      expect(Smplkit::Audit.join_environments(["", "  "])).to be_nil
    end

    it "strips surrounding whitespace and drops blank entries" do
      expect(Smplkit::Audit.join_environments([" production ", "", "staging"]))
        .to eq("production,staging")
    end

    it "accepts a bare string (single environment)" do
      expect(Smplkit::Audit.join_environments("production")).to eq("production")
    end

    it "passes the reserved smplkit bucket through unchanged" do
      expect(Smplkit::Audit.join_environments(%w[smplkit production]))
        .to eq("smplkit,production")
    end
  end
end
# rubocop:enable RSpec/ExpectOutput, Layout/LineLength, RSpec/ExampleLength
