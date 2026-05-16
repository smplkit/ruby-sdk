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

  # record an event
  client.audit.events.record(
    action: "invoice.created",
    resource_type: "invoice",
    resource_id: some_resource_id,
    occurred_at: Time.now.utc,
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
  raise "action mismatch" unless event.action == "invoice.created"

  puts "Fetched event #{event.id}: #{event.action}"

  # list resource types observed
  resource_types = client.audit.resource_types.list
  raise "expected 'invoice' in resource types" unless resource_types.resource_types.any? { |rt| rt.id == "invoice" }

  puts "Observed resource types: #{resource_types.resource_types.map(&:id)}"

  # list actions observed
  actions = client.audit.actions.list
  raise "expected 'invoice.created' in actions" unless actions.actions.any? { |a| a.id == "invoice.created" }

  puts "Observed actions: #{actions.actions.map(&:id)}"

  puts "Done!"
end
