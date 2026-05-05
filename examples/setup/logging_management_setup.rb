# frozen_string_literal: true

DEMO_LOG_ENVIRONMENTS = %w[staging production].freeze
DEMO_LOG_GROUPS = %w[showcase-service.app showcase-service.db].freeze

def setup_logging_management_showcase(manage)
  existing = manage.environments.list.map(&:key).to_set
  DEMO_LOG_ENVIRONMENTS.each do |env_id|
    next if existing.include?(env_id)

    manage.environments.new(env_id, name: env_id.capitalize).save
  end
  cleanup_logging_management_showcase(manage)
end

def cleanup_logging_management_showcase(manage)
  DEMO_LOG_GROUPS.each do |key|
    manage.log_groups.delete(key)
  rescue Smplkit::NotFoundError
    next
  end
end
