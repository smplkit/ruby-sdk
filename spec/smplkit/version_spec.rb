# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Smplkit version and User-Agent" do
  describe "Smplkit::VERSION" do
    it "is the frozen local-dev fallback" do
      expect(Smplkit::VERSION).to eq("0.0.0")
    end
  end

  describe ".gem_version" do
    it "reads the loaded smplkit gem's version from RubyGems metadata" do
      spec = instance_double(Gem::Specification, version: Gem::Version.new("9.8.7"))
      allow(Gem).to receive(:loaded_specs).and_return({ "smplkit" => spec })
      expect(Smplkit.gem_version).to eq("9.8.7")
    end

    it "falls back to the smplkit-sdk gem name (ADR-046 §2.1)" do
      spec = instance_double(Gem::Specification, version: Gem::Version.new("7.6.5"))
      allow(Gem).to receive(:loaded_specs).and_return({ "smplkit-sdk" => spec })
      expect(Smplkit.gem_version).to eq("7.6.5")
    end

    it "falls back to VERSION when no smplkit gem is loaded" do
      allow(Gem).to receive(:loaded_specs).and_return({})
      expect(Smplkit.gem_version).to eq(Smplkit::VERSION)
    end

    it "returns the real gem version in this bundled test process" do
      # The Gemfile declares +gemspec+, so bundler activates the smplkit gem
      # and its build-time-derived version (from the release tag) is visible.
      expect(Smplkit.gem_version).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe ".user_agent" do
    it "is smplkit-sdk-ruby/<gem version>" do
      spec = instance_double(Gem::Specification, version: Gem::Version.new("1.2.3"))
      allow(Gem).to receive(:loaded_specs).and_return({ "smplkit" => spec })
      expect(Smplkit.user_agent).to eq("smplkit-sdk-ruby/1.2.3")
    end

    it "always carries the smplkit-sdk-ruby prefix and the resolved version" do
      expect(Smplkit.user_agent).to start_with("smplkit-sdk-ruby/")
      expect(Smplkit.user_agent).to eq("smplkit-sdk-ruby/#{Smplkit.gem_version}")
    end
  end
end
