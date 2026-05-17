# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::LogLevel do
  it "exposes all canonical levels in increasing-severity order" do
    expect(described_class::ALL.map(&:name)).to eq(%w[TRACE DEBUG INFO WARN ERROR FATAL SILENT])
  end

  it "compares by ordinal" do
    expect(described_class::TRACE).to be < described_class::DEBUG
    expect(described_class::ERROR).to be > described_class::WARN
  end

  it "stringifies to its name" do
    expect(described_class::INFO.to_s).to eq("INFO")
    expect(described_class::INFO.to_str).to eq("INFO")
  end

  describe ".from_string" do
    it "parses upper/lowercase" do
      expect(described_class.from_string("info")).to eq(described_class::INFO)
      expect(described_class.from_string("WARN")).to eq(described_class::WARN)
    end

    it "raises on unknown" do
      expect { described_class.from_string("YELL") }.to raise_error(ArgumentError)
      expect { described_class.from_string(nil) }.to raise_error(ArgumentError)
    end
  end

  describe ".coerce" do
    it "passes through LogLevel instances" do
      expect(described_class.coerce(described_class::INFO)).to equal(described_class::INFO)
    end

    it "coerces strings" do
      expect(described_class.coerce("debug")).to eq(described_class::DEBUG)
    end
  end

  it "compares equal to a matching string" do
    expect(described_class::INFO == "INFO").to be(true)
  end
end
