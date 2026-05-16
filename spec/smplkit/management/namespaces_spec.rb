# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Smplkit::ManagementClient namespaces" do
  subject(:mgmt) { Smplkit::ManagementClient.from_resolved(resolved) }

  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedManagementConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:json_api) { { "Content-Type" => "application/vnd.api+json" } }

  def stub_get(svc, path, body)
    stub_request(:get, "https://#{svc}.smplkit.test#{path}")
      .to_return(status: 200, body: JSON.generate(body), headers: { "Content-Type" => "application/vnd.api+json" })
  end

  def stub_post(svc, path, body)
    stub_request(:post, "https://#{svc}.smplkit.test#{path}")
      .to_return(status: 200, body: JSON.generate(body), headers: { "Content-Type" => "application/vnd.api+json" })
  end

  def stub_put(svc, path, body)
    stub_request(:put, "https://#{svc}.smplkit.test#{path}")
      .to_return(status: 200, body: JSON.generate(body), headers: { "Content-Type" => "application/vnd.api+json" })
  end

  def stub_delete(svc, path)
    stub_request(:delete, "https://#{svc}.smplkit.test#{path}").to_return(status: 204)
  end

  describe "ContextsNamespace" do
    let(:ctx_data) do
      { "id" => "user:u-1", "type" => "context",
        "attributes" => { "name" => "u-1", "context_type" => "user", "attributes" => {} } }
    end

    it "list returns Smplkit::Context instances" do
      stub_get("app", "/api/v1/contexts", { "data" => [ctx_data] })
      result = mgmt.contexts.list
      expect(result.first.id).to eq("user:u-1")
    end

    it "get fetches by composite id" do
      stub_get("app", "/api/v1/contexts/user:u-1", { "data" => ctx_data })
      ctx = mgmt.contexts.get("user", "u-1")
      expect(ctx.type).to eq("user")
    end

    it "delete sends DELETE on the composite id" do
      stub_delete("app", "/api/v1/contexts/user:u-1")
      expect(mgmt.contexts.delete("user", "u-1")).to be(true)
    end

    it "_save_context PUTs and returns a bound Context" do
      stub_put("app", "/api/v1/contexts/user:u-1", { "data" => ctx_data })
      ctx = Smplkit::Context.new("user", "u-1", plan: "enterprise")
      saved = mgmt.contexts._save_context(ctx)
      expect(saved.key).to eq("u-1")
    end

    it "register accumulates and flushes the bulk endpoint" do
      stub_post("app", "/api/v1/contexts/bulk", { "contexts" => [] })
      mgmt.contexts.register([Smplkit::Context.new("user", "u-1")])
      mgmt.contexts.flush
      expect(WebMock).to have_requested(:post, "https://app.smplkit.test/api/v1/contexts/bulk")
    end

    it "context_from_resource exercises the bare-id fallback through the helper directly" do
      bare = { "id" => "user:u-1", "attributes" => {} }
      ctx = mgmt.contexts.send(:context_from_resource, bare)
      expect(ctx.type).to eq("user")
      expect(ctx.key).to eq("u-1")
    end

    it "register no-ops on a nil/empty list" do
      mgmt.contexts.register(nil)
      mgmt.contexts.register([])
      expect(WebMock).not_to have_requested(:any, /smplkit\.test/)
    end
  end

  describe "ContextTypesNamespace" do
    let(:ct_data) do
      { "id" => "user", "type" => "context_type", "attributes" => { "name" => "User" } }
    end

    it "list returns ContextType instances" do
      stub_get("app", "/api/v1/context_types", { "data" => [ct_data] })
      list = mgmt.context_types.list
      expect(list.first.key).to eq("user")
    end

    it "get fetches a ContextType" do
      stub_get("app", "/api/v1/context_types/user", { "data" => ct_data })
      expect(mgmt.context_types.get("user").name).to eq("User")
    end

    it "delete sends DELETE" do
      stub_delete("app", "/api/v1/context_types/user")
      expect(mgmt.context_types.delete("user")).to be(true)
    end

    it "create POSTs and returns a fresh ContextType" do
      stub_post("app", "/api/v1/context_types", { "data" => ct_data })
      ct = mgmt.context_types.new_context_type("user", name: "User")
      mgmt.context_types._create_context_type(ct)
      expect(WebMock).to have_requested(:post, "https://app.smplkit.test/api/v1/context_types")
    end

    it "update PUTs" do
      stub_put("app", "/api/v1/context_types/user", { "data" => ct_data })
      ct = Smplkit::Management::ContextType.new(mgmt.context_types, key: "user", name: "User", created_at: "now")
      mgmt.context_types._update_context_type(ct)
      expect(WebMock).to have_requested(:put, "https://app.smplkit.test/api/v1/context_types/user")
    end
  end

  describe "EnvironmentsNamespace" do
    let(:env_data) do
      { "id" => "staging", "type" => "environment",
        "attributes" => { "name" => "Staging", "color" => "#ef4444", "classification" => "STANDARD" } }
    end

    it "list returns Environments" do
      stub_get("app", "/api/v1/environments", { "data" => [env_data] })
      expect(mgmt.environments.list.first.color).to be_a(Smplkit::Color)
    end

    it "get fetches one" do
      stub_get("app", "/api/v1/environments/staging", { "data" => env_data })
      expect(mgmt.environments.get("staging").classification).to eq("STANDARD")
    end

    it "delete sends DELETE" do
      stub_delete("app", "/api/v1/environments/staging")
      expect(mgmt.environments.delete("staging")).to be(true)
    end

    it "create POSTs the body" do
      stub_post("app", "/api/v1/environments", { "data" => env_data })
      env = mgmt.environments.new("staging")
      mgmt.environments._create_environment(env)
      expect(WebMock).to have_requested(:post, "https://app.smplkit.test/api/v1/environments")
    end

    it "update PUTs" do
      stub_put("app", "/api/v1/environments/staging", { "data" => env_data })
      env = mgmt.environments.new("staging")
      mgmt.environments._update_environment(env)
      expect(WebMock).to have_requested(:put, "https://app.smplkit.test/api/v1/environments/staging")
    end
  end

  describe "AccountSettingsNamespace" do
    it "get fetches the account settings" do
      stub_get("app", "/api/v1/accounts/current/settings",
               { "data" => { "id" => "acct-1",
                             "attributes" => { "environment_order" => %w[staging production] } } })
      settings = mgmt.account_settings.get
      expect(settings.environment_order).to eq(%w[staging production])
    end

    it "update PUTs the body" do
      stub_put("app", "/api/v1/accounts/current/settings",
               { "data" => { "id" => "acct-1", "attributes" => { "environment_order" => ["staging"] } } })
      settings = Smplkit::Management::AccountSettings.new(
        mgmt.account_settings, environment_order: ["staging"], default_environment: "staging"
      )
      mgmt.account_settings._update_account_settings(settings)
      expect(WebMock).to have_requested(:put, "https://app.smplkit.test/api/v1/accounts/current/settings")
    end
  end

  describe "ConfigNamespace" do
    let(:cfg_data) do
      { "id" => "showcase", "type" => "config",
        "attributes" => { "name" => "Showcase", "description" => nil, "parent" => nil,
                          "items" => { "api.host" => { "value" => "x", "type" => "STRING" } },
                          "environments" => {} } }
    end

    it "list returns Configs" do
      stub_get("config", "/api/v1/configs", { "data" => [cfg_data] })
      expect(mgmt.config.list.first.key).to eq("showcase")
    end

    it "get fetches one Config" do
      stub_get("config", "/api/v1/configs/showcase", { "data" => cfg_data })
      expect(mgmt.config.get("showcase").items.first.value).to eq("x")
    end

    it "delete sends DELETE" do
      stub_delete("config", "/api/v1/configs/showcase")
      expect(mgmt.config.delete("showcase")).to be(true)
    end

    it "create POSTs a config body with items + environments wired" do
      stub_post("config", "/api/v1/configs", { "data" => cfg_data })
      cfg = mgmt.config.new_config("showcase")
      cfg.set_string("api.host", "x")
      cfg.set_string("api.host", "stg.example.com", environment: "staging")
      mgmt.config._create_config(cfg)
      expect(WebMock).to have_requested(:post, "https://config.smplkit.test/api/v1/configs")
    end

    it "update PUTs" do
      stub_put("config", "/api/v1/configs/showcase", { "data" => cfg_data })
      cfg = mgmt.config.new_config("showcase")
      cfg.set_number("retries", 3)
      mgmt.config._update_config(cfg)
      expect(WebMock).to have_requested(:put, "https://config.smplkit.test/api/v1/configs/showcase")
    end

    it "fetch_chain walks parent_id pointers across the full list" do
      child = { "id" => "child-cfg", "type" => "config",
                "attributes" => { "name" => "Child", "parent" => "parent-cfg",
                                  "items" => { "child.key" => { "value" => 1, "type" => "NUMBER" } },
                                  "environments" => {} } }
      parent = { "id" => "parent-cfg", "type" => "config",
                 "attributes" => { "name" => "Parent", "parent" => nil,
                                   "items" => { "parent.key" => { "value" => 2, "type" => "NUMBER" } },
                                   "environments" => {} } }
      stub_get("config", "/api/v1/configs", { "data" => [child, parent] })
      chain = mgmt.config.fetch_chain("child-cfg")
      expect(chain.length).to eq(2)
      expect(chain.first["items"]).to have_key("child.key")
      expect(chain.last["items"]).to have_key("parent.key")
    end

    it "fetch_chain returns [] when the target key is unknown" do
      stub_get("config", "/api/v1/configs", { "data" => [] })
      expect(mgmt.config.fetch_chain("missing")).to eq([])
    end
  end

  describe "FlagsNamespace" do
    let(:flag_data) do
      { "id" => "checkout-v2", "type" => "flag",
        "attributes" => { "name" => "Checkout V2", "type" => "BOOLEAN", "default" => false,
                          "environments" => {} } }
    end

    it "get fetches one Flag" do
      stub_get("flags", "/api/v1/flags/checkout-v2", { "data" => flag_data })
      flag = mgmt.flags.get("checkout-v2")
      expect(flag).to be_a(Smplkit::Flags::BooleanFlag)
    end

    it "delete sends DELETE" do
      stub_delete("flags", "/api/v1/flags/checkout-v2")
      expect(mgmt.flags.delete("checkout-v2")).to be(true)
    end

    it "create POSTs a Flag body" do
      stub_post("flags", "/api/v1/flags", { "data" => flag_data })
      flag = mgmt.flags.new_boolean_flag("checkout-v2", default: false)
      mgmt.flags._create_flag(flag)
      expect(WebMock).to have_requested(:post, "https://flags.smplkit.test/api/v1/flags")
    end

    it "update PUTs a Flag body with values + environments wired" do
      stub_put("flags", "/api/v1/flags/checkout-v2", { "data" => flag_data })
      flag = mgmt.flags.new_string_flag("checkout-v2", default: "red", values: [
                                          Smplkit::FlagValue.new(name: "Red", value: "red")
                                        ])
      flag.id = "checkout-v2"
      flag.add_rule(
        Smplkit::Rule.new("staging", environment: "staging")
                     .when("user.plan", Smplkit::Op::EQ, "enterprise")
                     .serve("blue")
      )
      mgmt.flags._update_flag(flag)
      expect(WebMock).to have_requested(:put, "https://flags.smplkit.test/api/v1/flags/checkout-v2")
    end

    it "fetch_flag returns the runtime-cache shape" do
      stub_get("flags", "/api/v1/flags/checkout-v2", { "data" => flag_data })
      d = mgmt.flags.fetch_flag("checkout-v2")
      expect(d["id"]).to eq("checkout-v2")
    end

    it "list_flags returns runtime-cache hashes" do
      stub_get("flags", "/api/v1/flags", { "data" => [flag_data] })
      list = mgmt.flags.list_flags
      expect(list.first["id"]).to eq("checkout-v2")
    end

    it "flag_from_resource builds typed handles for STRING flags" do
      stub_get("flags", "/api/v1/flags/banner",
               { "data" => { "id" => "banner", "type" => "flag",
                             "attributes" => { "name" => "B", "type" => "STRING", "default" => "red",
                                               "environments" => {} } } })
      expect(mgmt.flags.get("banner")).to be_a(Smplkit::Flags::StringFlag)
    end

    it "flag_from_resource builds typed handles for NUMERIC flags" do
      stub_get("flags", "/api/v1/flags/retries",
               { "data" => { "id" => "retries", "type" => "flag",
                             "attributes" => { "name" => "R", "type" => "NUMERIC", "default" => 3,
                                               "environments" => {} } } })
      expect(mgmt.flags.get("retries")).to be_a(Smplkit::Flags::NumberFlag)
    end

    it "flag_from_resource falls back to JsonFlag for unknown types" do
      stub_get("flags", "/api/v1/flags/payload",
               { "data" => { "id" => "payload", "type" => "flag",
                             "attributes" => { "name" => "P", "type" => "JSON", "default" => {},
                                               "environments" => {} } } })
      expect(mgmt.flags.get("payload")).to be_a(Smplkit::Flags::JsonFlag)
    end

    it "register dedupes and flushes once threshold is hit" do
      stub_post("flags", "/api/v1/flags/bulk", { "registered" => 1 })
      mgmt.flags.register(Smplkit::FlagDeclaration.new(id: "x", type: "BOOLEAN", default: false))
      mgmt.flags.flush
      expect(WebMock).to have_requested(:post, "https://flags.smplkit.test/api/v1/flags/bulk")
    end

    it "register triggers an inline threshold flush when the buffer is full" do
      stub_post("flags", "/api/v1/flags/bulk", { "registered" => 50 })
      Smplkit::Management::FLAG_BATCH_FLUSH_SIZE.times do |i|
        mgmt.flags.register(Smplkit::FlagDeclaration.new(id: "flag-#{i}", type: "BOOLEAN", default: false))
      end
      expect(WebMock).to have_requested(:post, "https://flags.smplkit.test/api/v1/flags/bulk")
    end

    it "register swallows a threshold flush failure and retains the buffer" do
      stub_request(:post, "https://flags.smplkit.test/api/v1/flags/bulk")
        .to_return(status: 500, body: JSON.generate("errors" => [{ "status" => "500", "detail" => "down" }]),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      expect do
        Smplkit::Management::FLAG_BATCH_FLUSH_SIZE.times do |i|
          mgmt.flags.register(Smplkit::FlagDeclaration.new(id: "flag-#{i}", type: "BOOLEAN", default: false))
        end
      end.not_to raise_error
      expect(mgmt.flags.pending_count).to eq(Smplkit::Management::FLAG_BATCH_FLUSH_SIZE)
    end

    it "pending_count reflects declarations waiting to be flushed" do
      mgmt.flags.register(Smplkit::FlagDeclaration.new(id: "x", type: "BOOLEAN", default: false))
      expect(mgmt.flags.pending_count).to eq(1)
    end

    it "new_json_flag constructs a JsonFlag" do
      flag = mgmt.flags.new_json_flag("payload", default: { "a" => 1 })
      expect(flag).to be_a(Smplkit::Flags::JsonFlag)
      expect(flag.type).to eq("JSON")
    end

    it "new_number_flag constructs a NumberFlag" do
      flag = mgmt.flags.new_number_flag("retries", default: 3)
      expect(flag).to be_a(Smplkit::Flags::NumberFlag)
      expect(flag.type).to eq("NUMERIC")
    end
  end

  describe "LoggersNamespace" do
    let(:logger_data) do
      { "id" => "rails", "type" => "logger",
        "attributes" => { "name" => "rails", "level" => "INFO", "managed" => true } }
    end

    it "list returns SmplLogger instances" do
      stub_get("logging", "/api/v1/loggers",
               { "data" => [logger_data], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } })
      expect(mgmt.loggers.list.first.name).to eq("rails")
    end

    it "get normalizes the input name" do
      stub_get("logging", "/api/v1/loggers/rails.middleware", { "data" => logger_data })
      mgmt.loggers.get("Rails/Middleware")
      expect(WebMock).to have_requested(:get, "https://logging.smplkit.test/api/v1/loggers/rails.middleware")
    end

    it "delete sends DELETE on the normalized name" do
      stub_delete("logging", "/api/v1/loggers/rails")
      expect(mgmt.loggers.delete("Rails")).to be(true)
    end

    it "_update_logger PUTs the body" do
      stub_put("logging", "/api/v1/loggers/rails", { "data" => logger_data })
      logger = Smplkit::Logging::SmplLogger.new(
        mgmt.loggers, id: "rails", name: "rails",
                      resolved_level: Smplkit::LogLevel::INFO, level: Smplkit::LogLevel::INFO
      )
      mgmt.loggers._update_logger(logger)
      expect(WebMock).to have_requested(:put, "https://logging.smplkit.test/api/v1/loggers/rails")
    end

    it "register accepts both single and array forms; flush sends the bulk body" do
      stub_post("logging", "/api/v1/loggers/bulk", { "loggers" => [] })
      mgmt.loggers.register(Smplkit::LoggerSource.new(name: "x", resolved_level: Smplkit::LogLevel::INFO))
      mgmt.loggers.register([
                              Smplkit::LoggerSource.new(name: "y", resolved_level: Smplkit::LogLevel::DEBUG,
                                                        level: Smplkit::LogLevel::INFO,
                                                        service: "showcase", environment: "staging")
                            ])
      mgmt.loggers.flush
      expect(WebMock).to have_requested(:post, "https://logging.smplkit.test/api/v1/loggers/bulk")
    end
  end

  describe "LogGroupsNamespace" do
    let(:group_data) do
      { "id" => "app", "type" => "log_group",
        "attributes" => { "name" => "App", "level" => "INFO" } }
    end

    it "list returns SmplLogGroup instances" do
      stub_get("logging", "/api/v1/log_groups",
               { "data" => [group_data], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } })
      list = mgmt.log_groups.list
      expect(list.first.key).to eq("app")
    end

    it "get fetches one" do
      stub_get("logging", "/api/v1/log_groups/app", { "data" => group_data })
      expect(mgmt.log_groups.get("app").level).to eq(Smplkit::LogLevel::INFO)
    end

    it "delete sends DELETE" do
      stub_delete("logging", "/api/v1/log_groups/app")
      expect(mgmt.log_groups.delete("app")).to be(true)
    end

    it "new_log_group accepts a parent SmplLogGroup directly" do
      parent = mgmt.log_groups.new_log_group("app")
      child = mgmt.log_groups.new_log_group("app.db", parent: parent)
      expect(child.parent_id).to eq("app")
    end

    it "create POSTs the body" do
      stub_post("logging", "/api/v1/log_groups", { "data" => group_data })
      group = mgmt.log_groups.new_log_group("app", level: "INFO")
      mgmt.log_groups._create_log_group(group)
      expect(WebMock).to have_requested(:post, "https://logging.smplkit.test/api/v1/log_groups")
    end

    it "update PUTs" do
      stub_put("logging", "/api/v1/log_groups/app", { "data" => group_data })
      group = mgmt.log_groups.new_log_group("app", level: "WARN")
      mgmt.log_groups._update_log_group(group)
      expect(WebMock).to have_requested(:put, "https://logging.smplkit.test/api/v1/log_groups/app")
    end
  end

  describe "ManagementClient construction" do
    it "close is a no-op on the namespace transports" do
      expect { mgmt.close }.not_to raise_error
    end
  end
end
