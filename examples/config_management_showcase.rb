# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Config.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/config_management_showcase.rb

require "smplkit"
require_relative "setup/config_management_setup"

Smplkit::Client.open do |client|
  setup_management_showcase(client)
  begin
    # create a "parent" configuration that all other configs inherit from
    shared = client.config.new(
      "showcase-common",
      name: "Showcase Common",
      description: "Showcase-only shared configuration."
    )
    shared.set_string("app_name", "Acme SaaS Platform")
    shared.set_string("support_email", "support@acme.dev")
    shared.set_number("max_retries", 3)
    shared.set_number("request_timeout_ms", 5000)
    shared.set_number("pagination_default_page_size", 25)
    shared.set_number("max_retries", 5, environment: "production")
    shared.set_number("request_timeout_ms", 10_000, environment: "production")
    shared.save
    puts "Created config: #{shared.id}"

    # create a config (inherits from showcase-common)
    user_service = client.config.new(
      "showcase-user-service",
      name: "Showcase User Service",
      description: "Configuration for the user microservice.",
      parent: shared
    )
    user_service.set_string("database.host", "localhost")
    user_service.set_number("database.port", 5432)
    user_service.set_string("database.name", "users_dev")
    user_service.set_number("database.pool_size", 5)
    user_service.set_number("cache_ttl_seconds", 300)
    user_service.set_boolean("enable_signup", true)
    user_service.set_number("pagination_default_page_size", 50)
    user_service.save

    # update a config
    user_service.set_string("database.host", "prod-users-rds.internal.acme.dev", environment: "production")
    user_service.set_string("database.name", "users_prod", environment: "production")
    user_service.set_number("database.pool_size", 20, environment: "production")
    user_service.set_number("cache_ttl_seconds", 600, environment: "production")
    user_service.set_boolean("enable_signup", false, environment: "production")
    user_service.save
    puts "Updated config: #{user_service.id}"

    # list configs
    configs = client.config.list
    configs.each do |cfg|
      parent_info = cfg.parent_id ? " (parent: #{cfg.parent_id})" : " (root)"
      puts "  #{cfg.id}#{parent_info}"
    end

    # get a config
    fetched = client.config.get("showcase-user-service")
    puts "Fetched: id=#{fetched.id}, name=#{fetched.name}"
    puts "  description=#{fetched.description}"
    puts "  parent=#{fetched.parent_id || "(none)"}"
    puts "  items: #{fetched.items.map(&:name)}"

    # delete configs
    user_service.delete
    shared.delete
    puts "Deleted configs"

    puts "Done!"
  ensure
    # Always tear down — even if an error above raised — so a failed run
    # never leaves orphaned configs for the next run.
    cleanup_management_showcase(client)
  end
end
