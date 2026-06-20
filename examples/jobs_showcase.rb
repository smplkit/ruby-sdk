# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Jobs.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/jobs_showcase.rb

require "smplkit"
require_relative "setup/jobs_setup"

RECURRING_JOB_ID = "showcase-recurring"
MANUAL_JOB_ID = "showcase-manual"
ONEOFF_JOB_ID = "showcase-oneoff"
RETRY_POLICY_ID = "showcase-retry"

# Jobs has no runtime/management split — one client. Here we use the standalone
# +Smplkit::JobsClient+; the same surface is also reachable as +client.jobs+ on
# a +Smplkit::Client+.
Smplkit::JobsClient.open do |jobs|
  setup_showcase(jobs)
  begin
    # create a retry policy
    retry_policy = jobs.retry_policies.new(
      RETRY_POLICY_ID,
      name: "Retry on server errors",
      max_retries: 5,
      backoff: Smplkit::Jobs::Backoff::EXPONENTIAL,
      delay_seconds: 2,
      max_delay_seconds: 60,
      retry_on: Smplkit::Jobs::RetryOn.new(
        statuses: [429, 503], reasons: [Smplkit::Jobs::RetryReason::TIMEOUT]
      )
    )
    retry_policy.save
    raise unless jobs.retry_policies.list.any? { |p| p.id == RETRY_POLICY_ID }

    puts "Created retry policy #{retry_policy.id.inspect}"

    # create a recurring job
    job = jobs.new_recurring_job(
      RECURRING_JOB_ID,
      name: "Nightly cache warm",
      description: "Warms the product cache nightly.",
      schedule: "0 2 * * *",
      configuration: Smplkit::Jobs::HttpConfig.new(
        method: "POST",
        url: "https://httpbin.org/post",
        headers: [{ name: "Authorization", value: "Bearer s3cr3t" }],
        body: '{"scope": "all"}',
        timeout: 30
      )
    )
    job.set_enabled(true, environment: "development")
    job.set_enabled(true, environment: "production")
    job.set_schedule("0 */6 * * *", timezone: "America/New_York", environment: "development")
    job.set_configuration(
      Smplkit::Jobs::HttpConfig.new(
        method: "POST",
        url: "https://development.example.com/cache/warm",
        headers: [{ name: "Authorization", value: "Bearer development-s3cr3t" }],
        body: '{"scope": "all"}'
      ),
      environment: "development"
    )
    job.save
    raise unless job.is_recurring == true
    raise unless job.is_enabled(environment: "development") == true
    raise unless job.is_enabled(environment: "production") == true
    raise unless job.environments["development"].timezone == "America/New_York"
    raise unless job.get_configuration(environment: "development").url == "https://development.example.com/cache/warm"

    puts "Created recurring job #{job.id.inspect} (v#{job.version})"

    # get a job
    fetched = jobs.get(RECURRING_JOB_ID)
    raise unless fetched.environments["development"].schedule == "0 */6 * * *"

    puts "Fetched job #{RECURRING_JOB_ID.inspect}"

    # list jobs, filtered to recurring jobs
    listing = jobs.list(kind: Smplkit::Jobs::JobKind::RECURRING)
    raise unless listing.any? { |j| j.id == RECURRING_JOB_ID }

    puts "Found job #{RECURRING_JOB_ID.inspect} in the listing"

    # update a job
    job.name = "Nightly cache warm (v2)"
    job.set_retry_policy(retry_policy, environment: "production")
    job.set_schedule("30 2 * * *", timezone: "America/Los_Angeles", environment: "production")
    job.save
    raise unless job.version == 2

    puts "Updated job to v#{job.version}"

    # trigger an immediate run
    run = job.trigger(environment: "production")
    raise unless run.trigger == "MANUAL" && run.environment == "production"

    puts "Triggered run #{run.id} (trigger=#{run.trigger}, env=#{run.environment})"

    # get this job's runs
    runs = job.list_runs(environment: "production")
    raise unless runs.any? { |r| r.id == run.id }

    puts "Listed #{runs.length} production run(s)"

    # get the last completed run in production
    recent = job.list_runs(environment: "production", last_run_only: true)
    puts "Last completed production run(s): #{recent.length}"

    # get a run
    run = jobs.runs.get(run.id)
    raise unless run.environment == "production"

    puts "Fetched run #{run.id} (env=#{run.environment})"

    # re-run a prior run (inherits its environment)
    rerun = run.rerun
    raise unless rerun.trigger == "RERUN" && rerun.environment == run.environment

    puts "Re-ran #{run.id} -> #{rerun.id} (env=#{rerun.environment})"

    # cancel a run (best-effort: a finished run can no longer be canceled)
    begin
      canceled = rerun.cancel
      puts "Canceled run #{canceled.id} -> #{canceled.status}"
    rescue Smplkit::ConflictError
      puts "Run #{rerun.id} already finished before it could be canceled"
    end

    # create a manual job (no schedule, runs only when triggered)
    manual = jobs.new_manual_job(
      MANUAL_JOB_ID,
      name: "On-demand reindex",
      configuration: Smplkit::Jobs::HttpConfig.new(method: "POST", url: "https://httpbin.org/post")
    )
    manual.set_enabled(true, environment: "production")
    manual.save
    raise unless manual.is_manual == true

    manual_run = manual.trigger(environment: "production")
    raise unless manual_run.trigger == Smplkit::Jobs::RunTrigger::MANUAL

    puts "Created manual job #{manual.id.inspect} and triggered it on demand"

    # schedule a one-off job to run tomorrow
    tomorrow = Time.now + (24 * 60 * 60)
    oneoff = jobs.schedule(
      ONEOFF_JOB_ID,
      name: "One-shot reindex",
      schedule: tomorrow,
      configuration: Smplkit::Jobs::HttpConfig.new(method: "POST", url: "https://httpbin.org/post"),
      environment: "development"
    )
    oneoff.save
    raise unless oneoff.is_one_off == true
    raise unless oneoff.is_enabled(environment: "development") == true
    raise unless oneoff.environments["development"].next_run_at

    puts "Created one-off job #{oneoff.id.inspect} to run in development"

    # delete a job
    job.delete
    raise unless jobs.list.none? { |j| j.id == RECURRING_JOB_ID }

    # delete the retry policy
    retry_policy.delete
    puts "Deleted job #{RECURRING_JOB_ID.inspect} and retry policy — jobs showcase complete."
  ensure
    cleanup_showcase(jobs)
  end
end
