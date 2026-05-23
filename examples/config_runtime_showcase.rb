# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Config.
#
# Headline pattern: declare configurations as Ruby Structs, +bind+ them to
# a config id, then use the returned objects directly — attribute access
# stays in sync with the server via the SDK's in-memory cache and
# WebSocket push.
#
# Also demonstrates three lower-friction patterns:
#   - +bind+ with a plain Hash
#   - +client.config.get(id)+ for dict-like lookup of an entire config
#   - +client.config.get(id, key, default)+ for one-shot value reads with fallback
#
# Usage:
#
#   bundle exec ruby examples/config_runtime_showcase.rb

require "smplkit"
require_relative "setup/config_runtime_setup"

# Example Struct schemas for the typed declarative path. Class names appear
# in the smplkit console as the config display name.
App = Struct.new(:name, keyword_init: true)
Support = Struct.new(:email, keyword_init: true)
Plan = Struct.new(:max_seats, :trial_days, :tier, keyword_init: true)
Common = Struct.new(:app, :support, keyword_init: true)
Billing = Struct.new(:app, :support, :plan, keyword_init: true)

Smplkit::Client.open(environment: "production", service: "showcase-billing") do |client|
  cleanup_runtime_showcase(client.manage)

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
  raise "Expected 'Acme SaaS', got #{common.app.name.inspect}" unless common.app.name == "Acme SaaS"
  raise "Expected 5, got #{billing.plan.max_seats}" unless billing.plan.max_seats == 5

  # add listeners if desired
  changes = []
  client.config.on_change("showcase-billing", item_key: "plan.max_seats") do |event|
    changes << event
    puts "    [CHANGE] #{event.config_id}.#{event.item_key}: " \
         "#{event.old_value.inspect} -> #{event.new_value.inspect}"
  end

  # simulate someone making a change in the smplkit console
  simulate_admin_override(client.manage)

  # wait for the WebSocket push to deliver the change
  deadline = Time.now + 10
  sleep(0.1) while Time.now < deadline && billing.plan.max_seats != 25

  # observe changes are automatically reflected in bound objects
  puts "billing.plan.max_seats after override = #{billing.plan.max_seats}"
  raise "Expected 25, got #{billing.plan.max_seats}" unless billing.plan.max_seats == 25
  raise "Expected at least one change event" if changes.empty?

  # you can also bind plain-old Hashes
  db = client.config.bind(
    "showcase-database",
    {
      "primary" => { "host" => "db.acme.example", "port" => 5432 },
      "pool_size" => 10,
      "statement_timeout_ms" => 30_000
    }
  )
  puts "db['primary']['host'] = #{db["primary"]["host"]}"
  puts "db['pool_size'] = #{db["pool_size"]}"
  raise "Expected db.acme.example" unless db["primary"]["host"] == "db.acme.example"
  raise "Expected 10" unless db["pool_size"] == 10

  # or get a config by ID (raises NotFoundError if not found)
  common_view = client.config.get("showcase-common")
  puts "showcase-common (via get):"
  common_view.each_pair { |k, v| puts "    #{k} = #{v}" }
  raise "Expected 'Acme SaaS'" unless common_view["app.name"] == "Acme SaaS"

  # or skip the schema and fetch a specific key directly with a default
  slow_query_ms = client.config.get("showcase-database", "slow_query_threshold_ms", 500)
  puts "showcase-database.slow_query_threshold_ms = #{slow_query_ms}  " \
       "# default used; now registered for visibility"
  raise "Expected 500, got #{slow_query_ms}" unless slow_query_ms == 500

  cleanup_runtime_showcase(client.manage)
  puts "Done!"
end
