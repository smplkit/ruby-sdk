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

# JSON Logic filter — only forward +invoice.*+ actions.
# Events that don't match are recorded as +filtered_out+ deliveries.
# See https://jsonlogic.com for the full operator reference.
INVOICE_FILTER = { "in" => ["invoice.", { "var" => "action" }] }.freeze

# JSONata template — reshape the event payload before POSTing to the
# destination. This example flattens the event into a compact SIEM-style
# record. See https://jsonata.org for the full language reference.
SIEM_TRANSFORM = <<~JSONATA
  {
      "event": action,
      "subject": resource_type & ":" & resource_id,
      "ts": occurred_at,
      "actor": actor_label
  }
JSONATA

# create the client
manage = Smplkit::ManagementClient.new

begin
  forwarder_name = "showcase-#{SecureRandom.hex(3)}"

  # create a forwarder
  forwarder = manage.audit.forwarders.create(
    name: forwarder_name,
    forwarder_type: Smplkit::Audit::ForwarderType::HTTP,
    http: Smplkit::Audit::ForwarderHttp.new(
      method: "POST",
      url: "https://httpbin.org/post",
      headers: [Smplkit::Audit::HttpHeader.new(name: "X-Showcase", value: "ok")],
      success_status: "2xx"
    ),
    filter: INVOICE_FILTER,
    transform: SIEM_TRANSFORM
  )
  raise "name mismatch" unless forwarder.name == forwarder_name
  raise "expected enabled=true" unless forwarder.enabled == true
  raise "filter round-trip mismatch" unless forwarder.filter == INVOICE_FILTER
  raise "transform round-trip mismatch" unless forwarder.transform == SIEM_TRANSFORM

  puts "Created forwarder: #{forwarder.slug}"

  # fetch a forwarder
  fetched = manage.audit.forwarders.get(forwarder.id)
  raise "id mismatch" unless fetched.id == forwarder.id
  raise "name mismatch on get" unless fetched.name == forwarder_name
  raise "filter mismatch on get" unless fetched.filter == INVOICE_FILTER
  raise "transform mismatch on get" unless fetched.transform == SIEM_TRANSFORM

  puts "Fetched forwarder: #{fetched.name}"

  # list forwarders
  listed = manage.audit.forwarders.list
  raise "expected forwarder in list" unless listed.forwarders.any? { |f| f.id == forwarder.id }

  puts "Account has #{listed.forwarders.length} forwarder(s)"

  # update a forwarder
  renamed = "#{forwarder.name}-renamed"
  updated = manage.audit.forwarders.update(
    forwarder.id,
    name: renamed,
    forwarder_type: forwarder.forwarder_type,
    http: Smplkit::Audit::ForwarderHttp.new(
      method: "POST",
      url: "https://httpbin.org/post",
      headers: [Smplkit::Audit::HttpHeader.new(name: "X-Showcase", value: "ok")],
      success_status: "2xx"
    ),
    enabled: false,
    filter: INVOICE_FILTER,
    transform: SIEM_TRANSFORM
  )
  raise "rename failed" unless updated.name == renamed
  raise "expected enabled=false" unless updated.enabled == false

  puts "Updated forwarder: #{updated.name} (enabled=#{updated.enabled})"

  # delete a forwarder
  manage.audit.forwarders.delete(forwarder.id)
  remaining = manage.audit.forwarders.list
  raise "delete failed — forwarder still listed" if remaining.forwarders.any? { |f| f.id == forwarder.id }

  puts "Deleted forwarder: #{forwarder.slug}"

  puts "Done!"
ensure
  manage.close
end
