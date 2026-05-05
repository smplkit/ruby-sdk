# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Flags::Helpers do
  describe ".flag_dict_from_json" do
    it "parses a full FlagResource into the runtime-cache shape" do
      resource = {
        "id" => "checkout-v2",
        "type" => "flag",
        "attributes" => {
          "name" => "Checkout V2",
          "type" => "BOOLEAN",
          "default" => false,
          "description" => "rollout",
          "values" => [{ "name" => "On", "value" => true }],
          "environments" => {
            "staging" => {
              "enabled" => true,
              "default" => true,
              "rules" => [{
                "logic" => { "==" => [{ "var" => "user.plan" }, "enterprise"] },
                "value" => true,
                "description" => "enterprise"
              }]
            }
          }
        }
      }
      d = described_class.flag_dict_from_json(resource)
      expect(d["id"]).to eq("checkout-v2")
      expect(d["type"]).to eq("BOOLEAN")
      expect(d["values"].first.name).to eq("On")
      env = d["environments"]["staging"]
      expect(env).to be_a(Smplkit::Flags::FlagEnvironment)
      expect(env.enabled).to be(true)
      expect(env.rules.first.value).to be(true)
    end

    it "tolerates a missing values list" do
      resource = { "id" => "x", "attributes" => { "name" => "x", "type" => "BOOLEAN", "default" => false,
                                                  "environments" => {} } }
      d = described_class.flag_dict_from_json(resource)
      expect(d["values"]).to be_nil
    end

    it "tolerates a missing environments map" do
      resource = { "id" => "x", "attributes" => { "name" => "x", "type" => "BOOLEAN", "default" => false } }
      expect(described_class.flag_dict_from_json(resource)["environments"]).to eq({})
    end

    it "treats environment.enabled missing as enabled-true" do
      resource = { "id" => "x", "attributes" => { "environments" => { "staging" => {} } } }
      env = described_class.flag_dict_from_json(resource)["environments"]["staging"]
      expect(env.enabled).to be(true)
      expect(env.rules).to eq([])
    end

    it "treats environment.enabled false as disabled" do
      resource = { "attributes" => { "environments" => { "staging" => { "enabled" => false } } } }
      expect(described_class.flag_dict_from_json(resource)["environments"]["staging"].enabled).to be(false)
    end

    it "falls back to the resource id when attributes.id is missing" do
      d = described_class.flag_dict_from_json({ "id" => "from-resource", "attributes" => {} })
      expect(d["id"]).to eq("from-resource")
    end

    it "uses attributes.id when present" do
      d = described_class.flag_dict_from_json({ "attributes" => { "id" => "from-attrs" } })
      expect(d["id"]).to eq("from-attrs")
    end
  end
end
