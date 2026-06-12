# frozen_string_literal: true

# Demonstrates the smplkit SDK for Smpl Audit.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/audit_showcase.rb

require "securerandom"
require "smplkit"

# JSON Logic filter — only forward +invoice.*+ event types. Events that don't
# match the filter aren't forwarded (and produce no delivery record).
# See https://jsonlogic.com for the full operator reference.
INVOICE_FILTER = { "in" => ["invoice.", { "var" => "event_type" }] }.freeze

# JSONata template — reshape the event payload before POSTing to the
# destination. This example flattens the event into a compact SIEM-style
# record. See https://jsonata.org for the full language reference.
SIEM_TRANSFORM = <<~JSONATA
  {
      "event": event_type,
      "subject": resource_type & ":" & resource_id,
      "ts": occurred_at,
      "actor": actor_label
  }
JSONATA

Smplkit::Client.open(environment: "production") do |client|
  some_resource_id = "showcase-#{SecureRandom.hex(4)}"

  # ----- Events: record / list / get --------------------------------

  # record an event
  client.audit.events.record(
    actor_id: "billing-bot:42",
    actor_label: "finance@example.com",
    actor_type: "USER",
    data: {
      "snapshot" => { "total_cents" => 4900, "currency" => "USD" },
      "request_id" => "req-abc"
    },
    event_type: "invoice.created",
    occurred_at: Time.now.utc,
    resource_id: some_resource_id,
    resource_type: "invoice"
  )
  client.audit.events.flush(timeout: 5.0) # or omit to have events flushed asynchronously
  puts "Recorded event for invoice #{some_resource_id}"

  # list events
  page = client.audit.events.list(resource_type: "invoice", resource_id: some_resource_id)
  raise unless page.events.any? { |e| e.resource_id == some_resource_id }

  recorded_event_id = page.events[0].id
  puts "Listed #{page.events.length} event(s) for invoice #{some_resource_id}"

  # fetch an event
  event = client.audit.events.get(recorded_event_id)
  raise unless event.id == recorded_event_id
  raise unless event.resource_id == some_resource_id
  raise unless event.event_type == "invoice.created"
  raise unless event.actor_id == "billing-bot:42"
  raise unless event.actor_label == "finance@example.com"

  puts "Fetched event #{event.id}: #{event.event_type} by #{event.actor_label} in #{event.environment}"

  # ----- Discovery: distinct resource_types / event_types / categories

  resource_types = client.audit.resource_types.list
  raise unless resource_types.resource_types.any? { |rt| rt.id == "invoice" }

  puts "Observed resource types: #{resource_types.resource_types.map(&:id)}"

  event_types = client.audit.event_types.list
  raise unless event_types.event_types.any? { |et| et.id == "invoice.created" }

  puts "Observed event types: #{event_types.event_types.map(&:id)}"

  categories = client.audit.categories.list
  puts "Observed categories: #{categories.categories.map(&:id)}"

  # ----- Forwarders: SIEM streaming CRUD ----------------------------

  forwarder_id = "showcase-#{SecureRandom.hex(3)}"

  begin
    # create a forwarder (disabled by default)
    forwarder = client.audit.forwarders.new(
      forwarder_id,
      configuration: Smplkit::Audit::HttpConfiguration.new(
        headers: [Smplkit::Audit::HttpHeader.new(name: "X-Showcase", value: "ok")],
        method: Smplkit::Audit::HttpMethod::POST,
        url: "https://example.com"
      ),
      filter: INVOICE_FILTER,
      forwarder_type: Smplkit::Audit::ForwarderType::HTTP,
      transform: SIEM_TRANSFORM,
      transform_type: Smplkit::Audit::TransformType::JSONATA
    )
    forwarder.save
    puts "Created forwarder: #{forwarder.name} (id=#{forwarder.id})"

    # list forwarders
    listed = client.audit.forwarders.list
    raise unless listed.forwarders.any? { |f| f.id == forwarder.id }

    puts "Account has #{listed.forwarders.length} forwarder(s)"

    # get a forwarder
    forwarder = client.audit.forwarders.get(forwarder_id)
    puts "Fetched forwarder: #{forwarder.name} (id=#{forwarder.id})"
    raise unless forwarder.id == forwarder_id

    # configure where to forward events in production
    forwarder.set_configuration(
      Smplkit::Audit::HttpConfiguration.new(
        headers: [Smplkit::Audit::HttpHeader.new(name: "X-Showcase", value: "ok")],
        method: Smplkit::Audit::HttpMethod::POST,
        url: "https://httpbin.org/post"
      ),
      environment: "production"
    )
    forwarder.save
    raise unless forwarder.environments["production"].configuration.url == "https://httpbin.org/post"

    puts "Updated forwarder: #{forwarder.name}"

    # start forwarding events in production
    forwarder.set_enabled(true, environment: "production")
    forwarder.save
    puts "Enabled forwarder #{forwarder.name} (id=#{forwarder.id}) to start forwarding events in production"

    # delete a forwarder
    forwarder.delete
    remaining = client.audit.forwarders.list
    raise unless remaining.forwarders.none? { |f| f.id == forwarder_id }

    puts "Deleted forwarder: #{forwarder.name}"
  ensure
    # tear-down: never leave the showcase forwarder behind, even on failure
    begin
      client.audit.forwarders.delete(forwarder_id)
    rescue Smplkit::NotFoundError
      nil
    end
  end

  puts "Done!"
end
