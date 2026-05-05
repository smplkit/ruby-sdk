# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Logging::Levels do
  describe ".smpl_level_to_stdlib" do
    it "maps every smpl level to a stdlib level" do
      Smplkit::LogLevel::ALL.each do |level|
        expect(described_class.smpl_level_to_stdlib(level)).to be_a(Integer)
      end
    end

    it "TRACE collapses to stdlib DEBUG (no native TRACE)" do
      expect(described_class.smpl_level_to_stdlib(Smplkit::LogLevel::TRACE)).to eq(Logger::DEBUG)
    end
  end

  describe ".stdlib_level_to_smpl" do
    it "maps stdlib DEBUG to smpl DEBUG (TRACE is unrecoverable)" do
      expect(described_class.stdlib_level_to_smpl(Logger::DEBUG)).to eq(Smplkit::LogLevel::DEBUG)
      expect(described_class.stdlib_level_to_smpl(Logger::WARN)).to eq(Smplkit::LogLevel::WARN)
    end

    it "treats nil as DEBUG (the most permissive default)" do
      expect(described_class.stdlib_level_to_smpl(nil)).to eq(Smplkit::LogLevel::DEBUG)
    end
  end

  describe "semantic mapping" do
    it "round-trips all native semantic levels" do
      %i[trace debug info warn error fatal].each do |level|
        smpl = described_class.semantic_level_to_smpl(level)
        expect(described_class.smpl_level_to_semantic(smpl)).to eq(level)
      end
    end
  end
end
