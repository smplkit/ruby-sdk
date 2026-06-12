# frozen_string_literal: true

# Setup / cleanup helpers for logging_management_showcase.rb.

require "smplkit"

DEMO_LOGGER_IDS = %w[
  showcase
  showcase.db
  showcase.payments
].freeze

def setup_management_showcase(client)
  cleanup_management_showcase(client)
end

def cleanup_management_showcase(client)
  DEMO_LOGGER_IDS.each do |logger_id|
    client.logging.loggers.delete(logger_id)
  rescue Smplkit::NotFoundError
    next
  end
end
