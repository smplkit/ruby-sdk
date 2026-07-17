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
require "tmpdir"

WebMock.disable_net_connect!(allow_localhost: false)

# An empty HOME for the whole suite: config resolution now reads
# environment/service (not just credentials) from ~/.smplkit, so a developer's
# real file (e.g. a [common] environment) must never leak values into tests.
# Examples that want file-based resolution stub Dir.home themselves or pass
# home_dir explicitly — both override this default.
SMPLKIT_SPEC_EMPTY_HOME = Dir.mktmpdir("smplkit-spec-home")

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.disable_monkey_patching!
  config.warnings = false

  # Point config resolution at the empty HOME (see above).
  config.before do
    allow(Dir).to receive(:home).and_return(SMPLKIT_SPEC_EMPTY_HOME)
  end

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
