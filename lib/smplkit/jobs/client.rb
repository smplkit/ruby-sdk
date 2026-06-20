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
#   Job#{save,delete,trigger,list_runs}
#   Run#{rerun,cancel}
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
      # @param page_size [Integer, nil] Maximum number of runs to return in this
      #   page. +nil+ uses the server default.
      # @param after [String, nil] Opaque cursor from a previous page; returns
      #   the runs that follow it. +nil+ starts from the first page.
      # @return [Array<Smplkit::Jobs::Run>] The runs in this page.
      def list(job: nil, environments: nil, page_size: nil, after: nil)
        opts = {}
        opts[:filter_job] = job unless job.nil?
        filter_environment = Jobs.resolve_environment_filter(environments, @environment)
        opts[:filter_environment] = filter_environment unless filter_environment.nil?
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

    # The Smpl Jobs client — accessed via +client.jobs+.
    #
    # Unlike Config/Flags/Logging, Jobs has no live "phone-home" agent — no
    # environment registration, no WebSocket — so its entire surface lives on
    # one client. Defining a job, triggering a run, and reading run history are
    # all plain request/response calls here:
    #
    #   client.jobs.{new_recurring_job,new_manual_job,schedule,get,list,delete,run,usage}
    #   client.jobs.runs.{list,get,cancel,rerun}
    #   Job#{save,delete,trigger,list_runs}
    #   Run#{rerun,cancel}
    #
    # Build a standalone Smpl Jobs transport from resolved config.
    #
    # Reuses the config resolver (jobs is account-global and never
    # environment-scoped at the transport layer) so a standalone jobs client
    # resolves credentials/base-domain from +~/.smplkit+ / env vars /
    # constructor args exactly like the top-level clients do. Smpl Jobs is
    # JSON:API, so the transport carries the +application/vnd.api+json+ Accept
    # header.
    def self.jobs_transport(api_key:, profile:, base_domain:, scheme:, debug:, extra_headers:)
      cfg = ConfigResolution.resolve_client_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme, debug: debug
      )
      merged = {}
      merged.merge!(cfg.extra_headers || {})
      merged.merge!(extra_headers || {})
      tcfg = ConfigResolution::ResolvedClientConfig.new(
        api_key: cfg.api_key, base_domain: cfg.base_domain, scheme: cfg.scheme,
        debug: cfg.debug, extra_headers: merged
      )
      Transport.build_api_client(SmplkitGeneratedClient::Jobs, "jobs", tcfg, accept: "application/vnd.api+json")
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
      #   and the default scope for +runs.list+. +nil+ leaves these unset (the
      #   credential's permitted environment is implied where unambiguous).
      # @param auth_client [Object, nil] Internal — a pre-built transport
      #   supplied by a top-level client so the jobs surface shares one
      #   connection pool. Not for direct use.
      def initialize(api_key = nil, profile: nil, base_domain: nil, scheme: nil,
                     debug: nil, extra_headers: nil, environment: nil, auth_client: nil)
        auth = auth_client || Jobs.jobs_transport(
          api_key: api_key, profile: profile, base_domain: base_domain,
          scheme: scheme, debug: debug, extra_headers: extra_headers
        )
        @environment = environment
        @api = SmplkitGeneratedClient::Jobs::JobsApi.new(auth)
        @runs = RunsClient.new(SmplkitGeneratedClient::Jobs::RunsApi.new(auth), environment: environment)
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
      #   evaluated in UTC (e.g. +"0 2 * * *"+) — that every environment inherits
      #   unless it sets its own override.
      # @param configuration [Smplkit::Jobs::HttpConfig] The HTTP request the job
      #   sends each time it fires.
      # @param description [String, nil] Optional free-text description.
      # @param environments [Hash{String => Smplkit::Jobs::JobEnvironment, Hash}, nil]
      #   Per-environment overrides keyed by environment key — each a
      #   {Smplkit::Jobs::JobEnvironment}, or a plain hash (+{ enabled: true }+,
      #   optionally with a +:schedule+ cron override and/or a +:configuration+
      #   {Smplkit::Jobs::HttpConfig} override). The job is scheduled only in
      #   environments enabled here.
      # @param concurrency_policy [String] How overlapping runs are handled.
      #   Defaults to +"ALLOW"+.
      # @return [Smplkit::Jobs::Job]
      def new_recurring_job(id, name:, schedule:, configuration:, description: nil,
                            environments: nil, concurrency_policy: "ALLOW")
        _new_job(
          id, name: name, schedule: schedule, configuration: configuration,
              description: description, environments: environments,
              concurrency_policy: concurrency_policy, environment: nil
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
      #   Per-environment overrides keyed by environment key — each a
      #   {Smplkit::Jobs::JobEnvironment}, or a plain hash (+{ enabled: true }+,
      #   optionally with a +:configuration+ {Smplkit::Jobs::HttpConfig}
      #   override). The job is triggerable only in environments enabled here.
      # @param concurrency_policy [String] How overlapping runs are handled.
      #   Defaults to +"ALLOW"+.
      # @return [Smplkit::Jobs::Job]
      def new_manual_job(id, name:, configuration:, description: nil,
                         environments: nil, concurrency_policy: "ALLOW")
        _new_job(
          id, name: name, schedule: nil, configuration: configuration,
              description: description, environments: environments,
              concurrency_policy: concurrency_policy, environment: nil
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
      # @param environment [String, nil] The environment the job is born in.
      #   Defaults to the client's configured environment.
      # @return [Smplkit::Jobs::Job]
      def schedule(id, name:, schedule:, configuration:, description: nil,
                   concurrency_policy: "ALLOW", environment: nil)
        _new_job(
          id, name: name, schedule: schedule.iso8601, configuration: configuration,
              description: description, environments: nil,
              concurrency_policy: concurrency_policy, environment: environment
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
        resp = Jobs.call_api { @api.run_job_now(id, x_smplkit_environment: env) }
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
      #   environment travels as the +X-Smplkit-Environment+ header.
      def _create_job(job)
        raise ArgumentError, "Job.id is required on create (caller-supplied key)" if job.id.nil? || job.id.empty?

        resp = Jobs.call_api { @api.create_job(build_create_body(job), x_smplkit_environment: job.birth_environment) }
        Job.from_resource(resp.data, client: self)
      end

      # @api private — Full-replace PUT for an existing job. Called by
      #   {Smplkit::Jobs::Job#save} on instances with +created_at+. The client's
      #   configured environment (if any) travels as the +X-Smplkit-Environment+
      #   header.
      #
      # Header values come back in plaintext on the GET path, so a fetched job
      # round-trips through this full-replace PUT with its header values intact
      # — no need to re-enter secrets.
      def _update_job(job)
        raise ArgumentError, "cannot update a Job with no id" if job.id.nil?

        resp = Jobs.call_api { @api.update_job(job.id, build_body(job), x_smplkit_environment: @environment) }
        Job.from_resource(resp.data, client: self)
      end

      private

      # Build an unsaved {Smplkit::Jobs::Job} bound to this client. The three
      # public constructors ({#new_recurring_job}, {#new_manual_job}, {#schedule})
      # funnel through here.
      def _new_job(id, name:, schedule:, configuration:, description:,
                   environments:, concurrency_policy:, environment:)
        Job.new(
          self,
          id: id,
          name: name,
          schedule: schedule,
          configuration: configuration,
          description: description,
          environments: Jobs.normalize_environments(environments),
          concurrency_policy: concurrency_policy,
          birth_environment: environment.nil? ? @environment : environment
        )
      end

      # Convert the wrapper +environments+ map to the generated model hash.
      #
      # Each entry's +enabled+ is always written; a per-environment +schedule+
      # (cron) override, +timezone+ override, and +configuration+ override are
      # each sent only when present (omit to inherit the job's base +schedule+ /
      # +timezone+ / +configuration+). The read-only per-environment
      # +next_run_at+ is never written.
      def environments_to_wire(environments)
        (environments || {}).each_with_object({}) do |(env_key, env), out|
          attrs = { enabled: env.enabled }
          attrs[:schedule] = env.schedule unless env.schedule.nil?
          attrs[:timezone] = env.timezone unless env.timezone.nil?
          attrs[:configuration] = HttpConfig.to_wire(env.configuration) unless env.configuration.nil?
          out[env_key.to_s] = SmplkitGeneratedClient::Jobs::JobEnvironment.new(attrs)
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
