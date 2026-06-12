# smplkit Ruby SDK Examples

Runnable examples demonstrating the [smplkit Ruby SDK](https://github.com/smplkit/ruby-sdk).

> **Note:** These examples require valid smplkit credentials and a live environment — they are not self-contained demos.

## Prerequisites

1. Install the SDK:

   ```bash
   gem install smplkit
   ```

2. A valid smplkit API key, provided via one of:
   - `SMPLKIT_API_KEY` environment variable
   - `~/.smplkit` configuration file (see SDK docs)
3. At least two environments configured (e.g., `staging`, `production`).

## Structure

There is **one** client per product, reached from `Smplkit::Client`:
`client.config`, `client.flags`, `client.logging`, `client.audit`, and
`client.jobs`. Management/CRUD lives directly on each product client —
`client.config.new/get/list/delete`, the `client.flags.new_*` builders, and
`client.logging.loggers` / `client.logging.log_groups`. Each product can also be
used via a standalone client (`Smplkit::AuditClient`, `Smplkit::JobsClient`).

Config/Flags/Logging keep a **management** + **runtime** showcase pair (the two
sides — CRUD vs. evaluation — are genuinely different). Audit and Jobs have **one**
showcase each — they have no runtime/management split (one client, full surface).

| Product | Management | Runtime | Setup |
|---------|-----------|---------|-------|
| **Flags** | `flags_management_showcase.rb` | `flags_runtime_showcase.rb` | `setup/flags_runtime_setup.rb` |
| **Config** | `config_management_showcase.rb` | `config_runtime_showcase.rb` | `setup/config_runtime_setup.rb` |
| **Logging** | `logging_management_showcase.rb` | `logging_runtime_showcase.rb` | `setup/logging_management_setup.rb` |
| **Audit** | `audit_showcase.rb` — single; events, discovery, categories, and forwarders | | _(none)_ |
| **Jobs** | `jobs_showcase.rb` — single; job CRUD, runs, usage | | _(none)_ |

**Management showcases** demonstrate the programmatic CRUD API directly on the
product client: creating resources with `new_*` + `save`, fetching with
`get(id)`, listing, mutating, and deleting. No `install`/`wait_until_ready`
needed — management methods are stateless HTTP calls.

**Runtime showcases** demonstrate the live evaluation path: config and flags
connect lazily on first live use (no install step), logging hooks in via
`client.logging.install`. Each declares typed handles / binds models, evaluates
against per-request context via `client.set_context([...])` (the typical
middleware shape), and reacts to live updates via `on_change` listeners. Each
runtime showcase imports its setup helper to create server-side state, then
cleans up after itself.

## Run

From the repo root:

```bash
bundle install

# Single-client products (Audit, Jobs — full surface, no runtime/management split)
make audit_showcase
make jobs_showcase

# Management / CRUD (directly on client.config / client.flags / client.logging)
make flags_management_showcase
make config_management_showcase
make logging_management_showcase

# Runtime (imports its setup helper automatically)
make flags_runtime_showcase
make config_runtime_showcase
make logging_runtime_showcase
```

Each `make <target>` shells out to `bundle exec ruby examples/<name>.rb`, creates
temporary resources, exercises all SDK features, then cleans up after itself.

## Ruby-specific notes

The Ruby SDK exposes a single `Smplkit::Client` (no async pair) per ADR-046 §2.2.
Block-form scope overrides mirror Python's `with client.set_context(...)`:

```ruby
client.set_context([Smplkit::Context.new("user", "u-1")]) do
  flag.get
end
# context restored
```

`save!` and `delete!` aliases are available for convention satisfaction; both raise on failure (matching the non-bang versions).
