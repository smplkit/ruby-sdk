# frozen_string_literal: true

DEMO_CFG_ENVIRONMENTS = %w[staging production].freeze
DEMO_CFG_KEYS = %w[platform-defaults showcase-service-config].freeze

def setup_config_management_showcase(manage)
  existing = manage.environments.list.map(&:key).to_set
  DEMO_CFG_ENVIRONMENTS.each do |env_id|
    next if existing.include?(env_id)

    manage.environments.new(env_id, name: env_id.capitalize).save
  end
  cleanup_config_management_showcase(manage)
end

def cleanup_config_management_showcase(manage)
  DEMO_CFG_KEYS.reverse_each do |key|
    manage.config.delete(key)
  rescue Smplkit::NotFoundError
    next
  end
end
