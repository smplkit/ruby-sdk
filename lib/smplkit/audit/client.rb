# frozen_string_literal: true

module Smplkit
  module Audit
    # The Smpl Audit client — accessed via +client.audit+.
    #
    # One client exposes the full surface — there is no runtime/management
    # split for audit. Owns event recording and read-side queries:
    # fire-and-forget +#events.record+, plus the audit-log +list+ / +get+ and
    # the distinct-value listings (+resource_types+, +event_types+,
    # +categories+) that back the Activity tab filter dropdowns, plus SIEM
    # forwarder CRUD on +#forwarders+. ADR-047 §2.7.
    class AuditClient
      attr_reader :events, :resource_types, :event_types, :categories, :forwarders

      SDK_OWNED_HEADERS = %w[authorization content-type user-agent].freeze

      def initialize(api_key:, base_url:, environment: nil, timeout: 10.0, extra_headers: nil)
        cfg = SmplkitGeneratedClient::Audit::Configuration.new
        cfg.host = URI.parse(base_url).host
        cfg.scheme = URI.parse(base_url).scheme
        cfg.access_token = api_key
        cfg.timeout = timeout
        HttpPool.configure(cfg)
        api_client = SmplkitGeneratedClient::Audit::ApiClient.new(cfg)
        api_client.default_headers["User-Agent"] = "smplkit-ruby-sdk/#{Smplkit::VERSION}"
        # Runtime audit ops are environment-scoped: record / list / get /
        # discovery all resolve their environment from the
        # +X-Smplkit-Environment+ request header (ADR-055). We stamp it once
        # at the client level from the SDK's configured runtime environment so
        # every generated call carries it. It is stamped before +extra_headers+
        # is applied so a caller-supplied entry of the same name wins (explicit
        # override).
        api_client.default_headers["X-Smplkit-Environment"] = environment unless environment.nil?
        extra_headers&.each do |k, v|
          api_client.default_headers[k] = v unless SDK_OWNED_HEADERS.include?(k.downcase)
        end
        @events = Events.new(SmplkitGeneratedClient::Audit::EventsApi.new(api_client))
        @resource_types = ResourceTypes.new(SmplkitGeneratedClient::Audit::ResourceTypesApi.new(api_client))
        @event_types = EventTypes.new(SmplkitGeneratedClient::Audit::EventTypesApi.new(api_client))
        @categories = Categories.new(SmplkitGeneratedClient::Audit::CategoriesApi.new(api_client))
        @forwarders = ForwardersClient.new(SmplkitGeneratedClient::Audit::ForwardersApi.new(api_client))
      end

      def _close
        @events._close
      end
    end
  end
end
