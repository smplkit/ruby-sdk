# frozen_string_literal: true

# The Smpl Jobs client — one unified +JobsClient+.
#
# Smpl Jobs schedules HTTP calls (cron-style +schedule+ + +http+ configuration)
# and records their run history. Unlike Config/Flags/Logging it installs no
# in-process machinery, so it has no runtime/management split: a single
# +JobsClient+ exposes the full surface and is reachable as +client.jobs+ on
# +Smplkit::Client+ or constructed directly.
#
#   client.jobs.{new,get,list,delete,run,usage}
#   client.jobs.runs.{list,get,cancel,rerun}
#   Job#{save,delete}
#
# The shared model classes (+Job+, +Run+, +Usage+, +HttpConfig+) live in
# +lib/smplkit/jobs/models.rb+.
module Smplkit
  module Jobs
    # +client.jobs.runs.*+ — read-only run history plus the cancel / rerun run
    # actions.
    class RunsClient
      def initialize(api)
        @api = api
      end

      # List runs for the authenticated account, newest first. Cursor paginated
      # (ADR-014): pass +page_size+ and the +after+ cursor from the prior page.
      # Pass +job+ to scope to a single job's history.
      #
      # @param job [String, nil] Filter to a single job's run history, by job id.
      # @param page_size [Integer, nil] Items per page (cursor pagination).
      # @param after [String, nil] Opaque cursor token from a prior page.
      # @return [Array<Smplkit::Jobs::Run>]
      def list(job: nil, page_size: nil, after: nil)
        opts = {}
        opts[:filter_job] = job unless job.nil?
        opts[:page_size] = page_size unless page_size.nil?
        opts[:page_after] = after unless after.nil?

        resp = Jobs.call_api { @api.list_runs(opts) }
        (resp.data || []).map { |r| Run.from_resource(r) }
      end

      # Fetch a single run by id.
      #
      # @param run_id [String]
      # @return [Smplkit::Jobs::Run]
      def get(run_id)
        resp = Jobs.call_api { @api.get_run(run_id) }
        Run.from_resource(resp.data)
      end

      # Cancel a pending run.
      #
      # @param run_id [String]
      # @return [Smplkit::Jobs::Run]
      def cancel(run_id)
        resp = Jobs.call_api { @api.cancel_run(run_id) }
        Run.from_resource(resp.data)
      end

      # Re-run a prior run, spawning a new +RERUN+ run.
      #
      # @param run_id [String]
      # @return [Smplkit::Jobs::Run]
      def rerun(run_id)
        resp = Jobs.call_api { @api.rerun_run(run_id) }
        Run.from_resource(resp.data)
      end
    end

    # The Smpl Jobs client — accessed via +client.jobs+.
    #
    # Unlike Config/Flags/Logging, Jobs has no live "phone-home" agent — no
    # environment registration, no WebSocket — so its entire surface lives on
    # one client. Defining a job, triggering a run, and reading run history are
    # all plain request/response calls here:
    #
    #   client.jobs.{new,get,list,delete,run,usage}
    #   client.jobs.runs.{list,get,cancel,rerun}
    #   Job#{save,delete}
    #
    # Build a standalone Smpl Jobs transport from resolved config.
    #
    # Reuses the config resolver (jobs is account-global and never
    # environment-scoped) so a standalone jobs client resolves
    # credentials/base-domain from +~/.smplkit+ / env vars / constructor args
    # exactly like the top-level clients do. Smpl Jobs is JSON:API, so the
    # transport carries the +application/vnd.api+json+ Accept header.
    def self.jobs_transport(api_key:, profile:, base_domain:, scheme:, debug:, extra_headers:)
      cfg = ConfigResolution.resolve_management_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme, debug: debug
      )
      merged = {}
      merged.merge!(cfg.extra_headers || {})
      merged.merge!(extra_headers || {})
      tcfg = ConfigResolution::ResolvedManagementConfig.new(
        api_key: cfg.api_key, base_domain: cfg.base_domain, scheme: cfg.scheme,
        debug: cfg.debug, extra_headers: merged
      )
      Transport.build_api_client(SmplkitGeneratedClient::Jobs, "jobs", tcfg, accept: "application/vnd.api+json")
    end

    # The active-record entry point is {#new}: instantiate a draft, mutate
    # fields, then call {Smplkit::Jobs::Job#save}. Run history and the cancel /
    # rerun run actions live on {#runs}.
    #
    # Reachable as +client.jobs+ (+Smplkit::Client+) or constructed directly —
    # +JobsClient.new+ resolves credentials from +~/.smplkit+ / env vars.
    class JobsClient
      # @return [RunsClient] Run history and run actions (+client.jobs.runs+).
      attr_reader :runs

      def initialize(api_key = nil, profile: nil, base_domain: nil, scheme: nil,
                     debug: nil, extra_headers: nil, auth_client: nil)
        auth = auth_client || Jobs.jobs_transport(
          api_key: api_key, profile: profile, base_domain: base_domain,
          scheme: scheme, debug: debug, extra_headers: extra_headers
        )
        @api = SmplkitGeneratedClient::Jobs::JobsApi.new(auth)
        @runs = RunsClient.new(SmplkitGeneratedClient::Jobs::RunsApi.new(auth))
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

      # Construct an unsaved {Smplkit::Jobs::Job} bound to this client. Call
      # +#save+ on the returned instance to create it.
      #
      # @param id [String] Caller-supplied unique identifier for the job. Unique
      #   within the account and immutable; the service returns 409 if another
      #   live job already uses this id.
      # @param name [String] Human-readable name for the job.
      # @param schedule [String] An ISO-8601 datetime, a 5-field UTC cron
      #   expression, or the literal +"now"+.
      # @param configuration [Smplkit::Jobs::HttpConfig] The HTTP request the
      #   job performs.
      # @param description [String, nil] Optional free-text description.
      # @param enabled [Boolean] Whether the job schedules runs. Defaults +true+.
      # @param concurrency_policy [String] How overlapping runs are handled.
      #   Defaults to +"ALLOW"+.
      # @return [Smplkit::Jobs::Job]
      def new(id, name:, schedule:, configuration:, description: nil,
              enabled: true, concurrency_policy: "ALLOW")
        Job.new(
          self,
          id: id,
          name: name,
          schedule: schedule,
          configuration: configuration,
          description: description,
          enabled: enabled,
          concurrency_policy: concurrency_policy
        )
      end

      # List jobs for the authenticated account.
      #
      # @param enabled [Boolean, nil] Filter to jobs matching this enabled state.
      # @param page_number [Integer, nil] 1-based page number to return.
      # @param page_size [Integer, nil] Items per page.
      # @return [Array<Smplkit::Jobs::Job>]
      def list(enabled: nil, page_number: nil, page_size: nil)
        opts = {}
        opts[:filter_enabled] = enabled unless enabled.nil?
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

      # Soft-delete a job.
      #
      # @param id [String]
      # @return [nil]
      def delete(id)
        Jobs.call_api { @api.delete_job(id) }
        nil
      end

      # Trigger one immediate +MANUAL+ run of the job.
      #
      # @param id [String]
      # @return [Smplkit::Jobs::Run]
      def run(id)
        resp = Jobs.call_api { @api.run_job_now(id) }
        Run.from_resource(resp.data)
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
      #   +data.id+ on create and 409s on conflict.
      def _create_job(job)
        raise ArgumentError, "Job.id is required on create (caller-supplied key)" if job.id.nil? || job.id.empty?

        resp = Jobs.call_api { @api.create_job(build_create_body(job)) }
        Job.from_resource(resp.data, client: self)
      end

      # @api private — Full-replace PUT for an existing job. Called by
      #   {Smplkit::Jobs::Job#save} on instances with +created_at+.
      #
      # Header values must be re-supplied as plaintext; the GET path redacts
      # them, so a PUT body containing the redacted placeholder would persist
      # that literal. Track real header values client-side and round-trip them.
      def _update_job(job)
        raise ArgumentError, "cannot update a Job with no id" if job.id.nil?

        resp = Jobs.call_api { @api.update_job(job.id, build_body(job)) }
        Job.from_resource(resp.data, client: self)
      end

      private

      def build_attrs(job)
        SmplkitGeneratedClient::Jobs::Job.new(
          name: job.name,
          description: job.description,
          enabled: job.enabled,
          type: job.type,
          schedule: job.schedule,
          configuration: HttpConfig.to_wire(job.configuration),
          concurrency_policy: job.concurrency_policy
        )
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
