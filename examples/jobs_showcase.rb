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

require "securerandom"
require "smplkit"

# Jobs has no runtime/management split — one client. Here we use the standalone
# +Smplkit::JobsClient+; the same surface is also reachable as +client.jobs+ on
# a +Smplkit::Client+.
Smplkit::JobsClient.open do |jobs|
  job_id = "showcase-mgmt-#{SecureRandom.hex(4)}"

  begin
    # create a job
    job = jobs.new(
      job_id,
      name: "Nightly cache warm",
      description: "Warms the product cache every night at 02:00 UTC.",
      schedule: "0 2 * * *", # 5-field cron, UTC
      enabled: false,
      configuration: Smplkit::Jobs::HttpConfig.new(
        method: "POST",
        url: "https://api.example.com/cache/warm",
        headers: [{ name: "Authorization", value: "Bearer s3cr3t" }],
        body: '{"scope": "all"}',
        timeout: 30
      )
    )
    job.save
    raise unless job.version == 1

    puts "Created job #{job.id.inspect} (v#{job.version})"

    # get a job
    fetched = jobs.get(job_id)
    raise unless fetched.configuration.url == "https://api.example.com/cache/warm"

    puts "Fetched job #{job_id.inspect}"

    # list jobs
    listing = jobs.list(enabled: false)
    raise unless listing.any? { |j| j.id == job_id }

    puts "Found job #{job_id.inspect} and in the listing"

    # update a job
    job.name = "Nightly cache warm (v2)"
    job.schedule = "30 2 * * *"
    job.enabled = true
    job.save
    raise unless job.version == 2 && job.enabled == true

    puts "Updated job to v#{job.version}: schedule=#{job.schedule.inspect}"

    # trigger an immediate run (a MANUAL run)
    run = jobs.run(job_id)
    raise unless run.trigger == "MANUAL" && run.job == job_id

    puts "Triggered run #{run.id} (trigger=#{run.trigger}, status=#{run.status})"

    # read run history for this job, and fetch a single run
    runs = jobs.runs.list(job: job_id)
    raise unless runs.any? { |r| r.id == run.id }

    got = jobs.runs.get(run.id)
    raise unless got.id == run.id

    puts "Listed #{runs.length} run(s); fetched run #{got.id} (status=#{got.status})"

    # re-run from a prior run, then cancel it while it's still pending
    rerun = jobs.runs.rerun(run.id)
    raise unless rerun.trigger == "RERUN" && rerun.rerun_of == run.id

    canceled = jobs.runs.cancel(rerun.id)
    raise unless canceled.status == "CANCELED"

    puts "Re-ran (#{rerun.id}) then canceled it -> #{canceled.status}"

    # delete a job
    job.delete
    raise unless jobs.list.none? { |j| j.id == job_id }

    puts "Deleted job #{job_id.inspect} — jobs showcase complete."
  ensure
    # tear-down: never leave the showcase job behind, even on failure
    begin
      jobs.delete(job_id)
    rescue Smplkit::NotFoundError
      nil
    end
  end
end
