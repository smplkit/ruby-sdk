# frozen_string_literal: true

# Setup, simulation, and cleanup helpers for config_runtime_showcase.rb.
#
# The runtime showcase is intentionally runtime-only — declarations,
# typed getters, change listeners. In a real deployment the configs
# would either already exist (admin-curated) or be created by the SDK's
# discovery on first run. Here we pre-create them through the management
# API so the showcase can also demonstrate a live admin override
# end-to-end in a single process.

DEMO_CONFIG_KEYS = %w[showcase-billing showcase-common].freeze

def setup_config_runtime_showcase(manage)
  cleanup_config_runtime_showcase(manage)

  common = manage.config.new_config("showcase-common",
                                    description: "Shared defaults for showcase services.")
  common.set_string("app.name", "Acme SaaS")
  common.set_string("support.email", "support@acme.dev")
  common.save

  billing = manage.config.new_config("showcase-billing",
                                     description: "Plan-limit configuration for billing.",
                                     parent: "showcase-common")
  billing.set_number("plan.max_seats", 5)
  billing.set_number("plan.trial_days", 14)
  billing.set_string("plan.tier", "free")
  billing.save
end

def simulate_admin_override(manage)
  billing = manage.config.get("showcase-billing")
  billing.set_number("plan.max_seats", 25, environment: "production")
  billing.save
end

def cleanup_config_runtime_showcase(manage)
  DEMO_CONFIG_KEYS.each do |key|
    manage.config.delete(key)
  rescue Smplkit::NotFoundError
    next
  end
end
