# frozen_string_literal: true

require "spec_helper"

# Tests for the fused +LoggingClient+ (one client, two surfaces):
#   - Management surface: +loggers+ / +log_groups+ sub-clients (CRUD, discovery
#     buffer, runtime entry fetches) — works immediately, no +install+.
#   - Pre-install configuration: +register_adapter+ / +adapters+.
#   - Live surface: +install+ (the consent gate), +on_change+ / +refresh+
#     (gated, raise +NotInstalledError+ before install), the event stream
#     dispatch pipeline, and +close+ / +_close+.
#   - Module helpers: +Logging.auto_load_adapters+, +LoggerChangeEvent+.
#
# The client is wired with a parent double plus an injected transport pointed
# at a WebMock host. The parent's shared event stream is constructed but never
# +start+ed — dispatch is driven directly via +EventStream#dispatch+, so no
# real connection opens.

# A real +Adapters::Base+ subclass (instance_double trips
# +is_a?(Adapters::Base)+, so the live surface needs a genuine subclass).
# Records +install_hook+ blocks, +apply_level+ calls, and +uninstall_hook+.
class TestAdapter < Smplkit::Logging::Adapters::Base
  attr_reader :applied, :hook_block, :uninstalled, :install_hook_calls

  def initialize(discovered = [["My.Logger", nil, Smplkit::LogLevel::INFO]])
    super()
    @discovered = discovered
    @applied = []
    @hook_block = nil
    @uninstalled = false
    @install_hook_calls = 0
    @raise_on_apply = false
  end

  attr_writer :raise_on_apply

  def name = "test-adapter"
  def discover = @discovered

  def apply_level(logger_name, level)
    raise "apply boom" if @raise_on_apply

    @applied << [logger_name, level]
  end

  def install_hook(&block)
    @install_hook_calls += 1
    @hook_block = block
  end

  def uninstall_hook
    @uninstalled = true
  end

  # Drive the continuous-discovery callback the way a framework hook would.
  def emit_new_logger(name, explicit, effective)
    @hook_block&.call(name, explicit, effective)
  end
end

RSpec.describe Smplkit::Logging::LoggingClient do
  subject(:logging) { described_class.new(parent: parent, transport: transport, metrics: metrics) }

  let(:base_url) { "https://logging.smplkit.test" }
  let(:tcfg) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end
  let(:transport) { Smplkit::Transport.build_api_client(SmplkitGeneratedClient::Logging, "logging", tcfg) }
  let(:stream) { Smplkit::EventStream.new(app_base_url: "https://app.smplkit.test", api_key: "k") }
  let(:parent) do
    double("Smplkit::Client",
           _environment: "staging", _service: "svc",
           _ensure_started: nil, _ensure_event_stream: stream)
  end
  let(:metrics) { nil }
  let(:adapter) { TestAdapter.new }

  # Always release the (never-started) event stream / adapter hooks so no
  # background state leaks between examples.
  after { logging.close }

  # ----------------------------------------------------------------
  # JSON:API fixtures
  # ----------------------------------------------------------------

  def jsonapi_headers
    { "Content-Type" => "application/vnd.api+json" }
  end

  # A logger JSON:API resource. +environments+ is the per-env override map.
  def logger_resource(id, level: nil, group: nil, managed: true, environments: {}, name: nil)
    {
      "id" => id, "type" => "logger",
      "attributes" => {
        "name" => name || id, "level" => level, "group" => group,
        "managed" => managed, "environments" => environments,
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-01T00:00:00Z"
      }
    }
  end

  def group_resource(id, level: nil, parent_id: nil, environments: {}, name: nil)
    {
      "id" => id, "type" => "log_group",
      "attributes" => {
        "name" => name || id, "level" => level, "parent_id" => parent_id,
        "environments" => environments,
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-01T00:00:00Z"
      }
    }
  end

  def list_body(*resources)
    {
      "data" => resources,
      "meta" => { "pagination" => { "page" => 1, "size" => 1000, "total" => resources.length,
                                    "total_pages" => 1 } }
    }.to_json
  end

  # Stub GET /api/v1/loggers (paginated list) with one page of resources.
  def stub_loggers_list(*resources)
    stub_request(:get, "#{base_url}/api/v1/loggers")
      .with(query: hash_including({}))
      .to_return(status: 200, body: list_body(*resources), headers: jsonapi_headers)
  end

  # Stub GET /api/v1/log_groups (paginated list).
  def stub_groups_list(*resources)
    stub_request(:get, "#{base_url}/api/v1/log_groups")
      .with(query: hash_including({}))
      .to_return(status: 200, body: list_body(*resources), headers: jsonapi_headers)
  end

  def stub_logger_get(id, resource, status: 200)
    body = status == 200 ? { "data" => resource }.to_json : %({"errors":[{"status":"404"}]})
    stub_request(:get, "#{base_url}/api/v1/loggers/#{id}")
      .to_return(status: status, body: body, headers: jsonapi_headers)
  end

  def stub_group_get(id, resource, status: 200)
    body = status == 200 ? { "data" => resource }.to_json : %({"errors":[{"status":"404"}]})
    stub_request(:get, "#{base_url}/api/v1/log_groups/#{id}")
      .to_return(status: status, body: body, headers: jsonapi_headers)
  end

  def stub_bulk
    stub_request(:post, "#{base_url}/api/v1/loggers/bulk")
      .to_return(status: 200, body: { "registered" => 1 }.to_json, headers: jsonapi_headers)
  end

  # ----------------------------------------------------------------
  # register_adapter / adapters (pre-install, ungated)
  # ----------------------------------------------------------------

  describe "#register_adapter" do
    it "appends a Base subclass before install and disables auto-loading" do
      logging.register_adapter(adapter)
      expect(logging.adapters).to eq([adapter])
    end

    it "returns self for chaining" do
      expect(logging.register_adapter(adapter)).to equal(logging)
    end

    it "rejects a non-Base instance with ArgumentError" do
      expect { logging.register_adapter(Object.new) }.to raise_error(ArgumentError, /Adapters::Base/)
    end

    it "raises RuntimeError when called after install" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      expect { logging.register_adapter(TestAdapter.new) }
        .to raise_error(RuntimeError, /after install/)
    end

    it "returns a copy of the adapter list (mutating it does not affect the client)" do
      logging.register_adapter(adapter)
      copy = logging.adapters
      copy << :extra
      expect(logging.adapters).to eq([adapter])
    end
  end

  # ----------------------------------------------------------------
  # install: discover -> register -> flush -> fetch -> apply
  # ----------------------------------------------------------------

  describe "#install" do
    it "discovers, bulk-registers (normalized id), fetches, and applies the resolved level" do
      adapter = TestAdapter.new([["My.Logger", nil, Smplkit::LogLevel::INFO]])
      captured = nil
      bulk = stub_request(:post, "#{base_url}/api/v1/loggers/bulk")
             .to_return do |req|
               captured = JSON.parse(req.body)
               { status: 200, body: { "registered" => 1 }.to_json, headers: jsonapi_headers }
             end
      stub_loggers_list(logger_resource("my.logger", level: "DEBUG"))
      stub_groups_list

      logging.register_adapter(adapter)
      logging.install

      expect(bulk).to have_been_requested
      # The discovered name "My.Logger" is normalized to "my.logger" in the bulk body.
      ids = captured["loggers"].map { |l| l["id"] }
      expect(ids).to contain_exactly("my.logger")
      # The resolved DEBUG level is applied against the original (un-normalized) name.
      expect(adapter.applied).to eq([["My.Logger", Smplkit::LogLevel::DEBUG]])
      expect(parent).to have_received(:_ensure_started)
    end

    it "applies a group-inherited level when the logger has no direct level" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: nil, group: "g1"))
      stub_groups_list(group_resource("g1", level: "WARN"))

      logging.register_adapter(adapter)
      logging.install
      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::WARN]])
    end

    it "applies an environment-override level (staging) over the base level" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(
        logger_resource("my.logger", level: "INFO", environments: { "staging" => { "level" => "TRACE" } })
      )
      stub_groups_list

      logging.register_adapter(adapter)
      logging.install
      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::TRACE]])
    end

    it "skips unmanaged loggers" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "ERROR", managed: false))
      stub_groups_list

      logging.register_adapter(adapter)
      logging.install
      expect(adapter.applied).to be_empty
    end

    it "skips loggers absent from the server-side cache" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list # empty
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      expect(adapter.applied).to be_empty
    end

    it "installs continuous-discovery hooks on every adapter" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      expect(adapter.install_hook_calls).to eq(1)
      expect(adapter.hook_block).to be_a(Proc)
    end

    it "registers event stream handlers for every level-affecting event" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      registered = stream.instance_variable_get(:@listeners)
      %w[logger_changed logger_deleted group_changed group_deleted loggers_changed].each do |event|
        expect(registered.keys).to include(event)
      end
    end

    it "registers the loggers_changed bulk-refresh path as the reconnect refetch" do
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear
      events = []
      logging.on_change { |e| events << [e.id, e.level, e.source] }
      stub_loggers_list(logger_resource("my.logger", level: "ERROR"))
      stub_groups_list
      stream.send(:run_refetch_callbacks)
      expect(adapter.applied).to eq([["My.Logger", Smplkit::LogLevel::ERROR]])
      expect(events).to eq([["my.logger", "ERROR", "push"]])
    end

    it "is idempotent — a second install does not re-hook or re-fetch" do
      stub_bulk
      list = stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      logging.install
      expect(adapter.install_hook_calls).to eq(1)
      expect(list).to have_been_requested.once
    end

    it "auto-loads the built-in adapters when none are explicitly registered" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.install
      expect(logging.adapters.map(&:name)).to include("stdlib-logger")
    end

    it "swallows a fetch failure and still installs the stream handlers" do
      stub_bulk
      stub_request(:get, "#{base_url}/api/v1/loggers")
        .with(query: hash_including({}))
        .to_return(status: 500, body: "boom")
      stub_groups_list
      logging.register_adapter(adapter)
      expect { logging.install }.not_to raise_error
      registered = stream.instance_variable_get(:@listeners)
      expect(registered.keys).to include("logger_changed")
    end

    it "swallows a flush failure and continues with fetch + apply" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_request(:post, "#{base_url}/api/v1/loggers/bulk").to_return(status: 500, body: "boom")
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(adapter)
      expect { logging.install }.not_to raise_error
      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::WARN]])
    end

    it "swallows an adapter discover error and carries on" do
      bad = TestAdapter.new
      allow(bad).to receive(:discover).and_raise(StandardError, "discover boom")
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(bad)
      expect { logging.install }.not_to raise_error
    end

    it "swallows an adapter install_hook error and carries on" do
      bad = TestAdapter.new([])
      allow(bad).to receive(:install_hook).and_raise(StandardError, "hook boom")
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(bad)
      expect { logging.install }.not_to raise_error
    end

    it "records a metric per applied logger when metrics is present" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      metrics = instance_double(Smplkit::MetricsReporter, record: nil)
      client = described_class.new(parent: parent, transport: transport, metrics: metrics)
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "DEBUG"))
      stub_groups_list
      client.register_adapter(adapter)
      client.install
      expect(metrics).to have_received(:record).with(
        "logging.level_changes", unit: "changes", dimensions: { "logger" => "my.logger" }
      )
      client.close
    end

    it "applies a cached level to a logger discovered after install via the hook" do
      adapter = TestAdapter.new([])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "ERROR"))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear
      # A new logger appears post-install; the hook re-resolves from cache.
      adapter.emit_new_logger("My.Logger", nil, Smplkit::LogLevel::INFO)
      expect(adapter.applied).to eq([["My.Logger", Smplkit::LogLevel::ERROR]])
    end

    it "does not apply when a hook-discovered logger is absent from the cache" do
      adapter = TestAdapter.new([])
      stub_bulk
      stub_loggers_list # empty
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear
      adapter.emit_new_logger("ghost.logger", nil, Smplkit::LogLevel::INFO)
      expect(adapter.applied).to be_empty
    end

    it "does not apply when a hook-discovered logger is unmanaged in the cache" do
      adapter = TestAdapter.new([])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "ERROR", managed: false))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear
      adapter.emit_new_logger("my.logger", nil, Smplkit::LogLevel::INFO)
      expect(adapter.applied).to be_empty
    end
  end

  # ----------------------------------------------------------------
  # on_change / refresh gating + behavior
  # ----------------------------------------------------------------

  describe "#on_change (gating)" do
    it "raises NotInstalledError before install" do
      expect { logging.on_change { |_e| nil } }.to raise_error(Smplkit::NotInstalledError)
    end

    it "raises ArgumentError without a block (after install)" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      expect { logging.on_change }.to raise_error(ArgumentError, /requires a block/)
    end

    it "returns the registered block" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      block = proc { |_e| }
      expect(logging.on_change(&block)).to equal(block)
    end
  end

  describe "#refresh (gating)" do
    it "raises NotInstalledError before install" do
      expect { logging.refresh }.to raise_error(Smplkit::NotInstalledError)
    end

    it "re-resolves and fires a global listener on a level delta" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install

      events = []
      logging.on_change { |e| events << [e.id, e.level, e.source] }
      adapter.applied.clear
      # Re-stub the list with a moved level.
      stub_loggers_list(logger_resource("my.logger", level: "ERROR"))
      logging.refresh

      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::ERROR]])
      expect(events).to eq([["my.logger", "ERROR", "manual"]])
    end

    it "fires a key-scoped listener for its own logger only (id not normalized)" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install

      seen = []
      other = []
      logging.on_change("my.logger") { |e| seen << e.id }
      logging.on_change("other.logger") { |e| other << e.id }
      stub_loggers_list(logger_resource("my.logger", level: "ERROR"))
      logging.refresh
      expect(seen).to eq(["my.logger"])
      expect(other).to be_empty
    end

    it "does not fire when the resolved level is unchanged" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install

      events = []
      logging.on_change { |e| events << e.id }
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      logging.refresh
      expect(events).to be_empty
    end

    it "swallows a listener exception and keeps firing the rest" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install

      seen = []
      logging.on_change { raise "boom" }
      logging.on_change { |e| seen << e.id }
      stub_loggers_list(logger_resource("my.logger", level: "ERROR"))
      expect { logging.refresh }.not_to raise_error
      expect(seen).to eq(["my.logger"])
    end

    it "swallows an apply_level exception so other adapters still receive the level" do
      bad = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      ok  = TestAdapter.new([])
      bad.raise_on_apply = true
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(bad)
      logging.register_adapter(ok)
      logging.install
      stub_loggers_list(logger_resource("my.logger", level: "ERROR"))
      expect { logging.refresh }.not_to raise_error
      expect(ok.applied.last).to eq(["my.logger", Smplkit::LogLevel::ERROR])
    end
  end

  # ----------------------------------------------------------------
  # Event stream dispatch pipeline (after install)
  # ----------------------------------------------------------------

  describe "event stream dispatch" do
    # Install with one direct-level logger; clear applied/stubs afterward.
    def install_with_logger(level: "WARN", group: nil, name: "my.logger")
      adapter = TestAdapter.new([[name, nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource(name, level: level, group: group))
      stub_groups_list(*(@initial_groups || []))
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear
      adapter
    end

    it "logger_changed re-resolves + applies + fires on a delta" do
      adapter = install_with_logger(level: "WARN")
      events = []
      logging.on_change { |e| events << [e.id, e.level, e.source] }
      stub_logger_get("my.logger", logger_resource("my.logger", level: "ERROR"))
      stream.dispatch("logger_changed", { "id" => "my.logger" })
      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::ERROR]])
      expect(events).to eq([["my.logger", "ERROR", "push"]])
    end

    it "logger_changed fires nothing when the effective level is unchanged" do
      adapter = install_with_logger(level: "WARN")
      events = []
      logging.on_change { |e| events << e.id }
      stub_logger_get("my.logger", logger_resource("my.logger", level: "WARN"))
      stream.dispatch("logger_changed", { "id" => "my.logger" })
      expect(events).to be_empty
      expect(adapter.applied).to be_empty
    end

    it "logger_changed swallows a fetch failure and leaves the cache intact" do
      adapter = install_with_logger(level: "WARN")
      events = []
      logging.on_change { |e| events << e.id }
      stub_request(:get, "#{base_url}/api/v1/loggers/my.logger").to_return(status: 500, body: "boom")
      expect { stream.dispatch("logger_changed", { "id" => "my.logger" }) }.not_to raise_error
      expect(events).to be_empty
      expect(adapter.applied).to be_empty
    end

    it "logger_changed with no id is a safe no-op (empty-key fetch)" do
      install_with_logger(level: "WARN")
      stub_request(:get, "#{base_url}/api/v1/loggers/").to_return(status: 500, body: "boom")
      expect { stream.dispatch("logger_changed", {}) }.not_to raise_error
    end

    it "logger_deleted drops the logger and re-applies dependents" do
      # Two dot-related loggers: parent direct WARN, child inherits via ancestry.
      adapter = TestAdapter.new(
        [["com.acme", nil, Smplkit::LogLevel::INFO], ["com.acme.x", nil, Smplkit::LogLevel::INFO]]
      )
      stub_bulk
      stub_loggers_list(
        logger_resource("com.acme", level: "WARN"),
        logger_resource("com.acme.x", level: nil)
      )
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear

      events = []
      logging.on_change { |e| events << [e.id, e.level] }
      stream.dispatch("logger_deleted", { "id" => "com.acme" })
      # com.acme.x resolved to WARN via ancestry; after deletion falls back to INFO.
      expect(adapter.applied).to eq([["com.acme.x", Smplkit::LogLevel::INFO]])
      expect(events).to eq([["com.acme.x", "INFO"]])
      expect(events.map(&:first)).not_to include("com.acme")
    end

    it "group_changed re-fetches the group and re-applies dependent loggers" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: nil, group: "g1"))
      stub_groups_list(group_resource("g1", level: "WARN"))
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear

      events = []
      logging.on_change { |e| events << [e.id, e.level] }
      stub_group_get("g1", group_resource("g1", level: "FATAL"))
      stream.dispatch("group_changed", { "id" => "g1" })
      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::FATAL]])
      expect(events).to eq([["my.logger", "FATAL"]])
    end

    it "group_changed swallows a fetch failure and leaves the cache untouched" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: nil, group: "g1"))
      stub_groups_list(group_resource("g1", level: "WARN"))
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear

      stub_request(:get, "#{base_url}/api/v1/log_groups/g1").to_return(status: 500, body: "boom")
      expect { stream.dispatch("group_changed", { "id" => "g1" }) }.not_to raise_error
      expect(adapter.applied).to be_empty
    end

    it "group_deleted drops the group and re-applies dependents" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: nil, group: "g1"))
      stub_groups_list(group_resource("g1", level: "WARN"))
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear

      events = []
      logging.on_change { |e| events << [e.id, e.level] }
      stream.dispatch("group_deleted", { "id" => "g1" })
      # my.logger resolved to WARN via g1; after deletion falls back to INFO.
      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::INFO]])
      expect(events).to eq([["my.logger", "INFO"]])
    end

    it "loggers_changed triggers a full re-fetch + apply pass" do
      adapter = TestAdapter.new([["my.logger", nil, Smplkit::LogLevel::INFO]])
      stub_bulk
      stub_loggers_list(logger_resource("my.logger", level: "WARN"))
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear

      events = []
      logging.on_change { |e| events << [e.id, e.level] }
      stub_loggers_list(logger_resource("my.logger", level: "ERROR"))
      stub_groups_list
      stream.dispatch("loggers_changed", {})
      expect(adapter.applied).to eq([["my.logger", Smplkit::LogLevel::ERROR]])
      expect(events).to eq([["my.logger", "ERROR"]])
    end

    it "loggers_changed swallows a re-fetch failure" do
      install_with_logger(level: "WARN")
      stub_request(:get, "#{base_url}/api/v1/loggers")
        .with(query: hash_including({}))
        .to_return(status: 500, body: "boom")
      expect { stream.dispatch("loggers_changed", {}) }.not_to raise_error
    end

    it "global + key-scoped listeners both receive each per-logger delta" do
      ids = %w[app.db app.queue]
      adapter = TestAdapter.new(ids.map { |id| [id, nil, Smplkit::LogLevel::INFO] })
      stub_bulk
      stub_loggers_list(*ids.map { |id| logger_resource(id, level: nil, group: "app") })
      stub_groups_list(group_resource("app", level: "WARN"))
      logging.register_adapter(adapter)
      logging.install
      adapter.applied.clear

      global_a = []
      global_b = []
      key_db = []
      logging.on_change { |e| global_a << e.id }
      logging.on_change { |e| global_b << e.id }
      logging.on_change("app.db") { |e| key_db << e.id }

      stub_group_get("app", group_resource("app", level: "ERROR"))
      stream.dispatch("group_changed", { "id" => "app" })

      expect(global_a.length).to eq(2)
      expect(global_b.length).to eq(2)
      expect(key_db).to eq(["app.db"])
    end
  end

  # ----------------------------------------------------------------
  # close / _close
  # ----------------------------------------------------------------

  describe "#close" do
    it "uninstalls adapter hooks and calls off for every stream handler and the refetch" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      listeners = stream.instance_variable_get(:@listeners)
      expect(listeners["logger_changed"]).not_to be_empty

      allow(stream).to receive(:off).and_call_original
      allow(stream).to receive(:off_reconnect).and_call_original
      logging.close
      expect(adapter.uninstalled).to be(true)
      %w[logger_changed logger_deleted group_changed group_deleted loggers_changed].each do |event|
        expect(stream).to have_received(:off).with(event, an_instance_of(Proc))
      end
      expect(stream).to have_received(:off_reconnect).with(an_instance_of(Proc))
      expect(stream.instance_variable_get(:@refetch_callbacks)).to be_empty
    end

    it "is a no-op before install and never raises" do
      expect { logging.close }.not_to raise_error
    end

    it "swallows an adapter uninstall_hook error" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      bad = TestAdapter.new([])
      logging.register_adapter(bad)
      logging.install
      allow(bad).to receive(:uninstall_hook).and_raise(StandardError, "uninstall boom")
      expect { logging.close }.not_to raise_error
    end

    it "does not stop the parent's shared event stream (wired client)" do
      stub_bulk
      stub_loggers_list
      stub_groups_list
      logging.register_adapter(adapter)
      logging.install
      logging.close
      expect(stream.connection_status).to eq("disconnected")
    end

    it "_close aliases close" do
      expect { logging._close }.not_to raise_error
    end
  end

  # ----------------------------------------------------------------
  # Management surface: loggers sub-client CRUD + discovery buffer
  # ----------------------------------------------------------------

  describe "#loggers (LoggersClient)" do
    it "new returns an unsaved SmplLogger" do
      logger = logging.loggers.new("my.logger")
      expect(logger).to be_a(Smplkit::Logging::SmplLogger)
      expect(logger.name).to eq("my.logger")
      expect(logger.managed).to be(true)
    end

    it "new(managed: false) carries the flag through" do
      expect(logging.loggers.new("my.logger", managed: false).managed).to be(false)
    end

    it "list maps every returned resource to a SmplLogger" do
      stub_loggers_list(logger_resource("a", level: "INFO"), logger_resource("b", level: "DEBUG"))
      loggers = logging.loggers.list
      expect(loggers.map(&:id)).to contain_exactly("a", "b")
      expect(loggers.map(&:name)).to contain_exactly("a", "b")
    end

    it "list forwards page_number / page_size" do
      stub = stub_request(:get, "#{base_url}/api/v1/loggers")
             .with(query: { "page[number]" => "2", "page[size]" => "10" })
             .to_return(status: 200, body: list_body, headers: jsonapi_headers)
      logging.loggers.list(page_number: 2, page_size: 10)
      expect(stub).to have_been_requested
    end

    it "list returns [] when data is empty" do
      stub_loggers_list
      expect(logging.loggers.list).to eq([])
    end

    it "get fetches a single logger by id" do
      stub_logger_get("my.logger", logger_resource("my.logger", level: "WARN"))
      logger = logging.loggers.get("my.logger")
      expect(logger.id).to eq("my.logger")
      expect(logger.level).to eq(Smplkit::LogLevel::WARN)
    end

    it "get raises NotFoundError on a 404" do
      stub_logger_get("missing", nil, status: 404)
      expect { logging.loggers.get("missing") }.to raise_error(Smplkit::NotFoundError)
    end

    it "delete issues a DELETE and returns nil" do
      stub = stub_request(:delete, "#{base_url}/api/v1/loggers/my.logger").to_return(status: 204, body: "")
      expect(logging.loggers.delete("my.logger")).to be_nil
      expect(stub).to have_been_requested
    end

    it "SmplLogger#save PUTs via _update_logger" do
      stub_logger_get("my.logger", logger_resource("my.logger", level: "INFO"))
      logger = logging.loggers.get("my.logger")
      put = stub_request(:put, "#{base_url}/api/v1/loggers/my.logger")
            .to_return(status: 200,
                       body: { "data" => logger_resource("my.logger", level: "ERROR") }.to_json,
                       headers: jsonapi_headers)
      logger.level = Smplkit::LogLevel::ERROR
      logger.save
      expect(put).to have_been_requested
      expect(logger.level).to eq(Smplkit::LogLevel::ERROR)
    end

    it "register normalizes the name, bumps pending_count, and flush POSTs the normalized id" do
      src = Smplkit::LoggerSource.new(name: "My/Logger:Engine", resolved_level: Smplkit::LogLevel::DEBUG)
      logging.loggers.register(src)
      expect(logging.loggers.pending_count).to eq(1)

      captured = nil
      bulk = stub_request(:post, "#{base_url}/api/v1/loggers/bulk")
             .to_return do |req|
               captured = JSON.parse(req.body)
               { status: 200, body: { "registered" => 1 }.to_json, headers: jsonapi_headers }
             end
      logging.loggers.flush
      expect(bulk).to have_been_requested
      expect(captured["loggers"].map { |l| l["id"] }).to eq(["my.logger.engine"])
      expect(logging.loggers.pending_count).to eq(0)
    end

    it "register(items, flush: true) flushes immediately" do
      bulk = stub_bulk
      src = Smplkit::LoggerSource.new(name: "my.logger", resolved_level: Smplkit::LogLevel::INFO)
      logging.loggers.register(src, flush: true)
      expect(bulk).to have_been_requested
      expect(logging.loggers.pending_count).to eq(0)
    end

    it "register accepts an array of sources" do
      srcs = [
        Smplkit::LoggerSource.new(name: "a", resolved_level: Smplkit::LogLevel::INFO),
        Smplkit::LoggerSource.new(name: "b", resolved_level: Smplkit::LogLevel::DEBUG)
      ]
      logging.loggers.register(srcs)
      expect(logging.loggers.pending_count).to eq(2)
    end

    it "flush is a no-op when nothing is pending" do
      logging.loggers.flush
      expect(a_request(:post, "#{base_url}/api/v1/loggers/bulk")).not_to have_been_made
    end

    it "flush_sync aliases flush" do
      bulk = stub_bulk
      logging.loggers.register(
        Smplkit::LoggerSource.new(name: "my.logger", resolved_level: Smplkit::LogLevel::INFO)
      )
      logging.loggers.flush_sync
      expect(bulk).to have_been_requested
    end

    it "spawns a background flush once the batch threshold is crossed" do
      bulk = stub_bulk
      # Run the spawned flush synchronously so coverage of the flush body never
      # depends on background-thread timing (which flakes under CI).
      allow(Thread).to receive(:new) { |*a, &blk|
        blk.call(*a)
        nil
      }
      Smplkit::LOGGER_BATCH_FLUSH_SIZE.times do |i|
        logging.loggers.register(
          Smplkit::LoggerSource.new(name: "logger.#{i}", resolved_level: Smplkit::LogLevel::INFO)
        )
      end
      expect(bulk).to have_been_requested
    end

    it "threshold_flush swallows an error raised by the flush" do
      allow(logging.loggers).to receive(:flush).and_raise(StandardError, "threshold boom")
      expect { logging.loggers.send(:threshold_flush) }.not_to raise_error
    end

    it "list_logger_entries returns an id-keyed resolution-cache hash" do
      stub_loggers_list(
        logger_resource("a", level: "WARN", group: "g1", managed: true,
                             environments: { "staging" => { "level" => "TRACE" } })
      )
      entries = logging.loggers.list_logger_entries
      expect(entries).to eq(
        "a" => { "level" => "WARN", "group" => "g1", "managed" => true,
                 "environments" => { "staging" => { "level" => "TRACE" } } }
      )
    end

    it "list_logger_entries defaults managed to true when the attribute is absent" do
      resource = logger_resource("a", level: "WARN")
      resource["attributes"].delete("managed")
      stub_loggers_list(resource)
      expect(logging.loggers.list_logger_entries["a"]["managed"]).to be(true)
    end

    it "get_logger_entry returns the [id, entry] pair" do
      stub_logger_get("a", logger_resource("a", level: "ERROR"))
      id, entry = logging.loggers.get_logger_entry("a")
      expect(id).to eq("a")
      expect(entry["level"]).to eq("ERROR")
    end
  end

  # ----------------------------------------------------------------
  # Management surface: log_groups sub-client CRUD
  # ----------------------------------------------------------------

  describe "#log_groups (LogGroupsClient)" do
    it "new returns an unsaved SmplLogGroup with a defaulted display name" do
      group = logging.log_groups.new("payment_services")
      expect(group).to be_a(Smplkit::Logging::SmplLogGroup)
      expect(group.key).to eq("payment_services")
      expect(group.name).to eq("Payment Services")
      expect(group.group).to be_nil
    end

    it "new honours an explicit name and parent group" do
      group = logging.log_groups.new("child", name: "Child Group", group: "parent")
      expect(group.name).to eq("Child Group")
      expect(group.group).to eq("parent")
    end

    it "list maps every returned resource to a SmplLogGroup" do
      stub_groups_list(group_resource("a", level: "WARN"), group_resource("b"))
      groups = logging.log_groups.list
      expect(groups.map(&:key)).to contain_exactly("a", "b")
    end

    it "list forwards page_number / page_size" do
      stub = stub_request(:get, "#{base_url}/api/v1/log_groups")
             .with(query: { "page[number]" => "3", "page[size]" => "5" })
             .to_return(status: 200, body: list_body, headers: jsonapi_headers)
      logging.log_groups.list(page_number: 3, page_size: 5)
      expect(stub).to have_been_requested
    end

    it "list returns [] when data is empty" do
      stub_groups_list
      expect(logging.log_groups.list).to eq([])
    end

    it "get fetches a single group by id" do
      stub_group_get("g1", group_resource("g1", level: "WARN"))
      group = logging.log_groups.get("g1")
      expect(group.key).to eq("g1")
      expect(group.level).to eq(Smplkit::LogLevel::WARN)
    end

    it "delete issues a DELETE and returns nil" do
      stub = stub_request(:delete, "#{base_url}/api/v1/log_groups/g1").to_return(status: 204, body: "")
      expect(logging.log_groups.delete("g1")).to be_nil
      expect(stub).to have_been_requested
    end

    it "SmplLogGroup#save POSTs a brand-new group (no created_at)" do
      captured = nil
      post = stub_request(:post, "#{base_url}/api/v1/log_groups")
             .to_return do |req|
               captured = JSON.parse(req.body)
               { status: 201, body: { "data" => group_resource("g1", level: "WARN") }.to_json,
                 headers: jsonapi_headers }
             end
      group = logging.log_groups.new("g1", name: "Group One")
      group.level = Smplkit::LogLevel::WARN
      group.set_level(Smplkit::LogLevel::DEBUG, environment: "staging")
      group.save
      expect(post).to have_been_requested
      expect(captured["data"]["attributes"]["name"]).to eq("Group One")
      expect(captured["data"]["attributes"]["environments"]).to eq("staging" => { "level" => "DEBUG" })
      expect(group.created_at).not_to be_nil
    end

    it "SmplLogGroup#save PUTs an existing group (created_at present)" do
      stub_group_get("g1", group_resource("g1", level: "WARN"))
      group = logging.log_groups.get("g1")
      put = stub_request(:put, "#{base_url}/api/v1/log_groups/g1")
            .to_return(status: 200,
                       body: { "data" => group_resource("g1", level: "ERROR") }.to_json,
                       headers: jsonapi_headers)
      group.level = Smplkit::LogLevel::ERROR
      group.save
      expect(put).to have_been_requested
      expect(group.level).to eq(Smplkit::LogLevel::ERROR)
    end

    it "list_group_entries returns an id-keyed resolution-cache hash (parent_id as group)" do
      stub_groups_list(
        group_resource("g1", level: "WARN", parent_id: "root",
                             environments: { "staging" => { "level" => "TRACE" } })
      )
      entries = logging.log_groups.list_group_entries
      expect(entries).to eq(
        "g1" => { "level" => "WARN", "group" => "root",
                  "environments" => { "staging" => { "level" => "TRACE" } } }
      )
    end

    it "get_group_entry returns the [id, entry] pair" do
      stub_group_get("g1", group_resource("g1", level: "FATAL"))
      id, entry = logging.log_groups.get_group_entry("g1")
      expect(id).to eq("g1")
      expect(entry["level"]).to eq("FATAL")
    end
  end

  # ----------------------------------------------------------------
  # Module helpers
  # ----------------------------------------------------------------

  describe "Smplkit::Logging helpers" do
    it "auto_load_adapters always loads stdlib and (since the gem is bundled) semantic-logger" do
      adapters = Smplkit::Logging.auto_load_adapters
      names = adapters.map(&:name)
      expect(names).to include("stdlib-logger")
      expect(names).to include("semantic-logger")
    end

    it "auto_load_adapters skips the semantic-logger adapter when the gem is unavailable" do
      original = Smplkit::Logging.method(:require)
      allow(Smplkit::Logging).to receive(:require) do |lib|
        raise LoadError, "no semantic_logger" if lib == "semantic_logger"

        original.call(lib)
      end
      names = Smplkit::Logging.auto_load_adapters.map(&:name)
      expect(names).to eq(["stdlib-logger"])
    end
  end

  describe "Smplkit::Logging::LoggerChangeEvent" do
    it "exposes id / level / source and compares structurally" do
      a = Smplkit::Logging::LoggerChangeEvent.new(id: "x", level: "WARN", source: "push")
      b = Smplkit::Logging::LoggerChangeEvent.new(id: "x", level: "WARN", source: "push")
      c = Smplkit::Logging::LoggerChangeEvent.new(id: "x", level: "ERROR", source: "push")
      expect(a.id).to eq("x")
      expect(a.level).to eq("WARN")
      expect(a.source).to eq("push")
      expect(a).to eq(b)
      expect(a).not_to eq(c)
      expect(a).not_to eq("not an event")
    end
  end
end

# --- LoggingClient standalone construction -----------------------------
#
# The standalone shape builds + owns its own logging transport and event
# stream (no parent). +close+ tears down only what it owns.
RSpec.describe "Smplkit::Logging::LoggingClient (standalone)" do
  subject(:logging) do
    Smplkit::Logging::LoggingClient.new(
      "sk_standalone", environment: "staging",
                       base_url: "https://logging.smplkit.test", base_domain: "smplkit.test"
    )
  end

  after { logging.close }

  def jsonapi_headers
    { "Content-Type" => "application/vnd.api+json" }
  end

  it "builds and owns its own logging transport, reaching the resolved base URL" do
    stub = stub_request(:get, "https://logging.smplkit.test/api/v1/loggers/my.logger")
           .to_return(
             status: 200,
             body: {
               "data" => {
                 "id" => "my.logger", "type" => "logger",
                 "attributes" => { "name" => "my.logger", "level" => "WARN",
                                   "managed" => true, "environments" => {} }
               }
             }.to_json,
             headers: jsonapi_headers
           )
    logger = logging.loggers.get("my.logger")
    expect(logger.id).to eq("my.logger")
    expect(stub).to have_been_requested
  end

  it "#close before any install is a no-op" do
    expect { logging.close }.not_to raise_error
  end

  it "opens and owns its event stream on install, then tears it down on close" do
    fake_stream = instance_double(Smplkit::EventStream, start: nil, stop: nil, on: nil, off: nil,
                                                        on_reconnect: nil, off_reconnect: nil)
    allow(Smplkit::EventStream).to receive(:new).and_return(fake_stream)
    custom = TestAdapter.new([])
    logging.register_adapter(custom)
    stub_request(:post, "https://logging.smplkit.test/api/v1/loggers/bulk")
      .to_return(status: 200, body: "{}", headers: jsonapi_headers)
    stub_request(:get, "https://logging.smplkit.test/api/v1/loggers")
      .with(query: hash_including({}))
      .to_return(status: 200,
                 body: { "data" => [], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }.to_json,
                 headers: jsonapi_headers)
    stub_request(:get, "https://logging.smplkit.test/api/v1/log_groups")
      .with(query: hash_including({}))
      .to_return(status: 200,
                 body: { "data" => [], "meta" => { "pagination" => { "page" => 1, "size" => 1000 } } }.to_json,
                 headers: jsonapi_headers)

    logging.install
    expect(fake_stream).to have_received(:start)
    expect(fake_stream).to have_received(:on).with("logger_changed")
    expect(fake_stream).to have_received(:on).with("loggers_changed")
    expect(fake_stream).to have_received(:on_reconnect)

    logging.close
    expect(fake_stream).to have_received(:stop)
  end
end

# --- LoggingClient stateless mode (streaming: false) --------------------
#
# The stateless shape still installs — adapters, discovery, one blocking
# fetch-and-apply — but never opens an event stream or spawns a background
# thread; +refresh+ re-fetches and re-applies on demand.
RSpec.describe "Smplkit::Logging::LoggingClient (stateless, streaming: false)" do
  subject(:logging) do
    Smplkit::Logging::LoggingClient.new(
      "sk_stateless", environment: "staging", streaming: false,
                      base_url: "https://logging.smplkit.test", base_domain: "smplkit.test"
    )
  end

  let(:base_url) { "https://logging.smplkit.test" }

  after { logging.close }

  def jsonapi_headers
    { "Content-Type" => "application/vnd.api+json" }
  end

  def logger_resource(id, level:, managed: true)
    {
      "id" => id, "type" => "logger",
      "attributes" => {
        "name" => id, "level" => level, "group" => nil,
        "managed" => managed, "environments" => {},
        "created_at" => "2026-01-01T00:00:00Z", "updated_at" => "2026-01-01T00:00:00Z"
      }
    }
  end

  def list_body(*resources)
    {
      "data" => resources,
      "meta" => { "pagination" => { "page" => 1, "size" => 1000, "total" => resources.length,
                                    "total_pages" => 1 } }
    }.to_json
  end

  def stub_bulk
    stub_request(:post, "#{base_url}/api/v1/loggers/bulk")
      .to_return(status: 200, body: { "registered" => 1 }.to_json, headers: jsonapi_headers)
  end

  def stub_groups_list
    stub_request(:get, "#{base_url}/api/v1/log_groups")
      .with(query: hash_including({}))
      .to_return(status: 200, body: list_body, headers: jsonapi_headers)
  end

  it "install applies levels once without ever creating an event stream" do
    expect(Smplkit::EventStream).not_to receive(:new)
    stub_bulk
    stub_groups_list
    stub_request(:get, "#{base_url}/api/v1/loggers")
      .with(query: hash_including({}))
      .to_return(status: 200, body: list_body(logger_resource("my.logger", level: "DEBUG")),
                 headers: jsonapi_headers)
    adapter = TestAdapter.new([["My.Logger", nil, Smplkit::LogLevel::INFO]])
    logging.register_adapter(adapter)
    logging.install
    expect(adapter.applied).to eq([["My.Logger", Smplkit::LogLevel::DEBUG]])
  end

  it "keeps the NotInstalledError gate on on_change/refresh before install" do
    expect { logging.refresh }.to raise_error(Smplkit::NotInstalledError)
    expect { logging.on_change { nil } }.to raise_error(Smplkit::NotInstalledError)
  end

  it "refresh re-fetches and re-applies on demand, firing change listeners" do
    stub_bulk
    stub_groups_list
    stub_request(:get, "#{base_url}/api/v1/loggers")
      .with(query: hash_including({}))
      .to_return(
        { status: 200, body: list_body(logger_resource("my.logger", level: "INFO")),
          headers: jsonapi_headers },
        { status: 200, body: list_body(logger_resource("my.logger", level: "WARN")),
          headers: jsonapi_headers }
      )
    adapter = TestAdapter.new([["My.Logger", nil, Smplkit::LogLevel::INFO]])
    logging.register_adapter(adapter)
    logging.install
    adapter.applied.clear
    events = []
    logging.on_change("my.logger") { |e| events << e }
    logging.refresh
    expect(adapter.applied).to eq([["My.Logger", Smplkit::LogLevel::WARN]])
    expect(events.size).to eq(1)
    expect(events.first.id).to eq("my.logger")
    expect(events.first.level).to eq("WARN")
    expect(events.first.source).to eq("manual")
  end

  it "runs logger threshold flushes inline instead of spawning a background thread" do
    expect(Thread).not_to receive(:new)
    bulk = stub_bulk
    sources = (0...Smplkit::LOGGER_BATCH_FLUSH_SIZE).map do |i|
      Smplkit::Logging::LoggerSource.new(name: "logger.#{i}", resolved_level: "INFO")
    end
    logging.loggers.register(sources)
    # The threshold flush ran synchronously inside the crossing register call.
    expect(bulk).to have_been_requested.once
    expect(logging.loggers.pending_count).to eq(0)
  end
end

# --- LoggingClient.open ------------------------------------------------
RSpec.describe "Smplkit::Logging::LoggingClient.open" do
  # +.open+ forwards only keyword args to +new+, whose +api_key+ is positional;
  # supply the key through the environment so resolution succeeds without it.
  around do |example|
    original = ENV.fetch("SMPLKIT_API_KEY", nil)
    ENV["SMPLKIT_API_KEY"] = "sk_open"
    example.run
  ensure
    ENV["SMPLKIT_API_KEY"] = original
  end

  it "yields a client and closes it on exit" do
    yielded = nil
    Smplkit::Logging::LoggingClient.open(
      base_url: "https://logging.smplkit.test", base_domain: "smplkit.test"
    ) do |client|
      expect(client).to be_a(Smplkit::Logging::LoggingClient)
      yielded = client
    end
    expect(yielded).to be_a(Smplkit::Logging::LoggingClient)
  end
end
