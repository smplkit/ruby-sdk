# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::LoggerSource do
  it "constructs from required+optional fields" do
    src = described_class.new(name: "rails", resolved_level: Smplkit::LogLevel::INFO)
    expect(src.name).to eq("rails")
    expect(src.resolved_level).to eq(Smplkit::LogLevel::INFO)
    expect(src.level).to be_nil
    expect(src.service).to be_nil
  end

  it "is value-equal" do
    a = described_class.new(name: "x", resolved_level: Smplkit::LogLevel::INFO)
    b = described_class.new(name: "x", resolved_level: Smplkit::LogLevel::INFO)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end
end
