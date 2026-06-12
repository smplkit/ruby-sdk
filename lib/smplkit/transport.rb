# frozen_string_literal: true

require "uri"

module Smplkit
  # Internal per-service HTTP transport construction.
  #
  # The top-level +Smplkit::Client+ needs one authenticated transport per
  # backend service (app, config, flags, logging, jobs) plus a
  # context-registration buffer that +client.platform+ owns. This module builds
  # them in one place so the construction is side-effect-free (transports
  # connect lazily on first call) and shared by the top-level client.
  #
  # There is no audit transport here — +client.audit+ owns its own.
  module Transport
    SDK_OWNED_HEADERS = %w[authorization content-type user-agent].freeze

    module_function

    # Project the runtime +ResolvedConfig+ down to the transport subset.
    #
    # The top-level client's resolved config is a superset of what the
    # transports need; this drops the runtime-only fields (environment,
    # service, telemetry).
    def to_transport_config(cfg, extra_headers = nil)
      ConfigResolution::ResolvedManagementConfig.new(
        api_key: cfg.api_key,
        base_domain: cfg.base_domain,
        scheme: cfg.scheme,
        debug: cfg.debug,
        extra_headers: extra_headers
      )
    end

    # The per-service authenticated transports built for a top-level client.
    #
    # Construction is side-effect-free: each transport connects lazily on its
    # first call. +app_url+ is carried alongside so the account settings client
    # and the WebSocket can reach the app service. +close+ tears down the
    # underlying Faraday connection pools.
    ServiceTransports = Struct.new(
      :app_url, :api_key, :app_http, :config_http, :flags_http, :logging_http, :jobs_http,
      keyword_init: true
    ) do
      def close
        # The generated ApiClient owns Faraday connections that release on GC.
        # No explicit shutdown is exposed; this stub keeps the API stable.
      end
    end

    # Build the five per-service transports from a resolved transport config.
    #
    # Side-effect-free — the underlying Faraday clients are created lazily on
    # the first request. Smpl Jobs is JSON:API, so its transport carries the
    # +application/vnd.api+json+ Accept header.
    def build_service_transports(cfg)
      app_url = ConfigResolution.service_url(cfg.scheme, "app", cfg.base_domain)
      ServiceTransports.new(
        app_url: app_url,
        api_key: cfg.api_key,
        app_http: build_api_client(SmplkitGeneratedClient::App, "app", cfg),
        config_http: build_api_client(SmplkitGeneratedClient::Config, "config", cfg),
        flags_http: build_api_client(SmplkitGeneratedClient::Flags, "flags", cfg),
        logging_http: build_api_client(SmplkitGeneratedClient::Logging, "logging", cfg),
        jobs_http: build_api_client(SmplkitGeneratedClient::Jobs, "jobs", cfg,
                                    accept: "application/vnd.api+json")
      )
    end

    # Build a generated +ApiClient+ for one service from a resolved config.
    #
    # +base_url+, when supplied, overrides the +scheme+/+host+ derived from
    # +subdomain+/+base_domain+ (the path a standalone product client takes
    # when handed a fully-resolved app URL).
    def build_api_client(generated_module, subdomain, cfg, accept: nil, base_url: nil)
      configuration = generated_module::Configuration.new
      if base_url.nil?
        configuration.scheme = cfg.scheme
        configuration.host = "#{subdomain}.#{cfg.base_domain}"
      else
        uri = URI.parse(base_url)
        configuration.scheme = uri.scheme
        port_suffix = uri.port && ![80, 443].include?(uri.port) ? ":#{uri.port}" : ""
        configuration.host = "#{uri.host}#{port_suffix}"
      end
      configuration.base_path = ""
      configuration.access_token = cfg.api_key
      configuration.debugging = cfg.debug
      HttpPool.configure(configuration)
      generated_module::ApiClient.new(configuration).tap do |client|
        client.default_headers["User-Agent"] = "smplkit-ruby-sdk/#{Smplkit::VERSION}"
        client.default_headers["Accept"] = accept if accept
        (cfg.extra_headers || {}).each do |k, v|
          client.default_headers[k] = v unless SDK_OWNED_HEADERS.include?(k.downcase)
        end
      end
    end
  end
end
