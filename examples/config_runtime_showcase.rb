# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Config.
#
# Usage:
#
#   bundle exec ruby examples/config_runtime_showcase.rb

require "smplkit"
require_relative "setup/config_runtime_setup"

Smplkit::Client.open(environment: "staging", service: "showcase-service") do |client|
  setup_config_runtime_showcase(client.manage)
  client.wait_until_ready

  api_host = client.config.get_string("api.host", default: "fallback.example.com",
                                                  config: "showcase-service-config")
  api_timeout = client.config.get_number("api.timeout_ms", default: 1000,
                                                           config: "showcase-service-config")
  beta = client.config.get_boolean("feature.beta", default: false,
                                                   config: "showcase-service-config")

  puts "api.host = #{api_host}"
  puts "api.timeout_ms = #{api_timeout}"
  puts "feature.beta = #{beta}"

  raise "Expected staging override" unless api_host == "staging.example.com"
  raise "Expected timeout 5000" unless api_timeout.to_i == 5000

  client.config.on_change do |event|
    puts "    config '#{event.key}' updated via #{event.source}"
  end

  cleanup_config_runtime_showcase(client.manage)
  puts "Done!"
end
