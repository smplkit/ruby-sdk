# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Flags.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/flags_management_showcase.rb

require "smplkit"
require_relative "setup/flags_management_setup"

Smplkit::Client.open do |client|
  setup_management_showcase(client)

  # create a boolean flag
  checkout_flag = client.flags.new_boolean_flag(
    "checkout-v2",
    default: false,
    description: "Controls rollout of the new checkout experience."
  )
  checkout_flag.save
  puts "Created flag: #{checkout_flag.id}"

  # create a string flag (constrained)
  banner_flag = client.flags.new_string_flag(
    "banner-color",
    default: "red",
    description: "Controls the banner color shown to users.",
    name: "Banner Color",
    values: [
      Smplkit::FlagValue.new(name: "Red", value: "red"),
      Smplkit::FlagValue.new(name: "Green", value: "green"),
      Smplkit::FlagValue.new(name: "Blue", value: "blue")
    ]
  )
  banner_flag.save
  puts "Created flag: #{banner_flag.id}"

  # create a numeric flag (unconstrained)
  retry_flag = client.flags.new_number_flag(
    "max-retries",
    default: 3,
    description: "Maximum number of API retries before failing."
  )
  retry_flag.save
  puts "Created flag: #{retry_flag.id}"

  # create a JSON flag (constrained)
  theme_flag = client.flags.new_json_flag(
    "ui-theme",
    default: { "mode" => "light", "accent" => "#0066cc" },
    description: "Controls the UI theme configuration.",
    values: [
      Smplkit::FlagValue.new(name: "Light", value: { "mode" => "light", "accent" => "#0066cc" }),
      Smplkit::FlagValue.new(name: "Dark", value: { "mode" => "dark", "accent" => "#66ccff" }),
      Smplkit::FlagValue.new(name: "High Contrast", value: { "mode" => "dark", "accent" => "#ffffff" })
    ]
  )
  theme_flag.save
  puts "Created flag: #{theme_flag.id}"

  # checkout_flag (serve true in production to enterprise US users)
  checkout_flag.enable_rules(environment: "production")
  checkout_flag.add_rule(
    Smplkit::Rule.new("Enable for enterprise users in US region", environment: "production")
                 .when("user.plan", Smplkit::Op::EQ, "enterprise")
                 .when("account.region", Smplkit::Op::EQ, "us")
                 .serve(true)
  )

  # checkout_flag (serve true in production for beta testers)
  checkout_flag.add_rule(
    Smplkit::Rule.new("Enable for beta testers", environment: "production")
                 .when("user.beta_tester", Smplkit::Op::EQ, true)
                 .serve(true)
  )

  checkout_flag.save
  puts "Updated flag: #{checkout_flag.id}"

  # list flags
  flags = client.flags.list
  puts "Total flags: #{flags.length}"
  flags.each do |f|
    envs = f.environments ? f.environments.keys : []
    puts "  #{f.id} (#{f.type}) — default=#{f.default}, environments=#{envs}"
  end

  # get a flag
  fetched = client.flags.get("checkout-v2")
  puts "\nFetched by id: #{fetched.id}"
  prod_rules = fetched.environments["production"].rules.length
  prod_enabled = fetched.environments["production"].enabled
  puts "  production rules: #{prod_rules}"
  puts "  production enabled: #{prod_enabled}"

  # update a flag
  banner_flag.add_value(Smplkit::FlagValue.new(name: "Purple", value: "purple"))
  banner_flag.default = "blue"
  banner_flag.description = "Controls the banner color — updated"
  banner_flag.add_rule(
    Smplkit::Rule.new("Purple for enterprise users", environment: "production")
                 .when("user.plan", Smplkit::Op::EQ, "enterprise")
                 .serve("purple")
  )
  banner_flag.save
  puts "Updated flag: #{banner_flag.id}'"

  # delete all the rules of a flag
  checkout_flag.clear_rules(environment: "production")
  checkout_flag.save
  puts "Updated flag: #{checkout_flag.id}'"

  # clear values (flag becomes unconstrained)
  banner_flag.clear_values
  banner_flag.save
  puts "Updated flag: #{banner_flag.id}'"

  # delete flags
  client.flags.delete("checkout-v2")
  banner_flag.delete
  puts "Deleted flags"

  # cleanup
  cleanup_management_showcase(client)
  puts "Done!"
end
