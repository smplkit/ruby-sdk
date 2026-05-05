# smplkit Ruby SDK

[![Gem Version](https://badge.fury.io/rb/smplkit.svg)](https://rubygems.org/gems/smplkit)
[![CI](https://github.com/smplkit/ruby-sdk/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/smplkit/ruby-sdk/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official Ruby SDK for the [smplkit](https://www.smplkit.com) platform — flags, config, and logging APIs with runtime evaluation, live updates, and management operations.

The Ruby SDK mirrors the [Python SDK](https://github.com/smplkit/python-sdk) class-for-class. Ruby-specific deviations are documented in [ADR-046](https://github.com/smplkit/app/blob/main/docs/adrs/ADR-046-ruby-sdk.md).

## Installation

```bash
gem install smplkit
```

Or in a Gemfile:

```ruby
gem "smplkit"
```

Requires Ruby 3.3+.

## Quick start

### Runtime

```ruby
require "smplkit"

Smplkit::Client.open(environment: "production", service: "my-svc") do |client|
  checkout_v2 = client.flags.boolean_flag("checkout-v2", default: false)
  client.wait_until_ready

  client.set_context([Smplkit::Context.new("user", "u-1", plan: "enterprise")]) do
    if checkout_v2.get
      # show new checkout
    end
  end
end
```

### Management

```ruby
manage = Smplkit::ManagementClient.new

flag = manage.flags.new_boolean_flag(
  "checkout-v2", default: false, description: "Controls rollout"
)
flag.add_rule(
  Smplkit::Rule.new("Enable for enterprise users", environment: "staging")
               .when("user.plan", Smplkit::Op::EQ, "enterprise")
               .serve(true)
)
flag.save
```

## Configuration

Resolution order, lowest to highest priority:

1. SDK hardcoded defaults
2. `~/.smplkit` config file (with `[common]` and profile sections)
3. `SMPLKIT_*` environment variables
4. Constructor arguments

See [ADR-021](https://github.com/smplkit/app/blob/main/docs/adrs/ADR-021-client-strategy.md) for details.

## Logging adapters

Two adapters ship at launch (per ADR-046 §2.3):

| Adapter           | Covers                                                                  |
|-------------------|-------------------------------------------------------------------------|
| `stdlib-logger`   | Ruby stdlib `Logger` (and Rails via `ActiveSupport::Logger`)            |
| `semantic-logger` | The [`semantic_logger` gem](https://github.com/reidmorrison/semantic_logger) |

Custom adapters subclass `Smplkit::Logging::Adapters::Base`.

## Rails integration

Add the gem and run:

```bash
rails generate smplkit:install
```

This creates `config/initializers/smplkit.rb` with documented examples for the per-request context provider and standard configuration knobs.

## Development

```bash
bundle install
bundle exec rspec        # unit tests
bundle exec rubocop      # lint
make generate            # regenerate clients (requires Node.js + npx)
```

The repository follows the standard smplkit "every commit lands on `main`" workflow — see CLAUDE.md.

## License

MIT — see [LICENSE](LICENSE).
