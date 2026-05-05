# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::MetricsReporter do
  subject(:reporter) do
    described_class.new(http_client: http, environment: "staging", service: "svc", flush_interval: 60)
  end

  let(:http) { instance_double(Faraday::Connection) }

  after { reporter.close }

  it "records counters and gauges" do
    reporter.record("flags.evaluations", unit: "evaluations")
    reporter.record_gauge("platform.connections", 1, unit: "connections")
    expect(reporter.instance_variable_get(:@counts).size).to eq(1)
    expect(reporter.instance_variable_get(:@gauges).size).to eq(1)
  end

  it "flush clears the in-memory buffers" do
    reporter.record("a", unit: "x")
    reporter.flush
    expect(reporter.instance_variable_get(:@counts)).to be_empty
  end

  it "close prevents further records" do
    reporter.close
    reporter.record("after-close", unit: "x")
    expect(reporter.instance_variable_get(:@counts)).to be_empty
  end
end
