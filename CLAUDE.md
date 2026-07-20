# smplkit Ruby SDK

See `~/.claude/CLAUDE.md` for universal rules (git workflow, testing, code quality, SDK conventions, etc.).

## Repository structure

Two-layer architecture per ADR-021:

- `lib/smplkit/_generated/` — Auto-generated client code from OpenAPI specs. Do not edit manually.
- `lib/smplkit/` (excluding `_generated/`) — Hand-crafted SDK wrapper. This is the public API.

## The reference rule (ADR-046)

The Python SDK at `smplkit/python-sdk` is the canonical reference for every public surface — class names, method names, comment text, showcase narrative. Where Ruby idiom genuinely demands a deviation, the deviation is documented in [ADR-046](https://github.com/smplkit/app/blob/main/docs/adrs/ADR-046-ruby-sdk.md). Do not invent new method names or restructure modules without a corresponding ADR-046 entry.

## Regenerating clients

```bash
make generate
```

Requires `npx` (Node.js) on PATH. Spec updates land here via automated PRs (see ADR-021).

## Testing

```bash
bundle exec rspec      # all unit tests
bundle exec rubocop    # lint
```

The Ruby SDK's wrapper layer aims for high coverage. The `_generated/` tree is excluded from the coverage calculation (matching the Python SDK's `fail_under = 100` exclusion).

## Ruby version policy

Minimum supported Ruby: **3.1**. Development uses 3.4 (latest stable). CI runs the full test suite against every supported minor (3.1, 3.2, 3.3, 3.4) on every push.

Do not use Ruby features introduced after 3.1 unless guarded. Specifically: `Data.define` (3.2+) is off-limits — use `Struct.new(keyword_init: true)` instead.

## Package naming

- **RubyGems gem name:** `smplkit` (install via `gem install smplkit`)
- **Top-level Ruby module:** `Smplkit` (require via `require "smplkit"`)

If RubyGems rejects the bare `smplkit` name on first publish, the gemspec falls back to `smplkit-sdk` while keeping the require path identical (per ADR-046 §2.1).

## Publishing

- Version is read from `lib/smplkit/version.rb` (`Smplkit::VERSION`), set by `sdk-release-prepare` from conventional commits.
- Publishes to RubyGems via OIDC trusted publishing (`rubygems/release-gem@v1`).
- Pre-launch SDK commit lockdown: every commit lands as `fix:` (no `feat:` or `BREAKING CHANGE:` until the lockdown is lifted by Mike).

## Coverage gate

CI fails the build if wrapper-layer line coverage is below 100% (set in `spec/spec_helper.rb`). The `_generated/`, Railtie, and Rails generator files are excluded from the gate. Use `# :nocov:` block markers sparingly for genuinely-unreachable defensive code; never lower the floor.

## Publishing — version comes from the tag

The gemspec derives the gem version at build time from `git describe --tags --abbrev=0` (with `SMPLKIT_GEM_VERSION` env-var override for the manual_version dispatch path). `lib/smplkit/version.rb` stays at `"0.0.0"` and is only used as a local-dev fallback. `sdk-release-prepare` creates the canonical tag; `rake release` is overridden in the `Rakefile` to skip Bundler's `git tag` step (the tag is already pushed) and just push the gem.

## smplkit MCP server — operate the platform via MCP

smplkit runs a **hosted MCP server** at `https://mcp.smplkit.com/api/mcp` that operates the whole platform — feature flags, config, log levels, audit search, and scheduled jobs — exposed as MCP tools (source: the `mcp` repo). When a task means *operating* the platform (reading job runs, flipping a flag, changing a config value, setting a log level, searching the audit log) rather than editing service source, prefer these MCP tools over ad-hoc curl or one-off SDK scripts.

If it isn't connected yet, tell the user and offer to add it:

    claude mcp add --transport http smplkit https://mcp.smplkit.com/api/mcp

First connect does a one-time browser sign-in (Google/Microsoft, WorkOS AuthKit OAuth) and refreshes itself after that. A committed `.mcp.json` at each repo root advertises the same server so Claude Code / Cursor auto-detect it.
