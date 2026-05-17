# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Color do
  it "accepts CSS hex strings" do
    expect(described_class.new("#fff").hex).to eq("#fff")
    expect(described_class.new("#FFAA00").hex).to eq("#ffaa00")
    expect(described_class.new("#ef4444aa").hex).to eq("#ef4444aa")
  end

  it "rejects malformed hex" do
    expect { described_class.new("blue") }.to raise_error(ArgumentError)
    expect { described_class.new("#zzz") }.to raise_error(ArgumentError)
  end

  it "rejects non-strings" do
    expect { described_class.new(123) }.to raise_error(TypeError)
  end

  describe ".rgb" do
    it "constructs from 0-255 components" do
      expect(described_class.rgb(239, 68, 68).hex).to eq("#ef4444")
    end

    it "validates range and type" do
      expect { described_class.rgb(256, 0, 0) }.to raise_error(ArgumentError)
      expect { described_class.rgb(0, -1, 0) }.to raise_error(ArgumentError)
      expect { described_class.rgb(0, 0, "f") }.to raise_error(TypeError)
    end
  end

  it "to_s returns the hex" do
    expect(described_class.new("#abc").to_s).to eq("#abc")
  end

  it "==" do
    expect(described_class.new("#fff")).to eq(described_class.new("#FFF"))
  end
end

RSpec.describe Smplkit::EnvironmentClassification do
  it "exposes AD_HOC and STANDARD in alphabetical order" do
    expect(described_class::ALL).to eq([described_class::AD_HOC, described_class::STANDARD])
  end
end
