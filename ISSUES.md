# Ruby SDK — Known Issues / Deferred Work

This file tracks work intentionally deferred from the initial Ruby SDK
implementation so it surfaces on the next look. Anything here that hasn't
been resolved when the SDK reaches feature parity with Python should be
addressed before a 1.0 release.

## Yank `smplkit-0.0.0` from rubygems.org

The initial release pipeline pushed `smplkit-0.0.0.gem` because Bundler
built the gem from `Smplkit::VERSION` (still hardcoded to `"0.0.0"` per
the "version lives in the tag, not the source" rule). The gemspec now
derives its version from `git describe --tags` at build time, so future
releases ship with the version that matches the GitHub release tag.

The `0.0.0` artifact on rubygems.org should be yanked manually:

```bash
gem yank smplkit -v 0.0.0
```

Requires owner-level RubyGems access. Not destructive — yanked versions
remain reachable for explicit installs but no longer satisfy version
ranges.

## RubyGems trusted-publisher (one-time setup, completed)

Configured 2026-05-05 for:

- Repository: `smplkit/ruby-sdk`
- Workflow: `ci-cd.yml`
- Environment: `production`

If the bare `smplkit` name is ever lost on rubygems.org, fall back to
`smplkit-sdk` per ADR-046 §2.1 — flip `spec.name` in `smplkit.gemspec`.
The `require "smplkit"` path stays the same.

## Generated client layer landed (2026-05-05)

All four generated trees (`app`, `config`, `flags`, `logging`) now ship
under `lib/smplkit/_generated/`, populated automatically by the
`smplkit/.github/actions/update-sdk` composite action when each source
service deploys. The wrapper layer still routes its CRUD/management
calls through hand-rolled Faraday connections in `ManagementClient` —
swapping those for the generated `AuthenticatedClient` per service is
the next mechanical pass.

**Next step:** require the appropriate `lib/smplkit/_generated/<svc>/...`
modules in `ManagementClient`, replace each `build_http(...)` with the
generated `AuthenticatedClient`, and migrate the namespace methods to
delegate to generated API calls (drop the hand-built JSON:API request
bodies in `helpers.rb` files where the generator covers them).

## Live WebSocket I/O wired (2026-05-05)

`Smplkit::SharedWebSocket` now hosts an `Async` reactor on a dedicated
daemon thread and uses `async-websocket` for the underlying I/O —
matching the Python `_ws.py` reference. Behaviors covered:

- `wss://` connect with `User-Agent: smplkit-ruby-sdk/<version>`.
- Wait for `{"type": "connected"}` handshake; surface `{"type":"error"}`
  as a runtime error.
- Heartbeat: server `"ping"` text → reply `"pong"`.
- Receive loop parses each JSON message and dispatches by `event` key.
- Reconnect with exponential backoff (1, 2, 4, 8, 16, 32, 60 s capped),
  using the Async-aware `task.sleep` so other fibers keep moving.
- `stop` closes the connection from the outer thread, the reader exits,
  and the daemon thread joins (with a 2 s deadline).

The unit specs cover URL building, listener register/dispatch/off,
ping/pong handling, JSON event parsing, the `:no_event`/`:unparseable`
branches, and start/stop lifecycle without standing up a real server.
Full integration verification (handshake against the real gateway,
backoff under flapping connections) is still a live-environment task.

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
