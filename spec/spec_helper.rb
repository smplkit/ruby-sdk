# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/lib/smplkit/_generated/"
  add_filter "/examples/"
  add_filter "/vendor/"
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
end
