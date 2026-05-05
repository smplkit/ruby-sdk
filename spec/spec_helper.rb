# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/lib/smplkit/_generated/"
  add_filter "/examples/"
  add_filter "/vendor/"
  add_filter "/lib/smplkit/railtie.rb"
  add_filter "/lib/smplkit/generators/"
  add_filter "/lib/smplkit/ws.rb"
  # Wrapper-layer floor. The standing target per the user's CLAUDE.md is
  # 100% on SDK wrappers; this floor is a regression guard while the
  # heavier paths (Client construction, save-cycle helpers, ManagementClient
  # CRUD against live servers) gain spec coverage. Never lower without
  # checking with Mike — only raise.
  minimum_coverage 75
end

require "smplkit"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: false)

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.disable_monkey_patching!
  config.warnings = false

  # Reset request context between examples to avoid leakage.
  config.after do
    Thread.current[Smplkit::RequestContext::KEY] = nil
  end

  # The StdlibLoggerAdapter prepends a permanent module onto ::Logger to catch
  # new-logger creation. The hook persists across examples; clear the active
  # adapter list between examples so prior tests' adapters can't fire on
  # later tests' Logger.new calls.
  config.after do
    Smplkit::Logging::Adapters::StdlibLoggerAdapter.adapters.clear
  end
end
