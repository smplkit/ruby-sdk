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

Each product has two showcases — **management** and **runtime** — plus a setup helper that creates server-side state for the runtime showcase.

| Product | Management | Runtime | Setup |
|---------|-----------|---------|-------|
| **Flags** | `flags_management_showcase.rb` | `flags_runtime_showcase.rb` | `setup/flags_runtime_setup.rb` |
| **Config** | `config_management_showcase.rb` | `config_runtime_showcase.rb` | `setup/config_runtime_setup.rb` |
| **Logging** | `logging_management_showcase.rb` | `logging_runtime_showcase.rb` | `setup/logging_management_setup.rb` |

**Management showcases** demonstrate the programmatic CRUD API: creating resources with `new_*` + `save`, fetching with `get(id)`, listing, mutating, and deleting. No `wait_until_ready` needed — management methods are stateless HTTP calls.

**Runtime showcases** demonstrate the live evaluation path: declare typed handles, evaluate against per-request context via `client.set_context([...])` (the typical middleware shape), and react to live updates via `on_change` listeners.

## Run

From the repo root:

```bash
bundle install
make flags_runtime_showcase
make flags_management_showcase
make config_runtime_showcase
make config_management_showcase
make logging_runtime_showcase
make logging_management_showcase
```

Each `make <target>` shells out to `bundle exec ruby examples/<name>.rb`.

## Ruby-specific notes

The Ruby SDK exposes a single `Smplkit::Client` and a single `Smplkit::ManagementClient` (no async pair) per ADR-046 §2.2. Block-form scope overrides mirror Python's `with client.set_context(...)`:

```ruby
client.set_context([Smplkit::Context.new("user", "u-1")]) do
  flag.get
end
# context restored
```

`save!` and `delete!` aliases are available for convention satisfaction; both raise on failure (matching the non-bang versions).
