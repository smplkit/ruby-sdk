# frozen_string_literal: true

# Setup / cleanup helpers for flags_runtime_showcase.rb.

require "smplkit"

DEMO_FLAG_IDS = %w[checkout-v2 banner-color max-retries].freeze

def setup_runtime_showcase(client)
  cleanup_runtime_showcase(client)

  checkout = client.flags.new_boolean_flag(
    "checkout-v2",
    default: false,
    description: "Controls rollout of the new checkout experience."
  )
  checkout.enable_rules(environment: "production")
  checkout.add_rule(
    Smplkit::Rule.new("Enable for enterprise users in US region", environment: "production")
                 .when("user.plan", Smplkit::Op::EQ, "enterprise")
                 .when("account.region", Smplkit::Op::EQ, "us")
                 .serve(true)
  )
  checkout.add_rule(
    Smplkit::Rule.new("Enable for beta testers", environment: "production")
                 .when("user.beta_tester", Smplkit::Op::EQ, true)
                 .serve(true)
  )
  checkout.save

  banner = client.flags.new_string_flag(
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
  banner.enable_rules(environment: "production")
  banner.add_rule(
    Smplkit::Rule.new("Blue for enterprise users", environment: "production")
                 .when("user.plan", Smplkit::Op::EQ, "enterprise")
                 .serve("blue")
  )
  banner.add_rule(
    Smplkit::Rule.new("Green for technology companies", environment: "production")
                 .when("account.industry", Smplkit::Op::EQ, "technology")
                 .serve("green")
  )
  banner.save

  retries = client.flags.new_number_flag(
    "max-retries",
    default: 3,
    description: "Maximum number of API retries before failing."
  )
  retries.enable_rules(environment: "production")
  retries.add_rule(
    Smplkit::Rule.new("High retries for large accounts", environment: "production")
                 .when("account.employee_count", Smplkit::Op::GT, 100)
                 .serve(5)
  )
  retries.save
end

def cleanup_runtime_showcase(client)
  DEMO_FLAG_IDS.each do |flag_id|
    client.flags.delete(flag_id)
  rescue Smplkit::NotFoundError
    next
  end
end
