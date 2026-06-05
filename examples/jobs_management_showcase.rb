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
#   bundle exec ruby examples/jobs_management_showcase.rb

require "securerandom"
require "smplkit"

# create the client
manage = Smplkit::ManagementClient.new

job_id = "showcase-mgmt-#{SecureRandom.hex(4)}"

begin
  # create a job
  job = manage.jobs.new(
    job_id,
    name: "Nightly cache warm",
    description: "Warms the product cache every night at 02:00 UTC.",
    schedule: "0 2 * * *", # 5-field cron, UTC
    enabled: false,
    configuration: Smplkit::Jobs::HttpConfig.new(
      method: "POST",
      url: "https://api.example.com/cache/warm",
      headers: [Smplkit::Jobs::HttpHeader.new(name: "Authorization", value: "Bearer s3cr3t")],
      body: "{\"scope\": \"all\"}",
      timeout: 30
    )
  )
  job.save
  raise "expected version 1" unless job.version == 1

  puts "Created job #{job.id.inspect} (v#{job.version})"

  # get a job
  fetched = manage.jobs.get(job_id)
  raise "url mismatch" unless fetched.configuration.url == "https://api.example.com/cache/warm"

  puts "Fetched job #{job_id.inspect}"

  # list jobs
  jobs = manage.jobs.list(enabled: false)
  raise "expected job in list" unless jobs.any? { |j| j.id == job_id }

  puts "Found job #{job_id.inspect} and in the listing"

  # update a job
  job.name = "Nightly cache warm (v2)"
  job.schedule = "30 2 * * *"
  job.enabled = true
  job.save
  raise "expected version 2, enabled" unless job.version == 2 && job.enabled == true

  puts "Updated job to v#{job.version}: schedule=#{job.schedule.inspect}"

  # trigger an immediate run (a MANUAL run)
  run = manage.jobs.run(job_id)
  raise "expected MANUAL run for this job" unless run.trigger == "MANUAL" && run.job == job_id

  puts "Triggered run #{run.id} (trigger=#{run.trigger}, status=#{run.status})"

  # read run history for this job, and fetch a single run
  runs = manage.jobs.runs.list(job: job_id)
  raise "expected the run in history" unless runs.any? { |r| r.id == run.id }

  got = manage.jobs.runs.get(run.id)
  raise "run id mismatch" unless got.id == run.id

  puts "Listed #{runs.length} run(s); fetched run #{got.id} (status=#{got.status})"

  # re-run from a prior run, then cancel it while it's still pending
  rerun = manage.jobs.runs.rerun(run.id)
  raise "expected RERUN linked to the source run" unless rerun.trigger == "RERUN" && rerun.rerun_of == run.id

  canceled = manage.jobs.runs.cancel(rerun.id)
  raise "expected CANCELED" unless canceled.status == "CANCELED"

  puts "Re-ran (#{rerun.id}) then canceled it -> #{canceled.status}"

  # delete a job
  job.delete
  raise "delete failed — job still listed" if manage.jobs.list.any? { |j| j.id == job_id }

  puts "Deleted job #{job_id.inspect} — management showcase complete."
ensure
  # tear-down: never leave the showcase job behind, even on failure
  begin
    manage.jobs.delete(job_id)
  rescue Smplkit::NotFoundError
    # already gone — nothing to clean up
  end
  manage.close
end
