# frozen_string_literal: true

DEMO_CFG_KEYS = %w[platform-defaults showcase-service-config].freeze

def setup_config_management_showcase(manage)
  cleanup_config_management_showcase(manage)
end

def cleanup_config_management_showcase(manage)
  DEMO_CFG_KEYS.reverse_each do |key|
    manage.config.delete(key)
  rescue Smplkit::NotFoundError
    next
  end
end
