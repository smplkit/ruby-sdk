# frozen_string_literal: true

# Setup and simulation helpers for config_runtime_showcase.rb.

DEMO_CONFIG_KEYS = %w[
  showcase-billing
  showcase-common
  showcase-database
].freeze

def simulate_admin_override(manage)
  # Real customers never read back through the management API immediately
  # after binding via the runtime client — this is a simulation-only step.
  # Push pending runtime-side registrations through so the lookup below
  # can find the freshly-declared config.
  manage.config.flush
  billing = manage.config.get("showcase-billing")
  billing.set_number("plan.max_seats", 25, environment: "production")
  billing.save
end

def cleanup_runtime_showcase(manage)
  DEMO_CONFIG_KEYS.each do |key|
    manage.config.delete(key)
  rescue Smplkit::NotFoundError
    next
  end
end
