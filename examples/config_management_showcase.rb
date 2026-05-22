# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Config.
#
# Usage:
#
#   bundle exec ruby examples/config_management_showcase.rb

require "smplkit"
require_relative "setup/config_management_setup"

manage = Smplkit::ManagementClient.new

begin
  setup_config_management_showcase(manage)

  defaults = manage.config.new_config("platform-defaults", description: "Org defaults")
  defaults.set_string("api.host", "default.example.com")
  defaults.set_number("api.timeout_ms", 5000)
  defaults.save
  puts "Created config: #{defaults.key}"

  service_cfg = manage.config.new_config("showcase-service-config", parent: defaults,
                                                                    description: "Showcase service overrides")
  service_cfg.set_string("api.host", "prod.example.com", environment: "production")
  service_cfg.set_boolean("feature.beta", false)
  service_cfg.save
  puts "Created config: #{service_cfg.key}"

  fetched = manage.config.get("showcase-service-config")
  puts "Fetched config: #{fetched.key} (parent=#{fetched.parent_id})"

  configs = manage.config.list
  puts "Found #{configs.length} configs"

  cleanup_config_management_showcase(manage)
  puts "Done!"
ensure
  manage.close
end
