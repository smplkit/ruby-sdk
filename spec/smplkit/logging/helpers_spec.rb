# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Logging::Helpers do
  describe ".logger_resource_to_model" do
    it "constructs a SmplLogger with coerced LogLevel fields" do
      resource = {
        "id" => "rails",
        "attributes" => {
          "name" => "rails",
          "resolved_level" => "WARN",
          "level" => "INFO",
          "service" => "showcase",
          "environment" => "staging",
          "log_group_id" => "app",
          "managed" => true,
          "description" => "rails-managed",
          "created_at" => "2026-05-05T00:00:00Z",
          "updated_at" => "2026-05-05T00:00:01Z"
        }
      }
      logger = described_class.logger_resource_to_model(:client, resource)
      expect(logger).to be_a(Smplkit::Logging::SmplLogger)
      expect(logger.id).to eq("rails")
      expect(logger.resolved_level).to eq(Smplkit::LogLevel::WARN)
      expect(logger.level).to eq(Smplkit::LogLevel::INFO)
      expect(logger.service).to eq("showcase")
      expect(logger.managed).to be(true)
    end

    it "tolerates missing levels" do
      resource = { "id" => "anon", "attributes" => { "name" => "anon" } }
      logger = described_class.logger_resource_to_model(:client, resource)
      expect(logger.resolved_level).to be_nil
      expect(logger.level).to be_nil
      expect(logger.managed).to be(true)
    end
  end

  describe ".log_group_resource_to_model" do
    it "constructs a SmplLogGroup with coerced LogLevel" do
      resource = {
        "id" => "app",
        "attributes" => {
          "key" => "app",
          "name" => "App",
          "level" => "INFO",
          "description" => "Application loggers",
          "parent_id" => nil,
          "environments" => { "staging" => { "level" => "DEBUG" } },
          "created_at" => "x",
          "updated_at" => "y"
        }
      }
      group = described_class.log_group_resource_to_model(:client, resource)
      expect(group).to be_a(Smplkit::Logging::SmplLogGroup)
      expect(group.key).to eq("app")
      expect(group.level).to eq(Smplkit::LogLevel::INFO)
      expect(group.environments["staging"].level).to eq(Smplkit::LogLevel::DEBUG)
    end

    it "falls back to resource id when attributes.key missing" do
      resource = { "id" => "fallback-key", "attributes" => {} }
      group = described_class.log_group_resource_to_model(:client, resource)
      expect(group.key).to eq("fallback-key")
    end
  end
end
