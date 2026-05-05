# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Logging.
#
# Usage:
#
#   bundle exec ruby examples/logging_management_showcase.rb

require "smplkit"
require_relative "setup/logging_management_setup"

manage = Smplkit::ManagementClient.new

begin
  setup_logging_management_showcase(manage)

  app_group = manage.log_groups.new_log_group(
    "showcase-service.app",
    name: "Showcase Service / App",
    level: Smplkit::LogLevel::INFO,
    description: "Application-level loggers"
  )
  app_group.save
  puts "Created log group: #{app_group.key}"

  db_group = manage.log_groups.new_log_group(
    "showcase-service.db",
    name: "Showcase Service / DB",
    level: Smplkit::LogLevel::WARN,
    description: "Database-related loggers",
    parent: app_group
  )
  db_group.save
  puts "Created log group: #{db_group.key}"

  groups = manage.log_groups.list
  puts "Found #{groups.length} log groups"

  loggers = manage.loggers.list
  puts "Found #{loggers.length} loggers"

  cleanup_logging_management_showcase(manage)
  puts "Done!"
ensure
  manage.close
end
