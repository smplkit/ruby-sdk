# frozen_string_literal: true

module Smplkit
  module Audit
    # The Smpl Audit client — accessed via +client.audit+.
    #
    # One client exposes the full surface — event recording and reads,
    # distinct-value discovery, and SIEM forwarder CRUD. Owns fire-and-forget
    # +#events.record+, plus the audit-log +list+ / +get+ and the distinct-value
    # listings (+resource_types+, +event_types+, +categories+), plus SIEM
    # forwarder CRUD on +#forwarders+.
    #
    # Reachable as +client.audit+ (+Smplkit::Client+) or constructed directly —
    # +AuditClient.new+ resolves credentials from +~/.smplkit+ / env vars and
    # derives the audit base URL from +base_domain+/+scheme+ when +base_url+ is
    # omitted.
    #
    # @param api_key [String, nil] API key used to authenticate every request.
    #   When omitted, resolved from +SMPLKIT_API_KEY+ or +~/.smplkit+.
    # @param base_url [String, nil] Full audit-service base URL. Usually resolved
    #   from +base_domain+/+scheme+; supplied directly by the top-level clients
    #   which have already computed it.
    # @param environment [String, nil] Deployment environment to scope recording
    #   and reads to. Optional — forwarder CRUD and discovery are
    #   environment-agnostic, and reads accept an explicit +environments: [...]+
    #   filter.
    # @param profile [String, nil] Named +~/.smplkit+ profile section.
    # @param base_domain [String, nil] Base domain for API requests (default
    #   +"smplkit.com"+).
    # @param scheme [String, nil] URL scheme (default +"https"+).
    # @param debug [Boolean, nil] Enable SDK debug logging.
    # @param timeout [Float] Per-request timeout, in seconds. Defaults to +10.0+.
    # @param extra_headers [Hash{String => String}, nil] Extra headers attached
    #   to every request. SDK-owned headers (authorization, content-type,
    #   user-agent) cannot be overridden.
    class AuditClient
      attr_reader :events, :resource_types, :event_types, :categories, :forwarders

      SDK_OWNED_HEADERS = %w[authorization content-type user-agent].freeze

      def initialize(api_key: nil, base_url: nil, environment: nil, profile: nil,
                     base_domain: nil, scheme: nil, debug: nil, timeout: 10.0,
                     extra_headers: nil)
        # +base_url+/+api_key+ are used directly when both are supplied (the
        # path the top-level client takes after it has already resolved them);
        # otherwise the config resolver fills in whatever is missing
        # (+~/.smplkit+ / env vars / defaults) and the audit base URL is derived
        # from +base_domain+/+scheme+ via +service_url+.
        if api_key.nil? || base_url.nil?
          resolved = ConfigResolution.resolve_client_config(
            profile: profile, api_key: api_key, base_domain: base_domain,
            scheme: scheme, debug: debug
          )
          api_key = resolved.api_key if api_key.nil?
          base_url = ConfigResolution.service_url(resolved.scheme, "audit", resolved.base_domain) if base_url.nil?
          debug = resolved.debug if debug.nil?
        end
        cfg = SmplkitGeneratedClient::Audit::Configuration.new
        cfg.host = URI.parse(base_url).host
        cfg.scheme = URI.parse(base_url).scheme
        cfg.access_token = api_key
        cfg.timeout = timeout
        cfg.debugging = debug unless debug.nil?
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

  AuditClient = Audit::AuditClient
end
