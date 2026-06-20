# frozen_string_literal: true

# Setup / cleanup helpers for jobs_showcase.rb.

require "smplkit"

# Every job and retry policy the jobs showcase creates. Start-of-run cleanup
# removes residue from a prior run; the matching teardown in the showcase's
# ensure block tears them down even when it fails mid-way, so a failed run never
# leaves orphans behind.
DEMO_JOB_IDS = %w[showcase-recurring showcase-manual showcase-oneoff].freeze
DEMO_RETRY_POLICY_IDS = %w[showcase-retry].freeze

def setup_showcase(jobs)
  cleanup_showcase(jobs)
end

def cleanup_showcase(jobs)
  # Jobs first, then the policies they reference.
  DEMO_JOB_IDS.each do |job_id|
    jobs.delete(job_id)
  rescue Smplkit::NotFoundError
    next
  end
  DEMO_RETRY_POLICY_IDS.each do |policy_id|
    jobs.retry_policies.delete(policy_id)
  rescue Smplkit::NotFoundError
    next
  end
end
