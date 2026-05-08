# frozen_string_literal: true

# Demonstrates the smplkit runtime SDK for Smpl Audit.
#
# Covers: event record / list / get, plus the SIEM forwarders surface
# (create / list / delete + the test_forwarder.execute proxy + a
# do_not_forward event flow). The forwarders portion gracefully skips
# on 402 (free / standard tier) so the showcase remains runnable in
# any environment.
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
    data: {
      "snapshot" => { "total_cents" => 4900, "currency" => "USD" },
      "request_id" => "req-abc"
    }
  )

  # force the event to be posted (normally happens automatically, in the
  # background, but we want to force it to be written now for this demo)
  client.audit.events.flush(timeout: 2.0)

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

  # Forwarders (Pro tier — gracefully skip on 402)
  fwd = nil
  begin
    fwd = client.audit.forwarders.create(
      name: "showcase-#{SecureRandom.hex(3)}",
      forwarder_type: "http",
      http: Smplkit::Audit::ForwarderHttp.new(
        url: "https://httpbin.org/post",
        headers: [Smplkit::Audit::HttpHeader.new(name: "X-Showcase", value: "ok")]
      )
    )
    puts "Created forwarder: #{fwd.slug}"
  rescue SmplkitGeneratedClient::Audit::ApiError => e
    if e.code == 402
      puts "Skipping forwarder showcase — account is not Pro tier"
      puts "Done!"
      next
    end
    raise
  end

  begin
    # do_not_forward suppresses the forward but still records the
    # skip in the delivery log.
    client.audit.events.record(
      action: "invoice.created",
      resource_type: "invoice",
      resource_id: "#{some_resource_id}-skipped",
      do_not_forward: true
    )
    client.audit.events.flush(timeout: 2.0)

    test = client.audit.functions.test_forwarder.actions.execute(
      url: "https://httpbin.org/post",
      body: '{"hello":"world"}',
      timeout_ms: 5000
    )
    puts "test_forwarder: succeeded=#{test.succeeded} status=#{test.response_status}"
  ensure
    client.audit.forwarders.delete(fwd.id)
    puts "Deleted forwarder: #{fwd.slug}"
  end

  puts "Done!"
end
