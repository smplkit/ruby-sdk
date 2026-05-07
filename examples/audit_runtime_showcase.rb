# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Audit.
#
# Mirrors examples/audit_runtime_showcase.py from the Python SDK.
#
# Usage:
#
#   bundle exec ruby examples/audit_runtime_showcase.rb

require "securerandom"
require "smplkit"

# create the client
Smplkit::Client.open(environment: "production", service: "showcase-service") do |client|
  # record an event
  some_resource_id = "showcase-#{SecureRandom.hex(4)}"
  client.audit.events.record(
    action: "invoice.created",
    resource_type: "invoice",
    resource_id: some_resource_id,
    occurred_at: Time.now.utc,
    snapshot: { "total_cents" => 4900, "currency" => "USD" },
    data: { "request_id" => "req-abc" }
  )

  # force the event to be posted (normally happens automatically, in the
  # background, but we want to force it to be written now for this demo)
  client.audit.events.flush(timeout: 0.2)

  # list events
  page = client.audit.events.list(
    resource_type: "invoice",
    resource_id: some_resource_id,
    page_size: 10
  )
  puts "Found #{page.events.length} events for #{some_resource_id}:"
  page.events.each do |ev|
    puts "  #{ev.action}  id=#{ev.id}  actor=#{ev.actor_type}"
  end

  raise "Expected 1 event, got #{page.events.length}" unless page.events.length == 1

  # fetch an event by ID
  first = client.audit.events.get(page.events[0].id)
  puts "Round-tripped: #{first.action} at #{first.occurred_at}"

  puts "Done!"
end
