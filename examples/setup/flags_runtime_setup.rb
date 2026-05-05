# frozen_string_literal: true

# Setup / cleanup helpers for flags_runtime_showcase.rb.
#
# Mirrors examples/setup/flags_runtime_setup.py from the Python SDK.

DEMO_ENVIRONMENTS = %w[staging production].freeze
DEMO_FLAG_IDS = %w[checkout-v2 banner-color max-retries].freeze

def setup_runtime_showcase(manage)
  existing = manage.environments.list.map(&:key).to_set
  DEMO_ENVIRONMENTS.each do |env_id|
    next if existing.include?(env_id)

    manage.environments.new(env_id, name: env_id.capitalize).save
  end
  cleanup_runtime_showcase(manage)

  checkout = manage.flags.new_boolean_flag(
    "checkout-v2",
    default: false,
    description: "Controls rollout of the new checkout experience."
  )
  checkout.enable_rules(environment: "staging")
  checkout.add_rule(
    Smplkit::Rule.new("Enable for enterprise users in US region", environment: "staging")
                 .when("user.plan", Smplkit::Op::EQ, "enterprise")
                 .when("account.region", Smplkit::Op::EQ, "us")
                 .serve(true)
  )
  checkout.add_rule(
    Smplkit::Rule.new("Enable for beta testers", environment: "staging")
                 .when("user.beta_tester", Smplkit::Op::EQ, true)
                 .serve(true)
  )
  checkout.disable_rules(environment: "production")
  checkout.set_default(false, environment: "production")
  checkout.save

  banner = manage.flags.new_string_flag(
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
  banner.enable_rules(environment: "staging")
  banner.add_rule(
    Smplkit::Rule.new("Blue for enterprise users", environment: "staging")
                 .when("user.plan", Smplkit::Op::EQ, "enterprise")
                 .serve("blue")
  )
  banner.add_rule(
    Smplkit::Rule.new("Green for technology companies", environment: "staging")
                 .when("account.industry", Smplkit::Op::EQ, "technology")
                 .serve("green")
  )
  banner.enable_rules(environment: "production")
  banner.set_default("blue", environment: "production")
  banner.save

  retries = manage.flags.new_number_flag(
    "max-retries",
    default: 3,
    description: "Maximum number of API retries before failing."
  )
  retries.enable_rules(environment: "staging")
  retries.add_rule(
    Smplkit::Rule.new("High retries for large accounts", environment: "staging")
                 .when("account.employee_count", Smplkit::Op::GT, 100)
                 .serve(5)
  )
  retries.enable_rules(environment: "production")
  retries.save
end

def cleanup_runtime_showcase(manage)
  DEMO_FLAG_IDS.each do |flag_id|
    manage.flags.delete(flag_id)
  rescue Smplkit::NotFoundError
    next
  end
end
