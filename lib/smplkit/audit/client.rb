# frozen_string_literal: true

module Smplkit
  module Audit
    # Audit-product entry point — accessed via +client.audit+.
    #
    # Owns event recording and read-side queries: fire-and-forget
    # +#events.record+, plus the audit-log +list+ / +get+ and the
    # distinct-value listings that back the Activity tab filter
    # dropdowns. ADR-047 §2.7.
    #
    # SIEM forwarder CRUD lives on {Smplkit::ManagementClient} under
    # +mgmt.audit.forwarders.*+.
    class AuditClient
      attr_reader :events, :resource_types, :event_types

      SDK_OWNED_HEADERS = %w[authorization content-type user-agent].freeze

      def initialize(api_key:, base_url:, timeout: 10.0, extra_headers: nil)
        cfg = SmplkitGeneratedClient::Audit::Configuration.new
        cfg.host = URI.parse(base_url).host
        cfg.scheme = URI.parse(base_url).scheme
        cfg.access_token = api_key
        cfg.timeout = timeout
        api_client = SmplkitGeneratedClient::Audit::ApiClient.new(cfg)
        api_client.default_headers["User-Agent"] = "smplkit-ruby-sdk/#{Smplkit::VERSION}"
        extra_headers&.each do |k, v|
          api_client.default_headers[k] = v unless SDK_OWNED_HEADERS.include?(k.downcase)
        end
        @events = Events.new(SmplkitGeneratedClient::Audit::EventsApi.new(api_client))
        @resource_types = ResourceTypes.new(SmplkitGeneratedClient::Audit::ResourceTypesApi.new(api_client))
        @event_types = EventTypes.new(SmplkitGeneratedClient::Audit::EventTypesApi.new(api_client))
      end

      def _close
        @events._close
      end
    end
  end
end
