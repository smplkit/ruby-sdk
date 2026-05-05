# frozen_string_literal: true

require "concurrent"

module Smplkit
  # Synchronous entry point for the smplkit SDK.
  #
  #   client = Smplkit::Client.new(environment: "production", service: "my-svc")
  #   checkout_v2 = client.flags.boolean_flag("checkout-v2", default: false)
  #   if checkout_v2.get
  #     # ...
  #   end
  #   client.close
  #
  # Block form:
  #
  #   Smplkit::Client.open(environment: "production", service: "my-svc") do |client|
  #     # ...
  #   end
  #
  # All parameters are optional. When omitted, the SDK resolves them from
  # environment variables (+SMPLKIT_*+) or the +~/.smplkit+ configuration file.
  # See ADR-021 for the full resolution algorithm.
  #
  # +Smplkit::Client+ is thread-safe by construction. Background work runs on
  # internal SDK-owned threads; public methods block the calling thread and
  # return values directly.
  class Client
    PERIODIC_FLUSH_INTERVAL = 60.0

    attr_reader :manage, :config, :flags, :logging

    # Construct, yield to the block, and close on exit.
    def self.open(**)
      client = new(**)
      begin
        yield client
      ensure
        client.close
      end
    end

    def initialize(api_key: nil, environment: nil, service: nil, profile: nil,
                   base_domain: nil, scheme: nil, debug: nil, telemetry: nil)
      cfg = ConfigResolution.resolve_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme,
        environment: environment, service: service, debug: debug, telemetry: telemetry
      )
      Smplkit.enable_debug if cfg.debug

      @api_key = cfg.api_key
      @environment = cfg.environment
      @service = cfg.service
      @base_domain = cfg.base_domain
      @scheme = cfg.scheme

      masked_key = cfg.api_key.length > 10 ? "#{cfg.api_key[0, 10]}..." : cfg.api_key
      Smplkit.debug(
        "lifecycle",
        "Client init: api_key=#{masked_key} env=#{cfg.environment.inspect} service=#{cfg.service.inspect} " \
        "base_domain=#{cfg.base_domain.inspect} scheme=#{cfg.scheme.inspect} " \
        "debug=#{cfg.debug} telemetry=#{cfg.telemetry}"
      )

      mgmt_cfg = ConfigResolution::ResolvedManagementConfig.new(
        api_key: cfg.api_key, base_domain: cfg.base_domain, scheme: cfg.scheme, debug: cfg.debug
      )
      @manage = ManagementClient.from_resolved(mgmt_cfg)

      app_url = ConfigResolution.service_url(cfg.scheme, "app", cfg.base_domain)
      flags_url = ConfigResolution.service_url(cfg.scheme, "flags", cfg.base_domain)
      logging_url = ConfigResolution.service_url(cfg.scheme, "logging", cfg.base_domain)
      @app_base_url = app_url

      @metrics = if cfg.telemetry
                   MetricsReporter.new(http_client: @manage._app_http,
                                       environment: cfg.environment,
                                       service: cfg.service)
                 end

      @ws_manager = nil
      @config = Config::ConfigClient.new(self, manage: @manage, metrics: @metrics)
      @flags = Flags::FlagsClient.new(self, manage: @manage, metrics: @metrics,
                                            flags_base_url: flags_url, app_base_url: app_url)
      @logging = Logging::LoggingClient.new(self, manage: @manage, metrics: @metrics,
                                                  logging_base_url: logging_url, app_base_url: app_url)

      @closed = false
      schedule_periodic_flush

      @init_thread = Thread.new(@manage, @environment, @service, @app_base_url) do |mgmt, env, svc, app_url|
        register_service_context(mgmt, env, svc, app_url)
      end
    end

    # Eagerly initialize the SDK and block until it is fully ready.
    #
    # Pre-fetches all flags and configs into the local cache, opens the
    # live-updates WebSocket, and waits for the handshake to complete.
    # After this returns, +flag.get+ / +client.config.get+ hit cache (no
    # first-request connect tax) and any +on_change+ listeners receive every
    # server event from this point forward.
    #
    # Logging integration is *not* installed here — call
    # +client.logging.install+ separately if you want it.
    def wait_until_ready(timeout: 10.0)
      @flags.start
      @config.start
      ws = _ensure_ws
      deadline = monotonic_now + timeout
      while ws.connection_status != "connected"
        if monotonic_now >= deadline
          raise TimeoutError, "Live-updates websocket did not connect within #{timeout}s " \
                              "(status: #{ws.connection_status.inspect})"
        end

        sleep(0.05)
      end
    end

    # Stash +contexts+ as the current request's evaluation context.
    #
    # Two usage shapes:
    #
    #   # Fire-and-forget (typical middleware)
    #   client.set_context([Smplkit::Context.new("user", "u-123")])
    #
    #   # Scoped block (impersonation or one-off override)
    #   client.set_context([Smplkit::Context.new("user", "impersonated")]) do
    #     # ...
    #   end
    #   # original context restored here
    #
    # Each unique +(type, key)+ is also queued for bulk registration on the
    # management API.
    def set_context(contexts, &block)
      @manage.contexts.register(contexts) if contexts && !contexts.empty?

      scope = Smplkit.set_request_context(contexts || [])
      if block
        scope.call(&block)
      else
        scope
      end
    end

    def close
      Smplkit.debug("lifecycle", "Client.close called")
      @closed = true
      @flush_timer&.shutdown
      final_flush
      @metrics&.close
      @logging._close
      @flags._close
      @config._close
      @ws_manager&.stop
      @ws_manager = nil
      @manage.close
    end

    # Internal accessors used by sub-clients --------------------------------

    def _service = @service
    def _environment = @environment
    def _api_key = @api_key
    def _app_base_url = @app_base_url
    def _metrics = @metrics

    def _ensure_ws
      @_ensure_ws ||= begin
        ws = SharedWebSocket.new(app_base_url: @app_base_url, api_key: @api_key, metrics: @metrics)
        ws.start
        ws
      end
    end

    def _flags_transport = @manage.flags
    def _config_transport = @manage.config

    private

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def schedule_periodic_flush
      @flush_timer = Concurrent::TimerTask.new(execution_interval: PERIODIC_FLUSH_INTERVAL) do
        next if @closed

        begin
          @manage.contexts.flush
          @manage.flags.flush
          @manage.loggers.flush
        rescue StandardError => e
          Smplkit.debug("registration", "periodic flush failed: #{e.class}: #{e.message}")
        end
      end
      @flush_timer.execute
    end

    def final_flush
      [@manage.contexts, @manage.flags, @manage.loggers].each do |ns|
        ns.flush
      rescue StandardError => e
        Smplkit.debug("registration", "final flush failed: #{e.class}: #{e.message}")
      end
    end

    def register_service_context(_mgmt, _env, _svc, _app_url)
      # No-op stub: bulk-registers the service + environment with the platform.
      # Wired up via the contexts buffer once the generated client layer is
      # committed. Until then, the in-process buffer captures these and the
      # next periodic flush attempts to send them.
    rescue StandardError => e
      Smplkit.debug("lifecycle", "register service context failed: #{e.class}: #{e.message}")
    end
  end
end
