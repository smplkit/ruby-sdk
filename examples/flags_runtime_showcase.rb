# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Flags.
#
# Prerequisites:
#   - +gem install smplkit+
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
# context-driven flag evaluation.  In a real app (Rails, Sinatra, Hanami,
# etc.), set_context is called once per request from middleware — not
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

LARGE_TECHNOLOGY_ACCOUNT = {
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

# Create context within which flags will be evaluated.
def create_context(user, account)
  [
    Smplkit::Context.new(
      "user", user["email"],
      beta_tester: user["beta_tester"], first_name: user["first_name"],
      last_name: user["last_name"], plan: user["plan"]
    ),
    Smplkit::Context.new(
      "account", account["id"].to_s,
      industry: account["industry"], region: account["region"],
      employee_count: account["employee_count"]
    )
  ]
end

def update_rules(client)
  current_banner = client.flags.get("banner-color")
  current_banner.add_rule(
    Smplkit::Rule.new("Red for small companies", environment: "production")
                 .when("account.employee_count", Smplkit::Op::LT, 50)
                 .serve("red")
  )
  current_banner.save
end

Smplkit::Client.open(environment: "production", service: "showcase-service") do |client|
  setup_runtime_showcase(client)
  client.wait_until_ready

  # declare flags - default values will be used if the flag does not exist or
  # smplkit is unreachable
  checkout_v2 = client.flags.boolean_flag("checkout-v2", default: false)
  banner_color = client.flags.string_flag("banner-color", default: "red")
  max_retries = client.flags.number_flag("max-retries", default: 3)

  all_changes = []
  banner_changes = []

  # global listener — fires when ANY flag definition changes
  client.flags.on_change do |event|
    all_changes << { id: event.id, source: event.source }
    puts "    Global flag listener: '#{event.id}' updated via #{event.source}"
  end

  # flag listener — fires only when a specific flag changes
  client.flags.on_change("banner-color") do |event|
    banner_changes << event
    puts "    banner-color flag changed!"
  end

  # request 1 — Alice from a large tech account
  client.set_context(create_context(ALICE, LARGE_TECHNOLOGY_ACCOUNT)) do
    checkout_result = checkout_v2.get
    puts "checkout-v2 = #{checkout_result}"
    raise "Expected true, got #{checkout_result}" unless checkout_result == true
    raise "Expected boolean return type" unless [true, false].include?(checkout_result)

    banner_result = banner_color.get
    puts "banner-color = #{banner_result}"
    raise "Expected 'blue', got #{banner_result}" unless banner_result == "blue"
    raise "Expected String return type" unless banner_result.is_a?(String)

    retries_result = max_retries.get
    puts "max-retries = #{retries_result}"
    raise "Expected 5, got #{retries_result}" unless retries_result == 5
  end

  # request 2 — Bob from a small retail account
  client.set_context(create_context(BOB, SMALL_RETAIL_ACCOUNT)) do
    checkout_result2 = checkout_v2.get
    puts "checkout-v2 = #{checkout_result2}"
    raise unless checkout_result2 == false

    banner_result2 = banner_color.get
    puts "banner-color = #{banner_result2}"
    raise unless banner_result2 == "red"

    retries_result2 = max_retries.get
    puts "max-retries = #{retries_result2}"
    raise unless retries_result2 == 3

    # nested scoped override — temporarily impersonate Alice without disturbing
    # the surrounding request's context.
    client.set_context(create_context(ALICE, LARGE_TECHNOLOGY_ACCOUNT)) do
      scoped_result = checkout_v2.get
      puts "checkout-v2 (scoped: Alice) = #{scoped_result}"
      raise unless scoped_result == true
    end

    # context auto-reverted to Bob/small retail here
    raise unless checkout_v2.get == false
  end

  # get a flag's value (explicitly pass context)
  explicit_result = checkout_v2.get(
    context: [
      Smplkit::Context.new("user", "john.smith@acme.com", plan: "free", beta_tester: false),
      Smplkit::Context.new("account", "1111", region: "jp")
    ]
  )
  puts "checkout-v2 (free, JP) = #{explicit_result}"
  raise unless explicit_result == false

  # simulate someone making changes to a flag to trigger listeners
  update_rules(client)

  # wait a moment for the event to be delivered (typical push round-trip is well
  # under 200ms; 400ms is plenty of headroom and anything past that is a real
  # signal, not noise to absorb).
  sleep(0.4)

  # verify both listeners fired
  raise "Expected at least one global change, got #{all_changes.length}" unless all_changes.length >= 1
  raise "Expected at least one banner change, got #{banner_changes.length}" unless banner_changes.length >= 1

  cleanup_runtime_showcase(client)
  puts "Done!"
end
