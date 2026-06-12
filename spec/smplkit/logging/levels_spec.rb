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

    it "defaults nil and unknown semantic levels to INFO" do
      expect(described_class.semantic_level_to_smpl(nil)).to eq(Smplkit::LogLevel::INFO)
      expect(described_class.semantic_level_to_smpl(:mystery)).to eq(Smplkit::LogLevel::INFO)
    end

    it "maps SILENT to the closest semantic level (:fatal)" do
      expect(described_class.smpl_level_to_semantic(Smplkit::LogLevel::SILENT)).to eq(:fatal)
    end
  end

  describe ".nearest_smpl_for" do
    it "snaps a between-breakpoints stdlib level down to the nearest known one" do
      # 2.5 sits between WARN (2) and ERROR (3); the nearest breakpoint at or
      # below it is WARN.
      expect(described_class.nearest_smpl_for(2.5)).to eq(Smplkit::LogLevel::WARN)
    end

    it "uses the lowest breakpoint when the level is below all of them" do
      expect(described_class.nearest_smpl_for(-1)).to eq(Smplkit::LogLevel::DEBUG)
    end

    it "is reached for an unmapped stdlib level via stdlib_level_to_smpl" do
      expect(described_class.stdlib_level_to_smpl(2.5)).to eq(Smplkit::LogLevel::WARN)
    end
  end
end
