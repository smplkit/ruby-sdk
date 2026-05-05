# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Flags.
#
# Prerequisites:
#   - +bundle add smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/flags_runtime_showcase.rb

require "smplkit"
require_relative "setup/flags_runtime_setup"

# ---------------------------------------------------------------------------
# Note: this showcase calls client.set_context(...) inline to demonstrate
# context-driven flag evaluation. In a real app (Rails, Sinatra, Hanami,
# Roda, etc.), set_context is called once per request from middleware - not
# scattered through your handlers.
# ---------------------------------------------------------------------------

ALICE = {
  "beta_tester" => true,
  "email" => "alice.adams@acme.com",
  "first_name" => "Alice",
  "last_name" => "Adams",
  "plan" => "enterprise"
}.freeze

BOB = {
  "beta_tester" => false,
  "email" => "bob.jones@acme.com",
  "first_name" => "Bob",
  "last_name" => "Jones",
  "plan" => "free"
}.freeze

LARGE_TECH_ACCOUNT = {
  "employee_count" => 500,
  "id" => 1234,
  "industry" => "technology",
  "region" => "us"
}.freeze

SMALL_RETAIL_ACCOUNT = {
  "employee_count" => 10,
  "id" => 5678,
  "industry" => "retail",
  "region" => "eu"
}.freeze

def make_context(user, account)
  [
    Smplkit::Context.new(
      "user", user["email"],
      beta_tester: user["beta_tester"],
      first_name: user["first_name"],
      last_name: user["last_name"],
      plan: user["plan"]
    ),
    Smplkit::Context.new(
      "account", account["id"].to_s,
      industry: account["industry"],
      region: account["region"],
      employee_count: account["employee_count"]
    )
  ]
end

Smplkit::Client.open(environment: "staging", service: "showcase-service") do |client|
  setup_runtime_showcase(client.manage)
  client.wait_until_ready

  checkout_v2 = client.flags.boolean_flag("checkout-v2", default: false)
  banner_color = client.flags.string_flag("banner-color", default: "red")
  max_retries = client.flags.number_flag("max-retries", default: 3)

  all_changes = []
  banner_changes = []

  client.flags.on_change do |event|
    all_changes << { id: event.id, source: event.source }
    puts "    Global flag listener: '#{event.id}' updated via #{event.source}"
  end

  client.flags.on_change("banner-color") do |event|
    banner_changes << event
    puts "    banner-color flag changed!"
  end

  # request 1 - Alice from a large tech account
  client.set_context(make_context(ALICE, LARGE_TECH_ACCOUNT)) do
    checkout_result = checkout_v2.get
    puts "checkout-v2 = #{checkout_result}"
    raise "Expected true, got #{checkout_result}" unless checkout_result == true

    banner_result = banner_color.get
    puts "banner-color = #{banner_result}"
    raise "Expected 'blue', got #{banner_result}" unless banner_result == "blue"

    retries_result = max_retries.get
    puts "max-retries = #{retries_result}"
    raise "Expected 5, got #{retries_result}" unless retries_result == 5
  end

  # request 2 - Bob from a small retail account
  client.set_context(make_context(BOB, SMALL_RETAIL_ACCOUNT)) do
    checkout_result_2 = checkout_v2.get
    puts "checkout-v2 = #{checkout_result_2}"
    raise "Expected false" unless checkout_result_2 == false

    banner_result_2 = banner_color.get
    puts "banner-color = #{banner_result_2}"
    raise "Expected 'red'" unless banner_result_2 == "red"

    retries_result_2 = max_retries.get
    puts "max-retries = #{retries_result_2}"
    raise "Expected 3" unless retries_result_2 == 3

    # nested scoped override - temporarily impersonate Alice without
    # disturbing the surrounding request's context.
    client.set_context(make_context(ALICE, LARGE_TECH_ACCOUNT)) do
      scoped_result = checkout_v2.get
      puts "checkout-v2 (scoped: Alice) = #{scoped_result}"
      raise "Expected true" unless scoped_result == true
    end

    # context auto-reverted to Bob/small retail here
    raise "Expected false" unless checkout_v2.get == false
  end

  # explicit context (no surrounding set_context)
  explicit_result = checkout_v2.get(context: [
                                      Smplkit::Context.new("user", "john.smith@acme.com", plan: "free",
                                                                                          beta_tester: false),
                                      Smplkit::Context.new("account", "1111", region: "jp")
                                    ])
  puts "checkout-v2 (free, JP) = #{explicit_result}"
  raise "Expected false" unless explicit_result == false

  # simulate someone making changes to a flag to trigger listeners
  current_banner = client.manage.flags.get("banner-color")
  current_banner.add_rule(
    Smplkit::Rule.new("Red for small companies", environment: "staging")
                 .when("account.employee_count", Smplkit::Op::LT, 50)
                 .serve("red")
  )
  current_banner.save

  # wait a moment for the event to be delivered
  sleep(0.2)

  raise "Expected at least one global change" if all_changes.empty?
  raise "Expected at least one banner change" if banner_changes.empty?

  cleanup_runtime_showcase(client.manage)
  puts "Done!"
end
