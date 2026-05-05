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
end
