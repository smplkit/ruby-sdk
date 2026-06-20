# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Jobs::JobsClient do
  subject(:jobs) { described_class.new(auth_client: api_client) }

  let(:api_client) do
    Smplkit::Transport.build_api_client(
      SmplkitGeneratedClient::Jobs, "jobs", resolved,
      accept: "application/vnd.api+json"
    )
  end
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:base_url) { "https://jobs.smplkit.test" }
  let(:job_id) { "nightly-cache-warm" }
  let(:run_id) { "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def env_header(headers)
    pair = headers&.find { |k, _| k.casecmp?("X-Smplkit-Environment") }
    pair&.last
  end

  def env_block(production_enabled: true)
    {
      production: { enabled: production_enabled, next_run_at: "2026-06-06T02:00:00Z" },
      development: {
        enabled: false,
        schedule: "30 2 * * *",
        configuration: {
          method: "POST", url: "https://development.example.com/cache/warm",
          headers: [], body: "{}", success_status: "2xx", timeout: 30,
          tls_verify: true, ca_cert: nil
        },
        next_run_at: nil
      }
    }
  end

  def job_resource(id: "nightly-cache-warm", version: 1, created: true,
                   environments: nil, kind: nil)
    attributes = {
      name: "Nightly cache warm", description: "does a thing",
      kind: kind, type: "http", schedule: "0 2 * * *",
      configuration: {
        method: "POST", url: "https://api.example.com/cache/warm",
        headers: [{ name: "Authorization", value: "<redacted>" }],
        body: "{\"scope\": \"all\"}", success_status: "2xx", timeout: 30,
        tls_verify: true, ca_cert: nil
      },
      concurrency_policy: "ALLOW",
      created_at: created ? "2026-06-04T00:00:00Z" : nil,
      updated_at: created ? "2026-06-04T00:00:00Z" : nil,
      deleted_at: nil, version: version
    }
    attributes[:environments] = environments unless environments.nil?
    { id: id, type: "job", attributes: attributes }
  end

  def run_resource(id: "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d", status: "SUCCEEDED",
                   trigger: "SCHEDULE", rerun_of: nil, environment: "production")
    {
      id: id,
      type: "run",
      attributes: {
        job: "nightly-cache-warm", job_version: 1, environment: environment,
        trigger: trigger, rerun_of: rerun_of,
        scheduled_for: "2026-06-05T00:00:00Z", status: status,
        started_at: "2026-06-05T00:00:00Z", finished_at: "2026-06-05T00:00:01Z",
        pending_duration_ms: 100, run_duration_ms: 300, total_duration_ms: 400,
        failure_reason: nil, error: nil,
        request: { method: "POST", url: "https://api.example.com/cache/warm" },
        result: { status: 200 }, created_at: "2026-06-05T00:00:00Z"
      }
    }
  end

  def usage_resource
    {
      id: "current", type: "usage",
      attributes: {
        period: "2026-06", runs_used: 12, runs_included: 3000,
        active_jobs: 2, active_jobs_limit: 10
      }
    }
  end

  def http_config
    Smplkit::Jobs::HttpConfig.new(
      method: "POST", url: "https://api.example.com/cache/warm",
      headers: [Smplkit::Jobs::HttpHeader.new(name: "Authorization", value: "Bearer s3cr3t")],
      body: "{\"scope\": \"all\"}", timeout: 30
    )
  end

  describe "#new_recurring_job + Job#save" do
    it "POSTs and refreshes the local instance with the server response" do
      stub_request(:post, "#{base_url}/api/v1/jobs").to_return(
        status: 201, body: { data: job_resource }.to_json, headers: json_api
      )
      job = jobs.new_recurring_job(job_id, name: "Nightly cache warm", schedule: "0 2 * * *",
                                           configuration: http_config, description: "does a thing")
      expect(job.created_at).to be_nil
      job.save
      expect(job.id).to eq(job_id)
      expect(job.version).to eq(1)
      expect(job.created_at).not_to be_nil
      expect(job.configuration.headers.first.value).to eq("<redacted>")
    end

    it "sends the create body with the caller-supplied id, body, and timeout" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        captured = req.body
        true
      end.to_return(status: 201, body: { data: job_resource }.to_json, headers: json_api)
      jobs.new_recurring_job(job_id, name: "Nightly cache warm", schedule: "0 2 * * *",
                                     configuration: http_config).save
      expect(captured).to include("\"id\":\"#{job_id}\"")
      expect(captured).to include("\"body\":\"{\\\"scope\\\": \\\"all\\\"}\"")
      expect(captured).to include("\"timeout\":30")
    end

    it "sends the environments map (per-env enabled + config) and never writes base enabled" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: job_resource }.to_json, headers: json_api)
      jobs.new_recurring_job(job_id, name: "n", schedule: "0 * * * *", configuration: http_config,
                                     environments: {
                                       "production" => Smplkit::Jobs::JobEnvironment.new(enabled: true),
                                       "staging" => Smplkit::Jobs::JobEnvironment.new(enabled: true,
                                                                                      configuration: http_config)
                                     }).save
      attrs = captured["data"]["attributes"]
      expect(attrs).not_to have_key("enabled")
      expect(attrs["environments"]["production"]).to eq({ "enabled" => true })
      expect(attrs["environments"]["staging"]["enabled"]).to be(true)
      expect(attrs["environments"]["staging"]["configuration"]["url"]).to eq("https://api.example.com/cache/warm")
    end

    it "sends the base timezone and a per-environment timezone override, omitting it where unset" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: job_resource }.to_json, headers: json_api)
      job = jobs.new_recurring_job(job_id, name: "n", schedule: "0 * * * *", configuration: http_config)
      job.set_timezone("America/New_York") # base timezone
      job.set_enabled(true, environment: "development")
      job.set_timezone("Europe/London", environment: "development") # per-env override
      job.set_enabled(true, environment: "production") # no per-env timezone
      job.save
      attrs = captured["data"]["attributes"]
      expect(attrs["timezone"]).to eq("America/New_York") # base on the wire
      expect(attrs["environments"]["development"]["timezone"]).to eq("Europe/London")
      expect(attrs["environments"]["production"]).not_to have_key("timezone") # omitted when unset
    end

    it "omits the base timezone from the wire when it is unset" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: job_resource }.to_json, headers: json_api)
      jobs.new_recurring_job(job_id, name: "n", schedule: "0 * * * *", configuration: http_config).save
      expect(captured["data"]["attributes"]).not_to have_key("timezone")
    end

    it "sends the base retry_policy and a per-environment retry_policy override, omitting it where unset" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: job_resource }.to_json, headers: json_api)
      job = jobs.new_recurring_job(job_id, name: "n", schedule: "0 * * * *", configuration: http_config,
                                           timezone: "America/New_York", retry_policy: "global-retry")
      job.set_enabled(true, environment: "development")
      job.set_retry_policy("dev-retry", environment: "development") # per-env override
      job.set_enabled(true, environment: "production") # no per-env retry override
      job.save
      attrs = captured["data"]["attributes"]
      expect(attrs["timezone"]).to eq("America/New_York") # threaded through the constructor
      expect(attrs["retry_policy"]).to eq("global-retry") # base on the wire
      expect(attrs["environments"]["development"]["retry_policy"]).to eq("dev-retry")
      expect(attrs["environments"]["production"]).not_to have_key("retry_policy") # omitted when unset
    end

    it "omits the base retry_policy from the wire when it is unset" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: job_resource }.to_json, headers: json_api)
      jobs.new_recurring_job(job_id, name: "n", schedule: "0 * * * *", configuration: http_config).save
      expect(captured["data"]["attributes"]).not_to have_key("retry_policy")
    end

    it "threads retry_policy onto manual and one-off jobs through their constructors" do
      manual = jobs.new_manual_job("manual-job", name: "Manual", configuration: http_config,
                                                 retry_policy: "manual-retry")
      expect(manual.retry_policy).to eq("manual-retry")
      oneoff = jobs.schedule("one-off", name: "One", schedule: Time.utc(2030, 1, 1),
                                        configuration: http_config, retry_policy: "oneoff-retry")
      expect(oneoff.retry_policy).to eq("oneoff-retry")
    end

    it "exposes a retry_policies sub-client" do
      expect(jobs.retry_policies).to be_a(Smplkit::Jobs::RetryPoliciesClient)
    end

    it "schedules a one-off job: ISO-8601 schedule, birth-environment header, no environments map" do
      body = nil
      headers = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        body = JSON.parse(req.body)
        headers = req.headers
        true
      end.to_return(status: 201, body: { data: job_resource }.to_json, headers: json_api)
      when_at = Time.utc(2030, 1, 1, 12, 30)
      jobs.schedule("one-off", name: "One", schedule: when_at, configuration: http_config,
                               environment: "development").save
      expect(body["data"]["attributes"]).not_to have_key("environments")
      expect(body["data"]["attributes"]["schedule"]).to eq(when_at.iso8601) # datetime -> ISO-8601
      expect(env_header(headers)).to eq("development")
    end

    it "creates a manual job with no schedule: sends schedule null and reads back kind manual" do
      body = nil
      stub_request(:post, "#{base_url}/api/v1/jobs").with do |req|
        body = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: job_resource(kind: "manual") }.to_json, headers: json_api)
      job = jobs.new_manual_job("manual-job", name: "Manual", configuration: http_config)
      expect(job.schedule).to be_nil # no schedule supplied
      job.set_enabled(true, environment: "production")
      job.save
      expect(job.is_manual).to be(true)
      expect(job.kind).to eq("manual")
      attrs = body["data"]["attributes"]
      expect(attrs).to have_key("schedule")
      expect(attrs["schedule"]).to be_nil # null sent on the wire
    end

    it "raises ArgumentError when save() is called on a job without an id" do
      job = jobs.new_manual_job("", name: "x", configuration: http_config)
      expect { job.save }.to raise_error(ArgumentError, /id is required/)
    end

    it "raises Smplkit::ConnectionError when the generated layer reports no status code" do
      stub_request(:post, "#{base_url}/api/v1/jobs").to_raise(Errno::ECONNREFUSED)
      job = jobs.new_manual_job(job_id, name: "x", configuration: http_config)
      expect { job.save }.to raise_error(Smplkit::ConnectionError)
    end

    it "raises ConflictError when the id is already taken" do
      stub_request(:post, "#{base_url}/api/v1/jobs").to_return(
        status: 409, body: { errors: [{ status: "409" }] }.to_json, headers: json_api
      )
      job = jobs.new_manual_job(job_id, name: "x", configuration: http_config)
      expect { job.save }.to raise_error(Smplkit::ConflictError)
    end

    it "raises when the Job has no client" do
      detached = Smplkit::Jobs::Job.new(
        id: "x", name: "x", schedule: "now", configuration: http_config
      )
      expect { detached.save }.to raise_error(/cannot save/)
    end
  end

  describe "#list" do
    it "forwards filter[kind], filter[scheduled], filter[name] and offset params to the generated client" do
      captured_uri = nil
      stub_request(:get, %r{#{base_url}/api/v1/jobs\b})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(status: 200,
                   body: { data: [job_resource(id: "a"), job_resource(id: "b")],
                           meta: { pagination: { page: 2, size: 10 } } }.to_json,
                   headers: json_api)
      result = jobs.list(kind: Smplkit::Jobs::JobKind::MANUAL, scheduled: true,
                         name: "health", page_number: 2, page_size: 10)
      expect(captured_uri).not_to include("filter%5Brecurring%5D")
      expect(captured_uri).to include("filter%5Bkind%5D=manual")
      expect(captured_uri).to include("filter%5Bscheduled%5D=true")
      expect(captured_uri).to include("filter%5Bname%5D=health")
      expect(captured_uri).to include("page%5Bnumber%5D=2")
      expect(captured_uri).to include("page%5Bsize%5D=10")
      expect(result.length).to eq(2)
      expect(result.first.id).to eq("a")
    end

    it "returns an empty list when data is empty" do
      stub_request(:get, %r{#{base_url}/api/v1/jobs\b}).to_return(
        status: 200, body: { data: [], meta: { pagination: { page: 1, size: 50 } } }.to_json,
        headers: json_api
      )
      expect(jobs.list).to be_empty
    end
  end

  describe "#get / save (update) / delete" do
    it "returns a Job on get bound to the client" do
      stub_request(:get, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 200, body: { data: job_resource }.to_json, headers: json_api
      )
      job = jobs.get(job_id)
      expect(job.configuration.method).to eq("POST")
      expect(job.configuration.url).to eq("https://api.example.com/cache/warm")
      expect(job.instance_variable_get(:@client)).to be(jobs)
    end

    it "Job#save issues PUT once created_at is present and bumps the version" do
      stub_request(:get, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 200, body: { data: job_resource }.to_json, headers: json_api
      )
      put_stub = stub_request(:put, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 200, body: { data: job_resource(version: 2) }.to_json, headers: json_api
      )
      job = jobs.get(job_id)
      job.name = "Nightly cache warm (v2)"
      job.set_schedule("30 2 * * *")
      job.save
      expect(put_stub).to have_been_requested
      expect(job.version).to eq(2)
    end

    it "_update_job rejects a Job with no id" do
      detached = Smplkit::Jobs::Job.new(
        jobs, id: nil, name: "x", schedule: "now", configuration: http_config
      )
      expect { jobs._update_job(detached) }.to raise_error(ArgumentError, /no id/)
    end

    it "Job#delete issues DELETE" do
      stub_request(:get, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 200, body: { data: job_resource }.to_json, headers: json_api
      )
      del_stub = stub_request(:delete, "#{base_url}/api/v1/jobs/#{job_id}").to_return(status: 204)
      jobs.get(job_id).delete
      expect(del_stub).to have_been_requested
    end

    it "Job#delete raises when constructed without a client" do
      detached = Smplkit::Jobs::Job.new(
        id: job_id, name: "x", schedule: "now", configuration: http_config
      )
      expect { detached.delete }.to raise_error(/cannot delete/)
    end

    it "client #delete returns nil and issues DELETE by id" do
      del_stub = stub_request(:delete, "#{base_url}/api/v1/jobs/#{job_id}").to_return(status: 204)
      expect(jobs.delete(job_id)).to be_nil
      expect(del_stub).to have_been_requested
    end

    it "raises NotFoundError on a 404" do
      stub_request(:get, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 404, body: { errors: [{ status: "404" }] }.to_json, headers: json_api
      )
      expect { jobs.get(job_id) }.to raise_error(Smplkit::NotFoundError)
    end
  end

  describe "environment header on writes" do
    it "sends the client's configured environment on update" do
      client = described_class.new(auth_client: api_client, environment: "production")
      stub_request(:get, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 200, body: { data: job_resource }.to_json, headers: json_api
      )
      captured = nil
      stub_request(:put, "#{base_url}/api/v1/jobs/#{job_id}").with do |req|
        captured = req.headers
        true
      end.to_return(status: 200, body: { data: job_resource(version: 2) }.to_json, headers: json_api)
      job = client.get(job_id)
      job.name = "renamed"
      job.save
      expect(env_header(captured)).to eq("production")
    end

    it "omits the environment header on update when the client has no environment" do
      stub_request(:get, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 200, body: { data: job_resource }.to_json, headers: json_api
      )
      captured = nil
      stub_request(:put, "#{base_url}/api/v1/jobs/#{job_id}").with do |req|
        captured = req.headers
        true
      end.to_return(status: 200, body: { data: job_resource(version: 2) }.to_json, headers: json_api)
      job = jobs.get(job_id)
      job.save
      expect(env_header(captured)).to be_nil
    end
  end

  describe "#run" do
    it "triggers a MANUAL run and returns the Run with its environment" do
      stub_request(:post, "#{base_url}/api/v1/jobs/#{job_id}/actions/run").to_return(
        status: 200, body: { data: run_resource(trigger: "MANUAL") }.to_json, headers: json_api
      )
      run = jobs.run(job_id)
      expect(run.trigger).to eq("MANUAL")
      expect(run.job).to eq("nightly-cache-warm")
      expect(run.environment).to eq("production")
      expect(run.total_duration_ms).to eq(400)
      expect(run.request["url"]).to eq("https://api.example.com/cache/warm")
      expect(run.result["status"]).to eq(200)
    end

    it "sends an explicit environment as the X-Smplkit-Environment header" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs/#{job_id}/actions/run").with do |req|
        captured = req.headers
        true
      end.to_return(status: 200, body: { data: run_resource(trigger: "MANUAL") }.to_json, headers: json_api)
      jobs.run(job_id, environment: "development")
      expect(env_header(captured)).to eq("development")
    end

    it "falls back to the client's configured environment, else omits the header" do
      with_default = described_class.new(auth_client: api_client, environment: "production")
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs/#{job_id}/actions/run").with do |req|
        captured = req.headers
        true
      end.to_return(status: 200, body: { data: run_resource(trigger: "MANUAL") }.to_json, headers: json_api)
      with_default.run(job_id)
      expect(env_header(captured)).to eq("production")
      jobs.run(job_id)
      expect(env_header(captured)).to be_nil
    end
  end

  describe "#usage" do
    it "returns the current-period usage counters" do
      stub_request(:get, "#{base_url}/api/v1/usage").to_return(
        status: 200, body: { data: usage_resource }.to_json, headers: json_api
      )
      usage = jobs.usage
      expect(usage.period).to eq("2026-06")
      expect(usage.runs_used).to eq(12)
      expect(usage.runs_included).to eq(3000)
      expect(usage.active_jobs).to eq(2)
      expect(usage.active_jobs_limit).to eq(10)
    end
  end

  describe "active-record Job#trigger / #list_runs" do
    let(:bound_job) do
      stub_request(:get, "#{base_url}/api/v1/jobs/#{job_id}").to_return(
        status: 200, body: { data: job_resource }.to_json, headers: json_api
      )
      jobs.get(job_id)
    end

    it "trigger sends the environment header and returns a re-runnable Run" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/jobs/#{job_id}/actions/run").with do |req|
        captured = req.headers
        true
      end.to_return(status: 200, body: { data: run_resource(trigger: "MANUAL") }.to_json, headers: json_api)
      rerun_stub = stub_request(:post, "#{base_url}/api/v1/runs/#{run_id}/actions/rerun").to_return(
        status: 200, body: { data: run_resource(trigger: "RERUN", rerun_of: run_id) }.to_json, headers: json_api
      )
      run = bound_job.trigger(environment: "production")
      expect(run.trigger).to eq("MANUAL")
      expect(env_header(captured)).to eq("production")
      expect(run.rerun.trigger).to eq("RERUN")
      expect(rerun_stub).to have_been_requested
    end

    it "list_runs scopes filter[environment] to the single environment, else omits it" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api)
      runs = bound_job.list_runs(environment: "production")
      expect(runs.length).to eq(1)
      expect(captured["filter[environment]"]).to eq("production")
      expect(captured["filter[job]"]).to eq(job_id)
      bound_job.list_runs
      expect(captured.key?("filter[environment]")).to be(false)
    end

    it "list_runs forwards triggers and last_run_only to the runs client" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api)
      bound_job.list_runs(environment: "production",
                          triggers: [Smplkit::Jobs::RunTrigger::RETRY], last_run_only: true)
      expect(captured["filter[trigger]"]).to eq("RETRY")
      expect(captured["last_run_only"]).to eq("true")
      expect(captured["filter[environment]"]).to eq("production")
      expect(captured["filter[job]"]).to eq(job_id)
    end

    it "raises when the Job has no client" do
      detached = Smplkit::Jobs::Job.new(id: "x", name: "x", schedule: "now", configuration: http_config)
      expect { detached.trigger }.to raise_error(/cannot trigger/)
      expect { detached.list_runs }.to raise_error(/cannot list runs/)
    end
  end

  describe "standalone construction" do
    it "resolves its own transport when no auth_client is given" do
      client = described_class.new("k", base_domain: "smplkit.test", scheme: "https")
      expect(client).to be_a(described_class)
      expect(client.close).to be_nil
    end

    it "open yields the client and closes it" do
      yielded = nil
      described_class.open(auth_client: api_client) { |j| yielded = j }
      expect(yielded).to be_a(described_class)
    end
  end
end

RSpec.describe Smplkit::Jobs::RunsClient do
  subject(:runs) { Smplkit::Jobs::JobsClient.new(auth_client: api_client).runs }

  let(:api_client) do
    Smplkit::Transport.build_api_client(
      SmplkitGeneratedClient::Jobs, "jobs", resolved,
      accept: "application/vnd.api+json"
    )
  end
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:base_url) { "https://jobs.smplkit.test" }
  let(:run_id) { "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def run_resource(id: "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d", status: "SUCCEEDED",
                   trigger: "SCHEDULE", rerun_of: nil, environment: "production", sparse: false)
    {
      id: id, type: "run",
      attributes: {
        job: "nightly-cache-warm", job_version: 1, environment: environment,
        trigger: trigger, rerun_of: rerun_of,
        scheduled_for: "2026-06-05T00:00:00Z", status: status,
        started_at: nil, finished_at: nil, pending_duration_ms: nil, run_duration_ms: nil,
        total_duration_ms: nil, failure_reason: nil, error: nil,
        request: sparse ? nil : { method: "POST" }, result: sparse ? nil : { status: 200 },
        created_at: "2026-06-05T00:00:00Z"
      }
    }
  end

  describe "#list" do
    it "scopes by job and forwards cursor params" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b})
        .with do |req|
          captured = req.uri.query_values
          true
        end
        .to_return(status: 200,
                   body: { data: [run_resource], meta: { page_size: 2 } }.to_json,
                   headers: json_api)
      result = runs.list(job: "nightly-cache-warm", page_size: 2, after: "cur")
      expect(captured["filter[job]"]).to eq("nightly-cache-warm")
      expect(captured["page[size]"]).to eq("2")
      expect(captured["page[after]"]).to eq("cur")
      expect(captured.key?("filter[environment]")).to be(false)
      expect(result.length).to eq(1)
      expect(result.first.id).to eq(run_id)
      expect(result.first.environment).to eq("production")
    end

    it "joins an explicit environments list into filter[environment]" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api)
      runs.list(environments: %w[production development])
      expect(captured["filter[environment]"]).to eq("production,development")
    end

    it "falls back to the client's configured environment when no list is given" do
      scoped = Smplkit::Jobs::JobsClient.new(auth_client: api_client, environment: "production").runs
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api)
      scoped.list
      expect(captured["filter[environment]"]).to eq("production")
    end

    it "returns an empty list when data is empty" do
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).to_return(
        status: 200, body: { data: [], meta: { page_size: 50 } }.to_json, headers: json_api
      )
      expect(runs.list).to be_empty
    end

    it "leaves request and result nil when the run carries neither" do
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).to_return(
        status: 200, body: { data: [run_resource(sparse: true)], meta: { page_size: 50 } }.to_json,
        headers: json_api
      )
      run = runs.list.first
      expect(run.request).to be_nil
      expect(run.result).to be_nil
    end

    it "sends filter[trigger] (comma-joined any-of) and last_run_only when requested" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api)
      runs.list(triggers: [Smplkit::Jobs::RunTrigger::SCHEDULE, Smplkit::Jobs::RunTrigger::RETRY],
                last_run_only: true)
      expect(captured["filter[trigger]"]).to eq("SCHEDULE,RETRY")
      expect(captured["last_run_only"]).to eq("true")
    end

    it "omits filter[trigger] and last_run_only on a default call" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api)
      runs.list(page_size: 1) # one param so query_values is present
      expect(captured.key?("filter[trigger]")).to be(false)
      expect(captured.key?("last_run_only")).to be(false)
    end

    it "omits filter[trigger] when triggers is an empty list" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api)
      runs.list(triggers: [], page_size: 1)
      expect(captured.key?("filter[trigger]")).to be(false)
    end
  end

  describe "retry-chain parsing" do
    def retry_run_body(trigger:, retry_attr:)
      {
        id: run_id, type: "run",
        attributes: {
          job: "nightly-cache-warm", job_version: 1, environment: "production",
          trigger: trigger, rerun_of: nil, retry: retry_attr,
          scheduled_for: nil, status: "FAILED", started_at: nil, finished_at: nil,
          pending_duration_ms: nil, run_duration_ms: nil, total_duration_ms: nil,
          failure_reason: "NON_SUCCESS_STATUS", error: nil, request: nil, result: nil,
          created_at: "2026-06-05T00:00:00Z"
        }
      }
    end

    it "parses retry into a RunRetry on a RETRY run" do
      stub_request(:get, "#{base_url}/api/v1/runs/#{run_id}").to_return(
        status: 200,
        body: { data: retry_run_body(trigger: "RETRY", retry_attr: { of: "orig-run", attempt: 2 }) }.to_json,
        headers: json_api
      )
      run = runs.get(run_id)
      expect(run.retry).to be_a(Smplkit::Jobs::RunRetry)
      expect(run.retry.of).to eq("orig-run")
      expect(run.retry.attempt).to eq(2)
    end

    it "leaves retry nil on a non-RETRY run even when a retry block is present" do
      stub_request(:get, "#{base_url}/api/v1/runs/#{run_id}").to_return(
        status: 200,
        body: { data: retry_run_body(trigger: "SCHEDULE", retry_attr: { of: "orig", attempt: 1 }) }.to_json,
        headers: json_api
      )
      expect(runs.get(run_id).retry).to be_nil
    end

    it "leaves retry nil on a RETRY run that carries no retry block" do
      stub_request(:get, "#{base_url}/api/v1/runs/#{run_id}").to_return(
        status: 200, body: { data: retry_run_body(trigger: "RETRY", retry_attr: nil) }.to_json,
        headers: json_api
      )
      expect(runs.get(run_id).retry).to be_nil
    end
  end

  describe "#get" do
    it "fetches a single run by id" do
      stub_request(:get, "#{base_url}/api/v1/runs/#{run_id}").to_return(
        status: 200, body: { data: run_resource }.to_json, headers: json_api
      )
      expect(runs.get(run_id).status).to eq("SUCCEEDED")
    end
  end

  describe "#cancel" do
    it "cancels a pending run" do
      stub_request(:post, "#{base_url}/api/v1/runs/#{run_id}/actions/cancel").to_return(
        status: 200, body: { data: run_resource(status: "CANCELED") }.to_json, headers: json_api
      )
      expect(runs.cancel(run_id).status).to eq("CANCELED")
    end
  end

  describe "#rerun" do
    it "spawns a RERUN run linked to the source run" do
      stub_request(:post, "#{base_url}/api/v1/runs/#{run_id}/actions/rerun").to_return(
        status: 200, body: { data: run_resource(trigger: "RERUN", rerun_of: run_id) }.to_json,
        headers: json_api
      )
      rerun = runs.rerun(run_id)
      expect(rerun.trigger).to eq("RERUN")
      expect(rerun.rerun_of).to eq(run_id)
    end
  end

  describe "Run active-record actions" do
    it "rerun and cancel act through the bound runs client" do
      stub_request(:get, "#{base_url}/api/v1/runs/#{run_id}").to_return(
        status: 200, body: { data: run_resource }.to_json, headers: json_api
      )
      stub_request(:post, "#{base_url}/api/v1/runs/#{run_id}/actions/rerun").to_return(
        status: 200, body: { data: run_resource(trigger: "RERUN", rerun_of: run_id) }.to_json, headers: json_api
      )
      stub_request(:post, "#{base_url}/api/v1/runs/#{run_id}/actions/cancel").to_return(
        status: 200, body: { data: run_resource(status: "CANCELED") }.to_json, headers: json_api
      )
      run = runs.get(run_id)
      expect(run.rerun.trigger).to eq("RERUN")
      expect(run.cancel.status).to eq("CANCELED")
    end

    it "raises when the Run has no bound runs client" do
      detached = Smplkit::Jobs::Run.from_resource(run_resource_struct)
      expect { detached.rerun }.to raise_error(/cannot rerun/)
      expect { detached.cancel }.to raise_error(/cannot cancel/)
    end

    # A generated RunResource carrying the minimal attributes, used to build a
    # Run with no runs backref.
    def run_resource_struct
      SmplkitGeneratedClient::Jobs::RunResource.new(
        id: run_id, type: "run",
        attributes: SmplkitGeneratedClient::Jobs::Run.new(
          job: "nightly-cache-warm", environment: "production", trigger: "MANUAL", status: "SUCCEEDED"
        )
      )
    end
  end
end

RSpec.describe Smplkit::Jobs::Job do
  let(:base) { Smplkit::Jobs::HttpConfig.new(url: "https://base.example.com") }
  let(:job) { described_class.new(id: "x", name: "X", schedule: "0 * * * *", configuration: base) }

  describe "#is_recurring / #is_manual / #is_one_off" do
    def job_of_kind(kind)
      described_class.new(id: "j", name: "n", configuration: base, kind: kind)
    end

    it "each predicate is true only for its own kind" do
      rec = job_of_kind(Smplkit::Jobs::JobKind::RECURRING)
      expect([rec.is_recurring, rec.is_manual, rec.is_one_off]).to eq([true, false, false])
      man = job_of_kind(Smplkit::Jobs::JobKind::MANUAL)
      expect([man.is_recurring, man.is_manual, man.is_one_off]).to eq([false, true, false])
      off = job_of_kind(Smplkit::Jobs::JobKind::ONE_OFF)
      expect([off.is_recurring, off.is_manual, off.is_one_off]).to eq([false, false, true])
    end

    it "leaves every predicate false when kind is nil" do
      nokind = described_class.new(id: "j", name: "n", configuration: base)
      expect(nokind.kind).to be_nil
      expect(nokind.is_recurring || nokind.is_manual || nokind.is_one_off).to be(false)
    end
  end

  describe "#set_enabled / #is_enabled" do
    it "creates and updates a per-environment override and reads it back" do
      expect(job.is_enabled).to be(false) # roll-up default (no envs)
      job.set_enabled(true, environment: "production")
      expect(job.environments["production"].enabled).to be(true)
      job.set_enabled(false, environment: "production") # existing-entry branch
      expect(job.is_enabled(environment: "production")).to be(false)
      expect(job.is_enabled(environment: "staging")).to be(false) # env absent from map
    end

    it "is_enabled / enabled with no argument derive the roll-up from environments" do
      expect(job.enabled).to be(false) # no environments enabled
      expect(job.is_enabled).to be(false)
      job.set_enabled(true, environment: "production")
      expect(job.enabled).to be(true) # at least one environment enabled
      expect(job.is_enabled).to be(true)
    end
  end

  describe "#set_configuration / #get_configuration" do
    it "sets and resolves base and per-environment configuration" do
      expect(job.get_configuration).to be(base) # base
      expect(job.get_configuration(environment: "production")).to be(base) # no override -> base
      override = Smplkit::Jobs::HttpConfig.new(url: "https://prod.example.com")
      job.set_configuration(override, environment: "production")
      expect(job.get_configuration(environment: "production")).to be(override) # override wins
      job.set_enabled(true, environment: "staging") # entry with no configuration
      expect(job.get_configuration(environment: "staging")).to be(base) # falls back to base
    end

    it "set_configuration with no environment replaces the base configuration" do
      new_cfg = Smplkit::Jobs::HttpConfig.new(url: "https://new.example.com")
      job.set_configuration(new_cfg)
      expect(job.configuration).to be(new_cfg)
    end
  end

  describe "#set_schedule" do
    it "replaces the base schedule when no environment is given" do
      job.set_schedule("30 2 * * *")
      expect(job.schedule).to eq("30 2 * * *")
    end

    it "sets a per-environment schedule override, creating the entry and preserving enabled" do
      job.set_enabled(true, environment: "production")
      job.set_schedule("0 3 * * *", environment: "production") # existing-entry branch
      job.set_schedule("0 4 * * *", environment: "staging") # new-entry branch
      expect(job.schedule).to eq("0 * * * *") # base untouched
      expect(job.environments["production"].schedule).to eq("0 3 * * *")
      expect(job.environments["production"].enabled).to be(true) # preserved
      expect(job.environments["staging"].schedule).to eq("0 4 * * *")
      expect(job.environments["staging"].enabled).to be(false) # default on new entry
    end

    it "also sets the timezone on the same scope when a timezone is given" do
      job.set_schedule("0 6 * * *", timezone: "America/New_York") # base
      expect(job.schedule).to eq("0 6 * * *")
      expect(job.timezone).to eq("America/New_York")
      job.set_schedule("0 7 * * *", timezone: "Europe/London", environment: "production") # per-env
      expect(job.environments["production"].schedule).to eq("0 7 * * *")
      expect(job.environments["production"].timezone).to eq("Europe/London")
    end

    it "leaves the timezone untouched when no timezone is given" do
      job.set_timezone("UTC")
      job.set_schedule("0 8 * * *") # no timezone arg
      expect(job.timezone).to eq("UTC")
    end
  end

  describe "#set_retry_policy" do
    it "accepts a policy id string — base and per-environment, preserving other env fields" do
      job.set_retry_policy("global-retry") # base
      expect(job.retry_policy).to eq("global-retry")
      job.set_enabled(true, environment: "production")
      job.set_retry_policy("prod-retry", environment: "production") # existing-entry branch
      job.set_retry_policy("stg-retry", environment: "staging") # new-entry branch
      expect(job.retry_policy).to eq("global-retry") # base untouched
      expect(job.environments["production"].retry_policy).to eq("prod-retry")
      expect(job.environments["production"].enabled).to be(true) # preserved
      expect(job.environments["staging"].retry_policy).to eq("stg-retry")
      expect(job.environments["staging"].enabled).to be(false) # default on new entry
    end

    it "accepts a RetryPolicy instance, using its id — base and per-environment" do
      policy = Smplkit::Jobs::RetryPolicy.new(
        id: "obj-retry", name: "P", max_retries: 1,
        backoff: Smplkit::Jobs::Backoff::FIXED, delay_seconds: 1
      )
      job.set_retry_policy(policy) # object, base
      expect(job.retry_policy).to eq("obj-retry")
      job.set_retry_policy(policy, environment: "production") # object, per-env
      expect(job.environments["production"].retry_policy).to eq("obj-retry")
    end
  end

  describe "#set_timezone" do
    it "replaces the base timezone when no environment is given" do
      job.set_timezone("America/New_York")
      expect(job.timezone).to eq("America/New_York")
    end

    it "sets a per-environment timezone override, preserving the per-env schedule and leaving the base untouched" do
      job.set_schedule("0 4 * * *", environment: "production")
      job.set_timezone("Europe/London", environment: "production") # existing-entry branch
      job.set_timezone("Asia/Tokyo", environment: "staging") # new-entry branch
      expect(job.timezone).to be_nil # base untouched
      expect(job.environments["production"].timezone).to eq("Europe/London")
      expect(job.environments["production"].schedule).to eq("0 4 * * *") # preserved
      expect(job.environments["staging"].timezone).to eq("Asia/Tokyo")
      expect(job.environments["staging"].enabled).to be(false) # default on new entry
    end
  end

  describe ".from_resource" do
    it "derives a false enabled roll-up and defaults type / concurrency_policy when the wire omits them" do
      resource = SmplkitGeneratedClient::Jobs::JobResource.new(
        id: "j", type: "job",
        attributes: SmplkitGeneratedClient::Jobs::Job.new(
          name: "n", schedule: "now",
          configuration: SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(url: "https://x"),
          type: nil, concurrency_policy: nil
        )
      )
      parsed = described_class.from_resource(resource)
      expect(parsed.enabled).to be(false) # no environments -> derived roll-up false
      expect(parsed.environments).to eq({})
      expect(parsed.type).to eq("http")
      expect(parsed.concurrency_policy).to eq("ALLOW")
    end

    it "decodes the base timezone and per-environment timezone overrides from the wire" do
      resource = SmplkitGeneratedClient::Jobs::JobResource.new(
        id: "j", type: "job",
        attributes: SmplkitGeneratedClient::Jobs::Job.new(
          name: "n", schedule: "0 * * * *", kind: "recurring",
          timezone: "America/New_York",
          configuration: SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(url: "https://x"),
          environments: {
            "development" => SmplkitGeneratedClient::Jobs::JobEnvironment.new(
              enabled: true, schedule: "0 3 * * *", timezone: "Europe/London"
            )
          }
        )
      )
      parsed = described_class.from_resource(resource)
      expect(parsed.timezone).to eq("America/New_York") # base decodes
      expect(parsed.environments["development"].timezone).to eq("Europe/London") # per-env decodes
    end

    it "decodes the base retry_policy and per-environment retry_policy overrides from the wire" do
      resource = SmplkitGeneratedClient::Jobs::JobResource.new(
        id: "j", type: "job",
        attributes: SmplkitGeneratedClient::Jobs::Job.new(
          name: "n", schedule: "0 * * * *", kind: "recurring",
          retry_policy: "global-retry",
          configuration: SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(url: "https://x"),
          environments: {
            "development" => SmplkitGeneratedClient::Jobs::JobEnvironment.new(
              enabled: true, retry_policy: "dev-retry"
            )
          }
        )
      )
      parsed = described_class.from_resource(resource)
      expect(parsed.retry_policy).to eq("global-retry") # base decodes
      expect(parsed.environments["development"].retry_policy).to eq("dev-retry") # per-env decodes
    end

    it "exposes save! and delete! aliases" do
      expect(described_class.instance_method(:save!)).to eq(described_class.instance_method(:save))
      expect(described_class.instance_method(:delete!)).to eq(described_class.instance_method(:delete))
    end
  end
end

RSpec.describe Smplkit::Jobs::JobEnvironment do
  describe ".from_wire" do
    it "returns a disabled, override-free environment for nil" do
      env = described_class.from_wire(nil)
      expect(env.enabled).to be(false)
      expect(env.schedule).to be_nil
      expect(env.timezone).to be_nil
      expect(env.configuration).to be_nil
      expect(env.next_run_at).to be_nil
    end

    it "coerces a nil enabled to false and leaves schedule / timezone / configuration nil when absent" do
      wire = SmplkitGeneratedClient::Jobs::JobEnvironment.new(enabled: nil)
      env = described_class.from_wire(wire)
      expect(env.enabled).to be(false)
      expect(env.schedule).to be_nil
      expect(env.timezone).to be_nil
      expect(env.configuration).to be_nil
      expect(env.next_run_at).to be_nil
    end

    it "parses the schedule, timezone, retry_policy, configuration overrides, and read-only next_run_at" do
      wire = SmplkitGeneratedClient::Jobs::JobEnvironment.new(
        enabled: true,
        schedule: "0 3 * * *",
        timezone: "Europe/London",
        retry_policy: "env-retry",
        configuration: SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(url: "https://e.com"),
        next_run_at: "2026-06-06T03:00:00Z"
      )
      env = described_class.from_wire(wire)
      expect(env.enabled).to be(true)
      expect(env.schedule).to eq("0 3 * * *")
      expect(env.timezone).to eq("Europe/London")
      expect(env.retry_policy).to eq("env-retry")
      expect(env.configuration).to be_a(Smplkit::Jobs::HttpConfig)
      expect(env.configuration.url).to eq("https://e.com")
      expect(env.next_run_at).to eq("2026-06-06T03:00:00Z")
    end
  end
end

RSpec.describe "Smplkit::Jobs environment helpers" do
  let(:cfg) { Smplkit::Jobs::HttpConfig.new(url: "https://api.example.com") }

  describe ".join_environments" do
    it "returns nil for nil, an empty array, and an all-blank array" do
      expect(Smplkit::Jobs.join_environments(nil)).to be_nil
      expect(Smplkit::Jobs.join_environments([])).to be_nil
      expect(Smplkit::Jobs.join_environments([" ", ""])).to be_nil
    end

    it "comma-joins a non-empty list" do
      expect(Smplkit::Jobs.join_environments(%w[production staging])).to eq("production,staging")
    end
  end

  describe ".resolve_environment_filter" do
    it "prefers an explicit list, then the client default, then nil" do
      expect(Smplkit::Jobs.resolve_environment_filter(%w[a b], "production")).to eq("a,b")
      expect(Smplkit::Jobs.resolve_environment_filter(nil, "production")).to eq("production")
      expect(Smplkit::Jobs.resolve_environment_filter(nil, nil)).to be_nil
    end
  end

  describe ".normalize_environments" do
    it "returns an empty hash for nil and empty input" do
      expect(Smplkit::Jobs.normalize_environments(nil)).to eq({})
      expect(Smplkit::Jobs.normalize_environments({})).to eq({})
    end

    it "passes JobEnvironment instances through and coerces hash forms" do
      out = Smplkit::Jobs.normalize_environments(
        "production" => Smplkit::Jobs::JobEnvironment.new(enabled: true, schedule: "0 1 * * *"),
        "staging" => { enabled: true, schedule: "0 2 * * *", retry_policy: "stg-retry", configuration: cfg },
        "dev" => { enabled: false, configuration: { url: "https://dev.example.com" } },
        "qa" => { "enabled" => true, "schedule" => "0 3 * * *", "retry_policy" => "qa-retry" }
      )
      expect(out["production"].enabled).to be(true)
      expect(out["production"].schedule).to eq("0 1 * * *")
      expect(out["staging"].schedule).to eq("0 2 * * *")
      expect(out["staging"].retry_policy).to eq("stg-retry") # symbol-key form
      expect(out["staging"].configuration).to be(cfg)
      expect(out["dev"].configuration).to be_a(Smplkit::Jobs::HttpConfig)
      expect(out["dev"].configuration.url).to eq("https://dev.example.com")
      expect(out["dev"].schedule).to be_nil # absent -> nil
      expect(out["dev"].retry_policy).to be_nil # absent -> nil
      expect(out["qa"].enabled).to be(true)
      expect(out["qa"].schedule).to eq("0 3 * * *") # string-key form
      expect(out["qa"].retry_policy).to eq("qa-retry") # string-key form
      expect(out["qa"].configuration).to be_nil
    end
  end
end

RSpec.describe Smplkit::Jobs::JobKind do
  it "carries the wire values for each kind in VALUES" do
    expect(described_class::RECURRING).to eq("recurring")
    expect(described_class::MANUAL).to eq("manual")
    expect(described_class::ONE_OFF).to eq("one_off")
    expect(described_class::VALUES).to eq(%w[manual one_off recurring])
  end
end

RSpec.describe Smplkit::Jobs::RunTrigger do
  it "carries the wire values for each trigger in VALUES" do
    expect(described_class::MANUAL).to eq("MANUAL")
    expect(described_class::RERUN).to eq("RERUN")
    expect(described_class::RETRY).to eq("RETRY")
    expect(described_class::SCHEDULE).to eq("SCHEDULE")
    expect(described_class::VALUES).to eq(%w[MANUAL RERUN RETRY SCHEDULE])
  end
end

RSpec.describe Smplkit::Jobs::Backoff do
  it "carries the wire values for each strategy in VALUES" do
    expect(described_class::EXPONENTIAL).to eq("exponential")
    expect(described_class::FIXED).to eq("fixed")
    expect(described_class::VALUES).to eq(%w[exponential fixed])
  end
end

RSpec.describe Smplkit::Jobs::RetryReason do
  it "carries the wire values for each reason in VALUES" do
    expect(described_class::CONNECTION_ERROR).to eq("CONNECTION_ERROR")
    expect(described_class::NON_SUCCESS_STATUS).to eq("NON_SUCCESS_STATUS")
    expect(described_class::TIMEOUT).to eq("TIMEOUT")
    expect(described_class::VALUES).to eq(%w[CONNECTION_ERROR NON_SUCCESS_STATUS TIMEOUT])
  end
end

RSpec.describe Smplkit::Jobs::RetryOn do
  it "defaults both lists to empty (retries nothing)" do
    on = described_class.new
    expect(on.statuses).to eq([])
    expect(on.reasons).to eq([])
  end

  describe ".to_wire" do
    it "serializes statuses and reasons (reasons as their string values)" do
      on = described_class.new(statuses: [429, 503], reasons: [Smplkit::Jobs::RetryReason::TIMEOUT])
      wire = described_class.to_wire(on)
      expect(wire.statuses).to eq([429, 503])
      expect(wire.reasons).to eq(["TIMEOUT"])
    end

    it "serializes an empty RetryOn to empty lists" do
      wire = described_class.to_wire(described_class.new)
      expect(wire.statuses).to eq([])
      expect(wire.reasons).to eq([])
    end
  end

  describe ".from_wire" do
    it "returns an empty RetryOn for nil" do
      on = described_class.from_wire(nil)
      expect(on.statuses).to eq([])
      expect(on.reasons).to eq([])
    end

    it "round-trips a populated wire model" do
      wire = described_class.to_wire(
        described_class.new(statuses: [500], reasons: [Smplkit::Jobs::RetryReason::CONNECTION_ERROR])
      )
      back = described_class.from_wire(wire)
      expect(back.statuses).to eq([500])
      expect(back.reasons).to eq(["CONNECTION_ERROR"])
    end

    it "coerces nil wire lists to empty arrays" do
      wire = SmplkitGeneratedClient::Jobs::RetryOn.new
      back = described_class.from_wire(wire)
      expect(back.statuses).to eq([])
      expect(back.reasons).to eq([])
    end
  end
end

RSpec.describe Smplkit::Jobs::HttpMethod do
  it "lists every verb in VALUES in alphabetical order" do
    expect(described_class::VALUES).to eq(%w[DELETE GET PATCH POST PUT])
  end

  describe ".coerce" do
    it "passes through valid verb strings" do
      expect(described_class.coerce("POST")).to eq("POST")
      expect(described_class.coerce(described_class::PUT)).to eq("PUT")
    end

    it "preserves nil" do
      expect(described_class.coerce(nil)).to be_nil
    end

    it "raises on an unknown verb" do
      expect { described_class.coerce("HEAD") }.to raise_error(ArgumentError, /Unknown HttpMethod/)
    end
  end
end

RSpec.describe Smplkit::Jobs::HttpConfig do
  it "rejects an invalid method at construction" do
    expect { described_class.new(method: "HEAD", url: "https://x") }
      .to raise_error(ArgumentError, /Unknown HttpMethod/)
  end

  it "defaults method, success_status, timeout, tls_verify, and body" do
    cfg = described_class.new(url: "https://x")
    expect(cfg.method).to eq("POST")
    expect(cfg.success_status).to eq("2xx")
    expect(cfg.timeout).to eq(30)
    expect(cfg.tls_verify).to be(true)
    expect(cfg.ca_cert).to be_nil
    expect(cfg.body).to be_nil
    expect(cfg.headers).to be_empty
  end

  describe ".to_wire" do
    it "maps Struct headers, body, and timeout onto the generated config" do
      cfg = described_class.new(
        url: "https://x", body: "{}", timeout: 45,
        headers: [Smplkit::Jobs::HttpHeader.new(name: "A", value: "1")]
      )
      wire = described_class.to_wire(cfg)
      expect(wire.url).to eq("https://x")
      expect(wire.body).to eq("{}")
      expect(wire.timeout).to eq(45)
      expect(wire.headers.first.name).to eq("A")
    end

    it "accepts a Hash and Hash-shaped headers" do
      wire = described_class.to_wire(
        url: "https://x", headers: [{ name: "h", value: "v" }]
      )
      expect(wire.url).to eq("https://x")
      expect(wire.headers.first.value).to eq("v")
    end
  end

  describe ".from_wire" do
    it "returns a default object for nil" do
      out = described_class.from_wire(nil)
      expect(out.method).to eq("POST")
      expect(out.timeout).to eq(30)
      expect(out.headers).to be_empty
    end

    it "round-trips a populated generated config" do
      wire = described_class.to_wire(
        described_class.new(url: "https://x", body: "{}", timeout: 60,
                            headers: [Smplkit::Jobs::HttpHeader.new(name: "A", value: "1")])
      )
      back = described_class.from_wire(wire)
      expect(back.url).to eq("https://x")
      expect(back.body).to eq("{}")
      expect(back.timeout).to eq(60)
      expect(back.headers.first.name).to eq("A")
    end

    it "defaults nullable method, headers, and tls_verify when the wire omits them" do
      # The generated config requires non-nil url / success_status / timeout,
      # so only the nullable fields are nilled here — the wrapper backfills
      # their defaults.
      wire = SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(
        method: nil, url: "https://x", headers: nil, body: nil,
        success_status: "2xx", timeout: 30, tls_verify: nil, ca_cert: nil
      )
      out = described_class.from_wire(wire)
      expect(out.method).to eq("POST")
      expect(out.url).to eq("https://x")
      expect(out.headers).to be_empty
      expect(out.success_status).to eq("2xx")
      expect(out.timeout).to eq(30)
      expect(out.tls_verify).to be(true)
    end

    it "preserves an explicit tls_verify false" do
      wire = SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(
        method: "POST", url: "https://x", headers: [], body: nil,
        success_status: "2xx", timeout: 30, tls_verify: false, ca_cert: nil
      )
      expect(described_class.from_wire(wire).tls_verify).to be(false)
    end
  end
end

RSpec.describe "Smplkit::Jobs::Job environments parsing" do
  subject(:jobs) { Smplkit::Jobs::JobsClient.new(auth_client: api_client) }

  let(:api_client) do
    Smplkit::Transport.build_api_client(
      SmplkitGeneratedClient::Jobs, "jobs", resolved, accept: "application/vnd.api+json"
    )
  end
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:base_url) { "https://jobs.smplkit.test" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def job_with_environments
    {
      id: "j", type: "job",
      attributes: {
        name: "n", description: nil, kind: "recurring", type: "http",
        schedule: "0 * * * *",
        configuration: { method: "POST", url: "https://api.example.com/hook", headers: [],
                         body: nil, success_status: "2xx", timeout: 30, tls_verify: true, ca_cert: nil },
        environments: {
          production: { enabled: true, schedule: "0 3 * * *", next_run_at: "2026-06-06T03:00:00Z" },
          staging: {
            enabled: false,
            configuration: { method: "POST", url: "https://staging.example.com/hook", headers: [],
                             body: nil, success_status: "2xx", timeout: 30, tls_verify: true, ca_cert: nil },
            next_run_at: nil
          }
        },
        concurrency_policy: "ALLOW", created_at: "2026-06-04T00:00:00Z",
        updated_at: "2026-06-04T00:00:00Z", deleted_at: nil, version: 1
      }
    }
  end

  it "parses the environments map, kind, derived roll-up, and per-env schedule / next_run_at on read" do
    stub_request(:get, "#{base_url}/api/v1/jobs/j").to_return(
      status: 200, body: { data: job_with_environments }.to_json, headers: json_api
    )
    job = jobs.get("j")
    expect(job.enabled).to be(true) # derived roll-up (production enabled)
    expect(job.kind).to eq("recurring")
    expect(job.is_recurring).to be(true)
    expect(job.is_enabled(environment: "production")).to be(true)
    expect(job.environments["production"].configuration).to be_nil # inherits base
    expect(job.environments["production"].schedule).to eq("0 3 * * *") # per-env override
    # next_run_at is typed Time on the generated model, so it round-trips as a
    # parsed Time; the wrapper passes it through unchanged.
    expect(job.environments["production"].next_run_at).to eq(Time.utc(2026, 6, 6, 3, 0, 0)) # read-only
    expect(job.is_enabled(environment: "staging")).to be(false)
    expect(job.environments["staging"].schedule).to be_nil # inherits base schedule
    expect(job.environments["staging"].next_run_at).to be_nil
    expect(job.get_configuration(environment: "staging").url).to eq("https://staging.example.com/hook")
  end

  it "sends a per-environment schedule override and never sends next_run_at on save" do
    stub_request(:get, "#{base_url}/api/v1/jobs/j").to_return(
      status: 200, body: { data: job_with_environments }.to_json, headers: json_api
    )
    captured = nil
    stub_request(:put, "#{base_url}/api/v1/jobs/j").with do |req|
      captured = JSON.parse(req.body)
      true
    end.to_return(status: 200, body: { data: job_with_environments }.to_json, headers: json_api)
    job = jobs.get("j")
    job.set_schedule("0 5 * * *", environment: "production")
    job.save
    prod = captured["data"]["attributes"]["environments"]["production"]
    expect(prod["schedule"]).to eq("0 5 * * *")
    expect(prod).not_to have_key("next_run_at") # read-only, never written
    expect(prod["enabled"]).to be(true) # preserved across the round-trip
  end
end

RSpec.describe Smplkit::Jobs::Usage do
  it "round-trips a usage resource via from_resource" do
    resource = SmplkitGeneratedClient::Jobs::UsageResource.new(
      id: "current", type: "usage",
      attributes: SmplkitGeneratedClient::Jobs::Usage.new(
        period: "2026-06", runs_used: 1, runs_included: -1,
        active_jobs: 0, active_jobs_limit: -1
      )
    )
    usage = described_class.from_resource(resource)
    expect(usage.period).to eq("2026-06")
    expect(usage.runs_included).to eq(-1)
    expect(usage.active_jobs_limit).to eq(-1)
  end
end

RSpec.describe "Smplkit::Jobs.call_api" do
  it "re-raises a generated ApiError that somehow survived raise_for_status" do
    err = SmplkitGeneratedClient::Jobs::ApiError.new(code: 200, response_body: "")
    expect { Smplkit::Jobs.call_api { raise err } }
      .to raise_error(SmplkitGeneratedClient::Jobs::ApiError)
  end
end

RSpec.describe Smplkit::Jobs::RetryPoliciesClient do
  subject(:policies) { Smplkit::Jobs::JobsClient.new(auth_client: api_client).retry_policies }

  let(:api_client) do
    Smplkit::Transport.build_api_client(
      SmplkitGeneratedClient::Jobs, "jobs", resolved, accept: "application/vnd.api+json"
    )
  end
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:base_url) { "https://jobs.smplkit.test" }
  let(:policy_id) { "showcase-retry" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def policy_resource(id: "showcase-retry", version: 1, created: true, max_delay: 60,
                      statuses: [429, 503], reasons: ["TIMEOUT"])
    {
      id: id, type: "retry_policy",
      attributes: {
        name: "Retry on server errors", max_retries: 5, backoff: "exponential",
        delay_seconds: 2, max_delay_seconds: max_delay,
        retry_on: { statuses: statuses, reasons: reasons },
        created_at: created ? "2026-06-04T00:00:00Z" : nil,
        updated_at: created ? "2026-06-04T00:00:00Z" : nil,
        deleted_at: nil, version: version
      }
    }
  end

  describe "#new + RetryPolicy#save (create)" do
    it "POSTs the create envelope and refreshes the instance from the response" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/retry-policies").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: policy_resource }.to_json, headers: json_api)
      policy = policies.new(policy_id, name: "Retry on server errors", max_retries: 5,
                                       backoff: Smplkit::Jobs::Backoff::EXPONENTIAL,
                                       delay_seconds: 2, max_delay_seconds: 60,
                                       retry_on: Smplkit::Jobs::RetryOn.new(
                                         statuses: [429, 503],
                                         reasons: [Smplkit::Jobs::RetryReason::TIMEOUT]
                                       ))
      expect(policy.created_at).to be_nil
      policy.save
      data = captured["data"]
      expect(data["id"]).to eq(policy_id)
      expect(data["type"]).to eq("retry_policy")
      attrs = data["attributes"]
      expect(attrs["name"]).to eq("Retry on server errors")
      expect(attrs["max_retries"]).to eq(5)
      expect(attrs["backoff"]).to eq("exponential")
      expect(attrs["delay_seconds"]).to eq(2)
      expect(attrs["max_delay_seconds"]).to eq(60)
      expect(attrs["retry_on"]).to eq({ "statuses" => [429, 503], "reasons" => ["TIMEOUT"] })
      expect(policy.created_at).not_to be_nil
      expect(policy.version).to eq(1)
    end

    it "omits max_delay_seconds from the wire when unset, but always sends retry_on" do
      captured = nil
      stub_request(:post, "#{base_url}/api/v1/retry-policies").with do |req|
        captured = JSON.parse(req.body)
        true
      end.to_return(status: 201, body: { data: policy_resource(max_delay: nil) }.to_json, headers: json_api)
      policies.new(policy_id, name: "n", max_retries: 0,
                              backoff: Smplkit::Jobs::Backoff::FIXED, delay_seconds: 1).save
      attrs = captured["data"]["attributes"]
      expect(attrs).not_to have_key("max_delay_seconds")
      expect(attrs["retry_on"]).to eq({ "statuses" => [], "reasons" => [] }) # empty: retries nothing
    end

    it "raises ArgumentError when saving a policy with an empty id" do
      policy = policies.new("", name: "n", max_retries: 1,
                                backoff: Smplkit::Jobs::Backoff::FIXED, delay_seconds: 1)
      expect { policy.save }.to raise_error(ArgumentError, /id is required/)
    end

    it "raises ConflictError when the id is already taken" do
      stub_request(:post, "#{base_url}/api/v1/retry-policies").to_return(
        status: 409, body: { errors: [{ status: "409" }] }.to_json, headers: json_api
      )
      policy = policies.new(policy_id, name: "n", max_retries: 1,
                                       backoff: Smplkit::Jobs::Backoff::FIXED, delay_seconds: 1)
      expect { policy.save }.to raise_error(Smplkit::ConflictError)
    end
  end

  describe "#get / RetryPolicy#save (update) / delete" do
    it "returns a RetryPolicy bound to the client on get" do
      stub_request(:get, "#{base_url}/api/v1/retry-policies/#{policy_id}").to_return(
        status: 200, body: { data: policy_resource }.to_json, headers: json_api
      )
      policy = policies.get(policy_id)
      expect(policy).to be_a(Smplkit::Jobs::RetryPolicy)
      expect(policy.backoff).to eq("exponential")
      expect(policy.max_delay_seconds).to eq(60)
      expect(policy.retry_on.statuses).to eq([429, 503])
      expect(policy.retry_on.reasons).to eq(["TIMEOUT"])
      expect(policy.instance_variable_get(:@client)).to be(policies)
    end

    it "RetryPolicy#save issues PUT once created_at is present and bumps the version" do
      stub_request(:get, "#{base_url}/api/v1/retry-policies/#{policy_id}").to_return(
        status: 200, body: { data: policy_resource }.to_json, headers: json_api
      )
      put_stub = stub_request(:put, "#{base_url}/api/v1/retry-policies/#{policy_id}").to_return(
        status: 200, body: { data: policy_resource(version: 2) }.to_json, headers: json_api
      )
      policy = policies.get(policy_id)
      policy.name = "Renamed"
      policy.save
      expect(put_stub).to have_been_requested
      expect(policy.version).to eq(2)
    end

    it "_update_retry_policy rejects a policy with no id" do
      detached = Smplkit::Jobs::RetryPolicy.new(
        policies, id: nil, name: "n", max_retries: 1,
                  backoff: Smplkit::Jobs::Backoff::FIXED, delay_seconds: 1
      )
      expect { policies._update_retry_policy(detached) }.to raise_error(ArgumentError, /no id/)
    end

    it "RetryPolicy#delete issues DELETE" do
      stub_request(:get, "#{base_url}/api/v1/retry-policies/#{policy_id}").to_return(
        status: 200, body: { data: policy_resource }.to_json, headers: json_api
      )
      del_stub = stub_request(:delete, "#{base_url}/api/v1/retry-policies/#{policy_id}").to_return(status: 204)
      policies.get(policy_id).delete
      expect(del_stub).to have_been_requested
    end

    it "client #delete returns nil and issues DELETE by id" do
      del_stub = stub_request(:delete, "#{base_url}/api/v1/retry-policies/#{policy_id}").to_return(status: 204)
      expect(policies.delete(policy_id)).to be_nil
      expect(del_stub).to have_been_requested
    end

    it "raises NotFoundError on a 404" do
      stub_request(:get, "#{base_url}/api/v1/retry-policies/#{policy_id}").to_return(
        status: 404, body: { errors: [{ status: "404" }] }.to_json, headers: json_api
      )
      expect { policies.get(policy_id) }.to raise_error(Smplkit::NotFoundError)
    end
  end

  describe "#list" do
    it "forwards filter[name] and paging params and returns bound policies" do
      captured = nil
      stub_request(:get, %r{#{base_url}/api/v1/retry-policies\b}).with do |req|
        captured = req.uri.query_values
        true
      end.to_return(status: 200,
                    body: { data: [policy_resource(id: "a"), policy_resource(id: "b")],
                            meta: { pagination: { page: 1, size: 10 } } }.to_json,
                    headers: json_api)
      result = policies.list(name: "server", page_number: 1, page_size: 10)
      expect(captured["filter[name]"]).to eq("server")
      expect(captured["page[number]"]).to eq("1")
      expect(captured["page[size]"]).to eq("10")
      expect(result.map(&:id)).to eq(%w[a b])
    end

    it "returns an empty list when data is empty" do
      stub_request(:get, %r{#{base_url}/api/v1/retry-policies\b}).to_return(
        status: 200, body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
        headers: json_api
      )
      expect(policies.list).to be_empty
    end
  end

  describe "active-record guards" do
    it "raises when save / delete are called without a bound client" do
      detached = Smplkit::Jobs::RetryPolicy.new(
        id: "x", name: "n", max_retries: 1, backoff: Smplkit::Jobs::Backoff::FIXED, delay_seconds: 1
      )
      expect { detached.save }.to raise_error(/cannot save/)
      expect { detached.delete }.to raise_error(/cannot delete/)
    end

    it "exposes save! and delete! aliases" do
      expect(Smplkit::Jobs::RetryPolicy.instance_method(:save!))
        .to eq(Smplkit::Jobs::RetryPolicy.instance_method(:save))
      expect(Smplkit::Jobs::RetryPolicy.instance_method(:delete!))
        .to eq(Smplkit::Jobs::RetryPolicy.instance_method(:delete))
    end
  end
end
