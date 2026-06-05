# frozen_string_literal: true

module Smplkit
  module Management
    # Smpl Jobs management surface — accessed via +mgmt.jobs+.
    #
    # Unlike Config/Flags/Logging, Jobs has no live "phone-home" agent — no
    # environment registration, no WebSocket — so its entire surface lives on
    # the management client. Defining a job, triggering a run, and reading run
    # history are all plain request/response calls here:
    #
    #   mgmt.jobs.{new,get,list,delete,run,usage}
    #   mgmt.jobs.runs.{list,get,cancel,rerun}
    #   Job#{save,delete}
    #
    # The active-record entry point is {#new}: instantiate a draft, mutate
    # fields, then call {Smplkit::Jobs::Job#save}. Run history and the
    # cancel / rerun run actions live on {#runs}.
    class JobsNamespace
      # @return [RunsNamespace] Run history and run actions (+mgmt.jobs.runs+).
      attr_reader :runs

      def initialize(api_client)
        @api = SmplkitGeneratedClient::Jobs::JobsApi.new(api_client)
        @runs = RunsNamespace.new(
          SmplkitGeneratedClient::Jobs::RunsApi.new(api_client)
        )
        @usage_api = SmplkitGeneratedClient::Jobs::UsageApi.new(api_client)
      end

      # Construct an unsaved {Smplkit::Jobs::Job} bound to this namespace. Call
      # +#save+ on the returned instance to create it.
      #
      # @param id [String] Caller-supplied unique identifier for the job.
      #   Unique within the account and immutable; the service returns 409 if
      #   another live job already uses this id.
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
        Smplkit::Jobs::Job.new(
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

        resp = Smplkit::Jobs.call_api { @api.list_jobs(opts) }
        (resp.data || []).map { |r| Smplkit::Jobs::Job.from_resource(r, client: self) }
      end

      # Fetch a single job by id. The returned instance is bound to this
      # namespace, so +job.save+ and +job.delete+ work.
      #
      # @param id [String]
      # @return [Smplkit::Jobs::Job]
      def get(id)
        resp = Smplkit::Jobs.call_api { @api.get_job(id) }
        Smplkit::Jobs::Job.from_resource(resp.data, client: self)
      end

      # Soft-delete a job.
      #
      # @param id [String]
      # @return [nil]
      def delete(id)
        Smplkit::Jobs.call_api { @api.delete_job(id) }
        nil
      end

      # Trigger one immediate +MANUAL+ run of the job.
      #
      # @param id [String]
      # @return [Smplkit::Jobs::Run]
      def run(id)
        resp = Smplkit::Jobs.call_api { @api.run_job_now(id) }
        Smplkit::Jobs::Run.from_resource(resp.data)
      end

      # Current-period usage counters for the account.
      #
      # @return [Smplkit::Jobs::Usage]
      def usage
        resp = Smplkit::Jobs.call_api { @usage_api.get_usage }
        Smplkit::Jobs::Usage.from_resource(resp.data)
      end

      # @api private — POST a new job. Called by {Smplkit::Jobs::Job#save} on
      #   unsaved instances. The jobs service requires a caller-supplied
      #   +data.id+ on create and 409s on conflict.
      def _create_job(job)
        raise ArgumentError, "Job.id is required on create (caller-supplied key)" if job.id.nil? || job.id.empty?

        resp = Smplkit::Jobs.call_api { @api.create_job(build_create_body(job)) }
        Smplkit::Jobs::Job.from_resource(resp.data, client: self)
      end

      # @api private — Full-replace PUT for an existing job. Called by
      #   {Smplkit::Jobs::Job#save} on instances with +created_at+.
      #
      # Header values must be re-supplied as plaintext; the GET path redacts
      # them, so a PUT body containing the redacted placeholder would persist
      # that literal. Track real header values client-side and round-trip them.
      def _update_job(job)
        raise ArgumentError, "cannot update a Job with no id" if job.id.nil?

        resp = Smplkit::Jobs.call_api { @api.update_job(job.id, build_body(job)) }
        Smplkit::Jobs::Job.from_resource(resp.data, client: self)
      end

      private

      def build_attrs(job)
        SmplkitGeneratedClient::Jobs::Job.new(
          name: job.name,
          description: job.description,
          enabled: job.enabled,
          type: job.type,
          schedule: job.schedule,
          configuration: Smplkit::Jobs::HttpConfig.to_wire(job.configuration),
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

    # +mgmt.jobs.runs.*+ — read-only run history plus the cancel / rerun run
    # actions.
    class RunsNamespace
      def initialize(api)
        @api = api
      end

      # List runs for the authenticated account, newest first. Cursor
      # paginated (ADR-014): pass +page_size+ and the +after+ cursor from the
      # prior page. Pass +job+ to scope to a single job's history.
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

        resp = Smplkit::Jobs.call_api { @api.list_runs(opts) }
        (resp.data || []).map { |r| Smplkit::Jobs::Run.from_resource(r) }
      end

      # Fetch a single run by id.
      #
      # @param run_id [String]
      # @return [Smplkit::Jobs::Run]
      def get(run_id)
        resp = Smplkit::Jobs.call_api { @api.get_run(run_id) }
        Smplkit::Jobs::Run.from_resource(resp.data)
      end

      # Cancel a pending run.
      #
      # @param run_id [String]
      # @return [Smplkit::Jobs::Run]
      def cancel(run_id)
        resp = Smplkit::Jobs.call_api { @api.cancel_run(run_id) }
        Smplkit::Jobs::Run.from_resource(resp.data)
      end

      # Re-run a prior run, spawning a new +RERUN+ run.
      #
      # @param run_id [String]
      # @return [Smplkit::Jobs::Run]
      def rerun(run_id)
        resp = Smplkit::Jobs.call_api { @api.rerun_run(run_id) }
        Smplkit::Jobs::Run.from_resource(resp.data)
      end
    end
  end
end
