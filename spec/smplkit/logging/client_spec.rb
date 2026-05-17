# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Logging::LoggingClient do
  subject(:client) do
    described_class.new(parent, manage: management, metrics: nil,
                                logging_base_url: "https://logging.smplkit.test",
                                app_base_url: "https://app.smplkit.test")
  end

  let(:loggers_ns) do
    instance_double(
      Smplkit::ManagementClient::LoggersNamespace,
      register: nil, flush: nil,
      list_logger_entries: {},
      get_logger_entry: ["rails", logger_entry]
    )
  end
  let(:groups_ns) do
    instance_double(
      Smplkit::ManagementClient::LogGroupsNamespace,
      list_group_entries: {},
      get_group_entry: ["g1", group_entry]
    )
  end
  let(:management) do
    instance_double(Smplkit::ManagementClient, loggers: loggers_ns, log_groups: groups_ns)
  end
  let(:ws) do
    Smplkit::SharedWebSocket.new(app_base_url: "https://app.smplkit.test", api_key: "k")
  end
  let(:parent) do
    double(_service: "svc", _environment: "production", _ensure_ws: ws)
  end
  let(:logger_entry) do
    { "level" => "WARN", "group" => nil, "managed" => true, "environments" => {} }
  end
  let(:group_entry) do
    { "level" => "DEBUG", "group" => nil, "environments" => {} }
  end
  let(:adapter) do
    instance_double(Smplkit::Logging::Adapters::Base, name: "fake",
                                                      discover: [["rails", nil, Smplkit::LogLevel::INFO]],
                                                      install_hook: nil,
                                                      apply_level: nil,
                                                      uninstall_hook: nil)
  end

  before do
    # instance_double trips +is_a?(Adapters::Base)+ — set the adapter list
    # directly so the suite can use mocked adapters.
    client.instance_variable_set(:@adapters, [adapter])
  end

  describe "#install" do
    it "applies the resolved level to the adapter on install" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      allow(groups_ns).to receive(:list_group_entries).and_return({})

      client.install
      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::WARN)
    end

    it "applies a group-inherited level when the logger has no direct level" do
      inherit_logger = { "level" => nil, "group" => "g1", "managed" => true, "environments" => {} }
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => inherit_logger)
      allow(groups_ns).to receive(:list_group_entries).and_return("g1" => group_entry)

      client.install
      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::DEBUG)
    end

    it "skips unmanaged loggers" do
      unmanaged = { "level" => "ERROR", "group" => nil, "managed" => false, "environments" => {} }
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => unmanaged)

      client.install
      expect(adapter).not_to have_received(:apply_level)
    end

    it "skips loggers absent from the server-side cache" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return({})

      client.install
      expect(adapter).not_to have_received(:apply_level)
    end

    it "registers WebSocket handlers for every level-affecting event" do
      allow(ws).to receive(:on)
      client.install
      %w[logger_changed logger_deleted group_changed group_deleted loggers_changed].each do |event|
        expect(ws).to have_received(:on).with(event)
      end
    end

    it "swallows a fetch failure and continues with adapter wiring" do
      allow(loggers_ns).to receive(:list_logger_entries).and_raise(Smplkit::ConnectionError, "down")
      expect { client.install }.not_to raise_error
      expect(client.instance_variable_get(:@installed)).to be(true)
    end

    it "swallows a flush failure and continues with fetch + apply" do
      allow(loggers_ns).to receive(:flush).and_raise(Smplkit::ConnectionError, "down")
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      expect { client.install }.not_to raise_error
      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::WARN)
    end

    it "is idempotent on repeat invocation" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return({})
      client.install
      client.install
      expect(adapter).to have_received(:install_hook).once
    end
  end

  describe "#refresh" do
    it "re-resolves levels and fires change listeners on a delta" do
      first = { "level" => "WARN", "group" => nil, "managed" => true, "environments" => {} }
      second = { "level" => "ERROR", "group" => nil, "managed" => true, "environments" => {} }
      allow(loggers_ns).to receive(:list_logger_entries).and_return({ "rails" => first }, "rails" => second)
      allow(groups_ns).to receive(:list_group_entries).and_return({})

      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }
      client.install
      events.clear

      client.refresh
      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::ERROR)
      expect(events).to eq([%w[rails ERROR]])
    end

    it "does not fire when the resolved level is unchanged" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      allow(groups_ns).to receive(:list_group_entries).and_return({})

      events = []
      client.on_change { |e| events << e.name }
      client.install
      events.clear

      client.refresh
      expect(events).to be_empty
    end
  end

  describe "#handle_group_changed" do
    it "fires a change event for a logger whose level moves with its group" do
      inherit_logger = { "level" => nil, "group" => "g1", "managed" => true, "environments" => {} }
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => inherit_logger)
      allow(groups_ns).to receive(:list_group_entries).and_return("g1" => group_entry)

      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }
      client.install
      events.clear

      allow(groups_ns).to receive(:get_group_entry).with("g1")
                                                   .and_return(["g1",
                                                                { "level" => "FATAL", "group" => nil,
                                                                  "environments" => {} }])
      client.send(:handle_group_changed, "id" => "g1")

      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::FATAL)
      expect(events).to eq([%w[rails FATAL]])
    end

    it "ignores empty group ids" do
      client.install
      expect { client.send(:handle_group_changed, {}) }.not_to raise_error
    end

    it "swallows a fetch failure and leaves the cache untouched" do
      inherit_logger = { "level" => nil, "group" => "g1", "managed" => true, "environments" => {} }
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => inherit_logger)
      allow(groups_ns).to receive(:list_group_entries).and_return("g1" => group_entry)
      client.install

      allow(groups_ns).to receive(:get_group_entry).and_raise(Smplkit::ConnectionError, "down")
      expect { client.send(:handle_group_changed, "id" => "g1") }.not_to raise_error
      expect(client.instance_variable_get(:@groups_cache)["g1"]).to eq(group_entry)
    end
  end

  describe "#handle_group_deleted" do
    it "drops the group, re-applies dependents, fires no event for the deleted key" do
      inherit_logger = { "level" => nil, "group" => "g1", "managed" => true, "environments" => {} }
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => inherit_logger)
      allow(groups_ns).to receive(:list_group_entries).and_return("g1" => group_entry)

      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }
      client.install
      events.clear

      client.send(:handle_group_deleted, "id" => "g1")

      # rails: previously resolved to DEBUG via g1, now falls back to INFO
      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::INFO)
      expect(events).to eq([%w[rails INFO]])
      expect(events.map(&:first)).not_to include("g1")
    end

    it "no-ops on an unknown group id" do
      client.install
      events = []
      client.on_change { |e| events << e.name }
      client.send(:handle_group_deleted, "id" => "ghost")
      expect(events).to be_empty
    end

    it "ignores an empty id" do
      client.install
      expect { client.send(:handle_group_deleted, {}) }.not_to raise_error
    end
  end

  describe "#handle_logger_changed" do
    it "re-resolves and applies the new level after fetching the logger entry" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      client.install

      allow(loggers_ns).to receive(:get_logger_entry).with("rails")
                                                     .and_return(["rails",
                                                                  { "level" => "ERROR", "group" => nil,
                                                                    "managed" => true, "environments" => {} }])

      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }
      client.send(:handle_logger_changed, "id" => "Rails")

      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::ERROR)
      expect(events).to eq([%w[rails ERROR]])
    end

    it "ignores empty logger ids" do
      client.install
      expect { client.send(:handle_logger_changed, {}) }.not_to raise_error
    end

    it "swallows a fetch failure without crashing" do
      client.install
      allow(loggers_ns).to receive(:get_logger_entry).and_raise(Smplkit::ConnectionError, "down")
      expect { client.send(:handle_logger_changed, "id" => "rails") }.not_to raise_error
    end
  end

  describe "#handle_logger_deleted" do
    it "fires no event for the deleted logger itself" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      client.install

      events = []
      client.on_change { |e| events << e.name }
      client.send(:handle_logger_deleted, "id" => "rails")
      expect(events).to be_empty
    end

    it "fires for dot-descendants whose effective level moves" do
      ancestor_entry = { "level" => "WARN", "group" => nil, "managed" => true, "environments" => {} }
      descendant_entry = { "level" => nil, "group" => nil, "managed" => true, "environments" => {} }
      cascade_adapter = instance_double(
        Smplkit::Logging::Adapters::Base, name: "fake",
                                          discover: [["com.acme", nil, Smplkit::LogLevel::INFO],
                                                     ["com.acme.x", nil, Smplkit::LogLevel::INFO]],
                                          install_hook: nil, apply_level: nil, uninstall_hook: nil
      )
      client.instance_variable_set(:@adapters, [cascade_adapter])
      allow(loggers_ns).to receive(:list_logger_entries)
        .and_return("com.acme" => ancestor_entry, "com.acme.x" => descendant_entry)
      allow(groups_ns).to receive(:list_group_entries).and_return({})

      client.install
      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }

      client.send(:handle_logger_deleted, "id" => "com.acme")
      # com.acme.x was resolving via dot-ancestry to com.acme (WARN); after
      # deletion it falls back to INFO and must fire.
      expect(events).to eq([["com.acme.x", "INFO"]])
    end

    it "no-ops on an unknown logger id" do
      client.install
      events = []
      client.on_change { |e| events << e.name }
      client.send(:handle_logger_deleted, "id" => "ghost")
      expect(events).to be_empty
    end

    it "ignores an empty id" do
      client.install
      expect { client.send(:handle_logger_deleted, {}) }.not_to raise_error
    end
  end

  describe "change-listener fanout (diagnostics)" do
    # Helper — builds a mock adapter that "discovers" the given normalized
    # names so they end up in @name_map after install.
    def adapter_for(ids)
      instance_double(
        Smplkit::Logging::Adapters::Base,
        name: "fake",
        discover: ids.map { |id| [id, nil, Smplkit::LogLevel::INFO] },
        install_hook: nil, apply_level: nil, uninstall_hook: nil
      )
    end

    # Diagnostic 1: dot-ancestor cascade via logger_changed.
    it "fires per-logger when logger_changed cascades through dot-ancestors" do
      ids = %w[com.acme com.acme.payments com.acme.api com.acme.db com.acme.queue com.acme.auth]
      ancestor = { "level" => "WARN", "group" => nil, "managed" => true, "environments" => {} }
      descendant = { "level" => nil, "group" => nil, "managed" => true, "environments" => {} }
      cascade_adapter = adapter_for(ids)
      client.instance_variable_set(:@adapters, [cascade_adapter])
      initial_cache = ids.to_h { |id| [id, id == "com.acme" ? ancestor : descendant] }
      allow(loggers_ns).to receive(:list_logger_entries).and_return(initial_cache)
      allow(groups_ns).to receive(:list_group_entries).and_return({})

      client.install
      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }

      new_ancestor = { "level" => "ERROR", "group" => nil, "managed" => true, "environments" => {} }
      allow(loggers_ns).to receive(:get_logger_entry).with("com.acme")
                                                     .and_return(["com.acme", new_ancestor])
      client.send(:handle_logger_changed, "id" => "com.acme")

      expect(events.length).to eq(6)
      expect(events.map(&:first)).to match_array(ids)
      events.each { |(_, lvl)| expect(lvl).to eq("ERROR") }
    end

    # Diagnostic 2: group cascade via group_changed.
    it "fires per-logger when group_changed cascades to dependent loggers" do
      ids = %w[app.db app.queue app.api]
      logger_via_group = { "level" => nil, "group" => "app", "managed" => true, "environments" => {} }
      group_warn = { "level" => "WARN", "group" => nil, "environments" => {} }
      group_error = { "level" => "ERROR", "group" => nil, "environments" => {} }
      cascade_adapter = adapter_for(ids)
      client.instance_variable_set(:@adapters, [cascade_adapter])
      allow(loggers_ns).to receive(:list_logger_entries)
        .and_return(ids.to_h { |id| [id, logger_via_group] })
      allow(groups_ns).to receive(:list_group_entries).and_return("app" => group_warn)

      client.install
      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }

      allow(groups_ns).to receive(:get_group_entry).with("app").and_return(["app", group_error])
      client.send(:handle_group_changed, "id" => "app")

      expect(events.length).to eq(3)
      expect(events.map(&:first)).to match_array(ids)
      events.each { |(_, lvl)| expect(lvl).to eq("ERROR") }
    end

    # Diagnostic 3: group_deleted cascades; deleted key itself fires nothing.
    it "fires per-dependent on group_deleted; deleted key emits no event" do
      ids = %w[app.db app.queue app.api]
      logger_via_group = { "level" => nil, "group" => "app", "managed" => true, "environments" => {} }
      group_warn = { "level" => "WARN", "group" => nil, "environments" => {} }
      cascade_adapter = adapter_for(ids)
      client.instance_variable_set(:@adapters, [cascade_adapter])
      allow(loggers_ns).to receive(:list_logger_entries)
        .and_return(ids.to_h { |id| [id, logger_via_group] })
      allow(groups_ns).to receive(:list_group_entries).and_return("app" => group_warn)

      client.install
      events = []
      client.on_change { |e| events << [e.name, e.level&.name] }

      client.send(:handle_group_deleted, "id" => "app")

      expect(events.length).to eq(3)
      expect(events.map(&:first)).to match_array(ids)
      events.each { |(_, lvl)| expect(lvl).to eq("INFO") }
      expect(events.map(&:first)).not_to include("app")
    end

    # Diagnostic 4: no-op edit (no effective-level change) → no fire.
    it "fires nothing for a logger_changed whose effective level is unchanged" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      allow(groups_ns).to receive(:list_group_entries).and_return({})

      client.install
      events = []
      client.on_change { |e| events << e.name }

      # Same entry on re-fetch — only a name / description-style edit, no
      # effective-level change.
      allow(loggers_ns).to receive(:get_logger_entry).with("rails")
                                                     .and_return(["rails", logger_entry])
      client.send(:handle_logger_changed, "id" => "rails")

      expect(events).to be_empty
    end

    it "per-logger fanout: each delta fires every global listener exactly once" do
      ids = %w[app.db app.queue]
      logger_via_group = { "level" => nil, "group" => "app", "managed" => true, "environments" => {} }
      cascade_adapter = adapter_for(ids)
      client.instance_variable_set(:@adapters, [cascade_adapter])
      allow(loggers_ns).to receive(:list_logger_entries)
        .and_return(ids.to_h { |id| [id, logger_via_group] })
      allow(groups_ns).to receive(:list_group_entries)
        .and_return("app" => { "level" => "WARN", "group" => nil, "environments" => {} })

      client.install
      global_a = []
      global_b = []
      key_db = []
      client.on_change { |e| global_a << e.name }
      client.on_change { |e| global_b << e.name }
      client.on_change("app.db") { |e| key_db << e.name }

      allow(groups_ns).to receive(:get_group_entry).with("app")
                                                   .and_return(["app",
                                                                { "level" => "ERROR", "group" => nil,
                                                                  "environments" => {} }])
      client.send(:handle_group_changed, "id" => "app")

      # Two loggers moved → each global listener fires twice.
      expect(global_a.length).to eq(2)
      expect(global_b.length).to eq(2)
      # Key-scoped listener for app.db fires once (only its own delta).
      expect(key_db).to eq(["app.db"])
    end
  end

  describe "#handle_loggers_changed" do
    it "triggers a full re-fetch + apply pass" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return({})
      client.install
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)

      client.send(:handle_loggers_changed, {})
      expect(adapter).to have_received(:apply_level).with("rails", Smplkit::LogLevel::WARN)
    end
  end

  describe "listener and adapter resilience" do
    it "swallows a listener exception and keeps firing the next one" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      client.install

      seen = []
      client.on_change { raise "boom" }
      client.on_change { |e| seen << e.name }

      client.refresh.tap do
        # force a delta so listeners fire
        allow(loggers_ns).to receive(:list_logger_entries)
          .and_return("rails" => { "level" => "ERROR", "group" => nil, "managed" => true, "environments" => {} })
      end
      client.refresh
      expect(seen).to eq(["rails"])
    end

    it "swallows an adapter exception so other adapters still receive the level" do
      ok = instance_double(Smplkit::Logging::Adapters::Base, name: "ok",
                                                             discover: [], install_hook: nil,
                                                             apply_level: nil, uninstall_hook: nil)
      bad = instance_double(Smplkit::Logging::Adapters::Base, name: "bad",
                                                              discover: [], install_hook: nil,
                                                              uninstall_hook: nil)
      allow(bad).to receive(:apply_level).and_raise("boom")
      fresh = described_class.new(parent, manage: management, metrics: nil,
                                          logging_base_url: "https://x", app_base_url: "https://y")
      fresh.instance_variable_set(:@adapters, [bad, ok])
      # The local registry needs at least one normalized name to apply for.
      fresh.instance_variable_set(:@name_map, "rails" => "rails")
      fresh.instance_variable_set(:@loggers_cache, "rails" => logger_entry)
      fresh.send(:apply_levels, source: "websocket")
      expect(ok).to have_received(:apply_level).with("rails", Smplkit::LogLevel::WARN)
    end

    it "key-scoped listeners only fire for their own logger" do
      allow(loggers_ns).to receive(:list_logger_entries).and_return("rails" => logger_entry)
      client.install

      seen = []
      client.on_change("rails") { |e| seen << e.name }
      client.on_change("other") { |e| seen << "other:#{e.name}" }

      # Force a delta on rails:
      allow(loggers_ns).to receive(:list_logger_entries)
        .and_return("rails" => { "level" => "ERROR", "group" => nil, "managed" => true, "environments" => {} })
      client.refresh
      expect(seen).to eq(["rails"])
    end

    it "raises ArgumentError when on_change is called without a block" do
      expect { client.on_change }.to raise_error(ArgumentError)
    end

    it "rejects non-adapter values from register_adapter" do
      expect { client.register_adapter("nope") }.to raise_error(ArgumentError)
    end
  end
end
