# frozen_string_literal: true

module Smplkit
  module Audit
    # Audit-product entry point — accessed via +client.audit+.
    #
    # Today the audit namespace is exclusively +#events+; future
    # iterations may add SIEM exports as additional sub-clients
    # (ADR-047 §2.7 lists SIEM streaming as a Pro-tier capability).
    class AuditClient
      attr_reader :events, :forwarders, :functions

      def initialize(api_key:, base_url:, timeout: 10.0)
        cfg = SmplkitGeneratedClient::Audit::Configuration.new
        cfg.host = URI.parse(base_url).host
        cfg.scheme = URI.parse(base_url).scheme
        cfg.access_token = api_key
        cfg.timeout = timeout
        api_client = SmplkitGeneratedClient::Audit::ApiClient.new(cfg)
        events_api = SmplkitGeneratedClient::Audit::EventsApi.new(api_client)
        forwarders_api = SmplkitGeneratedClient::Audit::ForwardersApi.new(api_client)
        @events = Events.new(events_api)
        @forwarders = Forwarders.new(forwarders_api)
        @functions = Functions.new(forwarders_api)
      end

      def _close
        @events._close
      end
    end
  end
end
