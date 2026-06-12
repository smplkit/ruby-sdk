# frozen_string_literal: true

# Setup / cleanup helpers for config_management_showcase.rb.

require "smplkit"

DEMO_CONFIG_IDS = %w[showcase-user-service showcase-common].freeze

def setup_management_showcase(client)
  cleanup_management_showcase(client)
end

def cleanup_management_showcase(client)
  DEMO_CONFIG_IDS.each do |config_id|
    client.config.delete(config_id)
  rescue Smplkit::NotFoundError
    next
  end
end
