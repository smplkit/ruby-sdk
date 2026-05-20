# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Audit.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/audit_runtime_showcase.rb

require "securerandom"
require "smplkit"

# create the client
Smplkit::Client.open(environment: "production", service: "showcase-service") do |client|
  some_resource_id = "showcase-#{SecureRandom.hex(4)}"

  # record an event with full customer-supplied actor attribution
  client.audit.events.record(
    event_type: "invoice.created",
    resource_type: "invoice",
    resource_id: some_resource_id,
    occurred_at: Time.now.utc,
    actor_type: "USER",
    actor_id: "billing-bot:42",
    actor_label: "finance@example.com",
    data: {
      "snapshot" => { "total_cents" => 4900, "currency" => "USD" },
      "request_id" => "req-abc"
    }
  )
  client.audit.events.flush(timeout: 5.0) # or omit to have events flushed asynchronously
  puts "Recorded events for invoice #{some_resource_id}"

  # list events
  page = client.audit.events.list(resource_type: "invoice", resource_id: some_resource_id)
  raise "expected event for #{some_resource_id}" unless page.events.any? { |e| e.resource_id == some_resource_id }

  recorded_event_id = page.events[0].id
  puts "Listed #{page.events.length} event(s) for invoice #{some_resource_id}"

  # fetch an event
  event = client.audit.events.get(recorded_event_id)
  raise "id mismatch" unless event.id == recorded_event_id
  raise "resource_id mismatch" unless event.resource_id == some_resource_id
  raise "event_type mismatch" unless event.event_type == "invoice.created"
  raise "actor_id mismatch" unless event.actor_id == "billing-bot:42"
  raise "actor_label mismatch" unless event.actor_label == "finance@example.com"

  puts "Fetched event #{event.id}: #{event.event_type} by #{event.actor_label}"

  # list resource types observed
  resource_types = client.audit.resource_types.list
  raise "expected 'invoice' in resource types" unless resource_types.resource_types.any? { |rt| rt.id == "invoice" }

  puts "Observed resource types: #{resource_types.resource_types.map(&:id)}"

  # list event types observed
  event_types = client.audit.event_types.list
  unless event_types.event_types.any? { |a| a.id == "invoice.created" }
    raise "expected 'invoice.created' in event types"
  end

  puts "Observed event types: #{event_types.event_types.map(&:id)}"

  puts "Done!"
end
