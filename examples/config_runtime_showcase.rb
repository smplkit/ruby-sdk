# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Config.
#
# Usage:
#
#   bundle exec ruby examples/config_runtime_showcase.rb

require "smplkit"
require_relative "setup/config_runtime_setup"

Smplkit::Client.open(environment: "production", service: "showcase-billing") do |client|
  setup_config_runtime_showcase(client.manage)

  # declare a common/shared configuration
  common = client.config.get_or_create(
    "showcase-common",
    description: "Shared defaults for showcase services."
  )

  # declare a configuration that inherits from some parent
  billing = client.config.get_or_create(
    "showcase-billing",
    parent: common,
    description: "Plan-limit configuration discovered from code."
  )

  # get a configured value
  app_name = common.get_string("app.name", "Acme SaaS")
  support_email = common.get_string("support.email", "support@acme.dev")
  max_seats = billing.get_int("plan.max_seats", 5, description: "Maximum seats per organization.")
  trial_days = billing.get_int("plan.trial_days", 14)
  tier = billing.get_string("plan.tier", "free")

  puts "app.name = #{app_name}"
  puts "support.email = #{support_email}"
  puts "plan.max_seats = #{max_seats}"
  puts "plan.trial_days = #{trial_days}"
  puts "plan.tier = #{tier}"

  # listen for changes
  changes = []
  billing.on_change("plan.max_seats") do |event|
    changes << event
    puts "    [CHANGE] #{event.key} updated via #{event.source}"
  end

  # simulate someone overriding a value in the console
  simulate_admin_override(client.manage)

  # wait for the WebSocket push to deliver the change, then refetch
  deadline = Time.now + 10
  sleep(0.1) while Time.now < deadline && billing.get_int("plan.max_seats", 5) != 25

  # get the latest value
  updated_seats = billing.get_int("plan.max_seats", 5)
  puts "plan.max_seats after override = #{updated_seats}"
  raise "Expected 25, got #{updated_seats}" unless updated_seats == 25
  raise "Expected at least one change event" if changes.empty?

  cleanup_config_runtime_showcase(client.manage)
  puts "Done!"
end
