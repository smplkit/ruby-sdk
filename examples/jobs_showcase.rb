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
ONEOFF_JOB_ID = "showcase-oneoff"

# Jobs has no runtime/management split — one client. Here we use the standalone
# +Smplkit::JobsClient+; the same surface is also reachable as +client.jobs+ on
# a +Smplkit::Client+.
Smplkit::JobsClient.open do |jobs|
  setup_showcase(jobs)
  begin
    # create a recurring job, enabled in production with a development override
    job = jobs.new(
      RECURRING_JOB_ID,
      name: "Nightly cache warm",
      description: "Warms the product cache every night at 02:00 UTC.",
      schedule: "0 2 * * *",
      configuration: Smplkit::Jobs::HttpConfig.new(
        method: "POST",
        url: "https://httpbin.org/post",
        headers: [{ name: "Authorization", value: "Bearer s3cr3t" }],
        body: '{"scope": "all"}',
        timeout: 30
      )
    )
    job.set_configuration(
      Smplkit::Jobs::HttpConfig.new(
        method: "POST",
        url: "https://development.example.com/cache/warm",
        headers: [{ name: "Authorization", value: "Bearer development-s3cr3t" }],
        body: '{"scope": "all"}'
      ),
      environment: "development"
    )
    job.set_enabled(false, environment: "development")
    job.set_enabled(true, environment: "production")
    job.save
    raise unless job.version == 1
    raise unless job.is_enabled(environment: "development") == false
    raise unless job.is_enabled(environment: "production") == true

    puts "Created recurring job #{job.id.inspect} (v#{job.version})"

    # get a job
    fetched = jobs.get(RECURRING_JOB_ID)
    raise unless fetched.is_enabled(environment: "development") == false
    raise unless fetched.is_enabled(environment: "production") == true

    development_url = fetched.get_configuration(environment: "development").url
    raise unless development_url == "https://development.example.com/cache/warm"

    puts "Fetched job #{RECURRING_JOB_ID.inspect}"

    # list jobs
    listing = jobs.list
    raise unless listing.any? { |j| j.id == RECURRING_JOB_ID }

    puts "Found job #{RECURRING_JOB_ID.inspect} in the listing"

    # update a job (the schedule is environment-agnostic)
    job.name = "Nightly cache warm (v2)"
    job.set_schedule("30 2 * * *")
    job.set_enabled(true, environment: "development")
    job.save
    raise unless job.version == 2 && job.is_enabled(environment: "development") == true

    puts "Updated job to v#{job.version}: now enabled in production and development"

    # trigger an immediate run
    run = job.trigger(environment: "production")
    raise unless run.trigger == "MANUAL" && run.environment == "production"

    puts "Triggered run #{run.id} (trigger=#{run.trigger}, env=#{run.environment})"

    # get this job's runs
    runs = job.list_runs(environment: "production")
    raise unless runs.any? { |r| r.id == run.id }

    puts "Listed #{runs.length} production run(s)"

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

    # create a one-off job, born in a single environment
    oneoff = jobs.new(
      ONEOFF_JOB_ID,
      name: "One-shot reindex",
      schedule: "now",
      configuration: Smplkit::Jobs::HttpConfig.new(method: "POST", url: "https://httpbin.org/post"),
      environment: "development"
    )
    oneoff.save
    raise unless oneoff.version == 1 && oneoff.is_enabled(environment: "development") == true

    puts "Created one-off job #{oneoff.id.inspect} born in development"

    # delete a job
    job.delete
    raise unless jobs.list.none? { |j| j.id == RECURRING_JOB_ID }

    puts "Deleted job #{RECURRING_JOB_ID.inspect} — jobs showcase complete."
  ensure
    cleanup_showcase(jobs)
  end
end
