# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::ManagementClient do
  subject(:mgmt) { described_class.from_resolved(resolved) }

  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end

  it "constructs all sub-namespaces" do
    expect(mgmt.contexts).to be_a(Smplkit::ManagementClient::ContextsNamespace)
    expect(mgmt.context_types).to be_a(Smplkit::ManagementClient::ContextTypesNamespace)
    expect(mgmt.environments).to be_a(Smplkit::ManagementClient::EnvironmentsNamespace)
    expect(mgmt.account_settings).to be_a(Smplkit::ManagementClient::AccountSettingsNamespace)
    expect(mgmt.config).to be_a(Smplkit::ManagementClient::ConfigNamespace)
    expect(mgmt.flags).to be_a(Smplkit::ManagementClient::FlagsNamespace)
    expect(mgmt.loggers).to be_a(Smplkit::ManagementClient::LoggersNamespace)
    expect(mgmt.log_groups).to be_a(Smplkit::ManagementClient::LogGroupsNamespace)
  end

  it "exposes Faraday connections per service" do
    expect(mgmt._app_http.url_prefix.to_s).to start_with("https://app.smplkit.test")
    expect(mgmt._config_http.url_prefix.to_s).to start_with("https://config.smplkit.test")
    expect(mgmt._flags_http.url_prefix.to_s).to start_with("https://flags.smplkit.test")
    expect(mgmt._logging_http.url_prefix.to_s).to start_with("https://logging.smplkit.test")
  end

  describe "FlagsNamespace" do
    it "creates typed flag handles" do
      bool = mgmt.flags.new_boolean_flag("checkout-v2", default: false)
      expect(bool).to be_a(Smplkit::Flags::BooleanFlag)
      expect(bool.id).to eq("checkout-v2")
    end

    it "registers and flushes flag declarations" do
      stub_request(:post, "https://flags.smplkit.test/api/flags/v1/bulk").to_return(status: 200, body: "")
      mgmt.flags.register(Smplkit::FlagDeclaration.new(id: "x", type: "BOOLEAN", default: false))
      mgmt.flags.flush
      expect(WebMock).to have_requested(:post, "https://flags.smplkit.test/api/flags/v1/bulk")
    end

    it "lists flags" do
      body = JSON.generate("data" => [{
                             "id" => "x", "type" => "flag",
                             "attributes" => { "id" => "x", "name" => "x", "type" => "BOOLEAN",
                                               "default" => false, "environments" => {} }
                           }])
      stub_request(:get, "https://flags.smplkit.test/api/flags/v1").to_return(status: 200, body: body)
      flags = mgmt.flags.list
      expect(flags.length).to eq(1)
      expect(flags.first.id).to eq("x")
    end

    it "delete sends DELETE" do
      stub_request(:delete, "https://flags.smplkit.test/api/flags/v1/x").to_return(status: 204, body: "")
      expect(mgmt.flags.delete("x")).to be(true)
    end

    it "raises NotFoundError on 404" do
      body = JSON.generate("errors" => [{ "status" => "404", "detail" => "x" }])
      stub_request(:get, "https://flags.smplkit.test/api/flags/v1/missing")
        .to_return(status: 404, body: body)
      expect { mgmt.flags.get("missing") }.to raise_error(Smplkit::NotFoundError)
    end
  end

  describe "ContextsNamespace" do
    it "register no-ops on empty input" do
      mgmt.contexts.register(nil)
      mgmt.contexts.register([])
      expect(WebMock).not_to have_requested(:any, /smplkit.test/)
    end

    it "split_id parses 'type:key' strings" do
      stub_request(:get, "https://app.smplkit.test/api/contexts/v1/user:u-1")
        .to_return(status: 200, body: JSON.generate("data" => {
                                                      "id" => "user:u-1",
                                                      "attributes" => { "type" => "user", "key" => "u-1",
                                                                        "attributes" => {} }
                                                    }))
      ctx = mgmt.contexts.get("user:u-1")
      expect(ctx.type).to eq("user")
      expect(ctx.key).to eq("u-1")
    end

    it "raises ArgumentError on non-composite single-arg" do
      expect { mgmt.contexts.delete("user-only") }.to raise_error(ArgumentError, /type:key/)
    end
  end

  describe "EnvironmentsNamespace#new" do
    it "constructs an Environment with defaults and a derived display name" do
      env = mgmt.environments.new("staging")
      expect(env.key).to eq("staging")
      expect(env.name).to eq("Staging")
      expect(env.classification).to eq(Smplkit::EnvironmentClassification::STANDARD)
    end

    it "accepts a CSS hex color" do
      env = mgmt.environments.new("prod", color: "#ef4444")
      expect(env.color).to be_a(Smplkit::Color)
    end
  end
end
