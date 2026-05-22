# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Logging.
#
# Mirrors examples/logging_runtime_showcase.py from the Python SDK.
#
# Usage:
#
#   bundle exec ruby examples/logging_runtime_showcase.rb

require "logger"
require "smplkit"

# A regular Ruby Logger instance — the exact thing a customer would already
# have in production.
app_logger = Logger.new($stdout)
app_logger.level = Logger::INFO

Smplkit::Client.open(environment: "production", service: "showcase-service") do |client|
  client.logging.install
  client.wait_until_ready

  app_logger.info("hello from showcase-service")
  app_logger.warn("a warning")

  loggers = client.logging.list
  puts "Tracked #{loggers.length} loggers via the smplkit Logging service"

  puts "Done!"
end
