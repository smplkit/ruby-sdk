# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Logging::Resolution do
  describe ".resolve_level — basic" do
    it "logger env override wins over base level" do
      loggers = {
        "com.example.sql" => {
          "level" => "DEBUG", "group" => nil, "managed" => true,
          "environments" => { "production" => { "level" => "ERROR" } }
        }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, {})).to eq("ERROR")
    end

    it "logger base level wins when no env override is present" do
      loggers = {
        "com.example.sql" => {
          "level" => "DEBUG", "group" => nil, "managed" => true, "environments" => {}
        }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, {})).to eq("DEBUG")
    end

    it "logger base level wins when an env override is set for a different environment" do
      loggers = {
        "com.example.sql" => {
          "level" => "DEBUG", "group" => nil, "managed" => true,
          "environments" => { "staging" => { "level" => "TRACE" } }
        }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, {})).to eq("DEBUG")
    end

    it "falls back to INFO when the logger is unknown" do
      expect(described_class.resolve_level("unknown.logger", "production", {}, {})).to eq("INFO")
    end
  end

  describe ".resolve_level — group chain" do
    it "uses the group's env-specific level" do
      loggers = {
        "com.example.sql" => { "level" => nil, "group" => "group-1", "managed" => true, "environments" => {} }
      }
      groups = {
        "group-1" => {
          "level" => "WARN", "group" => nil,
          "environments" => { "production" => { "level" => "ERROR" } }
        }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, groups)).to eq("ERROR")
    end

    it "uses the group's base level when no env override is set" do
      loggers = {
        "com.example.sql" => { "level" => nil, "group" => "group-1", "managed" => true, "environments" => {} }
      }
      groups = {
        "group-1" => { "level" => "WARN", "group" => nil, "environments" => {} }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, groups)).to eq("WARN")
    end

    it "walks a nested group chain to find a level on an ancestor" do
      loggers = {
        "com.example.sql" => { "level" => nil, "group" => "group-child", "managed" => true, "environments" => {} }
      }
      groups = {
        "group-child" => { "level" => nil, "group" => "group-parent", "environments" => {} },
        "group-parent" => { "level" => "FATAL", "group" => nil, "environments" => {} }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, groups)).to eq("FATAL")
    end

    it "does not infinite-loop on a cycle in the group chain" do
      loggers = {
        "com.example.sql" => { "level" => nil, "group" => "group-a", "managed" => true, "environments" => {} }
      }
      groups = {
        "group-a" => { "level" => nil, "group" => "group-b", "environments" => {} },
        "group-b" => { "level" => nil, "group" => "group-a", "environments" => {} }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, groups)).to eq("INFO")
    end
  end

  describe ".resolve_level — dot-notation ancestry" do
    it "inherits from a parent dot-segment when the leaf has nothing to say" do
      loggers = {
        "com.example" => { "level" => "WARN", "group" => nil, "managed" => true, "environments" => {} }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, {})).to eq("WARN")
    end

    it "inherits from a grandparent when no closer ancestor exists" do
      loggers = {
        "com" => { "level" => "ERROR", "group" => nil, "managed" => true, "environments" => {} }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, {})).to eq("ERROR")
    end

    it "the closest ancestor wins over a more distant one" do
      loggers = {
        "com" => { "level" => "ERROR", "group" => nil, "managed" => true, "environments" => {} },
        "com.example" => { "level" => "DEBUG", "group" => nil, "managed" => true, "environments" => {} }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, {})).to eq("DEBUG")
    end

    it "the leaf's group wins over a dot-ancestor's base level" do
      loggers = {
        "com.example.sql" => { "level" => nil, "group" => "group-1", "managed" => true, "environments" => {} },
        "com.example" => { "level" => "DEBUG", "group" => nil, "managed" => true, "environments" => {} }
      }
      groups = { "group-1" => { "level" => "ERROR", "group" => nil, "environments" => {} } }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, groups)).to eq("ERROR")
    end

    it "uses an ancestor's env override before its base level" do
      loggers = {
        "com.example" => {
          "level" => "DEBUG", "group" => nil, "managed" => true,
          "environments" => { "production" => { "level" => "FATAL" } }
        }
      }
      expect(described_class.resolve_level("com.example.sql", "production", loggers, {})).to eq("FATAL")
    end
  end

  describe ".resolve_level — edge cases" do
    it "falls back to INFO when neither logger nor ancestors are in the cache" do
      expect(described_class.resolve_level("nonexistent", "prod", {}, {})).to eq("INFO")
    end

    it "falls through to INFO when the logger's group id is not in the groups cache" do
      loggers = {
        "com.example" => { "level" => nil, "group" => "missing-group-id", "managed" => true, "environments" => {} }
      }
      expect(described_class.resolve_level("com.example", "prod", loggers, {})).to eq("INFO")
    end

    it "tolerates a nil environments field on a logger" do
      loggers = { "test" => { "level" => "WARN", "group" => nil, "managed" => true, "environments" => nil } }
      expect(described_class.resolve_level("test", "prod", loggers, {})).to eq("WARN")
    end

    it "tolerates an env override entry that is not a hash" do
      loggers = {
        "test" => {
          "level" => "WARN", "group" => nil, "managed" => true,
          "environments" => { "prod" => "not-a-hash" }
        }
      }
      expect(described_class.resolve_level("test", "prod", loggers, {})).to eq("WARN")
    end
  end

  describe ".find_resolution_source" do
    let(:loggers) do
      {
        "with.env" => {
          "level" => "DEBUG", "group" => nil,
          "environments" => { "production" => { "level" => "ERROR" } }
        },
        "with.base" => { "level" => "WARN", "group" => nil, "environments" => {} },
        "with.group" => { "level" => nil, "group" => "g1", "environments" => {} },
        "no.resolution" => { "level" => nil, "group" => nil, "environments" => {} }
      }
    end
    let(:groups) { { "g1" => { "level" => "DEBUG", "group" => nil, "environments" => {} } } }

    it "names the env override when that wins" do
      expect(described_class.find_resolution_source("with.env", "production", loggers, groups))
        .to eq('env override "production"')
    end

    it "names the base level when no env override exists" do
      expect(described_class.find_resolution_source("with.base", "production", loggers, groups))
        .to eq("base level")
    end

    it "names the group when the leaf had nothing to say but the group did" do
      expect(described_class.find_resolution_source("with.group", "production", loggers, groups))
        .to eq('group "g1"')
    end

    it "returns 'unknown' when nothing in the chain resolved" do
      expect(described_class.find_resolution_source("no.resolution", "production", loggers, groups))
        .to eq("unknown")
    end

    it "returns 'not found' when the logger itself is missing" do
      expect(described_class.find_resolution_source("missing", "production", {}, {})).to eq("not found")
    end
  end

  describe "debug output" do
    it "emits a resolution line when debug is enabled" do
      Smplkit::Debug.enabled = true
      loggers = {
        "sql" => {
          "level" => "DEBUG", "group" => nil,
          "environments" => { "prod" => { "level" => "ERROR" } }
        }
      }
      expect { described_class.resolve_level("sql", "prod", loggers, {}) }
        .to output(/\[smplkit:resolution\].*sql.*ERROR/).to_stderr
    ensure
      Smplkit::Debug.enabled = false
    end

    it "emits an ancestor-resolution line when a dot-ancestor wins" do
      Smplkit::Debug.enabled = true
      loggers = {
        "com" => { "level" => "ERROR", "group" => nil, "environments" => {} }
      }
      expect { described_class.resolve_level("com.example.sql", "prod", loggers, {}) }
        .to output(/ancestor "com"/).to_stderr
    ensure
      Smplkit::Debug.enabled = false
    end

    it "emits a fallback line when nothing matches" do
      Smplkit::Debug.enabled = true
      expect { described_class.resolve_level("nothing", "prod", {}, {}) }
        .to output(/system default/).to_stderr
    ensure
      Smplkit::Debug.enabled = false
    end
  end
end
