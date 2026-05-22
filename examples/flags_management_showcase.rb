# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Flags.
#
# Mirrors examples/flags_management_showcase.py from the Python SDK,
# adapted to the single +Smplkit::ManagementClient+ (no async pair) per
# ADR-046 §2.2.
#
# Usage:
#
#   bundle exec ruby examples/flags_management_showcase.rb

require "smplkit"
require_relative "setup/flags_management_setup"

manage = Smplkit::ManagementClient.new

begin
  setup_management_showcase(manage)

  checkout_flag = manage.flags.new_boolean_flag(
    "checkout-v2",
    default: false,
    description: "Controls rollout of the new checkout experience."
  )
  checkout_flag.save
  puts "Created flag: #{checkout_flag.id}"

  banner_flag = manage.flags.new_string_flag(
    "banner-color",
    default: "red",
    name: "Banner Color",
    description: "Controls the banner color shown to users.",
    values: [
      Smplkit::FlagValue.new(name: "Red", value: "red"),
      Smplkit::FlagValue.new(name: "Green", value: "green"),
      Smplkit::FlagValue.new(name: "Blue", value: "blue")
    ]
  )
  banner_flag.save
  puts "Created flag: #{banner_flag.id}"

  retry_flag = manage.flags.new_number_flag(
    "max-retries",
    default: 3,
    description: "Maximum number of API retries before failing."
  )
  retry_flag.save
  puts "Created flag: #{retry_flag.id}"

  fetched = manage.flags.get("checkout-v2")
  fetched.enable_rules(environment: "production")
  fetched.add_rule(
    Smplkit::Rule.new("Enable for enterprise users", environment: "production")
                 .when("user.plan", Smplkit::Op::EQ, "enterprise")
                 .serve(true)
  )
  fetched.save
  puts "Updated flag: #{fetched.id}"

  flags = manage.flags.list
  puts "Found #{flags.length} flags"

  cleanup_management_showcase(manage)
  puts "Done!"
ensure
  manage.close
end
