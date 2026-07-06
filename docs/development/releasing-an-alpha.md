# Releasing an `eql_v3` alpha

A concise runbook for cutting a **prerelease** (alpha/beta/rc) of the EQL SQL
surface, the `eql-bindings` crate, or both in lockstep. For a final
(non-prerelease) release, follow the **"Cutting a release"** section of
`CLAUDE.md` instead.

## What ships

Alpha releases ship the same EQL assets as final releases:

| Artifact | What it installs |
|----------|------------------|
| `cipherstash-encrypt.sql` / `cipherstash-encrypt-uninstall.sql` | **The standalone, self-contained `eql_v3` surface** (no `eql_v2`) |
| `eql-docs-*.zip` / `eql-docs-*.tar.gz` | Packaged API documentation |

The CI-native alpha coordinator (`.github/workflows/release-alpha.yml`) builds
and attaches the SQL files and docs bundle **in the same workflow run**. This is
intentional: releases created by the automatic `GITHUB_TOKEN` do not trigger
follow-on release workflows, so alpha assets cannot rely on release-event fan-out.

`cipherstash-encrypt.sql` is the only installer: it installs the `eql_v3`
schema into a database with no `eql_v2` present. There is no separate
`-supabase` or `-v3` artifact.

## Why a prerelease is different

The final-release `verify-changelog` job is gated to **real (non-prerelease)
`eql-*` releases**:

```yaml
if: ${{ github.event_name == 'release' && contains(github.event.release.tag_name, 'eql') && github.event.release.prerelease == false }}
```

For a prerelease, do **not** promote `[Unreleased]` to `[<version>]` in
`CHANGELOG.md`. Entries stay under `## [Unreleased]` until a final release is
cut.

## CI-native release tasks

Use one of the thin `mise` tasks. Each task dispatches
`.github/workflows/release-alpha.yml` via `workflow_dispatch`, passes a unique
`dispatch_id`, and watches that exact run. Release-relevant work happens in CI,
not locally.

| Task | Coordinator target | Result |
|------|--------------------|--------|
| `mise run release:all` | `all` | Pins `eql-bindings` to the resolved identity, commits and pushes the pin, builds and attaches SQL + docs, then dispatches `release-plz.yml` so the crate publishes from the same commit. |
| `mise run release:eql` | `eql` | Builds and attaches the SQL prerelease + docs only. No crate publish and no pin commit. |
| `mise run release:bindings` | `bindings` | Publishes `eql-bindings` for an existing `eql-<identity>` SQL release from the same source, with a metadata-only pin commit on top. |

`release:all` and `release:bindings` require `--ref <branch>` because the
coordinator pushes the crate-version pin. `release:eql` can run against any ref
because it does not push.

Common flags:

| Flag | Meaning | Default |
|------|---------|---------|
| `--version` | Base SemVer (`X.Y.Z`) | `3.0.0` |
| `--channel` | Prerelease channel: `alpha` \| `beta` \| `rc` | `alpha` |
| `--pre` | Exact identity (`X.Y.Z-(alpha\|beta\|rc).N`), bypassing derivation | derived |
| `--ref` | GitHub ref for `workflow_dispatch` | required explicitly for `release:all` and `release:bindings`; current branch for `release:eql` |
| `--dry-run` | Resolve, verify, and print the plan without mutating anything | off |

Examples:

```bash
# Always start here: derive identity and run drift gates without publishing.
mise run release:all --ref eql_v3 --dry-run

# Ship SQL + docs and the crate in lockstep.
mise run release:all --ref eql_v3

# Ship only the SQL surface + docs.
mise run release:eql --channel beta

# Publish the crate for an already-existing SQL alpha, same source.
mise run release:bindings --pre 3.0.0-alpha.2 --ref eql_v3
```

## Identity and lockstep

The release identity is `<version>-<channel>.<N>`, for example
`3.0.0-alpha.2`. The coordinator derives `N` server-side from freshly fetched
tags across both namespaces:

- SQL tags: `eql-<identity>`
- Crate tags: `eql-bindings-v<identity>`

For `release:all` and `release:eql`, `N` is one greater than the maximum matching
counter found in either namespace. For `release:bindings`, the coordinator finds
an existing SQL alpha that does not yet have a matching crate tag.

`release:all` is the normal lockstep path. The coordinator pins the crate,
commits that metadata change as commit `S`, builds SQL + docs at `S`, creates
`eql-<identity>` at `S`, and dispatches `release-plz.yml` against that immutable
SQL tag. The resulting `eql-<identity>` and `eql-bindings-v<identity>` tags land
on the same commit.

`release:bindings` is for catching up the crate after an existing SQL alpha. The
branch must currently point at the SQL tag commit. The coordinator verifies that
`HEAD == eql-<identity>`, adds the metadata-only crate pin commit on top, then
dispatches `release-plz.yml`. This guarantees the crate ships the same generated
source as the SQL release, not later product code.

## Coordinator checks

Before mutating anything, the coordinator validates inputs, fetches tags, derives
the identity, checks target-specific tag existence, and runs the drift gates:

```bash
mise run types:check
mise run codegen:parity
```

For `release:all` and `release:bindings`, it also rejects non-branch refs because
the crate pin must be pushed. For `release:bindings`, it rejects a branch that has
advanced past the SQL tag.

The crate publish remains a separate `release-plz.yml` run because crates.io
Trusted Publishing validates the entry-point workflow identity. The coordinator
dispatches that workflow only after SQL and docs have been built and attached.

## Verification note

The durable PR gate is `.github/workflows/lint-release.yml`. It runs actionlint
over the release workflows, ShellCheck over the release wrappers and identity
helper, and `.github/scripts/derive-identity.test.sh`.

The SQL to docs to crate ordering can be exercised safely only on a scratch
branch, because a real crate publish is irreversible. For a scratch validation,
temporarily force the docs reusable to fail, run `mise run release:eql --ref
<scratch-branch>` or `mise run release:all --ref <scratch-branch>`, and confirm
that no crate publish is dispatched when docs attachment fails. Revert the
scratch change before any real alpha.

## Smoke-test the alpha

Install the standalone v3 surface into a clean database (no `eql_v2`) and confirm
it loads:

```bash
gh release download eql-3.0.0-alpha.N -p 'cipherstash-encrypt.sql'
psql "$DATABASE_URL" -f cipherstash-encrypt.sql
psql "$DATABASE_URL" -c "\dn eql_v3"                 # eql_v3 schema present
psql "$DATABASE_URL" -c "SELECT eql_v3.version();"   # released semver
```

For a lockstep release, also confirm both tags point at the same commit:

```bash
git fetch --tags
git rev-list -n1 eql-3.0.0-alpha.N
git rev-list -n1 eql-bindings-v3.0.0-alpha.N
```

## Promoting to a final release later

When the alpha graduates to a real release, follow `CLAUDE.md` -> **"Cutting a
release"**: rename `## [Unreleased]` to `## [<version>] - YYYY-MM-DD`, add a
fresh empty `[Unreleased]`, update the link references at the bottom of
`CHANGELOG.md`, then cut a **non-prerelease** GitHub release whose body is the
new versioned section verbatim. The `verify-changelog` job then enforces that
the `## [<version>]` section exists at the tag.
