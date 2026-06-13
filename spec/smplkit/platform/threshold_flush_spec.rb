# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Platform::ContextsClient do
  subject(:platform) { Smplkit::Platform::PlatformClient.new(app_transport: app_http, context_buffer: buffer) }

  let(:tcfg) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:app_http) { Smplkit::Transport.build_api_client(SmplkitGeneratedClient::App, "app", tcfg) }
  let(:buffer) { Smplkit::ContextRegistrationBuffer.new }
  let(:host) { "https://app.smplkit.test" }
  let(:jsonapi) { { "Content-Type" => "application/vnd.api+json" } }

  it "swallows errors raised by a background threshold flush" do
    stub = stub_request(:post, "#{host}/api/v1/contexts/bulk")
           .to_return(status: 500, body: JSON.generate("errors" => [{ "status" => "500" }]), headers: jsonapi)

    batch = (0...Smplkit::CONTEXT_BATCH_FLUSH_SIZE).map { |i| Smplkit::Context.new("user", "u-#{i}") }
    # register spawns a Thread that runs threshold_flush once the batch size is
    # reached. The 500 response makes the inner flush raise; threshold_flush
    # must swallow it so the daemon thread never crashes the process.
    expect { platform.contexts.register(batch) }.not_to raise_error

    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.0
    until WebMock::RequestRegistry.instance.times_executed(stub.request_pattern).positive? ||
          Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.02
    end
    expect(stub).to have_been_requested
  ensure
    platform.close
  end

  it "threshold_flush logs and swallows when the inner flush raises" do
    stub_request(:post, "#{host}/api/v1/contexts/bulk")
      .to_return(status: 500, body: JSON.generate("errors" => [{ "status" => "500" }]), headers: jsonapi)

    platform.contexts.register([Smplkit::Context.new("user", "u-1")])
    expect { platform.contexts.send(:threshold_flush) }.not_to raise_error
    expect(platform.contexts.pending_count).to eq(0)
  ensure
    platform.close
  end
end
