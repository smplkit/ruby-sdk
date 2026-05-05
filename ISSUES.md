# Ruby SDK — Known Issues / Deferred Work

Tracks deferred work and notable decisions. Major items closed since
launch are listed first as historical record; open items follow.

## Closed (historical)

### `smplkit-0.0.0` yanked from rubygems.org (2026-05-05)

The very first release pipeline pushed `smplkit-0.0.0.gem` because
Bundler built from the hardcoded `Smplkit::VERSION = "0.0.0"`. The
gemspec now derives its version from `git describe --tags` at build
time. The `0.0.0` artifact was yanked manually:

```bash
gem yank smplkit -v 0.0.0
```

### RubyGems trusted-publisher configured (2026-05-05)

- Repository: `smplkit/ruby-sdk`
- Workflow: `ci-cd.yml`
- Environment: `production`

If the bare `smplkit` name is ever lost on rubygems.org, fall back to
`smplkit-sdk` per ADR-046 §2.1 — flip `spec.name` in `smplkit.gemspec`.
The `require "smplkit"` path stays the same.

### Generated client layer landed (2026-05-05)

All four generated trees (`app`, `config`, `flags`, `logging`) ship
under `lib/smplkit/_generated/`, populated automatically by the
`smplkit/.github/actions/update-sdk` composite action when each source
service deploys.

`ManagementClient` now routes every CRUD/management call through the
generated `SmplkitGeneratedClient::<Svc>::ApiClient` instances. The
namespaces hold a generated `<Resource>Api` and convert generated
response models to wrapper domain models at the boundary via
`ResourceShim.stringify` + the existing `helpers.rb` converters.
Errors are mapped from any `SmplkitGeneratedClient::*::ApiError` to
the `Smplkit::*` hierarchy via `ErrorMapping.call`.

`scripts/generate.sh` post-processes generator output to fix two
upstream-template bugs that recur on every regeneration:

1. `Logger.new(STDOUT)` in the per-service `Configuration` —
   inside `SmplkitGeneratedClient::Logging` this resolves to the
   generated model class. Replaced with `::Logger.new($stdout)`.
2. `:'AnyOf'` in openapi_types maps for `anyOf`-typed properties —
   the generator never declares an `AnyOf` constant, so
   deserialization fails. Replaced with `:'Object'`.

### Live WebSocket I/O wired (2026-05-05)

`Smplkit::SharedWebSocket` hosts an `Async` reactor on a dedicated
daemon thread and uses `async-websocket` for the underlying I/O,
mirroring the Python `_ws.py` reference. Forces HTTP/1.1 on the
`Async::HTTP::Endpoint` because the platform gateway speaks classic
RFC 6455 (not RFC 8441 over HTTP/2). Reconnect uses exponential
backoff (1, 2, 4, 8, 16, 32, 60 s capped) via Async-aware `task.sleep`.

### Eager service-context registration wired (2026-05-05)

`Client#register_service_context` now bulk-registers the active
environment + service as `Smplkit::Context` instances on construction,
flushing through `mgmt.contexts`. The buffer dedupes on `(type, key)`,
so this is safe to call on every client construction.

### SemanticLogger adapter discovery wired (2026-05-05)

`SemanticLoggerAdapter#install_hook` prepends into
`SemanticLogger::Logger#initialize` so every newly-created logger
fires the `on_new_logger` callback. `discover` reports tracked
loggers + the SemanticLogger root. Verified live with
`SemanticLogger["customer.module.payments"]` triggering the hook and
`apply_level` correctly mutating the logger.

### Coverage threshold enforced (2026-05-05)

`spec_helper.rb` sets `SimpleCov.minimum_coverage 75`; the build fails
if wrapper-layer coverage regresses. Current coverage sits at ~76%.
The standing target per CLAUDE.md is 100% — never lower the floor
without checking with Mike, only raise it.

### Per-class RBS sigs (2026-05-05)

`sig/smplkit.rbs` covers the top-level surface. `sig/smplkit/flags.rbs`,
`sig/smplkit/config.rbs`, `sig/smplkit/logging.rbs`, and
`sig/smplkit/management.rbs` add per-class signatures for the runtime
clients, domain models, adapter contract, and management namespaces.

## Open

### `make generate` requires Node.js + Java

`scripts/generate.sh` shells to `npx --yes @openapitools/openapi-generator-cli`,
which downloads the openapi-generator JAR and runs it via Java. Install
Node 18+ and a JRE (Java 11+) on PATH before invoking. The ci-cd
workflow's `update-sdk-ruby` job already pre-installs Ruby and the
GitHub-hosted runners include Node and Java by default.

### Coverage gap toward the 100% target

Wrapper-layer coverage is at ~76%; the longest-tail uncovered paths:

- `Client` construction — periodic flush timer, eager init thread,
  metrics path under telemetry on/off (24% covered).
- `ManagementClient` namespace bodies — many one-shot CRUD paths that
  need WebMock-stubbed requests through the generated transport
  (~56% covered).
- `Config::ConfigClient` resolve path under WS-driven invalidation
  (~54% covered).

Lift these by adding generated-transport-aware WebMock stubs (the
existing `client_spec.rb` already establishes the pattern for the
flags namespace).

### Ruby version floor: 3.3, not ADR-046's stated 3.2

ADR-046 §2.7 instructs to "verify the EOL schedule before fixing the
floor." Ruby 3.2 reached EOL on 2026-03-31; floor was raised to 3.3
(the lowest still-supported minor as of 2026-05-05). Update
`required_ruby_version` and the CI matrix when each subsequent minor
reaches EOL.

### `LICENSE` copyright year

Copied verbatim from the Python SDK (2026). No change needed; flagged
here to confirm ownership matches.
