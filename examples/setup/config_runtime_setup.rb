# frozen_string_literal: true

# Setup and simulation helpers for config_runtime_showcase.rb.

require "smplkit"

DEMO_CONFIG_IDS = %w[
  showcase-billing
  showcase-common
  showcase-database
].freeze

def simulate_admin_override(client)
  client.config.flush
  billing = client.config.get("showcase-billing")
  billing.set_number("plan.max_seats", 25, environment: "production")
  billing.save
end

def cleanup_runtime_showcase(client)
  DEMO_CONFIG_IDS.each do |config_id|
    client.config.delete(config_id)
  rescue Smplkit::NotFoundError
    next
  end
end
