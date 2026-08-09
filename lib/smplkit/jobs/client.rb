# frozen_string_literal: true

require "time"

# The Smpl Jobs client — one unified +JobsClient+.
#
# Smpl Jobs runs HTTP calls — on a schedule or on demand — and records their
# run history. Unlike Config/Flags/Logging it installs no in-process machinery,
# so it has no runtime/management split: a single +JobsClient+ exposes the full
# surface and is reachable as +client.jobs+ on +Smplkit::Client+ or constructed
# directly.
#
#   client.jobs.{new_recurring_job,new_manual_job,schedule,get,list,delete,run,usage}
#   client.jobs.runs.{list,get,cancel,rerun}
#   client.jobs.retry_policies.{new,list,get,delete}
#   Job#{save,delete,trigger,list_runs}
#   Run#{rerun,cancel}
#   RetryPolicy#{save,delete}
#
# A job is enabled per environment: a recurring (cron) job may be enabled in
# several environments at once, a manual job (no schedule) runs only when
# triggered, and a one-off (+now+ / future datetime) job is born in exactly
# one. A client-level +environment+ default supplies the one-off birth
# environment on create, the run-now environment, and the +runs.list+
# +filter[environment]+ scope.
#
# The shared model classes (+Job+, +JobEnvironment+, +Run+, +Usage+,
# +HttpConfig+) live in +lib/smplkit/jobs/models.rb+.
module Smplkit
  module Jobs
    # +client.jobs.runs.*+ — read-only run history plus the cancel / rerun run
    # actions.
    class RunsClient
      # @param api [SmplkitGeneratedClient::Jobs::RunsApi] The generated runs API.
      # @param environment [String, nil] Default environment scoping +#list+'s
      #   +filter[environment]+ when no explicit +environments+ are passed.
      def initialize(api, environment: nil)
        @api = api
        @environment = environment
      end

      # List past runs, most recent first. Cursor paginated: pass +page_size+
      # and the +after+ cursor from the prior page. Pass +job+ to scope to a
      # single job's history.
      #
      # @param job [String, nil] Return only runs of the job with this id.
      #   +nil+ lists runs across all jobs in the account.
      # @param environments [Array<String>, nil] Restrict to runs stamped with
      #   any of these environment keys. +nil+ falls back to the client's
      #   configured environment (if any), otherwise covers every environment you
      #   can access.
      # @param triggers [Array<String>, nil] Restrict to runs started by any of
      #   these triggers (see {RunTrigger}) — e.g. +[RunTrigger::RETRY]+ for
      #   automatic retries. Serialized as a comma-joined +filter[trigger]+
      #   (any-of). +nil+ or empty covers every trigger.
      # @param last_run_only [Boolean] When +true+, collapse the result to the
      #   last completed (succeeded / failed / canceled) run per
      #   job-and-environment; in-flight runs are excluded. The other filters
      #   apply first, then the collapse. Defaults to +false+; the query param is
      #   sent only when +true+.
      # @param page_size [Integer, nil] Maximum number of runs to return in this
      #   page. +nil+ uses the server default.
      # @param after [String, nil] Opaque cursor from a previous page; returns
      #   the runs that follow it. +nil+ starts from the first page.
      # @return [Array<Smplkit::Jobs::Run>] The runs in this page.
      def list(job: nil, environments: nil, triggers: nil, last_run_only: false, page_size: nil, after: nil)
        opts = {}
        opts[:filter_job] = job unless job.nil?
        filter_environment = Jobs.resolve_environment_filter(environments, @environment)
        opts[:filter_environment] = filter_environment unless filter_environment.nil?
        opts[:filter_trigger] = triggers.join(",") unless triggers.nil? || triggers.empty?
        # The generated default would emit +last_run_only=false+ on every call;
        # send the param only when explicitly requested.
        opts[:last_run_only] = true if last_run_only
        opts[:page_size] = page_size unless page_size.nil?
        opts[:page_after] = after unless after.nil?

        resp = Jobs.call_api { @api.list_runs(opts) }
        (resp.data || []).map { |r| Run.from_resource(r, runs: self) }
      end

      # Fetch a single run by its id.
      #
      # @param run_id [String] Identifier of the run to fetch.
      # @return [Smplkit::Jobs::Run] The matching run.
      # @raise [Smplkit::NotFoundError] when no run with this id exists.
      def get(run_id)
        resp = Jobs.call_api { @api.get_run(run_id) }
        Run.from_resource(resp.data, runs: self)
      end

      # Cancel a run that has not finished yet.
      #
      # @param run_id [String] Identifier of the run to cancel.
      # @return [Smplkit::Jobs::Run] The updated run reflecting the cancellation.
      def cancel(run_id)
        resp = Jobs.call_api { @api.cancel_run(run_id) }
        Run.from_resource(resp.data, runs: self)
      end

      # Start a new run that repeats a previous one.
      #
      # @param run_id [String] Identifier of the run to repeat.
      # @return [Smplkit::Jobs::Run] The new run, with +rerun_of+ set to the
      #   source +run_id+.
      def rerun(run_id)
        resp = Jobs.call_api { @api.rerun_run(run_id) }
        Run.from_resource(resp.data, runs: self)
      end
    end

    # +client.jobs.retry_policies.*+ — manage reusable, account-global retry
    # policies.
    #
    # A {RetryPolicy} is an active record: build one with {#new}, set fields, and
    # call +#save+; then reference it from a job's +retry_policy+ — base:
    # +job.retry_policy = policy+; per-environment:
    # +job.environment(env).retry_policy = policy+. Retry policies are
    # account-global — never environment-scoped.
    class RetryPoliciesClient
      # @param api [SmplkitGeneratedClient::Jobs::RetryPoliciesApi] The generated
      #   retry-policies API.
      def initialize(api)
        @api = api
      end

      # Construct an unsaved {RetryPolicy} bound to this client. Call +#save+ on
      # the returned instance to create it.
      #
      # @param id [String] Caller-supplied unique identifier for the policy.
      #   Unique within the account and immutable; the service returns 409 if
      #   another live policy already uses this id.
      # @param name [String] Human-readable name for the policy.
      # @param max_retries [Integer] How many times a failed run is retried after
      #   the initial attempt — +3+ means up to 4 attempts total. +0+ disables
      #   retries. Maximum 10.
      # @param backoff [String] How the wait between retries grows; one of
      #   {Backoff}.
      # @param delay_seconds [Integer] The wait before a retry, in seconds — the
      #   constant wait for {Backoff::FIXED}, or the base that doubles each retry
      #   for {Backoff::EXPONENTIAL}.
      # @param max_delay_seconds [Integer, nil] Ceiling on the wait between
      #   retries, for {Backoff::EXPONENTIAL} backoff only. +nil+ (the default)
      #   leaves it uncapped; omit it for {Backoff::FIXED}.
      # @param retry_on_timeout [Boolean] Retry a run that timed out. Defaults to
      #   +false+.
      # @param retry_on_connection_error [Boolean] Retry a run whose destination
      #   could not be reached. Defaults to +false+.
      # @param retry_statuses [Array<String>, nil] Allowlist of response-status
      #   patterns to retry on a non-success response. Each element is an exact
      #   3-digit code (e.g. +"429"+) or a class token (+"1xx"+ … +"5xx"+).
      #   +nil+ (the default) retries no statuses.
      # @param retry_statuses_except [Array<String>, nil] Patterns subtracted from
      #   +retry_statuses+, using the same syntax; +except+ wins on overlap.
      #   +nil+ (the default) subtracts nothing.
      # @return [Smplkit::Jobs::RetryPolicy]
      def new(id, name:, max_retries:, backoff:, delay_seconds:, max_delay_seconds: nil,
              retry_on_timeout: false, retry_on_connection_error: false,
              retry_statuses: nil, retry_statuses_except: nil)
        RetryPolicy.new(
          self,
          id: id, name: name, max_retries: max_retries, backoff: backoff,
          delay_seconds: delay_seconds, max_delay_seconds: max_delay_seconds,
          retry_on_timeout: retry_on_timeout,
          retry_on_connection_error: retry_on_connection_error,
          retry_statuses: retry_statuses, retry_statuses_except: retry_statuses_except
        )
      end

      # List retry policies in the account.
      #
      # @param name [String, nil] Return only policies whose name contains this
      #   text (case-insensitive). +nil+ lists all.
      # @param page_number [Integer, nil] 1-based page to return. +nil+ returns
      #   the first page.
      # @param page_size [Integer, nil] Maximum number of policies to return in
      #   this page. +nil+ uses the server default.
      # @return [Array<Smplkit::Jobs::RetryPolicy>] The policies in this page.
      def list(name: nil, page_number: nil, page_size: nil)
        opts = {}
        opts[:filter_name] = name unless name.nil?
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?

        resp = Jobs.call_api { @api.list_retry_policies(opts) }
        (resp.data || []).map { |r| RetryPolicy.from_resource(r, client: self) }
      end

      # Fetch a single retry policy by its id.
      #
      # @param id [String] Identifier of the policy to fetch.
      # @return [Smplkit::Jobs::RetryPolicy] The matching policy.
      # @raise [Smplkit::NotFoundError] when no policy with this id exists.
      def get(id)
        resp = Jobs.call_api { @api.get_retry_policy(id) }
        RetryPolicy.from_resource(resp.data, client: self)
      end

      # Delete a retry policy by its id.
      #
      # @param id [String] Identifier of the policy to delete.
      # @return [nil]
      def delete(id)
        Jobs.call_api { @api.delete_retry_policy(id) }
        nil
      end

      # @api private — POST a new retry policy. Called by {RetryPolicy#save} on
      #   unsaved instances. The jobs service requires a caller-supplied
      #   +data.id+ on create and 409s on conflict.
      def _create_retry_policy(policy)
        if policy.id.nil? || policy.id.empty?
          raise ArgumentError, "RetryPolicy.id is required on create (caller-supplied key)"
        end

        resp = Jobs.call_api { @api.create_retry_policy(build_create_body(policy)) }
        RetryPolicy.from_resource(resp.data, client: self)
      end

      # @api private — Full-replace PUT for an existing retry policy. Called by
      #   {RetryPolicy#save} on instances with +created_at+.
      def _update_retry_policy(policy)
        raise ArgumentError, "cannot update a RetryPolicy with no id" if policy.id.nil?

        resp = Jobs.call_api { @api.update_retry_policy(policy.id, build_body(policy)) }
        RetryPolicy.from_resource(resp.data, client: self)
      end

      private

      # Build the generated attributes model shared by create and update. The
      # four retry-condition fields are always sent; +max_delay_seconds+ is sent
      # only when present (omitting it leaves the policy uncapped / is invalid for
      # fixed backoff).
      def build_retry_policy_attrs(policy)
        attrs = {
          name: policy.name,
          max_retries: policy.max_retries,
          backoff: policy.backoff,
          delay_seconds: policy.delay_seconds,
          retry_on_timeout: policy.retry_on_timeout,
          retry_on_connection_error: policy.retry_on_connection_error,
          retry_statuses: Array(policy.retry_statuses).map(&:to_s),
          retry_statuses_except: Array(policy.retry_statuses_except).map(&:to_s)
        }
        attrs[:max_delay_seconds] = policy.max_delay_seconds unless policy.max_delay_seconds.nil?
        SmplkitGeneratedClient::Jobs::RetryPolicy.new(attrs)
      end

      def build_create_body(policy)
        # Create uses the distinct RetryPolicyCreateRequest envelope; the jobs
        # service requires data.id (the caller-supplied key) on create.
        resource = SmplkitGeneratedClient::Jobs::RetryPolicyCreateResource.new(
          id: policy.id.to_s, type: "retry_policy", attributes: build_retry_policy_attrs(policy)
        )
        SmplkitGeneratedClient::Jobs::RetryPolicyCreateRequest.new(data: resource)
      end

      def build_body(policy)
        # Update path uses the generic RetryPolicyRequest envelope.
        resource = SmplkitGeneratedClient::Jobs::RetryPolicyResource.new(
          id: policy.id.to_s, type: "retry_policy", attributes: build_retry_policy_attrs(policy)
        )
        SmplkitGeneratedClient::Jobs::RetryPolicyRequest.new(data: resource)
      end
    end

    # The Smpl Jobs client — accessed via +client.jobs+.
    #
    # Unlike Config/Flags/Logging, Jobs has no live "phone-home" agent — no
    # environment registration, no event stream — so its entire surface lives
    # on one client. Defining a job, triggering a run, and reading run history are
    # all plain request/response calls here:
    #
    #   client.jobs.{new_recurring_job,new_manual_job,schedule,get,list,delete,run,usage}
    #   client.jobs.runs.{list,get,cancel,rerun}
    #   client.jobs.retry_policies.{new,list,get,delete}
    #   Job#{save,delete,trigger,list_runs}
    #   Run#{rerun,cancel}
    #   RetryPolicy#{save,delete}
    #
    # Build a standalone Smpl Jobs transport from resolved config.
    #
    # Reuses the config resolver (jobs is account-global and never
    # environment-scoped at the transport layer) so a standalone jobs client
    # resolves credentials/base-domain from +~/.smplkit+ / env vars /
    # constructor args exactly like the top-level clients do. The client-level
    # default +environment+ resolves through the same chain (constructor
    # argument wins) and is returned alongside. Smpl Jobs is JSON:API, so the
    # transport carries the +application/vnd.api+json+ Accept header.
    def self.jobs_transport(api_key:, profile:, base_domain:, scheme:, environment:, debug:, extra_headers:)
      cfg = ConfigResolution.resolve_client_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme,
        environment: environment, debug: debug
      )
      merged = {}
      merged.merge!(cfg.extra_headers || {})
      merged.merge!(extra_headers || {})
      tcfg = ConfigResolution::ResolvedClientConfig.new(
        api_key: cfg.api_key, base_domain: cfg.base_domain, scheme: cfg.scheme,
        debug: cfg.debug, extra_headers: merged
      )
      transport = Transport.build_api_client(
        SmplkitGeneratedClient::Jobs, "jobs", tcfg, accept: "application/vnd.api+json"
      )
      [transport, cfg.environment]
    end

    # The active-record entry points are {#new_recurring_job}, {#new_manual_job},
    # and {#schedule}: instantiate a draft, mutate fields, then call
    # {Smplkit::Jobs::Job#save}. Run history and the cancel / rerun run actions
    # live on {#runs}.
    #
    # Reachable as +client.jobs+ (+Smplkit::Client+) or constructed directly —
    # +JobsClient.new+ resolves credentials from +~/.smplkit+ / env vars.
    class JobsClient
      # @return [RunsClient] Run history and run actions (+client.jobs.runs+).
      attr_reader :runs

      # @return [RetryPoliciesClient] Reusable retry policies
      #   (+client.jobs.retry_policies+).
      attr_reader :retry_policies

      # @param api_key [String, nil] API key. When omitted, resolved from
      #   +SMPLKIT_API_KEY+ or +~/.smplkit+.
      # @param profile [String, nil] Named +~/.smplkit+ profile section.
      # @param base_domain [String, nil] Base domain for API requests
      #   (default +"smplkit.com"+).
      # @param scheme [String, nil] URL scheme (default +"https"+).
      # @param debug [Boolean, nil] Enable SDK debug logging.
      # @param extra_headers [Hash, nil] Extra headers attached to every request.
      # @param environment [String, nil] Default environment for
      #   environment-scoped operations — the environment a one-off job created
      #   through this client is born in, the default a manual run executes in,
      #   and the default scope for +runs.list+. When omitted, resolved from
      #   +SMPLKIT_ENVIRONMENT+ or +~/.smplkit+. +nil+ leaves these unset (the
      #   credential's permitted environment is implied where unambiguous).
      # @param auth_client [Object, nil] Internal — a pre-built transport
      #   supplied by a top-level client so the jobs surface shares one
      #   connection pool. Not for direct use.
      def initialize(api_key = nil, profile: nil, base_domain: nil, scheme: nil,
                     debug: nil, extra_headers: nil, environment: nil, auth_client: nil)
        if auth_client.nil?
          # Standalone: resolve like Smplkit::Client — defaults → ~/.smplkit →
          # SMPLKIT_* env vars → constructor args — environment included.
          auth, resolved_env = Jobs.jobs_transport(
            api_key: api_key, profile: profile, base_domain: base_domain,
            scheme: scheme, environment: environment, debug: debug, extra_headers: extra_headers
          )
          @environment = resolved_env
        else
          auth = auth_client
          @environment = environment
        end
        @api = SmplkitGeneratedClient::Jobs::JobsApi.new(auth)
        @runs = RunsClient.new(SmplkitGeneratedClient::Jobs::RunsApi.new(auth), environment: environment)
        @retry_policies = RetryPoliciesClient.new(SmplkitGeneratedClient::Jobs::RetryPoliciesApi.new(auth))
        @usage_api = SmplkitGeneratedClient::Jobs::UsageApi.new(auth)
      end

      # The generated ApiClient owns Faraday connections that release on GC;
      # there is no explicit shutdown to call.
      def close
        nil
      end

      # Construct, yield to the block, and close on exit.
      def self.open(*args, **kwargs)
        client = new(*args, **kwargs)
        begin
          yield client
        ensure
          client.close
        end
      end

      # Construct an unsaved recurring {Smplkit::Jobs::Job} bound to this client.
      # Call +#save+ on the returned instance to create it.
      #
      # @param id [String] Caller-supplied unique identifier for the job. Unique
      #   within the account and immutable; the service returns 409 if another
      #   live job already uses this id.
      # @param name [String] Human-readable name for the job.
      # @param schedule [String] The base cadence — a 5-field cron expression
      #   evaluated in the job's +timezone+ (UTC by default), e.g. +"0 2 * * *"+ —
      #   that every environment inherits unless it sets its own override.
      # @param timezone [String, nil] Base IANA timezone the cron +schedule+ is
      #   evaluated in (e.g. +"America/New_York"+), DST-aware. +nil+ (the default)
      #   means UTC. Every environment inherits it unless it overrides it.
      # @param retry_policy [String, nil] Base retry policy for failed runs — the
      #   id of a {Smplkit::Jobs::RetryPolicy}, overridable per environment. +nil+
      #   (the default) uses the built-in +"Default"+ policy, which never retries.
      # @param configuration [Smplkit::Jobs::HttpConfig] The HTTP request the job
      #   sends each time it fires.
      # @param description [String, nil] Optional free-text description.
      # @param environments [Hash{String => Smplkit::Jobs::JobEnvironment, Hash}, nil]
      #   Per-environment sparse overrides keyed by environment key — each a
      #   {Smplkit::Jobs::JobEnvironment}, or a plain hash of its constructor kwargs
      #   (+{ enabled: true }+, optionally with +:schedule+, +:timezone+,
      #   +:retry_policy+, request leaves like +:url+, and a +:headers+ name→value
      #   map). Each entry overrides only the leaves it sets; the job is scheduled
      #   only in environments enabled here.
      # @param concurrency_policy [String] How overlapping runs are handled.
      #   Defaults to +"ALLOW"+.
      # @return [Smplkit::Jobs::Job]
      def new_recurring_job(id, name:, schedule:, configuration:, timezone: nil, retry_policy: nil,
                            description: nil, environments: nil, concurrency_policy: "ALLOW")
        _new_job(
          id, name: name, schedule: schedule, timezone: timezone, retry_policy: retry_policy,
              configuration: configuration, description: description, environments: environments,
              concurrency_policy: concurrency_policy
        )
      end

      # Construct an unsaved manual {Smplkit::Jobs::Job} bound to this client.
      # Call +#save+ on the returned instance to create it.
      #
      # A manual job has no schedule — it never auto-fires and runs only when
      # triggered via {#run} / {Smplkit::Jobs::Job#trigger}.
      #
      # @param id [String] Caller-supplied unique identifier for the job. Unique
      #   within the account and immutable; the service returns 409 if another
      #   live job already uses this id.
      # @param name [String] Human-readable name for the job.
      # @param configuration [Smplkit::Jobs::HttpConfig] The HTTP request the job
      #   sends each time it runs.
      # @param description [String, nil] Optional free-text description.
      # @param environments [Hash{String => Smplkit::Jobs::JobEnvironment, Hash}, nil]
      #   Per-environment sparse overrides keyed by environment key — each a
      #   {Smplkit::Jobs::JobEnvironment}, or a plain hash of its constructor kwargs
      #   (+{ enabled: true }+, optionally with request leaves like +:url+ and a
      #   +:headers+ name→value map). Each entry overrides only the leaves it sets;
      #   the job is triggerable only in environments enabled here.
      # @param concurrency_policy [String] How overlapping runs are handled.
      #   Defaults to +"ALLOW"+.
      # @param retry_policy [String, nil] Retry policy for failed runs — the id of
      #   a {Smplkit::Jobs::RetryPolicy}, overridable per environment. +nil+ (the
      #   default) uses the built-in +"Default"+ policy, which never retries.
      # @return [Smplkit::Jobs::Job]
      def new_manual_job(id, name:, configuration:, description: nil,
                         environments: nil, concurrency_policy: "ALLOW", retry_policy: nil)
        _new_job(
          id, name: name, schedule: nil, retry_policy: retry_policy,
              configuration: configuration, description: description, environments: environments,
              concurrency_policy: concurrency_policy
        )
      end

      # Construct an unsaved one-off {Smplkit::Jobs::Job} bound to this client.
      # Call +#save+ on the returned instance to create it.
      #
      # A one-off job runs a single time at +schedule+ and is then spent.
      #
      # @param id [String] Caller-supplied unique identifier for the job. Unique
      #   within the account and immutable; the service returns 409 if another
      #   live job already uses this id.
      # @param name [String] Human-readable name for the job.
      # @param schedule [Time] The instant the single run fires.
      # @param configuration [Smplkit::Jobs::HttpConfig] The HTTP request the job
      #   sends when it runs.
      # @param description [String, nil] Optional free-text description.
      # @param concurrency_policy [String] How overlapping runs are handled.
      #   Defaults to +"ALLOW"+.
      # @param retry_policy [String, nil] Retry policy for failed runs — the id of
      #   a {Smplkit::Jobs::RetryPolicy}. +nil+ (the default) uses the built-in
      #   +"Default"+ policy, which never retries.
      # @param environment [String, nil] The environment the job is born in.
      #   Defaults to the client's configured environment.
      # @return [Smplkit::Jobs::Job]
      def schedule(id, name:, schedule:, configuration:, description: nil,
                   concurrency_policy: "ALLOW", retry_policy: nil, environment: nil)
        _new_job(
          id, name: name, schedule: schedule.iso8601, retry_policy: retry_policy,
              configuration: configuration, description: description,
              environments: birth_env_map(environment.nil? ? @environment : environment),
              concurrency_policy: concurrency_policy
        )
      end

      # List jobs for the authenticated account.
      #
      # @param kind [String, nil] Filter to a single {Smplkit::Jobs::JobKind}
      #   (+JobKind::RECURRING+ / +JobKind::MANUAL+ / +JobKind::ONE_OFF+). +nil+
      #   lists recurring and manual jobs; one-off jobs are omitted unless you
      #   pass +JobKind::ONE_OFF+.
      # @param scheduled [Boolean, nil] Filter to jobs that have an upcoming fire
      #   in some environment (+true+) or none (+false+) — the feed for an
      #   upcoming-runs view, which includes one-offs. +nil+ does not filter on
      #   scheduling.
      # @param name [String, nil] Filter to jobs whose name contains this text
      #   (case-insensitive). +nil+ lists all.
      # @param page_number [Integer, nil] 1-based page number to return.
      # @param page_size [Integer, nil] Items per page.
      # @return [Array<Smplkit::Jobs::Job>]
      def list(kind: nil, scheduled: nil, name: nil, page_number: nil, page_size: nil)
        opts = {}
        opts[:filter_kind] = kind unless kind.nil?
        opts[:filter_scheduled] = scheduled unless scheduled.nil?
        opts[:filter_name] = name unless name.nil?
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?

        resp = Jobs.call_api { @api.list_jobs(opts) }
        (resp.data || []).map { |r| Job.from_resource(r, client: self) }
      end

      # Fetch a single job by id. The returned instance is bound to this client,
      # so +job.save+ and +job.delete+ work.
      #
      # @param id [String]
      # @return [Smplkit::Jobs::Job]
      def get(id)
        resp = Jobs.call_api { @api.get_job(id) }
        Job.from_resource(resp.data, client: self)
      end

      # Delete a job by its id.
      #
      # @param id [String] Identifier of the job to delete.
      # @return [nil]
      def delete(id)
        Jobs.call_api { @api.delete_job(id) }
        nil
      end

      # Trigger one immediate, manual run of a job, ignoring its schedule.
      #
      # This starts an ad-hoc run right now in addition to any scheduled runs;
      # it does not alter the job's schedule. To read or act on existing runs,
      # use +client.jobs.runs+.
      #
      # @param id [String] Identifier of the job to run.
      # @param environment [String, nil] Environment the manual run executes in.
      #   Defaults to the client's configured environment; when the job is
      #   enabled in exactly one environment that environment is used, and a
      #   single-environment credential implies it. The job must be enabled in
      #   the chosen environment.
      # @return [Smplkit::Jobs::Run] The run that was started, with +trigger+
      #   set to +MANUAL+.
      def run(id, environment: nil)
        env = environment.nil? ? @environment : environment
        # The target environment now travels in the run-now request body (the
        # X-Smplkit-Environment header was dropped). When no environment is
        # resolved, send no body at all so the service implies it.
        opts = {}
        opts[:run_now_request] = SmplkitGeneratedClient::Jobs::RunNowRequest.new(environment: env) unless env.nil?
        resp = Jobs.call_api { @api.run_job_now(id, opts) }
        Run.from_resource(resp.data, runs: @runs)
      end

      # Current-period usage counters for the account.
      #
      # @return [Smplkit::Jobs::Usage]
      def usage
        resp = Jobs.call_api { @usage_api.get_usage }
        Usage.from_resource(resp.data)
      end

      # @api private — POST a new job. Called by {Smplkit::Jobs::Job#save} on
      #   unsaved instances. The jobs service requires a caller-supplied
      #   +data.id+ on create and 409s on conflict. A one-off job's birth
      #   environment travels as an enabled entry in the body's +environments+
      #   map (see {#_new_job}); there is no request header.
      def _create_job(job)
        raise ArgumentError, "Job.id is required on create (caller-supplied key)" if job.id.nil? || job.id.empty?

        resp = Jobs.call_api { @api.create_job(build_create_body(job)) }
        Job.from_resource(resp.data, client: self)
      end

      # @api private — Full-replace PUT for an existing job. Called by
      #   {Smplkit::Jobs::Job#save} on instances with +created_at+. The target
      #   environment travels in the body (the +environments+ map), so the update
      #   carries no environment header.
      #
      # Header values come back in plaintext on the GET path, so a fetched job
      # round-trips through this full-replace PUT with its header values intact
      # — no need to re-enter secrets.
      def _update_job(job)
        raise ArgumentError, "cannot update a Job with no id" if job.id.nil?

        resp = Jobs.call_api { @api.update_job(job.id, build_body(job)) }
        Job.from_resource(resp.data, client: self)
      end

      private

      # Build an unsaved {Smplkit::Jobs::Job} bound to this client. The three
      # public constructors ({#new_recurring_job}, {#new_manual_job}, {#schedule})
      # funnel through here.
      def _new_job(id, name:, schedule:, configuration:, description:,
                   environments:, concurrency_policy:,
                   timezone: nil, retry_policy: nil)
        Job.new(
          self,
          id: id,
          name: name,
          schedule: schedule,
          timezone: timezone,
          retry_policy: retry_policy,
          configuration: configuration,
          description: description,
          environments: Jobs.normalize_environments(environments),
          concurrency_policy: concurrency_policy
        )
      end

      # A one-off job's birth environment as an enabled +environments+ entry.
      # The target environment of a one-off job is now conveyed by a key of the
      # body's +environments+ map (there is no request header). Returns +nil+
      # when the environment is unknown, leaving the map empty so a
      # single-environment credential implies it server-side.
      def birth_env_map(environment)
        return nil if environment.nil? || environment.empty?

        { environment => JobEnvironment.new(enabled: true) }
      end

      # Convert the wrapper +environments+ map to the flat per-environment overlay
      # the generated +Job+ model carries (ADR-056). Each value is the
      # environment's sparse leaf-path overlay: +enabled+ plus only the leaves it
      # overrides, with each header as a +headers.<name>+ leaf. The read-only
      # per-environment +next_run_at+ is never written.
      def environments_to_wire(environments)
        (environments || {}).each_with_object({}) do |(env_key, env), out|
          out[env_key.to_s] = env.to_payload
        end
      end

      def build_attrs(job)
        # The base +enabled+ is a read-only, server-derived roll-up; we never
        # send it. Enablement travels entirely through +environments+, which is
        # included only when non-empty.
        attrs = {
          name: job.name,
          description: job.description,
          type: job.type,
          schedule: job.schedule,
          configuration: HttpConfig.to_wire(job.configuration),
          concurrency_policy: job.concurrency_policy
        }
        # +timezone+ is only valid on a recurring (cron) job; an unset +nil+ is
        # omitted, leaving the server default of UTC. (Unlike +schedule+, whose
        # explicit +null+ creates a manual job, omitting +timezone+ simply
        # inherits UTC — so it is sent only when present.)
        attrs[:timezone] = job.timezone unless job.timezone.nil?
        # +retry_policy+ id; an unset +nil+ is omitted, leaving the server
        # default (the built-in +Default+ policy, which never retries).
        attrs[:retry_policy] = job.retry_policy unless job.retry_policy.nil?
        environments = job.environments
        attrs[:environments] = environments_to_wire(environments) unless environments.nil? || environments.empty?
        SmplkitGeneratedClient::Jobs::Job.new(attrs)
      end

      def build_create_body(job)
        # Create uses the distinct JobCreateRequest envelope; the jobs service
        # requires data.id (the caller-supplied key) on create and 409s on
        # conflict.
        resource = SmplkitGeneratedClient::Jobs::JobCreateResource.new(
          id: job.id.to_s,
          type: "job",
          attributes: build_attrs(job)
        )
        SmplkitGeneratedClient::Jobs::JobCreateRequest.new(data: resource)
      end

      def build_body(job)
        # Update path uses the generic JobRequest envelope.
        resource = SmplkitGeneratedClient::Jobs::JobResource.new(
          id: job.id.to_s,
          type: "job",
          attributes: build_attrs(job)
        )
        SmplkitGeneratedClient::Jobs::JobRequest.new(data: resource)
      end
    end
  end

  JobsClient = Jobs::JobsClient
end
