# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Config::Config do
  let(:config) { described_class.new(key: "showcase") }

  it "starts with empty items and environments" do
    expect(config.items).to eq([])
    expect(config.environments).to eq({})
  end

  it "set_string adds a typed item" do
    config.set_string("api.host", "x.example.com")
    item = config.items.first
    expect(item.name).to eq("api.host")
    expect(item.value).to eq("x.example.com")
    expect(item.type).to eq(Smplkit::Config::ItemType::STRING)
  end

  it "set_string with environment writes per-environment override" do
    config.set_string("api.host", "stg.example.com", environment: "staging")
    expect(config.environments["staging"].values["api.host"]).to eq("stg.example.com")
  end

  it "remove_item drops the item" do
    config.set_string("a", "1")
    config.set_string("b", "2")
    config.remove_item("a")
    expect(config.items.map(&:name)).to eq(["b"])
  end

  it "raises on save without a client" do
    expect { config.save }.to raise_error(RuntimeError, /without a client/)
  end
end

RSpec.describe Smplkit::Config::Helpers do
  describe ".deep_merge" do
    it "merges nested Hashes with override winning" do
      base = { "a" => 1, "b" => { "c" => 2, "d" => 3 } }
      override = { "b" => { "c" => 20, "e" => 5 } }
      expect(described_class.deep_merge(base, override)).to eq("a" => 1, "b" => { "c" => 20, "d" => 3, "e" => 5 })
    end

    it "replaces non-hash values wholesale" do
      expect(described_class.deep_merge({ "a" => [1, 2] }, "a" => [3])).to eq("a" => [3])
    end
  end

  describe ".unwrap_items" do
    it "extracts value from typed Hashes" do
      input = { "x" => { "value" => 1, "type" => "NUMBER" }, "y" => "raw" }
      expect(described_class.unwrap_items(input)).to eq("x" => 1, "y" => "raw")
    end
  end

  describe ".resolve_chain" do
    it "applies child over parent and env over base" do
      chain = [
        { "items" => { "feature.beta" => false },
          "environments" => { "staging" => { "values" => { "feature.beta" => true } } } },
        { "items" => { "api.host" => "default", "feature.beta" => false } }
      ]
      expect(described_class.resolve_chain(chain, "staging")).to eq("api.host" => "default", "feature.beta" => true)
    end
  end
end
