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
  # All parameters are optional. When omitted, the SDK resolves each one in
  # precedence order, lowest to highest: built-in defaults, then the
  # +~/.smplkit+ configuration file, then +SMPLKIT_*+ environment variables,
  # then the explicit constructor arguments (a value supplied at a higher
  # level overrides the lower ones).
  #
  # +Smplkit::Client+ is thread-safe by construction. Background work runs on
  # internal SDK-owned threads; public methods block the calling thread and
  # return values directly.
  class Client
    # Periodic flush of all sub-client registration buffers (contexts, flags,
    # loggers).  Threshold flushes still fire immediately when buffers fill up;
    # this timer is the liveness guarantee for the tail.
    PERIODIC_FLUSH_INTERVAL = 60.0

    attr_reader :platform, :account, :config, :flags, :logging, :audit, :jobs

    # Construct a client, yield it to the block, and close it on exit.
    #
    # @param kwargs [Hash] The same keyword arguments as {#initialize}.
    # @yieldparam client [Client] The constructed client.
    # @return [Object] The block's return value.
    def self.open(**kwargs)
      client = new(**kwargs)
      begin
        yield client
      ensure
        client.close
      end
    end

    # @param api_key [String, nil] API key for authenticating with the smplkit platform.
    # @param environment [String, nil] The environment to connect to (e.g. +"production"+).
    # @param service [String, nil] Service name (e.g. +"user-service"+).
    # @param profile [String, nil] Named profile section to read from +~/.smplkit+.
    # @param base_domain [String, nil] Base domain for API requests (default +"smplkit.com"+).
    # @param scheme [String, nil] URL scheme (default +"https"+).
    # @param debug [Boolean, nil] Enable debug logging in the SDK.
    # @param telemetry [Boolean, nil] Enable anonymous usage telemetry (default +true+).
    # @param extra_headers [Hash{String => String}, nil] Extra HTTP headers attached to
    #   every request the client sends.
    def initialize(api_key: nil, environment: nil, service: nil, profile: nil,
                   base_domain: nil, scheme: nil, debug: nil, telemetry: nil,
                   extra_headers: nil)
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
      @extra_headers = extra_headers

      masked_key = cfg.api_key.length > 10 ? "#{cfg.api_key[0, 10]}..." : cfg.api_key
      Smplkit.debug(
        "lifecycle",
        "Client init: api_key=#{masked_key} env=#{cfg.environment.inspect} service=#{cfg.service.inspect} " \
        "base_domain=#{cfg.base_domain.inspect} scheme=#{cfg.scheme.inspect} " \
        "debug=#{cfg.debug} telemetry=#{cfg.telemetry}"
      )

      # Build the per-service HTTP transports + the context-registration buffer.
      # Side-effect-free: each transport connects lazily on first call.
      # client.platform owns the buffer; client.config/flags/logging/jobs borrow
      # their transports from here.
      @transports = Transport.build_service_transports(Transport.to_transport_config(cfg, extra_headers))

      app_url = @transports.app_url
      audit_url = ConfigResolution.service_url(cfg.scheme, "audit", cfg.base_domain)

      # Alias the shared HTTP transports — single connection pool per service.
      @http_client = @transports.config_http
      @app_http = @transports.app_http
      @app_base_url = app_url

      # Metrics reporter
      @metrics = if cfg.telemetry
                   MetricsReporter.new(http_client: @app_http, environment: cfg.environment, service: cfg.service)
                 end

      @ws_manager = nil
      # Platform's cross-cutting CRUD on one client; wired into this parent so
      # it borrows the shared app transport, and owns the context-registration
      # buffer. Built BEFORE flags so the contexts seam below is available.
      @platform = Platform::PlatformClient.new(app_transport: @app_http)
      # Account-level settings on one client; built from the app url + api key
      # (the settings sub-client uses Faraday directly).
      @account = Account::AccountClient.new(api_key: cfg.api_key, base_url: app_url, extra_headers: extra_headers)
      # Config's full surface on one client; wired into this parent so it
      # borrows the shared config transport and WebSocket.
      @config = Config::ConfigClient.new(parent: self, transport: @transports.config_http, metrics: @metrics)
      # Flags' full surface on one client; wired into this parent so it borrows
      # the shared flags transport and WebSocket. ``contexts`` is the injection
      # seam for evaluation-context registration, wired to
      # ``client.platform.contexts``.
      @flags = Flags::FlagsClient.new(
        parent: self, transport: @transports.flags_http, contexts: @platform.contexts, metrics: @metrics
      )
      # Logging's full surface on one client; wired into this parent so it
      # borrows the shared logging transport and WebSocket. The two management
      # sub-clients live at client.logging.loggers / client.logging.log_groups.
      @logging = Logging::LoggingClient.new(parent: self, transport: @transports.logging_http, metrics: @metrics)
      # Audit's full surface on one client; this runtime instance scopes audit
      # ops to the configured environment via the body-driven path (ADR-055):
      # ``events.record`` stamps it on the event body and the read surfaces
      # default ``filter[environment]`` to it. Owns its own transport (closed in
      # ``close``).
      @audit = Audit::AuditClient.new(
        api_key: cfg.api_key, base_url: audit_url, environment: cfg.environment, extra_headers: extra_headers
      )
      # Jobs has no runtime/management split — reuse the shared jobs transport
      # (single connection pool) so ``client.jobs`` is one-stop.
      @jobs = Jobs::JobsClient.new(auth_client: @transports.jobs_http)

      # Construction is side-effect-free: no background threads, no phone-home.
      # The periodic registration-buffer flush and the service-context
      # registration are deferred until the first config/flags/logging operation
      # or set_context via ``_ensure_started`` — so an audit-only or jobs-only
      # customer pays zero threads and zero network at construction.
      @closed = false
      @started = false
      @start_lock = Mutex.new
      @flush_timer = nil
      @init_thread = nil
    end

    # Optionally pre-warm the SDK and block until the live socket is up.
    #
    # Eagerly connects config and flags — flushing discovery, pre-fetching all
    # flags and configs into the local cache, opening the live-updates WebSocket
    # — and waits for the handshake to complete. After this returns, +flag.get+
    # / +client.config.subscribe+ hit cache (no first-request connect tax) and
    # any +on_change+ listeners receive every server event from this point
    # forward.
    #
    # Optional: config and flags connect lazily on first live use, so this is
    # purely a pre-warm / WebSocket-ready barrier. Logging integration is *not*
    # connected here — call +client.logging.install+ separately if you want it
    # (it installs adapters and hooks into your application's logger, which
    # should be opt-in).
    #
    # @param timeout [Float] Maximum seconds to wait for the live-updates
    #   WebSocket handshake before giving up. Defaults to +10.0+.
    # @return [void]
    # @raise [Smplkit::TimeoutError] If the WebSocket fails to connect within
    #   +timeout+ seconds.
    def wait_until_ready(timeout: 10.0)
      @flags._ensure_connected
      @config._ensure_connected
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
    # Typical use is from middleware — set the context once at request entry and
    # every +flag.get+ (and other context-sensitive evaluations) inside that
    # request automatically picks it up.
    #
    # Each unique +(type, key)+ is also registered with the platform
    # (deduplicated via an LRU; sent in the background).
    #
    # Two usage shapes:
    #
    #   # Fire-and-forget (typical middleware)
    #   client.set_context([Smplkit::Context.new("user", "u-123")])
    #
    #   # Scoped block (e.g. impersonation or one-off override)
    #   client.set_context([Smplkit::Context.new("user", "impersonated")]) do
    #     # ...
    #   end
    #   # original context restored here
    #
    # @param contexts [Array<Smplkit::Context>] The contexts to make active for
    #   the current thread (e.g. the request's user and account). An empty array
    #   clears any registration step but still returns a scope.
    # @yield When a block is given, the contexts are active only for its
    #   duration and the previous context is restored on exit.
    # @return [Object, Smplkit::ContextScope] The block's return value when a
    #   block is given; otherwise a scope you can ignore for fire-and-forget use.
    def set_context(contexts, &block)
      _ensure_started
      @platform.contexts.register(contexts) if contexts && !contexts.empty?

      scope = Smplkit.set_request_context(contexts || [])
      if block
        scope.call(&block)
      else
        scope
      end
    end

    # Release all resources held by this client.
    #
    # @return [void]
    def close
      Smplkit.debug("lifecycle", "Client.close called")
      @closed = true
      @flush_timer&.shutdown
      @flush_timer = nil
      final_flush
      @metrics&.close
      @logging._close
      @flags._close
      @audit._close
      @ws_manager&.stop
      @ws_manager = nil
      # Close the shared per-service HTTP transports (app/config/flags/logging/
      # jobs). client.platform/account borrow the app transport and close
      # nothing; client.audit owns and closed its own transport above.
      @transports.close
    end

    # Internal accessors used by sub-clients --------------------------------

    def _service = @service
    def _environment = @environment
    def _api_key = @api_key
    def _app_base_url = @app_base_url
    def _metrics = @metrics
    def _extra_headers = @extra_headers

    # Start the deferred background machinery exactly once.
    #
    # Idempotent and thread-safe (lock + flag); a no-op after +close+. Triggered
    # by the first config/flags/logging operation, +set_context+,
    # +wait_until_ready+, or WebSocket open — never at construction.
    def _ensure_started
      @start_lock.synchronize do
        return if @started || @closed

        @started = true
      end
      schedule_periodic_flush
      @init_thread = Thread.new { register_service_context }
    end

    def _ensure_ws
      _ensure_started
      if @ws_manager.nil?
        @ws_manager = SharedWebSocket.new(app_base_url: @app_base_url, api_key: @api_key, metrics: @metrics)
        @ws_manager.start
      end
      @ws_manager
    end

    private

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def schedule_periodic_flush
      @flush_timer = Concurrent::TimerTask.new(execution_interval: PERIODIC_FLUSH_INTERVAL) do
        run_periodic_flush
      end
      @flush_timer.execute
    end

    # Extracted as a private method so the timer body is reachable from tests
    # without poking into Concurrent::TimerTask internals.
    def run_periodic_flush
      return if @closed

      @platform.contexts.flush
      @flags.flush
      @logging.loggers.flush
      @config.flush
    rescue StandardError => e
      Smplkit.debug("registration", "periodic flush failed: #{e.class}: #{e.message}")
    end

    def final_flush
      [@platform.contexts, @flags, @logging.loggers, @config].each do |target|
        target.flush
      rescue StandardError => e
        Smplkit.debug("registration", "final flush failed: #{e.class}: #{e.message}")
      end
    end

    def register_service_context
      # Register the environment and/or service as context instances. Only the
      # values that are set are registered; if neither environment nor service
      # was provided the POST is skipped entirely (an audit/jobs-only customer
      # has nothing to register).
      contexts = []
      contexts << Smplkit::Context.new("environment", @environment) if @environment
      contexts << Smplkit::Context.new("service", @service, { "name" => @service }) if @service
      return if contexts.empty?

      @platform.contexts.register(contexts, flush: true)
    rescue StandardError => e
      Smplkit.debug("lifecycle", "register service context failed (app: #{@app_base_url}): #{e.class}: #{e.message}")
    end
  end
end
