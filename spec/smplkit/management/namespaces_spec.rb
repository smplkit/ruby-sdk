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

  # Returns a [capture, stub] pair. The stub matches the GET URL regex; the
  # captured URI is exposed via +capture[:uri]+ once the request fires.
  def stub_get_capture(url_regex, response_body)
    capture = { uri: nil }
    stub = stub_request(:get, url_regex)
           .with { |req| capture[:uri] = req.uri.to_s }
           .to_return(status: 200, body: JSON.generate(response_body),
                      headers: { "Content-Type" => "application/vnd.api+json" })
    [capture, stub]
  end

  describe "ContextsNamespace" do
    let(:ctx_data) do
      { "id" => "user:u-1", "type" => "context",
        "attributes" => { "name" => "u-1", "context_type" => "user", "attributes" => {} } }
    end

    it "list returns Smplkit::Context instances" do
      stub_get("app", "/api/v1/contexts",
               { "data" => [ctx_data], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } })
      result = mgmt.contexts.list
      expect(result.first.id).to eq("user:u-1")
    end

    it "list passes through page_number and page_size to the generated client" do
      capture, = stub_get_capture(
        %r{https://app\.smplkit\.test/api/v1/contexts\b},
        { "data" => [ctx_data], "meta" => { "pagination" => { "page" => 2, "size" => 5 } } }
      )
      mgmt.contexts.list(page_number: 2, page_size: 5)
      expect(capture[:uri]).to include("page%5Bnumber%5D=2")
      expect(capture[:uri]).to include("page%5Bsize%5D=5")
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
      stub_get("app", "/api/v1/context_types",
               { "data" => [ct_data], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } })
      list = mgmt.context_types.list
      expect(list.first.key).to eq("user")
    end

    it "list forwards page_number and page_size to the generated client" do
      capture, = stub_get_capture(
        %r{https://app\.smplkit\.test/api/v1/context_types\b},
        { "data" => [ct_data], "meta" => { "pagination" => { "page" => 3, "size" => 2 } } }
      )
      mgmt.context_types.list(page_number: 3, page_size: 2)
      expect(capture[:uri]).to include("page%5Bnumber%5D=3")
      expect(capture[:uri]).to include("page%5Bsize%5D=2")
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
      stub_get("app", "/api/v1/environments",
               { "data" => [env_data], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } })
      expect(mgmt.environments.list.first.color).to be_a(Smplkit::Color)
    end

    it "list forwards page_number and page_size to the generated client" do
      capture, = stub_get_capture(
        %r{https://app\.smplkit\.test/api/v1/environments\b},
        { "data" => [env_data], "meta" => { "pagination" => { "page" => 4, "size" => 10 } } }
      )
      mgmt.environments.list(page_number: 4, page_size: 10)
      expect(capture[:uri]).to include("page%5Bnumber%5D=4")
      expect(capture[:uri]).to include("page%5Bsize%5D=10")
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
      stub_get("config", "/api/v1/configs",
               { "data" => [cfg_data], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } })
      expect(mgmt.config.list.first.key).to eq("showcase")
    end

    it "list forwards page_number and page_size to the generated client" do
      capture, = stub_get_capture(
        %r{https://config\.smplkit\.test/api/v1/configs\b},
        { "data" => [cfg_data], "meta" => { "pagination" => { "page" => 2, "size" => 25 } } }
      )
      mgmt.config.list(page_number: 2, page_size: 25)
      expect(capture[:uri]).to include("page%5Bnumber%5D=2")
      expect(capture[:uri]).to include("page%5Bsize%5D=25")
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
      stub_request(:get, %r{https://config\.smplkit\.test/api/v1/configs\b})
        .to_return(status: 200,
                   body: JSON.generate({ "data" => [child, parent],
                                         "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      chain = mgmt.config.fetch_chain("child-cfg")
      expect(chain.length).to eq(2)
      expect(chain.first["items"]).to have_key("child.key")
      expect(chain.last["items"]).to have_key("parent.key")
    end

    it "fetch_chain returns [] when the target key is unknown" do
      stub_request(:get, %r{https://config\.smplkit\.test/api/v1/configs\b})
        .to_return(status: 200,
                   body: JSON.generate({ "data" => [],
                                         "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      expect(mgmt.config.fetch_chain("missing")).to eq([])
    end

    it "fetch_chain walks every page when the first page returns RUNTIME_PAGE_SIZE rows" do
      page_size = Smplkit::ManagementClient::RUNTIME_PAGE_SIZE
      target = { "id" => "target-cfg", "type" => "config",
                 "attributes" => { "name" => "Target", "parent" => nil,
                                   "items" => {}, "environments" => {} } }
      filler = (1..page_size).map do |i|
        { "id" => "filler-#{i}", "type" => "config",
          "attributes" => { "name" => "Filler #{i}", "parent" => nil,
                            "items" => {}, "environments" => {} } }
      end
      page1_body = JSON.generate({ "data" => filler,
                                   "meta" => { "pagination" => { "page" => 1, "size" => page_size } } })
      page2_body = JSON.generate({ "data" => [target],
                                   "meta" => { "pagination" => { "page" => 2, "size" => page_size } } })
      stub_request(:get, %r{https://config\.smplkit\.test/api/v1/configs\b.*page%5Bnumber%5D=1\b})
        .to_return(status: 200, body: page1_body,
                   headers: { "Content-Type" => "application/vnd.api+json" })
      stub_request(:get, %r{https://config\.smplkit\.test/api/v1/configs\b.*page%5Bnumber%5D=2\b})
        .to_return(status: 200, body: page2_body,
                   headers: { "Content-Type" => "application/vnd.api+json" })
      chain = mgmt.config.fetch_chain("target-cfg")
      expect(chain.length).to eq(1)
      expect(chain.first["id"]).to eq("target-cfg")
    end
  end

  describe "FlagsNamespace" do
    let(:flag_data) do
      { "id" => "checkout-v2", "type" => "flag",
        "attributes" => { "name" => "Checkout V2", "type" => "BOOLEAN", "default" => false,
                          "environments" => {} } }
    end

    it "list forwards page_number and page_size to the generated client" do
      capture, = stub_get_capture(
        %r{https://flags\.smplkit\.test/api/v1/flags\b},
        { "data" => [flag_data], "meta" => { "pagination" => { "page" => 5, "size" => 50 } } }
      )
      mgmt.flags.list(page_number: 5, page_size: 50)
      expect(capture[:uri]).to include("page%5Bnumber%5D=5")
      expect(capture[:uri]).to include("page%5Bsize%5D=50")
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
      stub_request(:get, %r{https://flags\.smplkit\.test/api/v1/flags\b})
        .to_return(status: 200,
                   body: JSON.generate({ "data" => [flag_data],
                                         "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      list = mgmt.flags.list_flags
      expect(list.first["id"]).to eq("checkout-v2")
    end

    it "list_flags walks every page until a short page terminates the loop" do
      page_size = Smplkit::ManagementClient::RUNTIME_PAGE_SIZE
      first_page = (1..page_size).map do |i|
        { "id" => "flag-#{i}", "type" => "flag",
          "attributes" => { "name" => "F#{i}", "type" => "BOOLEAN", "default" => false,
                            "environments" => {} } }
      end
      second_page = [flag_data]
      stub_request(:get, %r{https://flags\.smplkit\.test/api/v1/flags\b.*page%5Bnumber%5D=1\b})
        .to_return(status: 200,
                   body: JSON.generate({ "data" => first_page,
                                         "meta" => { "pagination" => { "page" => 1, "size" => page_size } } }),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      stub_request(:get, %r{https://flags\.smplkit\.test/api/v1/flags\b.*page%5Bnumber%5D=2\b})
        .to_return(status: 200,
                   body: JSON.generate({ "data" => second_page,
                                         "meta" => { "pagination" => { "page" => 2, "size" => page_size } } }),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      list = mgmt.flags.list_flags
      expect(list.length).to eq(page_size + 1)
      expect(list.last["id"]).to eq("checkout-v2")
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

    it "list forwards page_number and page_size to the generated client" do
      capture, = stub_get_capture(
        %r{https://logging\.smplkit\.test/api/v1/loggers\b},
        { "data" => [logger_data], "meta" => { "pagination" => { "page" => 7, "size" => 20 } } }
      )
      mgmt.loggers.list(page_number: 7, page_size: 20)
      expect(capture[:uri]).to include("page%5Bnumber%5D=7")
      expect(capture[:uri]).to include("page%5Bsize%5D=20")
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

    it "list_logger_entries returns resolution-cache shape and walks every page" do
      page_size = Smplkit::ManagementClient::RUNTIME_PAGE_SIZE
      first = (1..page_size).map do |i|
        { "id" => "filler-#{i}", "type" => "logger",
          "attributes" => { "name" => "F#{i}", "level" => "INFO", "managed" => true,
                            "group" => nil, "environments" => {} } }
      end
      second = [{
        "id" => "rails", "type" => "logger",
        "attributes" => { "name" => "rails", "level" => "DEBUG", "managed" => true,
                          "group" => "app", "environments" => { "prod" => { "level" => "WARN" } } }
      }]
      stub_request(:get, %r{https://logging\.smplkit\.test/api/v1/loggers\b.*page%5Bnumber%5D=1\b})
        .to_return(status: 200,
                   body: JSON.generate({ "data" => first,
                                         "meta" => { "pagination" => { "page" => 1, "size" => page_size } } }),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      stub_request(:get, %r{https://logging\.smplkit\.test/api/v1/loggers\b.*page%5Bnumber%5D=2\b})
        .to_return(status: 200,
                   body: JSON.generate({ "data" => second,
                                         "meta" => { "pagination" => { "page" => 2, "size" => page_size } } }),
                   headers: { "Content-Type" => "application/vnd.api+json" })

      entries = mgmt.loggers.list_logger_entries
      expect(entries.length).to eq(page_size + 1)
      expect(entries["rails"]).to eq("level" => "DEBUG", "group" => "app", "managed" => true,
                                     "environments" => { "prod" => { "level" => "WARN" } })
    end

    it "get_logger_entry returns the resolution-cache shape after normalizing the name" do
      stub_get("logging", "/api/v1/loggers/rails.middleware",
               { "data" => { "id" => "rails.middleware", "type" => "logger",
                             "attributes" => { "name" => "rails.middleware", "level" => "DEBUG",
                                               "managed" => false, "group" => nil, "environments" => {} } } })
      id, entry = mgmt.loggers.get_logger_entry("Rails/Middleware")
      expect(id).to eq("rails.middleware")
      expect(entry).to eq("level" => "DEBUG", "group" => nil, "managed" => false, "environments" => {})
    end

    it "get_logger_entry defaults managed to true when the field is omitted" do
      stub_get("logging", "/api/v1/loggers/x",
               { "data" => { "id" => "x", "type" => "logger",
                             "attributes" => { "name" => "x", "level" => nil } } })
      _id, entry = mgmt.loggers.get_logger_entry("x")
      expect(entry["managed"]).to be(true)
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

    it "list forwards page_number and page_size to the generated client" do
      capture, = stub_get_capture(
        %r{https://logging\.smplkit\.test/api/v1/log_groups\b},
        { "data" => [group_data], "meta" => { "pagination" => { "page" => 8, "size" => 15 } } }
      )
      mgmt.log_groups.list(page_number: 8, page_size: 15)
      expect(capture[:uri]).to include("page%5Bnumber%5D=8")
      expect(capture[:uri]).to include("page%5Bsize%5D=15")
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

    it "list_group_entries returns resolution-cache shape with parent_id mapped onto +group+" do
      stub_request(:get, %r{https://logging\.smplkit\.test/api/v1/log_groups\b})
        .to_return(status: 200,
                   body: JSON.generate({
                                         "data" => [{ "id" => "child", "type" => "log_group",
                                                      "attributes" => { "name" => "Child", "level" => nil,
                                                                        "parent_id" => "root",
                                                                        "environments" => {
                                                                          "prod" => { "level" => "WARN" }
                                                                        } } }],
                                         "meta" => { "pagination" => { "page" => 1, "size" => 1000 } }
                                       }),
                   headers: { "Content-Type" => "application/vnd.api+json" })
      entries = mgmt.log_groups.list_group_entries
      expect(entries["child"]).to eq("level" => nil, "group" => "root",
                                     "environments" => { "prod" => { "level" => "WARN" } })
    end

    it "get_group_entry returns the resolution-cache shape" do
      stub_get("logging", "/api/v1/log_groups/app",
               { "data" => { "id" => "app", "type" => "log_group",
                             "attributes" => { "name" => "App", "level" => "INFO",
                                               "parent_id" => nil, "environments" => {} } } })
      id, entry = mgmt.log_groups.get_group_entry("app")
      expect(id).to eq("app")
      expect(entry).to eq("level" => "INFO", "group" => nil, "environments" => {})
    end
  end

  describe "ManagementClient construction" do
    it "close is a no-op on the namespace transports" do
      expect { mgmt.close }.not_to raise_error
    end
  end
end
