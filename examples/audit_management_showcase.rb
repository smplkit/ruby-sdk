# frozen_string_literal: true

# Demonstrates the smplkit management SDK for Smpl Audit.
#
# Prerequisites:
#   - +gem install smplkit+
#   - A valid smplkit API key, provided via one of:
#       - +SMPLKIT_API_KEY+ environment variable
#       - +~/.smplkit+ configuration file (see SDK docs)
#
# Usage:
#
#   bundle exec ruby examples/audit_management_showcase.rb

require "securerandom"
require "smplkit"

# JSON Logic filter — only forward +invoice.*+ event types.
# Events that don't match the filter aren't forwarded (and produce no delivery record).
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

# create the client
manage = Smplkit::ManagementClient.new

begin
  forwarder_id = "showcase-#{SecureRandom.hex(3)}"

  # create a new forwarder
  forwarder = manage.audit.forwarders.new_forwarder(
    forwarder_id,
    forwarder_type: Smplkit::Audit::ForwarderType::HTTP,
    configuration: Smplkit::Audit::HttpConfiguration.new(
      method: Smplkit::Audit::HttpMethod::POST,
      url: "https://httpbin.org/post",
      headers: [Smplkit::Audit::HttpHeader.new(name: "X-Showcase", value: "ok")]
    ),
    filter: INVOICE_FILTER,
    transform_type: Smplkit::Audit::TransformType::JSONATA,
    transform: SIEM_TRANSFORM
  )
  forwarder.save
  puts "Created forwarder: #{forwarder.name} (id=#{forwarder.id})"

  # list forwarders
  listed = manage.audit.forwarders.list
  raise "expected forwarder in list" unless listed.forwarders.any? { |f| f.id == forwarder.id }

  puts "Account has #{listed.forwarders.length} forwarder(s)"

  # get a forwarder
  fetched = manage.audit.forwarders.get(forwarder.id)
  raise "id mismatch" unless fetched.id == forwarder.id
  raise "expected enabled=true" unless fetched.enabled == true

  puts "Fetched forwarder: #{fetched.name}"

  # update a forwarder
  fetched.enabled = false
  fetched.save
  raise "expected enabled=false" unless fetched.enabled == false

  puts "Disabled forwarder: #{fetched.name} (enabled=#{fetched.enabled})"

  # delete a forwarder
  fetched.delete
  remaining = manage.audit.forwarders.list
  raise "delete failed — forwarder still listed" if remaining.forwarders.any? { |f| f.id == fetched.id }

  puts "Deleted forwarder: #{fetched.name}"

  puts "Done!"
ensure
  manage.close
end
