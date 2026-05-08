# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Helpers do
  describe ".key_to_display_name" do
    it "title-cases hyphen and underscore separators" do
      expect(described_class.key_to_display_name("checkout-v2")).to eq("Checkout V2")
      expect(described_class.key_to_display_name("user_service")).to eq("User Service")
      expect(described_class.key_to_display_name("user_service-v2")).to eq("User Service V2")
    end
  end

  describe ".deep_stringify_keys" do
    it "converts symbol keys to strings at every depth" do
      input = { snapshot: { currency: "USD", total_cents: 4900 }, request_id: "r1" }
      expect(described_class.deep_stringify_keys(input)).to eq(
        "snapshot" => { "currency" => "USD", "total_cents" => 4900 },
        "request_id" => "r1"
      )
    end

    it "passes string keys through unchanged" do
      input = { "a" => { "b" => 1 } }
      expect(described_class.deep_stringify_keys(input)).to eq("a" => { "b" => 1 })
    end

    it "handles arrays of hashes" do
      input = [{ key: "v" }, { key: "w" }]
      expect(described_class.deep_stringify_keys(input)).to eq(
        [{ "key" => "v" }, { "key" => "w" }]
      )
    end

    it "handles arrays nested inside hashes" do
      input = { items: [{ id: 1 }, { id: 2 }] }
      expect(described_class.deep_stringify_keys(input)).to eq(
        "items" => [{ "id" => 1 }, { "id" => 2 }]
      )
    end

    it "returns scalars unchanged" do
      expect(described_class.deep_stringify_keys("hello")).to eq("hello")
      expect(described_class.deep_stringify_keys(42)).to eq(42)
      expect(described_class.deep_stringify_keys(nil)).to be_nil
    end
  end
end
