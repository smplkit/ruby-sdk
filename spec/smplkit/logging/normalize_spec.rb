# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Logging::Normalize do
  describe ".normalize_logger_name" do
    it "lowercases and replaces / and :" do
      expect(described_class.normalize_logger_name("App/Database:Pool")).to eq("app.database.pool")
    end

    it "leaves already-normalized names alone" do
      expect(described_class.normalize_logger_name("rails.middleware")).to eq("rails.middleware")
    end
  end
end
