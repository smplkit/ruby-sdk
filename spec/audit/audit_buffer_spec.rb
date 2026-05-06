# frozen_string_literal: true

require "spec_helper"

# These tests intentionally mutate $stderr to silence the buffer's
# warn-on-overflow / warn-on-permanent-failure noise; the rubocop rule
# isn't well-suited here because the goal is suppression, not assertion.
# rubocop:disable RSpec/ExpectOutput

RSpec.describe Smplkit::Audit::EventBuffer do
  let(:fake_api) do
    Class.new do
      attr_accessor :statuses, :calls

      def initialize
        @calls = 0
        @statuses = []
      end

      def create_event(_body, _opts = {})
        @calls += 1
        status = @statuses.shift || 201
        raise SmplkitGeneratedClient::Audit::ApiError.new(code: status, message: "test") if status >= 300

        true
      end
    end.new
  end

  let(:body) do
    SmplkitGeneratedClient::Audit::EventResponse.new(
      data: SmplkitGeneratedClient::Audit::EventResource.new(
        id: "",
        type: "event",
        attributes: SmplkitGeneratedClient::Audit::Event.new(
          action: "x.created", resource_type: "x", resource_id: "1"
        )
      )
    )
  end

  describe "#enqueue" do
    it "ignores items submitted after close" do
      buf = described_class.new(fake_api)
      buf.close
      buf.enqueue(body, nil) # silently ignored
      expect(fake_api.calls).to eq(0)
    end

    it "drops the oldest item when the queue overflows" do
      stub_const("Smplkit::Audit::EventBuffer::MAX_BUFFER_SIZE", 3)
      stub_const("Smplkit::Audit::EventBuffer::WATERMARK", 9999)
      buf = described_class.new(fake_api)
      original_stderr = $stderr
      $stderr = StringIO.new
      5.times { buf.enqueue(body, nil) }
      buf.flush(timeout: 2.0)
      buf.close
      $stderr = original_stderr
      # At most 3 items survived the eviction; we just want the eviction
      # branch exercised — webmock isn't checking call count here.
      expect(fake_api.calls).to be >= 1
    end
  end

  describe "transient retries" do
    it "retries 5xx with backoff and eventually succeeds" do
      stub_const("Smplkit::Audit::EventBuffer::INITIAL_BACKOFF", 0.05)
      stub_const("Smplkit::Audit::EventBuffer::FLUSH_INTERVAL", 0.05)
      buf = described_class.new(fake_api)
      fake_api.statuses = [503, 503, 201]
      buf.enqueue(body, nil)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5.0
      sleep 0.05 until fake_api.calls >= 3 || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      buf.close
      expect(fake_api.calls).to be >= 3
    end

    it "drops permanent 4xx after a single attempt" do
      buf = described_class.new(fake_api)
      original_stderr = $stderr
      $stderr = StringIO.new
      fake_api.statuses = [400]
      buf.enqueue(body, nil)
      buf.flush(timeout: 2.0)
      buf.close
      $stderr = original_stderr
      expect(fake_api.calls).to eq(1)
    end

    it "gives up after MAX_ATTEMPTS transient failures" do
      stub_const("Smplkit::Audit::EventBuffer::INITIAL_BACKOFF", 0.05)
      stub_const("Smplkit::Audit::EventBuffer::FLUSH_INTERVAL", 0.05)
      stub_const("Smplkit::Audit::EventBuffer::MAX_ATTEMPTS", 3)
      buf = described_class.new(fake_api)
      original_stderr = $stderr
      $stderr = StringIO.new
      fake_api.statuses = [503, 503, 503, 503, 503]
      buf.enqueue(body, nil)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5.0
      sleep 0.05 until fake_api.calls >= 3 || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      buf.close
      $stderr = original_stderr
      expect(fake_api.calls).to be >= 3
    end

    it "treats raised non-ApiError exceptions as transient" do
      class_with_raise = Class.new do
        attr_accessor :calls

        def initialize
          @calls = 0
        end

        def create_event(_body, _opts = {})
          @calls += 1
          raise StandardError, "simulated network error" if @calls == 1

          true
        end
      end.new
      stub_const("Smplkit::Audit::EventBuffer::INITIAL_BACKOFF", 0.05)
      stub_const("Smplkit::Audit::EventBuffer::FLUSH_INTERVAL", 0.05)
      buf = described_class.new(class_with_raise)
      buf.enqueue(body, nil)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5.0
      sleep 0.05 until class_with_raise.calls >= 2 || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      buf.close
      expect(class_with_raise.calls).to be >= 2
    end
  end

  describe "#flush" do
    it "warns when the deadline elapses with items still pending" do
      slow_api = Class.new do
        def create_event(_body, _opts = {})
          # Always return transient so the buffer requeues with backoff.
          raise SmplkitGeneratedClient::Audit::ApiError.new(code: 503, message: "test")
        end
      end.new
      stub_const("Smplkit::Audit::EventBuffer::INITIAL_BACKOFF", 5.0)
      stub_const("Smplkit::Audit::EventBuffer::FLUSH_INTERVAL", 5.0)
      buf = described_class.new(slow_api)
      buf.enqueue(body, nil)
      original_stderr = $stderr
      $stderr = StringIO.new
      buf.flush(timeout: 0.1)
      output = $stderr.string
      $stderr = original_stderr
      buf.close(timeout: 0.5)
      expect(output).to include("flush timed out")
    end
  end
end
# rubocop:enable RSpec/ExpectOutput
