# frozen_string_literal: true

module Smplkit
  module Audit
    # +client.audit.functions.test_forwarder.actions.execute(...)+
    class Functions
      attr_reader :test_forwarder

      def initialize(api)
        @test_forwarder = TestForwarderNamespace.new(api)
      end
    end

    # Sub-namespace for the test_forwarder action.
    class TestForwarderNamespace
      attr_reader :actions

      def initialize(api)
        @actions = TestForwarderActions.new(api)
      end
    end

    # +execute+ is a server-side proxy that lets the console preview a
    # destination without browser CORS getting in the way. The audit
    # service applies its SSRF guard before resolving the URL —
    # private/loopback/link-local addresses (incl. the EC2 IMDS at
    # +169.254.169.254+) and disallowed ports are rejected.
    class TestForwarderActions
      def initialize(api)
        @api = api
      end

      def execute(url:, method: "POST", headers: nil, body: nil,
                  success_status: "2xx", timeout_ms: nil)
        req = SmplkitGeneratedClient::Audit::TestForwarderRequest.new(
          url: url,
          method: method,
          headers: (headers || []).map do |h|
            name, value = h.is_a?(Hash) ? [h[:name] || h["name"], h[:value] || h["value"]] : [h.name, h.value]
            SmplkitGeneratedClient::Audit::HttpHeader.new(name: name, value: value)
          end,
          body: body,
          success_status: success_status,
          timeout_ms: timeout_ms
        )
        resp = @api.execute_test_forwarder(req)
        TestForwarderResult.new(
          succeeded: resp.succeeded || false,
          response_status: resp.response_status,
          response_headers: resp.response_headers || {},
          response_body: resp.response_body || "",
          latency_ms: resp.latency_ms,
          error: resp.error
        )
      end
    end
  end
end
