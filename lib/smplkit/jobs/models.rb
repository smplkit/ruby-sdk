# frozen_string_literal: true

module Smplkit
  # Smpl Jobs surface — exposed through +client.jobs.*+.
  #
  # Unlike Config/Flags/Logging, Jobs has no live "phone-home" agent — no
  # environment registration, no WebSocket — so its entire surface lives on a
  # single client. A {Job} is an active record: build it with
  # +client.jobs.new_recurring_job(...)+ / +new_manual_job(...)+ /
  # +schedule(...)+, set fields, and call {Job#save} (create when new,
  # full-replace update when it already exists) or {Job#delete}. Runs are
  # read-only views with +rerun+ / +cancel+ actions; run history lives on
  # +client.jobs.runs+.
  #
  # A job is enabled per environment: a recurring (cron) job may run in several
  # environments at once, a manual job (no schedule) runs only when triggered,
  # and a one-off (+now+ / future datetime) job runs a single time in the
  # environment it was created in. Base {Job#enabled} is a derived roll-up
  # (+true+ when enabled in at least one environment), computed from the
  # per-environment {Job#environments} map.
  module Jobs
    # Wrap a generated-jobs-API call and translate +ApiError+ into the
    # +Smplkit::Error+ hierarchy. Connection-level failures (no response
    # code) become {Smplkit::ConnectionError}; status-coded failures route
    # through {Smplkit::Errors.raise_for_status}, which emits
    # +PaymentRequiredError+ / +NotFoundError+ / +ConflictError+ /
    # +ValidationError+ / +Error+ depending on the JSON:API body.
    def self.call_api
      yield
    rescue SmplkitGeneratedClient::Jobs::ApiError => e
      raise Smplkit::ConnectionError, e.message.to_s if e.code.nil? || e.code.zero?

      Smplkit::Errors.raise_for_status(e.code, e.response_body.to_s)
      # raise_for_status only returns on 2xx; if we get here the generated
      # layer raised on a 2xx (shouldn't happen) — re-raise the original so
      # the caller can inspect.
      raise
    end

    # Coerce a caller-supplied +environments+ value into the comma-separated
    # string the +GET /api/v1/runs+ endpoint expects for +filter[environment]+,
    # or +nil+ when no filter should be sent.
    #
    # +nil+ or an empty array (or one whose entries are all blank) returns
    # +nil+ so the caller omits the query param entirely and the read covers
    # every environment the credential can access.
    #
    # @api private
    def self.join_environments(environments)
      return nil if environments.nil?

      values = Array(environments).map { |e| e.to_s.strip }.reject(&:empty?)
      values.empty? ? nil : values.join(",")
    end

    # Resolve the +filter[environment]+ value for the runs listing.
    #
    # An explicit, non-empty +environments+ list always wins and is comma-joined
    # via {join_environments}. Otherwise the client's configured +default+
    # environment scopes the read. A client with no configured environment and
    # no explicit list returns +nil+ so the caller omits the query param and the
    # credential's own scoping applies server-side.
    #
    # @param environments [Array<String>, String, nil] Explicit per-call
    #   environment filter; an empty/blank value falls through to +default+.
    # @param default [String, nil] The client's configured environment.
    # @return [String, nil] The +filter[environment]+ value, or +nil+ to omit it.
    # @api private
    def self.resolve_environment_filter(environments, default)
      joined = join_environments(environments)
      return joined unless joined.nil?

      default
    end

    # Coerce a caller's +environments+ map to {JobEnvironment} instances.
    #
    # Accepts either {JobEnvironment} values or plain hashes
    # (+{ enabled: true, schedule: "0 3 * * *", configuration: HttpConfig.new(...) }+)
    # so callers can use the lightweight hash form without importing the model. A
    # dict-form +configuration+ override is coerced to an {HttpConfig} so it
    # serializes on save; optional +schedule+ cron, +timezone+, and
    # +retry_policy+ overrides pass through.
    #
    # @api private
    def self.normalize_environments(environments)
      return {} if environments.nil? || environments.empty?

      environments.each_with_object({}) do |(env_key, value), out|
        out[env_key.to_s] = if value.is_a?(JobEnvironment)
                              value
                            else
                              cfg = value[:configuration] || value["configuration"]
                              cfg = HttpConfig.new(**cfg) if cfg.is_a?(Hash)
                              JobEnvironment.new(
                                enabled: value[:enabled] || value["enabled"] || false,
                                schedule: value[:schedule] || value["schedule"],
                                timezone: value[:timezone] || value["timezone"],
                                retry_policy: value[:retry_policy] || value["retry_policy"],
                                configuration: cfg
                              )
                            end
      end
    end

    # How a job runs, derived from its schedule (read-only).
    #
    # - +MANUAL+: No schedule — never auto-fires; runs only when triggered.
    # - +ONE_OFF+: A +now+ or datetime schedule — runs a single time, then is
    #   spent.
    # - +RECURRING+: A cron schedule — fires on a repeating cadence.
    module JobKind
      MANUAL = "manual"
      ONE_OFF = "one_off"
      RECURRING = "recurring"

      VALUES = [MANUAL, ONE_OFF, RECURRING].freeze
    end

    # What started a run (read-only).
    #
    # - +MANUAL+: A +run+ / +trigger+ call started it on demand.
    # - +RERUN+: It repeats an earlier run.
    # - +RETRY+: An automatic retry of a failed run, per the job's retry policy.
    # - +SCHEDULE+: The job's schedule fired.
    module RunTrigger
      MANUAL = "MANUAL"
      RERUN = "RERUN"
      RETRY = "RETRY"
      SCHEDULE = "SCHEDULE"

      VALUES = [MANUAL, RERUN, RETRY, SCHEDULE].freeze
    end

    # How the wait between retries grows (a retry policy's backoff strategy).
    #
    # - +EXPONENTIAL+: Double the wait each retry — +delay_seconds+, then +2×+,
    #   +4×+, … — capped at +max_delay_seconds+.
    # - +FIXED+: Wait a constant +delay_seconds+ before every retry.
    module Backoff
      EXPONENTIAL = "exponential"
      FIXED = "fixed"

      VALUES = [EXPONENTIAL, FIXED].freeze
    end

    # HTTP verb a job uses when it fires.
    #
    # Mirrors the jobs spec's method enum so a job's
    # +configuration.method+ field is constrained to a known value instead
    # of accepting any string. Members are declared in alphabetical order.
    module HttpMethod
      DELETE = "DELETE"
      GET = "GET"
      PATCH = "PATCH"
      POST = "POST"
      PUT = "PUT"

      VALUES = [DELETE, GET, PATCH, POST, PUT].freeze

      # Validate and normalize an input to a wire-format string.
      #
      # @param value [String, nil] a published constant or its literal string.
      # @return [String, nil] the canonical wire value (or +nil+ when input is +nil+).
      # @raise [ArgumentError] when +value+ is not a member of {VALUES}.
      def self.coerce(value)
        return nil if value.nil?

        s = value.to_s
        return s if VALUES.include?(s)

        raise ArgumentError,
              "Unknown HttpMethod #{value.inspect}; expected one of #{VALUES.inspect}"
      end
    end

    # A single name/value HTTP header on the request a job performs.
    #
    # @!attribute [rw] name
    #   @return [String] Header name (e.g. +"Authorization"+, +"Content-Type"+).
    # @!attribute [rw] value
    #   @return [String] Header value. Returned in plaintext on reads, so a
    #     get-mutate-put round-trip preserves it without re-entering secrets.
    HttpHeader = Struct.new(:name, :value, keyword_init: true)

    # The HTTP request a job performs when it fires (the +http+ configuration).
    #
    # Extends the shared forwarder shape with the two fields a scheduled job
    # needs beyond a forwarder: a request +body+ and a per-run +timeout+.
    #
    # @!attribute [rw] method
    #   @return [String] HTTP verb used when the job fires. Defaults to {HttpMethod::POST}.
    # @!attribute [rw] url
    #   @return [String] Destination URL the job requests on each run.
    # @!attribute [rw] headers
    #   @return [Array<HttpHeader>] Headers attached to every request. Values
    #     often carry credentials and are returned in plaintext on reads, so a
    #     get-mutate-put round-trip preserves them without re-entering secrets.
    # @!attribute [rw] body
    #   @return [String, nil] Request body sent on each run. +nil+ (the default)
    #     sends an empty body, suitable for a connectivity ping. Sent verbatim —
    #     pair with a matching +Content-Type+ header.
    # @!attribute [rw] success_status
    #   @return [String] Status the destination must return for the run to count
    #     as success — an exact code (+"200"+, +"204"+) or a class (+"2xx"+,
    #     +"4xx"+). Defaults to +"2xx"+.
    # @!attribute [rw] timeout
    #   @return [Integer] Per-run timeout in seconds. A run that does not complete
    #     within this many seconds fails with reason +TIMEOUT+. Defaults to 30;
    #     bounded by your plan's maximum timeout.
    # @!attribute [rw] tls_verify
    #   @return [Boolean] Whether to verify the destination's TLS certificate
    #     chain. Defaults to +true+; flip to +false+ only for short-lived
    #     testing against an untrusted certificate. Prefer pinning the CA via
    #     +ca_cert+.
    # @!attribute [rw] ca_cert
    #   @return [String, nil] Optional PEM-encoded certificate (or bundle)
    #     trusted in addition to the system CA store. Ignored when +tls_verify+
    #     is +false+. +nil+ (the default) means "use system CAs only".
    #
    # rubocop:disable Lint/StructNewOverride -- ``:method`` matches the
    # API attribute and shadowing Struct#method is the expected ergonomics.
    HttpConfig = Struct.new(
      :method, :url, :headers, :body, :success_status, :timeout, :tls_verify, :ca_cert,
      keyword_init: true
    ) do
      def initialize(
        url:, method: HttpMethod::POST, headers: nil, body: nil,
        success_status: "2xx", timeout: 30, tls_verify: true, ca_cert: nil
      )
        super(
          method: HttpMethod.coerce(method), url: url, headers: headers || [], body: body,
          success_status: success_status, timeout: timeout, tls_verify: tls_verify, ca_cert: ca_cert
        )
      end

      # @api private — Convert an {HttpConfig} (or a Hash with the same keys)
      #   into the generated wire model the jobs service expects.
      #
      # @param src [HttpConfig, Hash] The HTTP configuration to serialize.
      # @return [SmplkitGeneratedClient::Jobs::JobHttpConfiguration] The wire model.
      def self.to_wire(src)
        h = src.is_a?(Hash) ? new(**src) : src
        SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(
          method: HttpMethod.coerce(h.method),
          url: h.url,
          headers: (h.headers || []).map do |hdr|
            name, value = if hdr.is_a?(Hash)
                            [hdr[:name] || hdr["name"], hdr[:value] || hdr["value"]]
                          else
                            [hdr.name, hdr.value]
                          end
            SmplkitGeneratedClient::Jobs::HttpHeader.new(name: name, value: value)
          end,
          body: h.body,
          success_status: h.success_status,
          timeout: h.timeout,
          tls_verify: h.tls_verify,
          ca_cert: h.ca_cert
        )
      end

      # @api private — Build an {HttpConfig} from the generated wire model
      #   returned by the jobs service. Header values arrive in plaintext, so a
      #   round-trip back through {to_wire} preserves them.
      #
      # @param src [SmplkitGeneratedClient::Jobs::JobHttpConfiguration, nil] The
      #   wire model, or +nil+ for an empty configuration.
      # @return [HttpConfig] The wrapper-side configuration.
      def self.from_wire(src)
        return new(url: "") if src.nil?

        # +url+, +success_status+, and +timeout+ are required non-nil on the
        # generated jobs config, so they pass straight through. +method+,
        # +tls_verify+, +headers+, +body+, and +ca_cert+ are nullable and get
        # wrapper-side defaults when the wire omits them.
        new(
          method: src.method || HttpMethod::POST,
          url: src.url,
          headers: (src.headers || []).map { |h| HttpHeader.new(name: h.name, value: h.value) },
          body: src.body,
          success_status: src.success_status,
          timeout: src.timeout,
          # rubocop:disable Style/RedundantCondition -- nil and false are
          # distinct: nil means "field absent on the wire" (default to true);
          # explicit false means "verification disabled".
          tls_verify: src.tls_verify.nil? ? true : src.tls_verify,
          # rubocop:enable Style/RedundantCondition
          ca_cert: src.ca_cert
        )
      end
    end
    # rubocop:enable Lint/StructNewOverride

    # Per-environment enablement, schedule, and configuration override for a job.
    #
    # A job runs in a given environment only when that environment has an entry
    # in {Job#environments} with +enabled: true+ (scheduled there for a
    # recurring job, triggerable there for a manual one); an environment with no
    # entry (or +enabled: false+) is disabled there.
    #
    # @!attribute [rw] enabled
    #   @return [Boolean] Whether the job is enabled in this environment.
    #     Defaults to +false+.
    # @!attribute [rw] schedule
    #   @return [String, nil] Optional per-environment cron schedule override
    #     that varies the cadence in this environment. +nil+ (the default)
    #     inherits the job's base {Job#schedule}. When present, it must be a
    #     5-field UTC cron expression and is only meaningful on a recurring job —
    #     it cannot turn a one-off job recurring or vice-versa.
    # @!attribute [rw] timezone
    #   @return [String, nil] Optional per-environment IANA timezone override for
    #     evaluating this environment's cron {#schedule} (recurring jobs only).
    #     +nil+ (the default) inherits the base {Job#timezone}, else UTC. When
    #     present, it must be a valid IANA zone key (e.g. +"America/New_York"+);
    #     it may be set on an environment that inherits the base schedule (it
    #     need not also override {#schedule}). Sent on writes only when present.
    # @!attribute [rw] retry_policy
    #   @return [String, nil] Optional per-environment retry-policy override — the
    #     id of a {RetryPolicy} (or +"Default"+). +nil+ (the default) inherits the
    #     job's base {Job#retry_policy}. Sent on writes only when present.
    # @!attribute [rw] configuration
    #   @return [HttpConfig, nil] Optional per-environment request configuration
    #     that fully replaces the job's base {Job#configuration} for this
    #     environment. +nil+ (the default) inherits the base configuration. As
    #     with the base configuration, header values are returned in plaintext on
    #     reads, so a get-mutate-put round-trip preserves them.
    # @!attribute [rw] next_run_at
    #   @return [String, nil] Read-only. The next scheduled fire time in this
    #     environment. +nil+ when the environment is not enabled, or once a
    #     one-off run has fired. Never written back on save.
    JobEnvironment = Struct.new(
      :enabled, :schedule, :timezone, :retry_policy, :configuration, :next_run_at, keyword_init: true
    ) do
      def initialize(enabled: false, schedule: nil, timezone: nil, retry_policy: nil,
                     configuration: nil, next_run_at: nil)
        super
      end

      # @api private — Build a {JobEnvironment} from the generated wire model.
      #
      # @param src [SmplkitGeneratedClient::Jobs::JobEnvironment, nil] The wire
      #   model, or +nil+ for a disabled environment with no override.
      # @return [JobEnvironment]
      def self.from_wire(src)
        return new if src.nil?

        cfg = src.configuration
        new(
          enabled: src.enabled.nil? ? false : src.enabled,
          schedule: src.schedule,
          timezone: src.timezone,
          retry_policy: src.retry_policy,
          configuration: cfg.nil? ? nil : HttpConfig.from_wire(cfg),
          next_run_at: src.next_run_at
        )
      end
    end

    # A unit of work: an HTTP request, run on a schedule or triggered on demand.
    #
    # Active-record style: instantiate via +client.jobs.new_recurring_job(...)+,
    # +new_manual_job(...)+, or +schedule(...)+, mutate fields directly, and call
    # {#save} to persist or {#delete} to remove. Header values in
    # +configuration.headers+ are returned in plaintext on reads, so fetching a
    # job, mutating it, and calling {#save} preserves its header values without
    # re-entering secrets.
    #
    # A job's {#kind} follows from its {#schedule}: a recurring (cron) job, a
    # manual job (no schedule, runs only when triggered), or a one-off (+now+ /
    # datetime) job that runs a single time. Enablement is per environment, set
    # via {#set_enabled} (and read via {#is_enabled}); base {#enabled} is a
    # derived roll-up over {#environments}. The base schedule is
    # environment-agnostic, while each environment may carry its own cron
    # {#set_schedule} override.
    class Job
      # @return [String] Caller-supplied unique identifier for the job (the
      #   resource +id+). Unique within the account and immutable; the service
      #   returns 409 if another live job already uses this id.
      attr_accessor :id

      # @return [String] Human-readable name for the job.
      attr_accessor :name

      # @return [String, nil] Free-text description. +nil+ when unset.
      attr_accessor :description

      # @return [Boolean] Derived roll-up: +true+ when the job is enabled in at
      #   least one environment. Computed from {#environments} rather than read
      #   from the wire — the API no longer carries a top-level +enabled+. Set
      #   enablement per environment via {#set_enabled} / {#environments}.
      def enabled
        (@environments || {}).each_value.any?(&:enabled)
      end

      # @return [Hash{String => JobEnvironment}] Per-environment overrides keyed
      #   by environment key (e.g. +"production"+). The writable surface for
      #   enablement: a recurring job fires in an environment only when
      #   +environments[env].enabled+ is +true+. Each entry may carry an optional
      #   {HttpConfig} override; omit it to inherit the base {#configuration}.
      #   Every referenced environment must exist and be managed for the account.
      attr_accessor :environments

      # @return [String, nil] Read-only. How the job runs, derived from its
      #   {#schedule} by the server: one of {JobKind::RECURRING},
      #   {JobKind::MANUAL}, or {JobKind::ONE_OFF}. +nil+ on an unsaved instance.
      attr_accessor :kind

      # @return [String] Job type. Only +"http"+ is supported today.
      attr_accessor :type

      # @return [String, nil] The base schedule every environment inherits, and
      #   the field that determines the job's {#kind}: +nil+ (omitted) for a
      #   permanent manual job that never auto-fires; a 5-field cron expression
      #   evaluated in UTC for a recurring job; an ISO-8601 datetime for a
      #   one-off run at that instant; or the literal +"now"+ for a one-off run
      #   as soon as possible. A datetime or +"now"+ job disables itself after it
      #   fires. The schedule is environment-agnostic — set it with
      #   {#set_schedule}.
      attr_accessor :schedule

      # @return [String, nil] The base IANA timezone the cron {#schedule} is
      #   evaluated in (e.g. +"America/New_York"+); +nil+ (the default) means
      #   UTC. The base every environment inherits unless it sets its own
      #   {JobEnvironment#timezone}. The cron fires on this zone's wall clock
      #   (DST-aware) while +next_run_at+ is still reported as a UTC instant.
      #   Only valid on a recurring (cron) job — leave +nil+ for a manual or
      #   one-off job. Set it with {#set_timezone}; sent on writes only when
      #   present.
      attr_accessor :timezone

      # @return [String, nil] The base retry policy for failed runs — the id of a
      #   {RetryPolicy}, overridable per environment via
      #   {JobEnvironment#retry_policy}. +nil+ (the default, omitted on the wire)
      #   uses the built-in +"Default"+ policy, which never retries. Set it with
      #   {#set_retry_policy}; sent on writes only when present.
      attr_accessor :retry_policy

      # @return [HttpConfig] The base HTTP request to perform when the job fires.
      #   Per-environment overrides live in {#environments}.
      attr_accessor :configuration

      # @return [String] How overlapping runs are handled. +"ALLOW"+ (the only
      #   value) permits them.
      attr_accessor :concurrency_policy

      # @return [String, nil] ISO-8601 timestamp of first persist. +nil+ for an
      #   unsaved instance.
      attr_accessor :created_at

      # @return [String, nil] ISO-8601 timestamp of the most recent mutation.
      attr_accessor :updated_at

      # @return [String, nil] Timestamp when the job was deleted; +nil+ for live
      #   jobs.
      attr_accessor :deleted_at

      # @return [Integer, nil] Monotonic version counter, bumped on every
      #   server-side write.
      attr_accessor :version

      # @api private — For a one-off job, the environment it is born in, sent as
      #   the +X-Smplkit-Environment+ header by {JobsClient#_create_job}. Ignored
      #   for recurring and manual jobs, whose environments come from
      #   {#environments}.
      attr_accessor :birth_environment

      def initialize(client = nil, id:, name:, configuration:, schedule: nil,
                     timezone: nil, retry_policy: nil, description: nil, environments: nil,
                     kind: nil, type: "http", concurrency_policy: "ALLOW",
                     birth_environment: nil, created_at: nil,
                     updated_at: nil, deleted_at: nil, version: nil)
        @client = client
        @id = id
        @name = name
        @description = description
        @environments = environments || {}
        @kind = kind
        @type = type
        @schedule = schedule
        @timezone = timezone
        @retry_policy = retry_policy
        @configuration = configuration
        @concurrency_policy = concurrency_policy
        @birth_environment = birth_environment
        @created_at = created_at
        @updated_at = updated_at
        @deleted_at = deleted_at
        @version = version
      end

      # Create this job, or full-replace it if it already exists.
      #
      # Upsert behavior is driven by {#created_at}: a job with no +created_at+
      # is created (POST); otherwise it's full-replace updated (PUT). After the
      # call, every field is refreshed from the server response (including
      # newly-assigned +created_at+, +version+, and per-environment +next_run_at+
      # inside {#environments}).
      #
      # @return [self]
      def save
        raise "Job was constructed without a client; cannot save" if @client.nil?

        updated = @created_at.nil? ? @client._create_job(self) : @client._update_job(self)
        _apply(updated)
        self
      end
      alias save! save

      # Delete this job on the server.
      #
      # @return [nil]
      def delete
        raise "Job was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      # Enable or disable the job in a single environment.
      #
      # Sets the per-environment override's +enabled+ on {#environments},
      # creating the override entry if it doesn't exist yet (preserving any
      # already-set +configuration+ on it). Call {#save} to persist.
      #
      # @param enabled [Boolean] Whether the job should fire in this environment.
      # @param environment [String] The environment key to enable / disable.
      def set_enabled(enabled, environment:)
        _environment_override(environment).enabled = enabled
      end

      # Whether the job is enabled.
      #
      # With +environment+ omitted (the default), returns the roll-up — +true+
      # when the job is enabled in at least one environment. With an
      # +environment+, returns whether the job is enabled in that specific
      # environment.
      #
      # @param environment [String, nil] An environment key, or +nil+ for the
      #   roll-up across every environment.
      # @return [Boolean]
      def is_enabled(environment: nil)
        return enabled if environment.nil?

        override = @environments[environment]
        return false if override.nil?

        override.enabled
      end

      # Whether this is a recurring (cron-scheduled) job.
      #
      # @return [Boolean]
      def is_recurring
        @kind == JobKind::RECURRING
      end

      # Whether this is a manual job — no schedule; runs only when triggered.
      #
      # @return [Boolean]
      def is_manual
        @kind == JobKind::MANUAL
      end

      # Whether this is a one-off job — a single +now+ / datetime run.
      #
      # @return [Boolean]
      def is_one_off
        @kind == JobKind::ONE_OFF
      end

      # Set the job's configuration — base (+environment+ omitted) or
      # per-environment.
      #
      # With +environment+ given, sets the per-environment override's
      # configuration on {#environments}, creating the override entry if it
      # doesn't exist yet (preserving any already-set +enabled+ on it). Call
      # {#save} to persist.
      #
      # @param configuration [HttpConfig] The HTTP request configuration.
      # @param environment [String, nil] An environment key for a per-environment
      #   override, or +nil+ to set the base configuration.
      def set_configuration(configuration, environment: nil)
        if environment.nil?
          @configuration = configuration
        else
          _environment_override(environment).configuration = configuration
        end
      end

      # The job's effective configuration.
      #
      # With +environment+ omitted (the default), returns the base
      # configuration. With an +environment+, returns that environment's
      # configuration override when it has one, else the base configuration —
      # the request the job actually sends when it fires in that environment.
      #
      # @param environment [String, nil] An environment key, or +nil+ for the
      #   base configuration.
      # @return [HttpConfig]
      def get_configuration(environment: nil)
        unless environment.nil?
          override = @environments[environment]
          return override.configuration if override && !override.configuration.nil?
        end
        @configuration
      end

      # Set the job's schedule — base (+environment+ omitted) or per-environment.
      #
      # With +environment+ omitted (the default), sets the base {#schedule} —
      # an ISO-8601 datetime, a 5-field UTC cron expression, or the literal
      # +"now"+ — which every environment inherits unless it overrides it.
      #
      # With +environment+ given, sets that environment's per-environment cron
      # +schedule+ override on {#environments}, creating the override entry if it
      # doesn't exist yet (preserving any already-set +enabled+ / +configuration+
      # on it). A per-environment override is a cron expression only and varies
      # the cadence within that environment; it cannot turn a one-off job
      # recurring or vice-versa. Call {#save} to persist.
      #
      # Because the timezone is an integral part of a cron cadence, a +timezone+
      # may be supplied alongside the schedule; when given it sets the same
      # scope's timezone too (equivalent to a follow-up {#set_timezone}). Omit it
      # to leave the timezone untouched. For a timezone-only change, use
      # {#set_timezone}.
      #
      # @param schedule [String] An ISO-8601 datetime, a 5-field UTC cron
      #   expression, or the literal +"now"+ (base); a 5-field UTC cron
      #   expression (per-environment).
      # @param timezone [String, nil] An optional IANA timezone to set on the
      #   same scope (recurring jobs only). +nil+ (the default) leaves the
      #   timezone untouched.
      # @param environment [String, nil] An environment key for a per-environment
      #   override, or +nil+ to set the base schedule.
      def set_schedule(schedule, timezone: nil, environment: nil)
        if environment.nil?
          @schedule = schedule
        else
          _environment_override(environment).schedule = schedule
        end
        set_timezone(timezone, environment: environment) unless timezone.nil?
      end

      # Set the IANA timezone the cron schedule is evaluated in — base
      # (+environment+ omitted) or per-environment.
      #
      # With +environment+ omitted (the default), sets the base {#timezone}
      # every environment inherits unless it overrides it. With an +environment+
      # given, sets that environment's per-environment +timezone+ override on
      # {#environments}, creating the override entry if it doesn't exist yet
      # (preserving any already-set +enabled+ / +schedule+ / +configuration+ on
      # it). A timezone is only valid on a recurring (cron) job; +nil+ means UTC
      # (base) or "inherit the base" (per-environment). Call {#save} to persist.
      #
      # @param timezone [String, nil] A valid IANA timezone key (e.g.
      #   +"America/New_York"+), or +nil+ for UTC / inherit.
      # @param environment [String, nil] An environment key for a per-environment
      #   override, or +nil+ to set the base timezone.
      def set_timezone(timezone, environment: nil)
        if environment.nil?
          @timezone = timezone
        else
          _environment_override(environment).timezone = timezone
        end
      end

      # Set the retry policy for failed runs — base (+environment+ omitted) or
      # per-environment.
      #
      # With +environment+ omitted (the default), sets the base {#retry_policy}
      # every environment inherits unless it overrides it. With an +environment+
      # given, sets that environment's per-environment override on
      # {#environments}, creating the override entry if it doesn't exist yet
      # (preserving any already-set +enabled+ / +schedule+ / +timezone+ /
      # +configuration+ on it). Call {#save} to persist.
      #
      # Accepts either a {RetryPolicy} instance (its id is used) or a policy id
      # string — pass +"Default"+ for the built-in never-retry policy.
      #
      # @param retry_policy [RetryPolicy, String] A {RetryPolicy} or a policy id.
      # @param environment [String, nil] An environment key for a per-environment
      #   override, or +nil+ to set the base retry policy.
      def set_retry_policy(retry_policy, environment: nil)
        policy_id = retry_policy.is_a?(RetryPolicy) ? retry_policy.id : retry_policy
        if environment.nil?
          @retry_policy = policy_id
        else
          _environment_override(environment).retry_policy = policy_id
        end
      end

      # Trigger one immediate, manual run of this job (a +MANUAL+ run).
      #
      # @param environment [String, nil] Environment the run executes in.
      #   Defaults to the client's configured environment; when the job is
      #   enabled in exactly one environment that environment is used.
      # @return [Smplkit::Jobs::Run] The run that was started.
      # @raise [RuntimeError] when this job has no bound client.
      def trigger(environment: nil)
        raise "Job was constructed without a client; cannot trigger a run" if @client.nil?

        @client.run(@id, environment: environment)
      end

      # List this job's run history, most recent first.
      #
      # @param environment [String, nil] Restrict to runs stamped with this
      #   environment. +nil+ covers every environment you can access.
      # @param triggers [Array<String>, nil] Restrict to runs started by any of
      #   these triggers (see {RunTrigger}) — e.g. +[RunTrigger::RETRY]+ for
      #   automatic retries. +nil+ covers every trigger.
      # @param last_run_only [Boolean] When +true+, return only the last
      #   completed run per environment (in-flight runs excluded). Defaults to
      #   +false+.
      # @param page_size [Integer, nil] Maximum number of runs to return in this
      #   page.
      # @param after [String, nil] Opaque cursor from a previous page.
      # @return [Array<Smplkit::Jobs::Run>] The runs in this page.
      # @raise [RuntimeError] when this job has no bound client.
      def list_runs(environment: nil, triggers: nil, last_run_only: false, page_size: nil, after: nil)
        raise "Job was constructed without a client; cannot list runs" if @client.nil?

        @client.runs.list(
          job: @id,
          environments: environment.nil? ? nil : [environment],
          triggers: triggers,
          last_run_only: last_run_only,
          page_size: page_size,
          after: after
        )
      end

      # Return the override for +environment+, creating an empty one if absent.
      #
      # The per-environment mutators reach through here so an existing override's
      # other field is preserved when only one of +enabled+ / +configuration+ is
      # being set.
      #
      # @api private
      def _environment_override(environment)
        @environments[environment] ||= JobEnvironment.new
      end

      # @api private
      def _apply(other)
        @id = other.id
        @name = other.name
        @description = other.description
        @environments = other.environments
        @kind = other.kind
        @type = other.type
        @schedule = other.schedule
        @timezone = other.timezone
        @retry_policy = other.retry_policy
        @configuration = other.configuration
        @concurrency_policy = other.concurrency_policy
        @created_at = other.created_at
        @updated_at = other.updated_at
        @deleted_at = other.deleted_at
        @version = other.version
      end

      # @api private — Build a {Job} from a JSON:API resource returned by the
      #   jobs service, binding it to +client+ so {#save} and {#delete} work.
      #
      # @param resource [Object] The JSON:API resource (id + attributes).
      # @param client [JobsClient, nil] Client to bind the job to.
      # @return [Job] The hydrated job.
      def self.from_resource(resource, client: nil)
        a = resource.attributes
        environments = (a.environments || {}).each_with_object({}) do |(env_key, env_raw), out|
          out[env_key.to_s] = JobEnvironment.from_wire(env_raw)
        end
        new(
          client,
          id: resource.id,
          name: a.name,
          description: a.description,
          # The base +enabled+ roll-up is derived from +environments+, not read
          # from the wire — the API no longer carries a top-level +enabled+.
          environments: environments,
          kind: a.kind,
          type: a.type || "http",
          schedule: a.schedule,
          timezone: a.timezone,
          retry_policy: a.retry_policy,
          configuration: HttpConfig.from_wire(a.configuration),
          concurrency_policy: a.concurrency_policy || "ALLOW",
          created_at: a.created_at,
          updated_at: a.updated_at,
          deleted_at: a.deleted_at,
          version: a.version
        )
      end
    end

    # Where a +RETRY+ run sits in its retry chain (read-only).
    #
    # @!attribute [rw] of
    #   @return [String] Id of the chain's original run — the first attempt that
    #     failed and started the chain.
    # @!attribute [rw] attempt
    #   @return [Integer] Which retry this run is — +1+ for the first retry, +2+
    #     for the second, and so on.
    RunRetry = Struct.new(:of, :attempt, keyword_init: true)

    # A single execution of a job (read-only) with +rerun+ / +cancel+ actions.
    #
    # Runs are created and mutated by the jobs service, not by clients; clients
    # influence runs only through {#rerun} / {#cancel} (and the +run+ action on
    # +client.jobs+). A run returned from the SDK holds a backref to the runs
    # client so {#rerun} / {#cancel} work without re-deriving the client.
    #
    # @!attribute [rw] id
    #   @return [String] Server-assigned UUID for this run.
    # @!attribute [rw] job
    #   @return [String] The id of the job this run belongs to.
    # @!attribute [rw] job_version
    #   @return [Integer, nil] The job's version at the time the run executed.
    # @!attribute [rw] environment
    #   @return [String] The environment this run executed in. A scheduled run
    #     inherits the firing job-environment; a manual run uses the environment
    #     named on the run-now request; a rerun copies its source run's environment.
    # @!attribute [rw] trigger
    #   @return [String] Why the run exists — a raw string equal to one of the
    #     {RunTrigger} constants: +SCHEDULE+, +MANUAL+ (run now), or +RERUN+.
    # @!attribute [rw] rerun_of
    #   @return [String, nil] The source run's id; set only when +trigger+ is +RERUN+.
    # @!attribute [rw] retry
    #   @return [RunRetry, nil] Retry-chain position, populated only when
    #     +trigger+ is +RETRY+; +nil+ otherwise.
    # @!attribute [rw] scheduled_for
    #   @return [String, nil] The intended fire time for a scheduled run; +nil+
    #     for manual / rerun runs.
    # @!attribute [rw] status
    #   @return [String] Lifecycle state of the run.
    # @!attribute [rw] started_at
    #   @return [String, nil] When execution started.
    # @!attribute [rw] finished_at
    #   @return [String, nil] When execution finished.
    # @!attribute [rw] pending_duration_ms
    #   @return [Integer, nil] Milliseconds the run waited as +PENDING+ before starting.
    # @!attribute [rw] run_duration_ms
    #   @return [Integer, nil] Milliseconds the run spent executing.
    # @!attribute [rw] total_duration_ms
    #   @return [Integer, nil] Milliseconds from enqueue to finish.
    # @!attribute [rw] failure_reason
    #   @return [String, nil] Why a +FAILED+ run failed; +nil+ otherwise.
    # @!attribute [rw] error
    #   @return [String, nil] Free-text failure detail, if any.
    # @!attribute [rw] request
    #   @return [Hash, nil] Snapshot of the request that was sent (header values redacted).
    # @!attribute [rw] result
    #   @return [Hash, nil] Outcome of the call (status, headers, body, ...).
    # @!attribute [rw] created_at
    #   @return [String, nil] When the run was enqueued (became +PENDING+).
    Run = Struct.new(
      :id, :job, :job_version, :environment, :trigger, :rerun_of, :retry, :scheduled_for,
      :status, :started_at, :finished_at, :pending_duration_ms, :run_duration_ms,
      :total_duration_ms, :failure_reason, :error, :request, :result, :created_at,
      keyword_init: true
    ) do
      # @api private — Build a {Run} from a JSON:API resource returned by the
      #   jobs service, binding it to +runs+ so {#rerun} / {#cancel} work.
      #
      # @param resource [Object] The JSON:API resource (id + attributes).
      # @param runs [RunsClient, nil] Runs client to bind the run to.
      # @return [Run] The hydrated run.
      def self.from_resource(resource, runs: nil)
        a = resource.attributes
        # The retry-chain position is populated only on a +RETRY+ run; the
        # generated model exposes it as +_retry+ (+retry+ is a Ruby keyword).
        retry_chain = a._retry
        retry_pos = if a.trigger == RunTrigger::RETRY && !retry_chain.nil?
                      RunRetry.new(of: retry_chain.of, attempt: retry_chain.attempt)
                    end
        new(
          id: resource.id,
          job: a.job,
          job_version: a.job_version,
          environment: a.environment,
          trigger: a.trigger,
          rerun_of: a.rerun_of,
          retry: retry_pos,
          scheduled_for: a.scheduled_for,
          status: a.status,
          started_at: a.started_at,
          finished_at: a.finished_at,
          pending_duration_ms: a.pending_duration_ms,
          run_duration_ms: a.run_duration_ms,
          total_duration_ms: a.total_duration_ms,
          failure_reason: a.failure_reason,
          error: a.error,
          request: a.request.nil? ? nil : Smplkit::Helpers.deep_stringify_keys(a.request),
          result: a.result.nil? ? nil : Smplkit::Helpers.deep_stringify_keys(a.result),
          created_at: a.created_at
        ).tap { |run| run.instance_variable_set(:@runs, runs) }
      end

      # Start a new run that repeats this one (a +RERUN+), in the same
      # environment.
      #
      # @return [Smplkit::Jobs::Run] The new run, with +rerun_of+ set to this
      #   run's id.
      # @raise [RuntimeError] when this run has no bound runs client.
      def rerun
        raise "Run was constructed without a client; cannot rerun" if @runs.nil?

        @runs.rerun(id)
      end

      # Cancel this run if it has not finished yet.
      #
      # @return [Smplkit::Jobs::Run] The updated run reflecting the cancellation.
      # @raise [RuntimeError] when this run has no bound runs client.
      def cancel
        raise "Run was constructed without a client; cannot cancel" if @runs.nil?

        @runs.cancel(id)
      end
    end

    # Current-period usage against the account's plan allotments (read-only).
    #
    # @!attribute [rw] period
    #   @return [String] The usage period this report covers, as +YYYY-MM+ (UTC).
    # @!attribute [rw] runs_used
    #   @return [Integer] Runs metered so far this period.
    # @!attribute [rw] runs_included
    #   @return [Integer] Runs included in the plan this period (+-1+ means unlimited).
    # @!attribute [rw] active_jobs
    #   @return [Integer] Number of currently-enabled jobs.
    # @!attribute [rw] active_jobs_limit
    #   @return [Integer] Maximum enabled jobs the plan allows (+-1+ means unlimited).
    Usage = Struct.new(
      :period, :runs_used, :runs_included, :active_jobs, :active_jobs_limit,
      keyword_init: true
    ) do
      # @api private — Build a {Usage} snapshot from a JSON:API resource
      #   returned by the jobs service.
      #
      # @param resource [Object] The JSON:API resource (attributes).
      # @return [Usage] The usage snapshot.
      def self.from_resource(resource)
        a = resource.attributes
        new(
          period: a.period,
          runs_used: a.runs_used,
          runs_included: a.runs_included,
          active_jobs: a.active_jobs,
          active_jobs_limit: a.active_jobs_limit
        )
      end
    end

    # A named, reusable automatic-retry policy.
    #
    # Active-record style: instantiate via +client.jobs.retry_policies.new(...)+,
    # mutate fields directly, and call {#save} to persist or {#delete} to remove.
    # Reference a saved policy from a job's {Job#retry_policy} (see
    # {JobsClient#new_recurring_job} and {Job#set_retry_policy}). Retry policies
    # are account-global — never environment-scoped.
    #
    # A policy decides whether and how a failed run is retried. A job that
    # references nothing uses the built-in +"Default"+ policy, which never
    # retries.
    class RetryPolicy
      # @return [String] Caller-supplied unique identifier for the policy (the
      #   resource +id+). Unique within the account and immutable; the service
      #   returns 409 if another live policy already uses this id.
      attr_accessor :id

      # @return [String] Human-readable name for the policy.
      attr_accessor :name

      # @return [Integer] How many times a failed run is retried after the
      #   initial attempt — +3+ means up to 4 attempts total. +0+ disables
      #   retries. Maximum 10.
      attr_accessor :max_retries

      # @return [String] How the wait between retries grows; one of {Backoff}.
      attr_accessor :backoff

      # @return [Integer] The wait before a retry, in seconds — the constant wait
      #   for {Backoff::FIXED}, or the base that doubles each retry for
      #   {Backoff::EXPONENTIAL}.
      attr_accessor :delay_seconds

      # @return [Integer, nil] Ceiling on the wait between retries, for
      #   {Backoff::EXPONENTIAL} backoff only. +nil+ (the default, omitted on the
      #   wire) leaves it uncapped; omit it for {Backoff::FIXED}.
      attr_accessor :max_delay_seconds

      # @return [Boolean] Retry a run that timed out. Defaults to +false+.
      attr_accessor :retry_on_timeout

      # @return [Boolean] Retry a run whose destination could not be reached (a
      #   connection error). Defaults to +false+.
      attr_accessor :retry_on_connection_error

      # @return [Array<String>] Allowlist of response-status patterns to retry on
      #   a non-success response. Each element is an exact 3-digit code (e.g.
      #   +"429"+) or a class token (+"1xx"+ … +"5xx"+). Defaults to an empty
      #   list (retries no statuses).
      attr_accessor :retry_statuses

      # @return [Array<String>] Patterns subtracted from {#retry_statuses}, using
      #   the same exact-code or class syntax. A status matching both lists is not
      #   retried — +except+ wins on overlap. Defaults to an empty list.
      attr_accessor :retry_statuses_except

      # @return [String, nil] ISO-8601 timestamp of first persist. +nil+ for an
      #   unsaved instance.
      attr_accessor :created_at

      # @return [String, nil] ISO-8601 timestamp of the most recent mutation.
      attr_accessor :updated_at

      # @return [String, nil] Timestamp when the policy was deleted; +nil+ for
      #   live policies.
      attr_accessor :deleted_at

      # @return [Integer, nil] Monotonic version counter, bumped on every
      #   server-side write.
      attr_accessor :version

      def initialize(client = nil, id:, name:, max_retries:, backoff:, delay_seconds:,
                     max_delay_seconds: nil, retry_on_timeout: false,
                     retry_on_connection_error: false, retry_statuses: nil,
                     retry_statuses_except: nil, created_at: nil,
                     updated_at: nil, deleted_at: nil, version: nil)
        @client = client
        @id = id
        @name = name
        @max_retries = max_retries
        @backoff = backoff
        @delay_seconds = delay_seconds
        @max_delay_seconds = max_delay_seconds
        @retry_on_timeout = retry_on_timeout
        @retry_on_connection_error = retry_on_connection_error
        @retry_statuses = retry_statuses || []
        @retry_statuses_except = retry_statuses_except || []
        @created_at = created_at
        @updated_at = updated_at
        @deleted_at = deleted_at
        @version = version
      end

      # Create this policy, or full-replace it if it already exists.
      #
      # Upsert behavior is driven by {#created_at}: a policy with no +created_at+
      # is created (POST); otherwise it's full-replace updated (PUT). After the
      # call, every field is refreshed from the server response.
      #
      # @return [self]
      def save
        raise "RetryPolicy was constructed without a client; cannot save" if @client.nil?

        updated = @created_at.nil? ? @client._create_retry_policy(self) : @client._update_retry_policy(self)
        _apply(updated)
        self
      end
      alias save! save

      # Delete this policy on the server.
      #
      # @return [nil]
      def delete
        raise "RetryPolicy was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      # @api private
      def _apply(other)
        @id = other.id
        @name = other.name
        @max_retries = other.max_retries
        @backoff = other.backoff
        @delay_seconds = other.delay_seconds
        @max_delay_seconds = other.max_delay_seconds
        @retry_on_timeout = other.retry_on_timeout
        @retry_on_connection_error = other.retry_on_connection_error
        @retry_statuses = other.retry_statuses
        @retry_statuses_except = other.retry_statuses_except
        @created_at = other.created_at
        @updated_at = other.updated_at
        @deleted_at = other.deleted_at
        @version = other.version
      end

      # @api private — Build a {RetryPolicy} from a JSON:API resource returned by
      #   the jobs service, binding it to +client+ so {#save} and {#delete} work.
      #
      # @param resource [Object] The JSON:API resource (id + attributes).
      # @param client [RetryPoliciesClient, nil] Client to bind the policy to.
      # @return [RetryPolicy] The hydrated policy.
      def self.from_resource(resource, client: nil)
        a = resource.attributes
        new(
          client,
          id: resource.id,
          name: a.name,
          max_retries: a.max_retries,
          backoff: a.backoff,
          delay_seconds: a.delay_seconds,
          max_delay_seconds: a.max_delay_seconds,
          retry_on_timeout: a.retry_on_timeout || false,
          retry_on_connection_error: a.retry_on_connection_error || false,
          retry_statuses: a.retry_statuses || [],
          retry_statuses_except: a.retry_statuses_except || [],
          created_at: a.created_at,
          updated_at: a.updated_at,
          deleted_at: a.deleted_at,
          version: a.version
        )
      end
    end
  end
end
