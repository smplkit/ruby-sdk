# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Config::ConfigClient do
  subject(:client) { described_class.new(parent, manage: nil, metrics: nil) }

  let(:transport) { instance_double(ConfigTransport) }
  let(:parent) do
    double(_environment: "staging", _service: "svc",
           _ensure_ws: instance_double(Smplkit::SharedWebSocket, on: nil),
           _config_transport: transport)
  end

  def chain_with(items: {}, environments: {})
    [{ "id" => "svc", "items" => items, "environments" => environments }]
  end

  it "get_string returns the staging override for a flat dotted key" do
    items = { "api.host" => { "value" => "default.example.com", "type" => "STRING" } }
    envs = { "staging" => { "values" => { "api.host" => { "value" => "stg.example.com" } } } }
    allow(transport).to receive(:fetch_chain).with("svc").and_return(chain_with(items: items, environments: envs))
    expect(client.get_string("api.host", default: "fallback", config: "svc")).to eq("stg.example.com")
  end

  it "get_string returns the default when the config has no entry" do
    allow(transport).to receive(:fetch_chain).with("svc").and_return(chain_with)
    expect(client.get_string("api.missing", default: "fallback", config: "svc")).to eq("fallback")
  end

  it "get_number coerces numeric values" do
    items = { "timeout" => { "value" => 5000, "type" => "NUMBER" } }
    allow(transport).to receive(:fetch_chain).with("svc").and_return(chain_with(items: items))
    expect(client.get_number("timeout", default: 1, config: "svc")).to eq(5000)
  end

  it "get_boolean returns the typed boolean" do
    items = { "feature.beta" => { "value" => true, "type" => "BOOLEAN" } }
    allow(transport).to receive(:fetch_chain).with("svc").and_return(chain_with(items: items))
    expect(client.get_boolean("feature.beta", default: false, config: "svc")).to be(true)
  end

  it "falls back to nested-walk when snapshot keys are nested rather than dot-flat" do
    items = { "api" => { "value" => { "host" => "nested.example.com" }, "type" => "JSON" } }
    allow(transport).to receive(:fetch_chain).with("svc").and_return(chain_with(items: items))
    expect(client.get_string("api.host", default: "fallback", config: "svc")).to eq("nested.example.com")
  end
end

class ConfigTransport
  def fetch_chain(_); end
end
