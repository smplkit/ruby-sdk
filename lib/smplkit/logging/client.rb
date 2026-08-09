# frozen_string_literal: true

# The Smpl Logging client — one unified +LoggingClient+.
#
# Smpl Logging has two surfaces on a single client, mirroring how the config,
# flags, audit, and jobs clients expose their full surface from one class:
#
# * *CRUD surface* — works immediately, no +install+ required. Two
#   sub-clients (the audit pattern):
#
#   * +client.logging.loggers+ — logger CRUD + discovery: +new+ / +list+ / +get+
#     / +delete+ plus +register+ / +flush+ / +flush_sync+ / +pending_count+.
#   * +client.logging.log_groups+ — log-group CRUD: +new+ / +list+ / +get+ /
#     +delete+.
#
#   The fused client owns the logger-discovery buffer directly; the +loggers+
#   sub-client shares that same buffer so discovery and explicit registration
#   drain through one queue.
#
# * *Live surface* — directly on the client. +register_adapter+ is a PRE-install
#   configuration call (allowed before +install+). +install+ opens the live
#   connection (monkey-patches the app's logging framework, discovers loggers,
#   fetches + applies levels, opens the shared event stream). +on_change+ /
#   +refresh+ require +install+ first; calling them earlier raises
#   +NotInstalledError+.
#
# The client supports two construction shapes:
#
# * *Wired* into +Smplkit::Client+ — borrows the parent's logging transport for
#   both runtime fetch and CRUD and the parent's shared event stream for the
#   live channel. This is the common path.
# * *Standalone* — +LoggingClient.new(api_key: ..., base_url: ..., ...)+ builds
#   and owns its own logging transport and an app transport (the event stream
#   lives on the app service), and on +install+ opens and owns its own event
#   stream. +close+ tears down only the owned transports and owned event stream.
module Smplkit
  module Logging
    NOT_INSTALLED_MESSAGE = "Smpl Logging live operations require install() first — this opens a live " \
                            "connection to your running service and hooks into your application's logging " \
                            "framework. Call client.logging.install() before on_change/refresh()."

    # Build standalone logging + app transports and resolve the app base URL.
    #
    # +base_url+/+api_key+ are used directly when supplied (the path a top-level
    # client takes after it has already resolved them); otherwise the management
    # config resolver fills in whatever is missing (+~/.smplkit+ / env vars /
    # defaults). +environment+/+service+ resolve the same way (constructor
    # argument wins). The app transport is needed because the event stream
    # lives on the app service (like flags); the app base URL is returned so a
    # standalone client can open its own event stream against the app service.
    #
    # @api private
    def self.logging_transport(api_key:, base_url:, profile:, base_domain:, scheme:,
                               environment:, service:, debug:, extra_headers:)
      cfg = ConfigResolution.resolve_client_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme,
        environment: environment, service: service, debug: debug
      )
      resolved_key = api_key.nil? ? cfg.api_key : api_key
      merged = {}
      merged.merge!(cfg.extra_headers || {})
      merged.merge!(extra_headers || {})
      tcfg = ConfigResolution::ResolvedClientConfig.new(
        api_key: resolved_key, base_domain: cfg.base_domain, scheme: cfg.scheme,
        debug: cfg.debug, extra_headers: merged
      )
      app_url = ConfigResolution.service_url(cfg.scheme, "app", cfg.base_domain)
      logging_http = Transport.build_api_client(SmplkitGeneratedClient::Logging, "logging", tcfg, base_url: base_url)
      app_http = Transport.build_api_client(SmplkitGeneratedClient::App, "app", tcfg)
      [logging_http, app_http, app_url, resolved_key, cfg.environment, cfg.service]
    end

    # Discover and load the SDK's built-in logging adapters.
    #
    # @api private
    def self.auto_load_adapters
      adapters = [Adapters::StdlibLoggerAdapter.new]

      begin
        require "semantic_logger"
        require_relative "adapters/semantic_logger_adapter"
        adapters << Adapters::SemanticLoggerAdapter.new
      rescue LoadError
        Smplkit.debug("registration", "semantic_logger gem not installed; semantic-logger adapter skipped")
      end

      adapters
    end

    # Fired once per managed logger whose effective level the SDK just applied.
    #
    # @!attribute [rw] id
    #   @return [String] The affected logger's normalized id.
    # @!attribute [rw] level
    #   @return [String] The newly-applied effective smplkit level string (e.g.
    #     +"INFO"+, +"DEBUG"+) — the same value the resolution algorithm returns.
    # @!attribute [rw] source
    #   @return [String] Short string identifying the trigger — typically
    #     +"push"+ (a live update) or +"manual"+ (a +refresh+ call).
    LoggerChangeEvent = Struct.new(:id, :level, :source, keyword_init: true) do
      def ==(other)
        other.is_a?(LoggerChangeEvent) &&
          id == other.id && level == other.level && source == other.source
      end
    end

    # Surface for +client.logging.loggers.*+ (sync).
    #
    # Logger CRUD plus the discovery buffer. The buffer is owned by the fused
    # +LoggingClient+ and shared here so discovery (driven by
    # +LoggingClient#install+) and explicit +register+ drain through one queue.
    class LoggersClient
      # @param http_client [Object] The logging-service transport.
      # @param buffer [LoggerRegistrationBuffer] The shared discovery buffer,
      #   owned by the fused +LoggingClient+.
      # @param streaming [Boolean] Internal — +false+ runs threshold flushes
      #   inline instead of on a background thread (stateless mode).
      def initialize(http_client, buffer:, streaming: true)
        @api = SmplkitGeneratedClient::Logging::LoggersApi.new(http_client)
        @buffer = buffer
        @streaming = streaming ? true : false
      end

      # Queue one or more logger sources for registration with the server.
      #
      # Sources are buffered locally and sent in a batch. The batch is sent
      # automatically once enough sources accumulate; pass +flush: true+ to send
      # the current batch right away instead of waiting.
      #
      # @param items [LoggerSource, Array<LoggerSource>] A single logger source,
      #   or an array of them, to queue.
      # @param flush [Boolean] When +true+, send the buffered sources immediately
      #   rather than waiting for the batch to fill.
      # @return [void]
      def register(items, flush: false)
        batch = items.is_a?(Array) ? items : [items]
        batch.each do |src|
          @buffer.add(LoggerSource.new(
                        name: Normalize.normalize_logger_name(src.name),
                        resolved_level: src.resolved_level, level: src.level,
                        service: src.service, environment: src.environment
                      ))
        end
        if flush
          self.flush
          return
        end
        return unless @buffer.pending_count >= LOGGER_BATCH_FLUSH_SIZE

        # Stateless mode (+streaming: false+) never spawns background threads —
        # the threshold flush runs inline (blocking) instead.
        if @streaming
          Thread.new { threshold_flush }
        else
          threshold_flush
        end
      end

      # Drain the buffer and POST pending logger sources to the bulk endpoint.
      #
      # @return [void]
      def flush
        batch = @buffer.drain
        return if batch.empty?

        items = batch.map do |entry|
          SmplkitGeneratedClient::Logging::LoggerBulkItem.new(
            id: entry["id"], resolved_level: entry["resolved_level"], level: entry["level"],
            service: entry["service"], environment: entry["environment"]
          )
        end
        body = SmplkitGeneratedClient::Logging::LoggerBulkRequest.new(loggers: items)
        ApiSupport::ErrorMapping.call { @api.bulk_register_loggers(body) }
      end

      # Synchronous flush — alias of +flush+ for the periodic-flush path.
      #
      # @return [void]
      def flush_sync
        flush
      end

      # Number of sources queued and awaiting flush.
      #
      # @return [Integer] count of buffered sources not yet sent.
      def pending_count
        @buffer.pending_count
      end

      # Build a new unsaved logger. The returned +SmplLogger+ is local only;
      # call its +SmplLogger#save+ to persist it.
      #
      # @param id [String] Identifier for the logger (its normalized name).
      # @param managed [Boolean] When +true+ (the default), smplkit controls
      #   this logger's level at runtime. Set +false+ to register the logger for
      #   visibility without taking over its level.
      # @return [SmplLogger] An unsaved logger bound to this client.
      def new(id, managed: true)
        SmplLogger.new(self, id: id, name: id, resolved_level: nil, managed: managed)
      end

      # List loggers for the authenticated account.
      #
      # @param page_number [Integer, nil] 1-based page index to fetch. When
      #   omitted, the server returns the first page.
      # @param page_size [Integer, nil] Maximum number of loggers per page. When
      #   omitted, the server applies its default page size.
      # @return [Array<SmplLogger>] The loggers on the requested page.
      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_loggers(opts) }
        (response.data || []).map { |r| Helpers.logger_resource_to_model(self, ApiSupport::ResourceShim.from_model(r)) }
      end

      # Fetch a single logger by id.
      #
      # @param id [String] Identifier of the logger to fetch.
      # @return [SmplLogger] The editable logger resource.
      # @raise [Smplkit::NotFoundError] If no logger with that id exists.
      def get(id)
        response = ApiSupport::ErrorMapping.call { @api.get_logger(id) }
        Helpers.logger_resource_to_model(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      # Delete a logger by id.
      #
      # @param id [String] Identifier of the logger to delete.
      # @return [void]
      # @raise [Smplkit::NotFoundError] If no logger with that id exists.
      def delete(id)
        ApiSupport::ErrorMapping.call { @api.delete_logger(id) }
        nil
      end

      # @api private
      def _update_logger(logger)
        response = ApiSupport::ErrorMapping.call { @api.update_logger(logger.id || logger.name, logger_body(logger)) }
        Helpers.logger_resource_to_model(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      # Runtime entry — walks every page and returns an id-keyed Hash of
      # resolution-cache entries (+level+, +group+, +managed+, +environments+).
      #
      # @api private
      def list_logger_entries
        rows = ApiSupport::PaginatedFetch.collect { |opts| @api.list_loggers(opts) }
        rows.to_h { |r| logger_entry_from_resource(ApiSupport::ResourceShim.from_model(r)) }
      end

      # Fetch one logger as a resolution-cache entry. Used by the +logger_changed+
      # WS handler.
      #
      # @api private
      def get_logger_entry(id)
        response = ApiSupport::ErrorMapping.call { @api.get_logger(id) }
        logger_entry_from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      private

      def threshold_flush
        flush
      rescue StandardError => e
        Smplkit.debug("registration", "logger registration flush failed: #{e.class}: #{e.message}")
      end

      def logger_entry_from_resource(resource)
        attrs = resource["attributes"] || {}
        [
          resource["id"],
          {
            "level" => attrs["level"],
            "group" => attrs["group"],
            "managed" => attrs.key?("managed") ? attrs["managed"] : true,
            "environments" => attrs["environments"] || {}
          }
        ]
      end

      def logger_body(logger)
        # Logger server schema: name, level, group, managed, environments.
        # +resolved_level+ is read-only, +service+/+environment+ are observed via
        # bulk register, +description+ is wrapper-local. The PUT is a full
        # replace, so the (possibly empty) environments map is always sent —
        # omitting it would leave a cleared override in place server-side.
        SmplkitGeneratedClient::Logging::LoggerResponse.new(
          data: SmplkitGeneratedClient::Logging::LoggerResource.new(
            type: "logger",
            id: logger.id,
            attributes: SmplkitGeneratedClient::Logging::Logger.new(
              name: logger.name,
              level: logger.level&.to_s,
              group: logger.log_group_id,
              managed: logger.managed,
              environments: Logging.environments_to_wire(logger.environments)
            )
          )
        )
      end
    end

    # Surface for +client.logging.log_groups.*+ (sync).
    class LogGroupsClient
      def initialize(http_client)
        @api = SmplkitGeneratedClient::Logging::LogGroupsApi.new(http_client)
      end

      # Build a new unsaved log group. The returned +SmplLogGroup+ is local
      # only; call its +SmplLogGroup#save+ to persist it.
      #
      # @param id [String] Identifier for the log group.
      # @param name [String, nil] Human-readable display name. Defaults to a
      #   title-cased version of +id+ when omitted.
      # @param group [String, nil] Identifier of the parent log group, when
      #   nesting groups. +nil+ for a top-level group.
      # @return [SmplLogGroup] An unsaved log group bound to this client.
      def new(id, name: nil, group: nil)
        SmplLogGroup.new(
          self, key: id, name: name.nil? ? Smplkit::Helpers.key_to_display_name(id) : name, group: group
        )
      end

      # List log groups for the authenticated account.
      #
      # @param page_number [Integer, nil] 1-based page index to fetch. When
      #   omitted, the server returns the first page.
      # @param page_size [Integer, nil] Maximum number of log groups per page.
      #   When omitted, the server applies its default page size.
      # @return [Array<SmplLogGroup>] The log groups on the requested page.
      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_log_groups(opts) }
        (response.data || []).map do |r|
          Helpers.log_group_resource_to_model(self, ApiSupport::ResourceShim.from_model(r))
        end
      end

      # Fetch a single log group by id.
      #
      # @param id [String] Identifier of the log group to fetch.
      # @return [SmplLogGroup] The editable log group resource.
      # @raise [Smplkit::NotFoundError] If no log group with that id exists.
      def get(id)
        response = ApiSupport::ErrorMapping.call { @api.get_log_group(id) }
        Helpers.log_group_resource_to_model(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      # Delete a log group by id.
      #
      # @param id [String] Identifier of the log group to delete.
      # @return [void]
      # @raise [Smplkit::NotFoundError] If no log group with that id exists.
      def delete(id)
        ApiSupport::ErrorMapping.call { @api.delete_log_group(id) }
        nil
      end

      # @api private
      def _create_log_group(group)
        response = ApiSupport::ErrorMapping.call { @api.create_log_group(log_group_body(group)) }
        Helpers.log_group_resource_to_model(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      # @api private
      def _update_log_group(group)
        response = ApiSupport::ErrorMapping.call { @api.update_log_group(group.key, log_group_body(group)) }
        Helpers.log_group_resource_to_model(self, ApiSupport::ResourceShim.from_model(response.data))
      end

      # Runtime entry — walks every page and returns an id-keyed Hash of
      # resolution-cache entries (+level+, +group+, +environments+). The +group+
      # key carries the *parent group id* so the resolution algorithm can walk
      # the chain with the same key shape it uses for loggers.
      #
      # @api private
      def list_group_entries
        rows = ApiSupport::PaginatedFetch.collect { |opts| @api.list_log_groups(opts) }
        rows.to_h { |r| group_entry_from_resource(ApiSupport::ResourceShim.from_model(r)) }
      end

      # Fetch one log group as a resolution-cache entry. Used by the
      # +group_changed+ WS handler.
      #
      # @api private
      def get_group_entry(key)
        response = ApiSupport::ErrorMapping.call { @api.get_log_group(key) }
        group_entry_from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      private

      def group_entry_from_resource(resource)
        attrs = resource["attributes"] || {}
        [
          resource["id"],
          {
            "level" => attrs["level"],
            "group" => attrs["parent_id"],
            "environments" => attrs["environments"] || {}
          }
        ]
      end

      def log_group_body(group)
        # LogGroup server schema: name, level, parent_id, environments (no description).
        SmplkitGeneratedClient::Logging::LogGroupResponse.new(
          data: SmplkitGeneratedClient::Logging::LogGroupResource.new(
            type: "log_group",
            id: group.key,
            attributes: SmplkitGeneratedClient::Logging::LogGroup.new(
              name: group.name,
              level: group.level&.to_s,
              parent_id: group.group,
              environments: Logging.environments_to_wire(group.environments)
            )
          )
        )
      end
    end

    # The Smpl Logging client (sync).
    #
    # One client exposes the full surface, reachable as +client.logging+
    # (+Smplkit::Client+) or constructed directly:
    #
    #   logging = Smplkit::LoggingClient.new(environment: "production", service: "my-svc")
    #   logging.loggers.new("sqlalchemy.engine").save
    #   logging.install
    #
    # The CRUD surface (+loggers+ / +log_groups+ sub-clients) works
    # immediately. +register_adapter+ is a pre-install configuration call. The
    # live surface (+install+ / +on_change+ / +refresh+) requires +install+
    # first; calling +on_change+ / +refresh+ earlier raises +NotInstalledError+.
    class LoggingClient
      attr_reader :loggers, :log_groups

      # @param api_key [String, nil] API key. When omitted, resolved from
      #   +SMPLKIT_API_KEY+ or +~/.smplkit+.
      # @param environment [String, nil] Deployment environment used to resolve
      #   logger levels and to scope discovery declarations. When omitted,
      #   resolved from +SMPLKIT_ENVIRONMENT+ or +~/.smplkit+.
      # @param service [String, nil] Service name attached to discovery
      #   declarations. When omitted, resolved from +SMPLKIT_SERVICE+ or
      #   +~/.smplkit+. Optional.
      # @param base_url [String, nil] Full logging-service base URL. Usually
      #   resolved from +base_domain+/+scheme+; supplied directly by the
      #   top-level clients which have already computed it.
      # @param profile [String, nil] Named +~/.smplkit+ profile section.
      # @param base_domain [String, nil] Base domain for API requests (default
      #   +"smplkit.com"+).
      # @param scheme [String, nil] URL scheme (default +"https"+).
      # @param debug [Boolean, nil] Enable SDK debug logging.
      # @param extra_headers [Hash{String => String}, nil] Extra headers
      #   attached to every request.
      # @param streaming [Boolean] Live updates over the event stream (default
      #   +true+): +install+ opens a shared stream and server-side level
      #   changes stream in. Set +false+ for the stateless apply-once surface:
      #   +install+ still loads adapters, flushes discovery, and applies the
      #   server's levels — all blocking — but NO socket or background thread
      #   is ever created; +refresh+ re-fetches and re-applies on demand. The
      #   right shape for serverless and edge runtimes; note that live level
      #   changes then arrive only via +refresh+.
      # @param parent [Smplkit::Client, nil] Internal — the owning client. Not
      #   for direct use.
      # @param transport [Object, nil] Internal — a pre-built logging transport
      #   supplied by a top-level client so the logging surface shares one
      #   connection pool. Not for direct use.
      # @param metrics [Object, nil] Internal — the parent's metrics reporter.
      def initialize(api_key = nil, environment: nil, service: nil, base_url: nil, profile: nil,
                     base_domain: nil, scheme: nil, debug: nil, extra_headers: nil,
                     streaming: true, parent: nil, transport: nil, metrics: nil)
        @parent = parent
        @metrics = metrics
        @streaming = streaming ? true : false
        @standalone_api_key = nil
        if transport.nil?
          # Standalone: resolve like Smplkit::Client — defaults → ~/.smplkit →
          # SMPLKIT_* env vars → constructor args — environment and service
          # included.
          @logging_http, _app_http, @app_base_url, @standalone_api_key, resolved_env, resolved_service =
            Logging.logging_transport(
              api_key: api_key, base_url: base_url, profile: profile,
              base_domain: base_domain, scheme: scheme, environment: environment,
              service: service, debug: debug, extra_headers: extra_headers
            )
          @environment = parent.nil? ? resolved_env : parent._environment
          @service = parent.nil? ? resolved_service : parent._service
        else
          @logging_http = transport
          @app_base_url = nil
          # Wired: the parent has already resolved environment/service once —
          # its values win over both the raw kwargs and re-resolution.
          @environment = parent.nil? ? environment : parent._environment
          @service = parent.nil? ? service : parent._service
        end

        # Discovery buffer is owned by this client; the loggers sub-client shares
        # it so discovery and explicit registration drain together.
        @buffer = LoggerRegistrationBuffer.new
        @loggers = LoggersClient.new(@logging_http, buffer: @buffer, streaming: @streaming)
        @log_groups = LogGroupsClient.new(@logging_http)

        # Live-surface state.
        @connected = false
        @name_map = {}        # original_name → normalized_id
        @loggers_cache = {}   # id → logger data
        @groups_cache = {}    # id → group data
        @global_listeners = []
        @key_listeners = Hash.new { |h, k| h[k] = [] }
        @adapters = []
        @explicit_adapters = false
        @event_stream = nil
        @owns_stream = false
        @lock = Mutex.new
      end

      # --- Adapter registration (pre-install, ungated) ---

      # Register a logging adapter. Must be called before install().
      #
      # If called at least once, auto-loading is disabled — only explicitly
      # registered adapters are used. This is a pre-install configuration call:
      # it is intentionally NOT gated by +install+.
      def register_adapter(adapter)
        raise "Cannot register adapters after install()" if @connected
        unless adapter.is_a?(Adapters::Base)
          raise ArgumentError, "adapter must implement Smplkit::Logging::Adapters::Base"
        end

        @explicit_adapters = true
        @adapters << adapter
        self
      end

      # Registered logging adapters.
      #
      # @return [Array<Adapters::Base>] a copy of the adapters this client uses
      #   to discover loggers and apply levels.
      def adapters
        @adapters.dup
      end

      # --- Live surface: install (gate) + transport / event stream helpers ---

      # Hook smplkit into the application's logging machinery.
      #
      # Loads adapters, scans existing loggers, applies levels from the smplkit
      # server, and wires event stream handlers for live updates. This IS the
      # explicit consent gate — +on_change+ / +refresh+ require it first.
      #
      # Idempotent — safe to call multiple times.
      def install
        Smplkit.debug("lifecycle", "LoggingClient.install() called")
        @parent&._ensure_started
        return self if @connected

        # 0. Load adapters
        @adapters = Logging.auto_load_adapters if @adapters.empty?

        # 1. Discover existing loggers from all adapters (keep discovery and hook
        # installation as two passes — discover every adapter before any hook is
        # live, mirroring the Python SDK).
        # rubocop:disable Style/CombinableLoops
        @adapters.each do |adapter|
          existing = adapter.discover
          existing.each do |name, explicit_level, effective_level|
            @name_map[name] = Normalize.normalize_logger_name(name)
            @loggers.register(loggersource_for(name, explicit_level, effective_level))
          end
        rescue StandardError => e
          Smplkit.debug("logging", "adapter #{adapter.name} discover failed: #{e.class}: #{e.message}")
        end

        # 2. Install continuous discovery hooks
        @adapters.each do |adapter|
          adapter.install_hook { |name, explicit, effective| on_new_logger(name, explicit, effective) }
        rescue StandardError => e
          Smplkit.debug("logging", "adapter #{adapter.name} install_hook failed: #{e.class}: #{e.message}")
        end
        # rubocop:enable Style/CombinableLoops

        # 3. Flush initial batch
        begin
          @loggers.flush
        rescue StandardError => e
          Smplkit.debug("registration", "bulk logger registration failed: #{e.class}: #{e.message}")
        end

        # 4-6. Fetch, resolve, apply
        begin
          fetch_and_apply(trigger: "install()")
        rescue StandardError => e
          Smplkit.debug("resolution",
                        "failed to fetch/apply logging levels during connect " \
                        "(logging: #{@logging_http&.config&.host}): #{e.class}: #{e.message}")
        end

        # 7. Register event stream handlers for real-time level updates, plus
        # the bulk-refresh path as the stream's reconnect refetch so a stream
        # outage ends with a full re-sync. In stateless mode
        # (+streaming: false+) no stream is ever created — level changes then
        # arrive only via +refresh+.
        if @streaming
          @event_stream = ensure_event_stream
          stream_handlers.each { |event, handler| @event_stream.on(event, &handler) }
          @event_stream.on_reconnect(refetch_callback)
        end

        @connected = true
        self
      end

      # --- Live surface: change listeners ---

      # Register a change listener.
      #
      #   client.logging.on_change { |event| ... }                 # global
      #   client.logging.on_change("sqlalchemy.engine") { |e| ... } # key-scoped
      #
      # Requires +install+ first; raises +NotInstalledError+ otherwise.
      def on_change(name = nil, &block)
        require_installed
        raise ArgumentError, "on_change requires a block" unless block

        if name.nil?
          @global_listeners << block
        else
          @key_listeners[name] << block
        end
        block
      end

      # Re-fetch all loggers and groups and fire listener events for any deltas.
      #
      # Requires +install+ first; raises +NotInstalledError+ otherwise.
      def refresh
        require_installed
        Smplkit.debug("resolution", "refresh() called, triggering full resolution pass")
        fetch_and_apply_deltas(trigger: "refresh()", source: "manual")
      end

      # Release resources — only those this client owns.
      #
      # Uninstalls the adapter hooks, unsubscribes from the event stream, and
      # tears down the owned event stream (standalone install). A wired client
      # borrows the parent's transport and event stream and closes neither.
      def close
        Smplkit.debug("lifecycle", "LoggingClient.close() called")
        @adapters.each do |adapter|
          adapter.uninstall_hook
        rescue StandardError => e
          Smplkit.debug("logging", "adapter #{adapter.name} uninstall_hook failed: #{e.class}: #{e.message}")
        end
        if @event_stream
          stream_handlers.each { |event, handler| @event_stream.off(event, handler) }
          @event_stream.off_reconnect(refetch_callback)
          if @owns_stream
            @event_stream.stop
            @owns_stream = false
          end
          @event_stream = nil
        end
        @connected = false
      end

      # Release resources held by this client.
      #
      # @api private
      # @return [void]
      alias _close close

      # Construct a +LoggingClient+, yield it to the block, and close it on exit.
      #
      # Mirrors Ruby's +File.open+ block form: the client is closed
      # automatically when the block returns or raises, so a standalone client's
      # owned transports and event stream are always torn down.
      #
      #   Smplkit::LoggingClient.open(environment: "production") do |logging|
      #     logging.loggers.new("sqlalchemy.engine").save
      #     logging.install
      #   end
      #
      # @param kwargs [Hash] keyword arguments forwarded to +new+.
      # @yieldparam client [LoggingClient] the constructed client.
      # @return [Object] the block's return value.
      def self.open(**kwargs)
        client = new(**kwargs)
        begin
          yield client
        ensure
          client.close
        end
      end

      private

      def require_installed
        raise NotInstalledError, NOT_INSTALLED_MESSAGE unless @connected
      end

      # Memoized event → handler map so +install+ registers and +close+
      # unsubscribes the exact same callback objects. They are stored as procs
      # (not bound methods) because +EventStream#off+ removes by object
      # identity, and +on(event, &proc)+ stores the very proc passed here.
      def stream_handlers
        @stream_handlers ||= {
          "logger_changed" => proc { |data| handle_logger_changed(data) },
          "logger_deleted" => proc { |data| handle_logger_deleted(data) },
          "group_changed" => proc { |data| handle_group_changed(data) },
          "group_deleted" => proc { |data| handle_group_deleted(data) },
          "loggers_changed" => proc { |data| handle_loggers_changed(data) }
        }
      end

      # Memoized reconnect refetch — the same bulk-refresh path the
      # +loggers_changed+ handler runs, registered with the stream on
      # +install+ and deregistered (by object identity) on +close+.
      def refetch_callback
        @refetch_callback ||= proc { handle_loggers_changed({}) }
      end

      def ensure_event_stream
        return @parent._ensure_event_stream unless @parent.nil?

        if @event_stream.nil?
          @event_stream = EventStream.new(
            app_base_url: @app_base_url, api_key: @standalone_api_key, metrics: @metrics
          )
          @event_stream.start
          @owns_stream = true
        end
        @event_stream
      end

      # --- Internal ---

      # Build a LoggerSource from an adapter's (name, explicit, effective)
      # discovery tuple.
      def loggersource_for(name, explicit_level, effective_level)
        LoggerSource.new(
          name: name,
          resolved_level: effective_level,
          level: explicit_level,
          service: @service,
          environment: @environment
        )
      end

      # Callback from adapters when a new logger is created.
      def on_new_logger(name, explicit_level, effective_level)
        normalized = Normalize.normalize_logger_name(name)
        @name_map[name] = normalized
        @loggers.register(loggersource_for(name, explicit_level, effective_level))

        # If connected, try to apply level from cache.
        return unless @connected && @loggers_cache.key?(normalized)

        entry = @loggers_cache[normalized]
        return unless entry["managed"]

        resolved = Resolution.resolve_level(normalized, @environment, @loggers_cache, @groups_cache)
        coerced = LogLevel.coerce(resolved)
        push_to_adapters(name, coerced)
      end

      def push_to_adapters(original_name, coerced_level)
        @adapters.each do |adapter|
          adapter.apply_level(original_name, coerced_level)
        rescue StandardError => e
          Smplkit.debug("logging", "adapter #{adapter.name} apply_level failed for #{original_name}: " \
                                   "#{e.class}: #{e.message}")
        end
      end

      # Re-fetch loggers/groups into the cache (no apply, no fire).
      def fetch_cache(trigger)
        Smplkit.debug("resolution", "full resolution pass starting (trigger: #{trigger})")
        @loggers_cache = @loggers.list_logger_entries
        @groups_cache = @log_groups.list_group_entries
      end

      # Fetch loggers/groups and unconditionally apply levels (initial install
      # path).
      #
      # Silent — does not fire change-listener events. Use
      # +fetch_and_apply_deltas+ from the push / refresh paths to get
      # per-logger fanout.
      def fetch_and_apply(trigger: "unknown")
        fetch_cache(trigger)
        apply_levels
      end

      # Fetch loggers/groups; apply + fire listeners only on effective-level
      # deltas.
      def fetch_and_apply_deltas(trigger:, source:)
        pre = snapshot_effective_levels
        fetch_cache(trigger)
        apply_deltas_and_fire(pre, source)
      end

      # Apply resolved levels to all managed, locally-present loggers.
      def apply_levels
        @name_map.each do |original_name, normalized_id|
          entry = @loggers_cache[normalized_id]
          next if entry.nil?
          next unless entry["managed"]

          resolved = Resolution.resolve_level(normalized_id, @environment, @loggers_cache, @groups_cache)
          push_to_adapters(original_name, LogLevel.coerce(resolved))
          @metrics&.record("logging.level_changes", unit: "changes", dimensions: { "logger" => normalized_id })
        end
      end

      # Effective level for every locally-tracked managed logger.
      #
      # This is the universe of loggers the adapter applies levels to — the only
      # loggers whose listener can fire. A logger not in +name_map+ (never
      # instantiated locally) or marked +managed=false+ in the cache is excluded.
      def snapshot_effective_levels
        snapshot = {}
        @name_map.each_value do |normalized_id|
          entry = @loggers_cache[normalized_id]
          next if entry.nil? || !entry["managed"]

          snapshot[normalized_id] = Resolution.resolve_level(
            normalized_id, @environment, @loggers_cache, @groups_cache
          )
        end
        snapshot
      end

      # Apply + fire per-logger whenever the effective level moved.
      #
      # For every locally-tracked managed logger, recompute the effective level
      # and compare to +pre+. On a delta: call +apply_level+ on every adapter AND
      # fire one +LoggerChangeEvent+ per affected logger — once to each matching
      # key-scoped listener and once to every global listener (a global is
      # semantically a key-scoped subscription on every logger). No-op when
      # nothing moved: no apply, no fire.
      def apply_deltas_and_fire(pre, source)
        @name_map.each do |original_name, normalized_id|
          entry = @loggers_cache[normalized_id]
          next if entry.nil? || !entry["managed"]

          new_level = Resolution.resolve_level(normalized_id, @environment, @loggers_cache, @groups_cache)
          next if pre[normalized_id] == new_level

          push_to_adapters(original_name, LogLevel.coerce(new_level))
          @metrics&.record("logging.level_changes", unit: "changes", dimensions: { "logger" => normalized_id })
          fire_for_logger(normalized_id, new_level, source)
        end
      end

      # Fire one +LoggerChangeEvent+ to every matching subscriber.
      #
      # Both the key-scoped listeners registered for +logger_id+ and every global
      # listener receive the same payload.
      def fire_for_logger(logger_id, level, source)
        event = LoggerChangeEvent.new(id: logger_id, level: level, source: source)
        (@global_listeners + @key_listeners[logger_id]).each do |cb|
          cb.call(event)
        rescue StandardError => e
          Smplkit.debug("logging", "listener raised: #{e.class}: #{e.message}")
        end
      end

      # --- Internal: event handlers (called by EventStream) ---

      def handle_logger_changed(data)
        key = data["id"] || ""
        Smplkit.debug("events", "logger_changed: fetching logger #{key.inspect}")
        pre = snapshot_effective_levels
        begin
          entry_id, entry = @loggers.get_logger_entry(key)
          @loggers_cache[entry_id || key] = entry
        rescue StandardError => e
          Smplkit.debug("events", "failed to fetch logger #{key.inspect} after push event: #{e.class}: #{e.message}")
          return
        end
        apply_deltas_and_fire(pre, "push")
      end

      def handle_logger_deleted(data)
        key = data["id"] || ""
        Smplkit.debug("events", "logger_deleted: removing logger #{key.inspect}")
        pre = snapshot_effective_levels
        @loggers_cache.delete(key)
        apply_deltas_and_fire(pre, "push")
      end

      def handle_group_changed(data)
        key = data["id"] || ""
        Smplkit.debug("events", "group_changed: fetching group #{key.inspect}")
        pre = snapshot_effective_levels
        begin
          entry_id, entry = @log_groups.get_group_entry(key)
          @groups_cache[entry_id || key] = entry
        rescue StandardError => e
          Smplkit.debug("events",
                        "failed to fetch log group #{key.inspect} after push event: #{e.class}: #{e.message}")
          return
        end
        apply_deltas_and_fire(pre, "push")
      end

      def handle_group_deleted(data)
        key = data["id"] || ""
        Smplkit.debug("events", "group_deleted: removing group #{key.inspect}")
        pre = snapshot_effective_levels
        @groups_cache.delete(key)
        apply_deltas_and_fire(pre, "push")
      end

      def handle_loggers_changed(_data)
        Smplkit.debug("events", "loggers_changed: full re-fetch")
        fetch_and_apply_deltas(trigger: "loggers_changed event", source: "push")
      rescue StandardError => e
        Smplkit.debug("events",
                      "failed to re-fetch/apply logging levels after loggers_changed event: #{e.class}: #{e.message}")
      end
    end
  end

  LoggingClient = Logging::LoggingClient
end
