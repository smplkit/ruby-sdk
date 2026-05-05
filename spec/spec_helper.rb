# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/lib/smplkit/_generated/"
  add_filter "/examples/"
  add_filter "/vendor/"
  # Rails-only adjacent files: only meaningful inside a Rails process.
  # Excluded from the wrapper-coverage gate so the SDK doesn't have to
  # boot Rails to test them.
  add_filter "/lib/smplkit/railtie.rb"
  add_filter "/lib/smplkit/generators/"
  # 100% wrapper-layer line coverage is the standing target per
  # ~/.claude/CLAUDE.md and is enforced here. Use +# :nocov:+ blocks
  # for genuinely-unreachable code (e.g. live-only background-thread
  # bodies) — never lower this floor.
  enable_coverage :line
  minimum_coverage line: 100
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
