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
    #   and reads to. Sent on the event request body when recording and as the
    #   default +filter[environment]+ on the read surfaces (events list and the
    #   resource_type / event_type / category discovery lists). When omitted,
    #   resolved from +SMPLKIT_ENVIRONMENT+ or +~/.smplkit+. Optional —
    #   forwarder CRUD is environment-agnostic, and reads accept an explicit
    #   +environments: [...]+ filter that overrides this default. With no
    #   configured environment, recording falls back to the server-side default
    #   environment and the read filter is left off.
    # @param profile [String, nil] Named +~/.smplkit+ profile section.
    # @param base_domain [String, nil] Base domain for API requests (default
    #   +"smplkit.com"+).
    # @param scheme [String, nil] URL scheme (default +"https"+).
    # @param debug [Boolean, nil] Enable SDK debug logging.
    # @param timeout [Float] Per-request timeout, in seconds. Defaults to +10.0+.
    # @param extra_headers [Hash{String => String}, nil] Extra headers attached
    #   to every request. SDK-owned headers (authorization, content-type,
    #   user-agent) cannot be overridden.
    # @param buffered [Boolean] Buffer event recording (default +true+):
    #   +events.record+ enqueues onto an in-memory buffer that a background
    #   worker drains with retry, and returns immediately. Set +false+ for the
    #   stateless write path: +events.record+ performs one blocking POST per
    #   call and raises on failure, +events.flush+ is a no-op, and no worker
    #   thread or background state is created — the right shape for serverless
    #   and edge runtimes, where an instance may be constructed per request.
    class AuditClient
      attr_reader :events, :resource_types, :event_types, :categories, :forwarders

      SDK_OWNED_HEADERS = %w[authorization content-type user-agent].freeze

      def initialize(api_key: nil, base_url: nil, environment: nil, profile: nil,
                     base_domain: nil, scheme: nil, debug: nil, timeout: 10.0,
                     extra_headers: nil, buffered: true)
        # +api_key+/+base_url+/+environment+ are used directly when all three
        # are supplied (the path the top-level client takes after it has
        # already resolved them); otherwise the config resolver fills in
        # whatever is missing (+~/.smplkit+ / env vars / defaults) and the
        # audit base URL is derived from +base_domain+/+scheme+ via
        # +service_url+.
        if api_key.nil? || base_url.nil? || environment.nil?
          resolved = ConfigResolution.resolve_client_config(
            profile: profile, api_key: api_key, base_domain: base_domain,
            scheme: scheme, environment: environment, debug: debug
          )
          api_key = resolved.api_key if api_key.nil?
          base_url = ConfigResolution.service_url(resolved.scheme, "audit", resolved.base_domain) if base_url.nil?
          environment = resolved.environment if environment.nil?
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
        # Runtime audit ops are environment-scoped, but the scoping is
        # body-driven (ADR-055): +events.record+ stamps the configured
        # environment onto the event request body, and the read surfaces
        # (events list plus the resource_type / event_type / category discovery
        # lists) default +filter[environment]+ to it. The transport therefore
        # carries only auth plus any caller-supplied +extra_headers+ — no
        # environment header. Forwarder CRUD is environment-agnostic.
        extra_headers&.each do |k, v|
          api_client.default_headers[k] = v unless SDK_OWNED_HEADERS.include?(k.downcase)
        end
        @events = Events.new(
          SmplkitGeneratedClient::Audit::EventsApi.new(api_client),
          environment: environment, buffered: buffered
        )
        @resource_types = ResourceTypes.new(
          SmplkitGeneratedClient::Audit::ResourceTypesApi.new(api_client), environment: environment
        )
        @event_types = EventTypes.new(
          SmplkitGeneratedClient::Audit::EventTypesApi.new(api_client), environment: environment
        )
        @categories = Categories.new(
          SmplkitGeneratedClient::Audit::CategoriesApi.new(api_client), environment: environment
        )
        @forwarders = ForwardersClient.new(SmplkitGeneratedClient::Audit::ForwardersApi.new(api_client))
      end

      def _close
        @events._close
      end
    end
  end

  AuditClient = Audit::AuditClient
end
