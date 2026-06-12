# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Logging.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/logging_runtime_showcase.rb

require "smplkit"

Smplkit::Client.open do |client|
  client.logging.install
  puts "All loggers are now controlled by smplkit"
end
