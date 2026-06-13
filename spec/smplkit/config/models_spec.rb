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

  it "remove drops the item" do
    config.set_string("a", "1")
    config.set_string("b", "2")
    config.remove("a")
    expect(config.items.map(&:name)).to eq(["b"])
  end

  it "set adds (and replaces) a ConfigItem, and sets a raw env override" do
    config.set(Smplkit::Config::ConfigItem.new(name: "a", value: "1", type: Smplkit::Config::ItemType::STRING))
    expect(config.items.first.value).to eq("1")
    config.set(Smplkit::Config::ConfigItem.new(name: "a", value: "2", type: Smplkit::Config::ItemType::STRING),
               environment: "staging")
    expect(config.environments["staging"].values["a"]).to eq("2")
  end

  it "set_number, set_boolean and set_json add typed items" do
    config.set_number("n", 1)
    config.set_boolean("b", true)
    config.set_json("j", { "k" => "v" })
    by_name = config.items.to_h { |i| [i.name, i.type] }
    expect(by_name).to eq(
      "n" => Smplkit::Config::ItemType::NUMBER,
      "b" => Smplkit::Config::ItemType::BOOLEAN,
      "j" => Smplkit::Config::ItemType::JSON
    )
  end

  it "remove with environment drops only the per-environment override" do
    config.set_string("a", "stg-a", environment: "staging")
    config.set_string("b", "stg-b", environment: "staging")
    config.remove("a", environment: "staging")
    expect(config.environments["staging"].values).to eq("b" => "stg-b")
  end

  it "remove with an unknown environment is a no-op" do
    expect { config.remove("a", environment: "nope") }.not_to raise_error
  end

  it "raises on save without a client" do
    expect { config.save }.to raise_error(RuntimeError, /without a client/)
  end

  it "delete raises without a client" do
    expect { config.delete }.to raise_error(RuntimeError, /without a client/)
  end

  it "delete routes through the bound client" do
    client = double("config_client")
    bound = described_class.new(client, key: "showcase")
    expect(client).to receive(:delete).with("showcase")
    bound.delete
  end
end

RSpec.describe Smplkit::Config::ConfigItem do
  it "to_h compacts nil attributes" do
    item = described_class.new(name: "k", value: 1, type: "NUMBER")
    expect(item.to_h).to eq("name" => "k", "value" => 1, "type" => "NUMBER")
  end

  it "to_h includes description when present" do
    item = described_class.new(name: "k", value: 1, type: "NUMBER", description: "doc")
    expect(item.to_h).to eq("name" => "k", "value" => 1, "type" => "NUMBER", "description" => "doc")
  end

  it "implements value equality, eql? and a matching hash" do
    a = described_class.new(name: "k", value: 1, type: "NUMBER")
    b = described_class.new(name: "k", value: 1, type: "NUMBER")
    c = described_class.new(name: "k", value: 2, type: "NUMBER")
    expect(a).to eq(b)
    expect(a.eql?(b)).to be(true)
    expect(a.hash).to eq(b.hash)
    expect(a).not_to eq(c)
    expect(a).not_to eq("not an item")
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
      # Per ADR-024 §2.4 env entries are flat +{key: rawValue}+ maps.
      chain = [
        { "items" => { "feature.beta" => false },
          "environments" => { "staging" => { "feature.beta" => true } } },
        { "items" => { "api.host" => "default", "feature.beta" => false } }
      ]
      expect(described_class.resolve_chain(chain, "staging")).to eq("api.host" => "default", "feature.beta" => true)
    end
  end

  describe ".build_chain" do
    let(:parent_cfg) do
      Smplkit::Config::Config.new(nil, id: "parent-id", key: "parent", parent_id: nil,
                                       items: [Smplkit::Config::ConfigItem.new(name: "k", value: 1, type: "NUMBER")])
    end
    let(:child_cfg) do
      Smplkit::Config::Config.new(nil, id: "child-id", key: "child", parent_id: "parent-id",
                                       items: [Smplkit::Config::ConfigItem.new(name: "k", value: 2, type: "NUMBER")])
    end

    it "walks parent_id pointers across the by_id map" do
      by_id = { "parent-id" => parent_cfg, "child-id" => child_cfg }
      chain = described_class.build_chain(child_cfg, by_id)
      expect(chain.map { |entry| entry["id"] }).to eq(%w[child-id parent-id])
    end

    it "terminates when the parent is not present in the by_id map" do
      by_id = { "child-id" => child_cfg } # parent-id intentionally absent
      chain = described_class.build_chain(child_cfg, by_id)
      expect(chain.map { |entry| entry["id"] }).to eq(["child-id"])
    end

    it "treats an empty-string parent_id as no parent" do
      root = Smplkit::Config::Config.new(nil, id: "x", key: "x", parent_id: "")
      chain = described_class.build_chain(root, {})
      expect(chain.map { |entry| entry["id"] }).to eq(["x"])
    end
  end

  describe ".config_to_chain_entry" do
    it "compacts nil item attributes (description, type)" do
      item = Smplkit::Config::ConfigItem.new(name: "k", value: 1, type: "NUMBER", description: "doc")
      cfg = Smplkit::Config::Config.new(nil, id: "x", key: "x", items: [item])
      entry = described_class.config_to_chain_entry(cfg)
      expect(entry["items"]["k"]).to eq("value" => 1, "type" => "NUMBER", "description" => "doc")
    end
  end

  describe ".config_from_json" do
    it "wraps a bare (non-typed-hash) item value as a JSON item" do
      resource = {
        "id" => "cfg-1",
        "attributes" => {
          "key" => "showcase",
          "items" => { "raw" => [1, 2, 3] }
        }
      }
      cfg = described_class.config_from_json(nil, resource)
      item = cfg.items.first
      expect(item.name).to eq("raw")
      expect(item.value).to eq([1, 2, 3])
      expect(item.type).to eq(Smplkit::Config::ItemType::JSON)
    end
  end
end
