# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Smplkit::ConfigResolution do
  around do |ex|
    saved = ENV.to_h.slice("SMPLKIT_API_KEY", "SMPLKIT_BASE_DOMAIN", "SMPLKIT_SCHEME",
                           "SMPLKIT_ENVIRONMENT", "SMPLKIT_SERVICE", "SMPLKIT_DEBUG",
                           "SMPLKIT_TELEMETRY", "SMPLKIT_PROFILE")
    %w[SMPLKIT_API_KEY SMPLKIT_BASE_DOMAIN SMPLKIT_SCHEME SMPLKIT_ENVIRONMENT
       SMPLKIT_SERVICE SMPLKIT_DEBUG SMPLKIT_TELEMETRY SMPLKIT_PROFILE].each { |k| ENV.delete(k) }
    Dir.mktmpdir do |dir|
      @home_dir = dir
      ex.run
    end
  ensure
    saved.each { |k, v| ENV[k] = v }
  end

  describe ".parse_bool" do
    it "parses common truthy/falsy strings" do
      expect(described_class.parse_bool("yes", "k")).to be(true)
      expect(described_class.parse_bool("0", "k")).to be(false)
      expect(described_class.parse_bool("TRUE", "k")).to be(true)
    end

    it "raises on garbage" do
      expect { described_class.parse_bool("maybe", "k") }.to raise_error(Smplkit::Error)
    end
  end

  describe ".parse_ini" do
    it "parses sections, comments, and empty lines" do
      ini = <<~INI
        # comment
        [common]
        api_key = abc
        ; semicolon comment
        [default]
        environment = prod
      INI
      sections = described_class.parse_ini(ini)
      expect(sections["common"]).to eq("api_key" => "abc")
      expect(sections["default"]).to eq("environment" => "prod")
    end
  end

  describe ".read_config_file" do
    it "returns an empty hash when reading the file raises" do
      File.write(File.join(@home_dir, ".smplkit"), "[default]\napi_key = abc\n")
      allow(File).to receive(:read).and_raise(Errno::EACCES, "permission denied")
      expect(described_class.send(:read_config_file, "default", home_dir: @home_dir)).to eq({})
    end
  end

  describe ".resolve_config" do
    it "errors when required fields are missing" do
      expect do
        described_class.resolve_config(home_dir: @home_dir)
      end.to raise_error(Smplkit::Error, /api_key|environment|service/)
    end

    it "uses constructor args" do
      cfg = described_class.resolve_config(
        api_key: "k", environment: "prod", service: "svc", home_dir: @home_dir
      )
      expect(cfg.api_key).to eq("k")
      expect(cfg.environment).to eq("prod")
      expect(cfg.service).to eq("svc")
      expect(cfg.base_domain).to eq("smplkit.com")
      expect(cfg.scheme).to eq("https")
      expect(cfg.debug).to be(false)
      expect(cfg.telemetry).to be(true)
    end

    it "reads env vars" do
      ENV["SMPLKIT_API_KEY"] = "envkey"
      ENV["SMPLKIT_ENVIRONMENT"] = "stg"
      ENV["SMPLKIT_SERVICE"] = "svc-env"
      ENV["SMPLKIT_DEBUG"] = "true"
      ENV["SMPLKIT_TELEMETRY"] = "no"
      cfg = described_class.resolve_config(home_dir: @home_dir)
      expect(cfg.api_key).to eq("envkey")
      expect(cfg.environment).to eq("stg")
      expect(cfg.debug).to be(true)
      expect(cfg.telemetry).to be(false)
    end

    it "reads config file with profile section" do
      File.write(File.join(@home_dir, ".smplkit"), <<~INI)
        [common]
        api_key = ck
        environment = staging
        [default]
        service = filesvc
      INI
      cfg = described_class.resolve_config(home_dir: @home_dir)
      expect(cfg.api_key).to eq("ck")
      expect(cfg.environment).to eq("staging")
      expect(cfg.service).to eq("filesvc")
    end

    it "raises when named profile missing but other profiles exist" do
      File.write(File.join(@home_dir, ".smplkit"), <<~INI)
        [staging]
        api_key = stg
      INI
      expect do
        described_class.resolve_config(profile: "production", home_dir: @home_dir)
      end.to raise_error(Smplkit::Error, /Profile \[production\]/)
    end

    it "constructor args override env and file" do
      File.write(File.join(@home_dir, ".smplkit"), "[default]\napi_key = filekey\n")
      ENV["SMPLKIT_API_KEY"] = "envkey"
      cfg = described_class.resolve_config(
        api_key: "ctorkey", environment: "p", service: "s", home_dir: @home_dir
      )
      expect(cfg.api_key).to eq("ctorkey")
    end
  end

  describe ".resolve_management_config" do
    it "requires only api_key" do
      cfg = described_class.resolve_management_config(api_key: "k", home_dir: @home_dir)
      expect(cfg.api_key).to eq("k")
      expect(cfg.base_domain).to eq("smplkit.com")
    end

    it "errors without api_key" do
      expect do
        described_class.resolve_management_config(home_dir: @home_dir)
      end.to raise_error(Smplkit::Error, /api_key/)
    end

    it "reads from env" do
      ENV["SMPLKIT_API_KEY"] = "envkey"
      ENV["SMPLKIT_DEBUG"] = "yes"
      cfg = described_class.resolve_management_config(home_dir: @home_dir)
      expect(cfg.api_key).to eq("envkey")
      expect(cfg.debug).to be(true)
    end
  end

  describe ".service_url" do
    it "builds expected URL" do
      expect(described_class.service_url("https", "app", "smplkit.com")).to eq("https://app.smplkit.com")
    end
  end
end
