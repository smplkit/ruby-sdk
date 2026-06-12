# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Config.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/config_runtime_showcase.rb

require "smplkit"
require_relative "setup/config_runtime_setup"

# Example Struct configuration classes to showcase how "code-first"
# configuration management works
App = Struct.new(:name, keyword_init: true)
Support = Struct.new(:email, keyword_init: true)
Plan = Struct.new(:max_seats, :trial_days, :tier, keyword_init: true)
Common = Struct.new(:app, :support, keyword_init: true)
Billing = Struct.new(:app, :support, :plan, keyword_init: true)

Smplkit::Client.open(environment: "production") do |client|
  cleanup_runtime_showcase(client)

  # bind Struct schemas
  common = client.config.bind("showcase-common", Common.new(
                                                   app: App.new(name: "Acme SaaS"),
                                                   support: Support.new(email: "support@acme.dev")
                                                 ))
  billing = client.config.bind(
    "showcase-billing",
    Billing.new(
      app: App.new(name: "Acme SaaS"),
      support: Support.new(email: "support@acme.dev"),
      plan: Plan.new(max_seats: 5, trial_days: 14, tier: "free")
    ),
    parent: common
  )
  puts "common.app.name = #{common.app.name}"
  puts "billing.app.name = #{billing.app.name}  # inherited from common"
  puts "billing.plan.max_seats = #{billing.plan.max_seats}"

  # add listeners if desired
  changes = []

  client.config.on_change("showcase-billing", item_key: "plan.max_seats") do |event|
    changes << event
    puts "    [CHANGE] #{event.config_id}.#{event.item_key}: #{event.old_value.inspect} -> #{event.new_value.inspect}"
  end

  client.wait_until_ready

  # simulate someone making a change in smplkit console
  simulate_admin_override(client)
  sleep(0.4)

  # observe changes are automatically reflected in bound models
  puts "billing.plan.max_seats after override = #{billing.plan.max_seats}"
  raise "Expected 25, got #{billing.plan.max_seats}" unless billing.plan.max_seats == 25
  raise "Expected at least one change" unless changes.length >= 1

  # you can also bind plain-old Hashes
  db = client.config.bind(
    "showcase-database",
    {
      "primary" => {
        "host" => "db.acme.example",
        "port" => 5432
      },
      "pool_size" => 10,
      "statement_timeout_ms" => 30_000
    }
  )
  puts "db['primary']['host'] = #{db["primary"]["host"]}"
  puts "db['pool_size'] = #{db["pool_size"]}"
  raise unless db["primary"]["host"] == "db.acme.example"
  raise unless db["pool_size"] == 10

  # or read live values via subscribe(id)
  common_view = client.config.subscribe("showcase-common")
  puts "showcase-common (via subscribe):"
  common_view.each_pair { |k, v| puts "    #{k} = #{v}" }
  raise unless common_view["app.name"] == "Acme SaaS"

  # or skip the model/hash and just fetch specific keys directly
  slow_query_ms = client.config.get_value("showcase-database", "slow_query_threshold_ms", 500)
  puts "showcase-database.slow_query_threshold_ms = #{slow_query_ms}  # default used (key absent)"
  raise unless slow_query_ms == 500

  cleanup_runtime_showcase(client)
  puts "Done!"
end
