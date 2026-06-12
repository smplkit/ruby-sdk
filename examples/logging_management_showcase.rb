# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Logging.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/logging_management_showcase.rb

require "smplkit"
require_relative "setup/logging_management_setup"

Smplkit::Client.open do |client|
  setup_management_showcase(client)

  # create a parent logger with a default level
  root = client.logging.loggers.new("showcase")
  root.set_level(Smplkit::LogLevel::INFO)
  root.save
  puts "Created: #{root.id} (level=#{root.level})"
  raise unless root.level == Smplkit::LogLevel::INFO

  # child logger with no level (inherits from parent)
  db = client.logging.loggers.new("showcase.db")
  db.save
  puts "Created: #{db.id} (inherits)"
  raise unless db.level.nil?

  # child logger with explicit level (overrides parent)
  payments = client.logging.loggers.new("showcase.payments")
  payments.set_level(Smplkit::LogLevel::WARN)
  payments.save
  puts "Created: #{payments.id} (level=#{payments.level})"
  raise unless payments.level == Smplkit::LogLevel::WARN

  # override log level for the production environment
  root.set_level(Smplkit::LogLevel::ERROR, environment: "production")
  root.save
  puts "Set environment overrides: #{root.environments}"
  raise unless root.environments["production"].level == Smplkit::LogLevel::ERROR

  # clear environment override (inherits from the default level again)
  root.clear_level(environment: "production")
  root.save
  puts "Cleared production override: #{root.environments}"
  raise if root.environments.key?("production")

  # get a logger
  fetched = client.logging.loggers.get("showcase")
  raise unless fetched.level == Smplkit::LogLevel::INFO

  cleanup_management_showcase(client)
  puts "Done!"
end
