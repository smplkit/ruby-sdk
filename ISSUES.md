# Ruby SDK — Known Issues / Deferred Work

This file tracks work intentionally deferred from the initial Ruby SDK
implementation so it surfaces on the next look. Anything here that hasn't
been resolved when the SDK reaches feature parity with Python should be
addressed before a 1.0 release.

## RubyGems trusted-publisher needs to be configured (manual step)

CI's first release run completed every step except the final
`rubygems/release-gem@v1` upload, which exits with:

> No trusted publisher configured for this workflow found on
> https://rubygems.org for audience rubygems.org

This matches the implementation prompt's note that the `production`
GitHub environment + the rubygems.org trusted-publisher entry are a
one-time manual setup on Mike's end. Steps:

1. Sign into rubygems.org under the smplkit org account.
2. Either reserve the `smplkit` gem name first (push the locally-built
   `smplkit-1.0.0.gem` once with an API key) or create a "pending
   trusted publisher" entry directly. Per
   https://guides.rubygems.org/trusted-publishing/ pending publishers
   are the supported flow for first-time publishes via OIDC.
3. Configure the trusted publisher with:
   - Repository: `smplkit/ruby-sdk`
   - Workflow: `ci-cd.yml`
   - Environment: `production`
4. Re-run the failed release job (or push any new commit to `main`).

Side effect of the failure: GitHub release `v1.0.0` and the corresponding
git tag are already created and pushed by `sdk-release-prepare`. They are
fine; the workflow is idempotent and will pick up where it left off after
the trusted publisher exists.

If the bare `smplkit` name is already taken on rubygems.org, fall back to
`smplkit-sdk` per ADR-046 §2.1 — flip `spec.name` in `smplkit.gemspec`.
The `require "smplkit"` path stays the same.

## Generated client layer not yet committed

`lib/smplkit/_generated/` is empty in this initial commit. The wrapper layer
talks directly to Faraday for the management endpoints it needs (CRUD on
flags, configs, environments, etc.) using JSON:API request bodies it builds
itself.

**Why deferred:** running `openapi-generator-cli` with the `ruby-faraday`
template requires a clean Node toolchain and a careful pass through the
generator's output (it produces a fairly large tree per service). The
wrapper layer is structured so the switch to generated transports is a
mechanical change (replace each `Faraday.new(...)` with the generated
`AuthenticatedClient`).

**Next step:** `make generate` (with `npx` available) and wire the four
generated namespaces — `SmplkitGeneratedClient::App`, `::Config`, `::Flags`,
`::Logging` — into the existing `ManagementClient` namespaces. Adjust
`require_relative "_generated/..."` paths and rerun the spec suite.

## Live WebSocket I/O is in-memory only

`Smplkit::SharedWebSocket#start` marks the connection as `"connected"`
without opening a real socket. Listener registration, dispatch, and the URL
builder all work; the actual read/write loop is what's stubbed.

**Why deferred:** `async-websocket` integration needs to be tested against
the live event gateway's protocol (User-Agent header requirement, `ping` /
`pong` heartbeat semantics, exponential backoff). Wiring the full I/O path
without that integration test is risky.

**Next step:** add the I/O thread that wraps `Async { ... }`,
`async-websocket`'s `WebSocket.connect`, and the receive loop. Use
`SharedWebSocket#mark_connected!` from inside the loop after the initial
`{"type": "connected"}` frame arrives.

## Service-context registration on init is a stub

`Client#register_service_context` rescues every exception and exits. The
buffered registration path through `mgmt.contexts.register` works; only the
eager bootstrap call into the bulk endpoint is stubbed.

**Next step:** call `@manage.contexts.register(...)` with the
service+environment pair on the init thread, then trigger an immediate
flush. (The buffer is already deduplicated, so it's safe to do this on
every client construction.)

## SemanticLogger adapter discovery is partial

`SemanticLoggerAdapter#discover` falls back to whatever loggers were
explicitly tracked. The full crawl of `SemanticLogger`'s internal registry
is left for a follow-up because the gem's API for "list all loggers"
varies across versions and needs version-pinning.

**Next step:** pin `semantic_logger` to a specific minor in `Gemfile`,
read the source for that version, and implement crawling against it.

## `make generate` requires Node.js

`scripts/generate.sh` invokes `npx --yes @openapitools/openapi-generator-cli`.
Install Node 18+ first.

## Coverage threshold not enforced at 100%

Per the userMemories the SDK target is 100% on the wrapper layer. The
initial release lands at ~67-70% line coverage (verified locally) — full
100% requires both the generated layer to land and additional spec passes
covering the request/response code paths. Coverage threshold is not
enforced in CI yet (`SimpleCov` runs but doesn't fail the build); it should
be flipped on once the generated layer brings the denominator down.

## RBS sigs are minimal

`sig/smplkit.rbs` covers the top-level constants. Per-class sigs are not
yet written. They'd be straightforward to generate from the public method
signatures in the wrapper layer.

## Ruby version: bumped from ADR-046 §2.7 floor of 3.2 to 3.3

Per the ADR's "verify EOL schedule before fixing the floor" instruction,
Ruby 3.2 reached EOL on 2026-03-31; the floor was raised to 3.3 (the lowest
still-supported minor as of 2026-05-05). Update `required_ruby_version` and
the CI matrix when each subsequent minor reaches EOL.

## `LICENSE` copyright year

Copied verbatim from the Python SDK (2026). No change needed; flagged here
to confirm ownership matches.
