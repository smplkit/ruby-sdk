# frozen_string_literal: true

# Setup / cleanup helpers for flags_management_showcase.rb.

require "smplkit"

DEMO_FLAG_IDS = %w[checkout-v2 banner-color max-retries ui-theme].freeze

def setup_management_showcase(client)
  cleanup_management_showcase(client)
end

def cleanup_management_showcase(client)
  DEMO_FLAG_IDS.each do |flag_id|
    client.flags.delete(flag_id)
  rescue Smplkit::NotFoundError
    next
  end
end
