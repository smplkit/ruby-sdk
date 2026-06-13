# frozen_string_literal: true

require "faraday"
require "json"

module Smplkit
  module Account
    # Resolve the (app_base_url, api_key, extra_headers) for the settings client.
    #
    # +base_url+/+api_key+ are used directly when both are supplied (the path
    # the top-level client takes after it has already resolved them); otherwise
    # the config resolver fills in whatever is missing.
    #
    # @api private
    def self.resolve_account_target(api_key:, base_url:, profile:, base_domain:, scheme:, debug:, extra_headers:)
      cfg = ConfigResolution.resolve_client_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme, debug: debug
      )
      resolved_key = api_key.nil? ? cfg.api_key : api_key
      app_url = base_url.nil? ? ConfigResolution.service_url(cfg.scheme, "app", cfg.base_domain) : base_url
      headers = {}
      headers.merge!(cfg.extra_headers || {})
      headers.merge!(extra_headers || {})
      [app_url.sub(%r{/+\z}, ""), resolved_key, headers]
    end

    # Sync account-settings get/save (+client.account.settings+).
    #
    # The endpoint isn't JSON:API — body is a raw JSON object — so we use an
    # HTTP client directly rather than going through a generated client.
    class SettingsClient
      SETTINGS_PATH = "/api/v1/accounts/current/settings"

      def initialize(app_base_url, api_key, extra_headers = nil)
        @base_url = app_base_url
        @headers = {
          "Authorization" => "Bearer #{api_key}",
          "Content-Type" => "application/json"
        }.merge(extra_headers || {})
      end

      # Fetch the authenticated account's current settings.
      #
      # @return [Smplkit::Account::AccountSettings] An active record. Mutate its
      #   fields and call +save+ to persist the changes.
      def get
        resp = connection.get(SETTINGS_PATH)
        Errors.raise_for_status(resp.status, resp.body.to_s)
        AccountSettings.new(self, data: parse_body(resp.body))
      end

      # @api private
      def _save(data)
        resp = connection.put(SETTINGS_PATH) { |req| req.body = JSON.generate(data) }
        Errors.raise_for_status(resp.status, resp.body.to_s)
        AccountSettings.new(self, data: parse_body(resp.body))
      end

      private

      # A short-lived connection per call — mirrors the Python settings client
      # opening and closing its own HTTP client each time.
      def connection
        Faraday.new(url: @base_url, headers: @headers, request: { timeout: 30 })
      end

      def parse_body(body)
        return {} if body.nil? || body.to_s.empty?

        parsed = JSON.parse(body)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError
        {}
      end
    end

    # The Smpl Account client (sync).
    #
    # Exposes the authenticated account's own configuration, reachable as
    # +client.account+ (+Smplkit::Client+) or constructed directly:
    #
    #   account = Smplkit::AccountClient.new(api_key: "sk_...")
    #   settings = account.settings.get
    #   settings.environment_order = ["production", "staging"]
    #   settings.save
    #
    # Sub-client: +settings+ (get/save). Pure CRUD — no +install+ required.
    #
    # @param api_key [String, nil] API key. When omitted, resolved from
    #   +SMPLKIT_API_KEY+ or +~/.smplkit+.
    # @param base_url [String, nil] Full app-service base URL. Usually resolved
    #   from +base_domain+/+scheme+; supplied directly by the top-level clients
    #   which have already computed it.
    # @param profile [String, nil] Named +~/.smplkit+ profile section.
    # @param base_domain [String, nil] Base domain for API requests (default
    #   +"smplkit.com"+).
    # @param scheme [String, nil] URL scheme (default +"https"+).
    # @param debug [Boolean, nil] Enable SDK debug logging.
    # @param extra_headers [Hash, nil] Extra headers attached to every request.
    class AccountClient
      attr_reader :settings

      def initialize(api_key: nil, base_url: nil, profile: nil, base_domain: nil,
                     scheme: nil, debug: nil, extra_headers: nil)
        app_url, resolved_key, headers = Account.resolve_account_target(
          api_key: api_key, base_url: base_url, profile: profile,
          base_domain: base_domain, scheme: scheme, debug: debug, extra_headers: extra_headers
        )
        @settings = SettingsClient.new(app_url, resolved_key, headers.empty? ? nil : headers)
      end

      # No-op — the settings client opens a short-lived HTTP client per call.
      def close; end

      # Construct, yield to the block, and close on exit.
      def self.open(**kwargs)
        client = new(**kwargs)
        begin
          yield client
        ensure
          client.close
        end
      end
    end
  end

  AccountClient = Account::AccountClient
end
