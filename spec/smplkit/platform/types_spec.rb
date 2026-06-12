# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Platform::Color do
  it "is aliased as Smplkit::Color" do
    expect(Smplkit::Color).to be(described_class)
  end

  it "accepts 3-digit, 6-digit, and 8-digit CSS hex strings" do
    expect(described_class.new("#fff").hex).to eq("#fff")
    expect(described_class.new("#FFAA00").hex).to eq("#ffaa00")
    expect(described_class.new("#ef4444aa").hex).to eq("#ef4444aa")
  end

  it "downcases and freezes the hex" do
    color = described_class.new("#ABC")
    expect(color.hex).to eq("#abc")
    expect(color).to be_frozen
    expect(color.hex).to be_frozen
  end

  it "rejects malformed hex" do
    expect { described_class.new("blue") }.to raise_error(ArgumentError, /Invalid color/)
    expect { described_class.new("#zzz") }.to raise_error(ArgumentError)
    expect { described_class.new("#ff") }.to raise_error(ArgumentError)
  end

  it "rejects non-strings" do
    expect { described_class.new(123) }.to raise_error(TypeError, /must be a String/)
  end

  describe ".rgb" do
    it "constructs from 0-255 components" do
      expect(described_class.rgb(239, 68, 68).hex).to eq("#ef4444")
    end

    it "zero-pads single-hex-digit components" do
      expect(described_class.rgb(0, 0, 0).hex).to eq("#000000")
      expect(described_class.rgb(1, 2, 3).hex).to eq("#010203")
    end

    it "validates range" do
      expect { described_class.rgb(256, 0, 0) }.to raise_error(ArgumentError, /range 0-255/)
      expect { described_class.rgb(0, -1, 0) }.to raise_error(ArgumentError)
    end

    it "validates type" do
      expect { described_class.rgb(0, 0, "f") }.to raise_error(TypeError, /must be an Integer/)
      expect { described_class.rgb(true, 0, 0) }.to raise_error(TypeError)
    end
  end

  describe "value semantics" do
    it "to_s and to_str return the hex" do
      color = described_class.new("#abc")
      expect(color.to_s).to eq("#abc")
      expect(color.to_str).to eq("#abc")
    end

    it "== compares by hex, case-insensitively" do
      expect(described_class.new("#fff")).to eq(described_class.new("#FFF"))
      expect(described_class.new("#fff")).not_to eq(described_class.new("#000"))
      expect(described_class.new("#fff")).not_to eq("#fff")
    end

    it "eql? aliases ==" do
      expect(described_class.new("#fff").eql?(described_class.new("#FFF"))).to be(true)
    end

    it "hashes equal colors equally" do
      expect(described_class.new("#fff").hash).to eq(described_class.new("#FFF").hash)
    end
  end
end

RSpec.describe Smplkit::Platform::EnvironmentClassification do
  it "is aliased as Smplkit::EnvironmentClassification" do
    expect(Smplkit::EnvironmentClassification).to be(described_class)
  end

  it "exposes AD_HOC and STANDARD constants" do
    expect(described_class::AD_HOC).to eq("AD_HOC")
    expect(described_class::STANDARD).to eq("STANDARD")
  end

  it "exposes ALL in alphabetical order" do
    expect(described_class::ALL).to eq([described_class::AD_HOC, described_class::STANDARD])
    expect(described_class::ALL).to be_frozen
  end
end
