# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Audit.
#
# Audit is a fire-and-forget event-recording surface. +create+ enqueues
# the event onto an in-memory bounded buffer and returns immediately;
# the buffer worker retries with exponential backoff on transient
# failures and drops oldest under back-pressure (ADR-047 §2.6).
# Reads (+get+, +list+) are synchronous on the wire.
#
# Mirrors examples/audit_runtime_showcase.py from the Python SDK.
#
# Usage:
#
#   bundle exec ruby examples/audit_runtime_showcase.rb

require "securerandom"
require "smplkit"

Smplkit::Client.open(environment: "production", service: "showcase-service") do |client|
  # unique resource id so we can find back exactly the events this
  # showcase wrote, regardless of what other history exists.
  resource_id = "showcase-#{SecureRandom.hex(4)}"

  # 1) fire-and-forget create — returns immediately. The actual POST
  #    happens on the buffer worker. Customer events must NOT use a
  #    +resource_type+ beginning with +"smpl."+ — that namespace is
  #    reserved for smplkit-emitted events; the server returns 403.
  client.audit.events.create(
    action: "invoice.created",
    resource_type: "invoice",
    resource_id: resource_id,
    occurred_at: Time.now.utc,
    snapshot: { "total_cents" => 4900, "currency" => "USD" },
    data: { "request_id" => "req-abc" }
  )

  # 2) caller-supplied idempotency key — replaying with the same key
  #    returns the original event (server dedupes on
  #    account_id + idempotency_key).
  idempotency_key = "showcase-#{SecureRandom.uuid}"
  2.times do
    client.audit.events.create(
      action: "invoice.updated",
      resource_type: "invoice",
      resource_id: resource_id,
      snapshot: { "total_cents" => 5400 },
      idempotency_key: idempotency_key
    )
  end

  # 3) flush — block until the in-memory buffer drains so that the
  #    events we just wrote are durable before we read them.
  client.audit.events.flush(timeout: 5.0)

  # 4) list — server-side filters per ADR-047 §4.  Cursor pagination
  #    via +page_size+ / +page_after+; +page.next_cursor+ is non-nil
  #    when more pages exist.
  page = client.audit.events.list(
    resource_type: "invoice",
    resource_id: resource_id,
    page_size: 10
  )
  puts "Found #{page.events.length} events for #{resource_id}:"
  page.events.each do |ev|
    puts "  #{ev.action}  id=#{ev.id}  actor=#{ev.actor_type}"
  end

  # idempotency dedupe check — 3 creates (1 distinct + 2 with the same
  # idempotency key) so we expect exactly 2 events.
  raise "Expected 2 events (idempotency dedup), got #{page.events.length}" \
    unless page.events.length == 2

  # 5) get — read a single event by id.
  first = client.audit.events.get(page.events[0].id)
  puts "Round-tripped: #{first.action} at #{first.occurred_at}"

  puts "Done!"
end
