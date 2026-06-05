# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Management::JobsNamespace do
  subject(:jobs) { mgmt.jobs }

  let(:mgmt) { Smplkit::ManagementClient.from_resolved(resolved) }
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:base_url) { "https://jobs.smplkit.test" }
  let(:job_id) { "nightly-cache-warm" }
  let(:run_id) { "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def job_resource(id: "nightly-cache-warm", enabled: true, version: 1, created: true)
    {
      id: id,
      type: "job",
      attributes: {
        name: "Nightly cache warm", description: "does a thing", enabled: enabled,
        type: "http", schedule: "0 2 * * *",
        configuration: {
          method: "POST", url: "https://api.example.com/cache/warm",
          headers: [{ name: "Authorization", value: "<redacted>" }],
          body: "{\"scope\": \"all\"}", success_status: "2xx", timeout: 30,
          tls_verify: true, ca_cert: nil
        },
        concurrency_policy: "ALLOW", next_run_at: "2026-06-06T02:00:00Z",
        created_at: created ? "2026-06-04T00:00:00Z" : nil,
        updated_at: created ? "2026-06-04T00:00:00Z" : nil,
        deleted_at: nil, version: version
      }
    }
  end

  def run_resource(id: "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d", status: "SUCCEEDED",
                   trigger: "SCHEDULE", rerun_of: nil)
    {
      id: id,
      type: "run",
      attributes: {
        job: "nightly-cache-warm", job_version: 1, trigger: trigger, rerun_of: rerun_of,
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

  describe "#new + Job#save" do
    it "POSTs and refreshes the local instance with the server response" do
      stub_request(:post, "#{base_url}/api/v1/jobs").to_return(
        status: 201, body: { data: job_resource }.to_json, headers: json_api
      )
      job = jobs.new(job_id, name: "Nightly cache warm", schedule: "0 2 * * *",
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
      jobs.new(job_id, name: "Nightly cache warm", schedule: "0 2 * * *",
                       configuration: http_config, enabled: false).save
      expect(captured).to include("\"id\":\"#{job_id}\"")
      expect(captured).to include("\"body\":\"{\\\"scope\\\": \\\"all\\\"}\"")
      expect(captured).to include("\"timeout\":30")
    end

    it "raises ArgumentError when save() is called on a job without an id" do
      job = jobs.new("", name: "x", schedule: "now", configuration: http_config)
      expect { job.save }.to raise_error(ArgumentError, /id is required/)
    end

    it "raises Smplkit::ConnectionError when the generated layer reports no status code" do
      stub_request(:post, "#{base_url}/api/v1/jobs").to_raise(Errno::ECONNREFUSED)
      job = jobs.new(job_id, name: "x", schedule: "now", configuration: http_config)
      expect { job.save }.to raise_error(Smplkit::ConnectionError)
    end

    it "raises ConflictError when the id is already taken" do
      stub_request(:post, "#{base_url}/api/v1/jobs").to_return(
        status: 409, body: { errors: [{ status: "409" }] }.to_json, headers: json_api
      )
      job = jobs.new(job_id, name: "x", schedule: "now", configuration: http_config)
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
    it "forwards filter[enabled] and offset params to the generated client" do
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
      result = jobs.list(enabled: false, page_number: 2, page_size: 10)
      expect(captured_uri).to include("filter%5Benabled%5D=false")
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
    it "returns a Job on get bound to the namespace" do
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
        status: 200, body: { data: job_resource(version: 2, enabled: true) }.to_json, headers: json_api
      )
      job = jobs.get(job_id)
      job.name = "Nightly cache warm (v2)"
      job.schedule = "30 2 * * *"
      job.enabled = true
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

    it "namespace #delete returns nil and issues DELETE by id" do
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

  describe "#run" do
    it "triggers a MANUAL run and returns the Run" do
      stub_request(:post, "#{base_url}/api/v1/jobs/#{job_id}/actions/run").to_return(
        status: 200, body: { data: run_resource(trigger: "MANUAL") }.to_json, headers: json_api
      )
      run = jobs.run(job_id)
      expect(run.trigger).to eq("MANUAL")
      expect(run.job).to eq("nightly-cache-warm")
      expect(run.total_duration_ms).to eq(400)
      expect(run.request["url"]).to eq("https://api.example.com/cache/warm")
      expect(run.result["status"]).to eq(200)
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
end

RSpec.describe Smplkit::Management::RunsNamespace do
  subject(:runs) { mgmt.jobs.runs }

  let(:mgmt) { Smplkit::ManagementClient.from_resolved(resolved) }
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:base_url) { "https://jobs.smplkit.test" }
  let(:run_id) { "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d" }
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def run_resource(id: "8f2b1c4a-0000-4a1b-9c3d-1e2f3a4b5c6d", status: "SUCCEEDED",
                   trigger: "SCHEDULE", rerun_of: nil)
    {
      id: id, type: "run",
      attributes: {
        job: "nightly-cache-warm", job_version: 1, trigger: trigger, rerun_of: rerun_of,
        scheduled_for: "2026-06-05T00:00:00Z", status: status,
        started_at: nil, finished_at: nil, pending_duration_ms: nil, run_duration_ms: nil,
        total_duration_ms: nil, failure_reason: nil, error: nil, request: nil, result: nil,
        created_at: "2026-06-05T00:00:00Z"
      }
    }
  end

  describe "#list" do
    it "scopes by job and forwards cursor params" do
      captured_uri = nil
      stub_request(:get, %r{#{base_url}/api/v1/runs\b})
        .with do |req|
          captured_uri = req.uri.to_s
          true
        end
        .to_return(status: 200,
                   body: { data: [run_resource], meta: { page_size: 2 } }.to_json,
                   headers: json_api)
      result = runs.list(job: "nightly-cache-warm", page_size: 2, after: "cur")
      expect(captured_uri).to include("filter%5Bjob%5D=nightly-cache-warm")
      expect(captured_uri).to include("page%5Bsize%5D=2")
      expect(captured_uri).to include("page%5Bafter%5D=cur")
      expect(result.length).to eq(1)
      expect(result.first.id).to eq(run_id)
    end

    it "returns an empty list when data is empty" do
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).to_return(
        status: 200, body: { data: [], meta: { page_size: 50 } }.to_json, headers: json_api
      )
      expect(runs.list).to be_empty
    end

    it "leaves request and result nil when the run carries neither" do
      stub_request(:get, %r{#{base_url}/api/v1/runs\b}).to_return(
        status: 200, body: { data: [run_resource], meta: { page_size: 50 } }.to_json, headers: json_api
      )
      run = runs.list.first
      expect(run.request).to be_nil
      expect(run.result).to be_nil
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

RSpec.describe Smplkit::Jobs::Job do
  let(:http_config) { Smplkit::Jobs::HttpConfig.new(url: "https://x") }

  it "defaults enabled, type, and concurrency_policy when the wire omits them" do
    resource = SmplkitGeneratedClient::Jobs::JobResource.new(
      id: "j", type: "job",
      attributes: SmplkitGeneratedClient::Jobs::Job.new(
        name: "n", schedule: "now",
        configuration: SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new(url: "https://x"),
        enabled: nil, type: nil, concurrency_policy: nil
      )
    )
    job = described_class.from_resource(resource)
    expect(job.enabled).to be(true)
    expect(job.type).to eq("http")
    expect(job.concurrency_policy).to eq("ALLOW")
  end

  it "exposes save! and delete! aliases" do
    expect(described_class.instance_method(:save!)).to eq(described_class.instance_method(:save))
    expect(described_class.instance_method(:delete!)).to eq(described_class.instance_method(:delete))
  end
end

RSpec.describe "Smplkit::Jobs.call_api" do
  it "re-raises a generated ApiError that somehow survived raise_for_status" do
    err = SmplkitGeneratedClient::Jobs::ApiError.new(code: 200, response_body: "")
    expect { Smplkit::Jobs.call_api { raise err } }
      .to raise_error(SmplkitGeneratedClient::Jobs::ApiError)
  end
end
