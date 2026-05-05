# frozen_string_literal: true

# Setup / cleanup helpers for config_runtime_showcase.rb.

DEMO_CONFIG_ENVIRONMENTS = %w[staging production].freeze
DEMO_CONFIG_KEYS = %w[showcase-service-config].freeze

def setup_config_runtime_showcase(manage)
  existing = manage.environments.list.map(&:key).to_set
  DEMO_CONFIG_ENVIRONMENTS.each do |env_id|
    next if existing.include?(env_id)

    manage.environments.new(env_id, name: env_id.capitalize).save
  end
  cleanup_config_runtime_showcase(manage)

  cfg = manage.config.new_config("showcase-service-config")
  cfg.set_string("api.host", "default.example.com")
  cfg.set_number("api.timeout_ms", 5000)
  cfg.set_boolean("feature.beta", false)
  cfg.set_string("api.host", "staging.example.com", environment: "staging")
  cfg.save
end

def cleanup_config_runtime_showcase(manage)
  DEMO_CONFIG_KEYS.each do |key|
    manage.config.delete(key)
  rescue Smplkit::NotFoundError
    next
  end
end
