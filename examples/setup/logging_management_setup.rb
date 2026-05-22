# frozen_string_literal: true

DEMO_LOG_GROUPS = %w[showcase-service.app showcase-service.db].freeze

def setup_logging_management_showcase(manage)
  cleanup_logging_management_showcase(manage)
end

def cleanup_logging_management_showcase(manage)
  DEMO_LOG_GROUPS.each do |key|
    manage.log_groups.delete(key)
  rescue Smplkit::NotFoundError
    next
  end
end
