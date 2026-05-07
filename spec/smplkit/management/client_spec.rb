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

  it "configures one ApiClient per service host" do
    expect(mgmt._app_http).to be_a(SmplkitGeneratedClient::App::ApiClient)
    expect(mgmt._app_http.config.host).to eq("app.smplkit.test")
    expect(mgmt._app_http.config.scheme).to eq("https")
    expect(mgmt._app_http.config.access_token).to eq("k")
    expect(mgmt._config_http.config.host).to eq("config.smplkit.test")
    expect(mgmt._flags_http.config.host).to eq("flags.smplkit.test")
    expect(mgmt._logging_http.config.host).to eq("logging.smplkit.test")
  end

  it "stamps the SDK User-Agent on each generated ApiClient" do
    expect(mgmt._flags_http.default_headers["User-Agent"]).to eq("smplkit-ruby-sdk/#{Smplkit::VERSION}")
  end

  describe "extra_headers" do
    it "applies extra headers to every generated ApiClient" do
      client = described_class.from_resolved(resolved, extra_headers: { "X-Custom" => "hello" })
      expect(client._app_http.default_headers["X-Custom"]).to eq("hello")
      expect(client._flags_http.default_headers["X-Custom"]).to eq("hello")
      expect(client._config_http.default_headers["X-Custom"]).to eq("hello")
      expect(client._logging_http.default_headers["X-Custom"]).to eq("hello")
    end

    it "SDK-owned headers cannot be overridden via extra_headers" do
      client = described_class.from_resolved(resolved,
                                             extra_headers: {
                                               "Authorization" => "Bearer overridden",
                                               "Content-Type" => "text/plain",
                                               "User-Agent" => "rogue",
                                               "X-Passthrough" => "yes"
                                             })
      # SDK-owned headers kept intact
      expect(client._flags_http.default_headers["Authorization"]).not_to eq("Bearer overridden")
      expect(client._flags_http.default_headers["User-Agent"]).to eq("smplkit-ruby-sdk/#{Smplkit::VERSION}")
      # Non-SDK header passes through
      expect(client._flags_http.default_headers["X-Passthrough"]).to eq("yes")
    end
  end

  describe "FlagsNamespace" do
    it "creates typed flag handles" do
      bool = mgmt.flags.new_boolean_flag("checkout-v2", default: false)
      expect(bool).to be_a(Smplkit::Flags::BooleanFlag)
      expect(bool.id).to eq("checkout-v2")
    end

    it "registers and flushes flag declarations" do
      stub_request(:post, "https://flags.smplkit.test/api/v1/flags/bulk")
        .to_return(status: 200, body: JSON.generate("flags" => []),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      mgmt.flags.register(Smplkit::FlagDeclaration.new(id: "x", type: "BOOLEAN", default: false))
      mgmt.flags.flush
      expect(WebMock).to have_requested(:post, "https://flags.smplkit.test/api/v1/flags/bulk")
    end

    it "lists flags" do
      body = JSON.generate("data" => [{
                             "id" => "x", "type" => "flag",
                             "attributes" => { "name" => "x", "type" => "BOOLEAN",
                                               "default" => false, "environments" => {} }
                           }])
      stub_request(:get, "https://flags.smplkit.test/api/v1/flags")
        .to_return(status: 200, body: body, headers: { "Content-Type" => "application/vnd.api+json" })
      flags = mgmt.flags.list
      expect(flags.length).to eq(1)
      expect(flags.first.id).to eq("x")
    end

    it "delete sends DELETE" do
      stub_request(:delete, "https://flags.smplkit.test/api/v1/flags/x")
        .to_return(status: 204, body: "")
      expect(mgmt.flags.delete("x")).to be(true)
    end

    it "raises NotFoundError on 404" do
      body = JSON.generate("errors" => [{ "status" => "404", "detail" => "x" }])
      stub_request(:get, "https://flags.smplkit.test/api/v1/flags/missing")
        .to_return(status: 404, body: body, headers: { "Content-Type" => "application/vnd.api+json" })
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
      body = JSON.generate("data" => {
                             "id" => "user:u-1",
                             "type" => "context",
                             "attributes" => { "name" => "u-1", "context_type" => "user", "attributes" => {} }
                           })
      stub_request(:get, "https://app.smplkit.test/api/v1/contexts/user:u-1")
        .to_return(status: 200, body: body, headers: { "Content-Type" => "application/vnd.api+json" })
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

  describe "ResourceShim.stringify" do
    it "deep-converts symbol keys to strings" do
      input = { id: "x", attributes: { name: "X", nested: { key: "v" } }, list: [{ a: 1 }] }
      expected = {
        "id" => "x",
        "attributes" => { "name" => "X", "nested" => { "key" => "v" } },
        "list" => [{ "a" => 1 }]
      }
      expect(Smplkit::ManagementClient::ResourceShim.stringify(input)).to eq(expected)
    end

    it "passes through non-Hash values unchanged" do
      expect(Smplkit::ManagementClient::ResourceShim.stringify("plain")).to eq("plain")
      expect(Smplkit::ManagementClient::ResourceShim.stringify(nil)).to be_nil
    end
  end

  describe "ErrorMapping" do
    it "passes through non-generated errors" do
      expect { Smplkit::ManagementClient::ErrorMapping.call { raise "boom" } }
        .to raise_error(RuntimeError, "boom")
    end

    it "maps a 404 ApiError to NotFoundError" do
      err = SmplkitGeneratedClient::Flags::ApiError.new(
        code: 404,
        response_body: JSON.generate("errors" => [{ "status" => "404", "detail" => "missing" }])
      )
      expect { Smplkit::ManagementClient::ErrorMapping.call { raise err } }
        .to raise_error(Smplkit::NotFoundError, /missing/)
    end

    it "maps a 0-code ApiError (transport failure) to ConnectionError" do
      err = SmplkitGeneratedClient::Flags::ApiError.new(code: 0, message: "timeout")
      expect { Smplkit::ManagementClient::ErrorMapping.call { raise err } }
        .to raise_error(Smplkit::ConnectionError, /timeout/)
    end
  end
end
