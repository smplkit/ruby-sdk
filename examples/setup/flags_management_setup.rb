# frozen_string_literal: true

# Setup / cleanup helpers for flags_management_showcase.rb.

DEMO_MGMT_ENVIRONMENTS = %w[staging production].freeze
DEMO_MGMT_FLAG_IDS = %w[checkout-v2 banner-color max-retries beta-config].freeze

def setup_management_showcase(manage)
  existing = manage.environments.list.map(&:key).to_set
  DEMO_MGMT_ENVIRONMENTS.each do |env_id|
    next if existing.include?(env_id)

    manage.environments.new(env_id, name: env_id.capitalize).save
  end
  cleanup_management_showcase(manage)
end

def cleanup_management_showcase(manage)
  DEMO_MGMT_FLAG_IDS.each do |flag_id|
    manage.flags.delete(flag_id)
  rescue Smplkit::NotFoundError
    next
  end
end
