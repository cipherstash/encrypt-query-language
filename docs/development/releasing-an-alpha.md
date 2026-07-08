# Releasing from `release.yml`

A concise runbook for cutting a **prerelease** of the EQL SQL surface, its
language binding packages (the `eql-bindings` crate and the `@cipherstash/eql`
npm package), or all of them in lockstep. For a final (non-prerelease) release,
follow the **"Cutting a release"** section of `CLAUDE.md` instead.

## What ships

Alpha releases ship the same EQL assets as final releases:

| Artifact | What it installs |
|----------|------------------|
| `cipherstash-encrypt.sql` / `cipherstash-encrypt-uninstall.sql` | **The standalone, self-contained `eql_v3` surface** (no `eql_v2`) |
| `eql-docs-*.zip` / `eql-docs-*.tar.gz` | Packaged API documentation |

The CI-native release workflow (`.github/workflows/release.yml`) builds and
attaches the SQL files and docs bundle **in the same workflow run**. On
`eql_v3`, prerelease runs only proceed when the push is an explicit conventional
release commit (`chore(release): ...`). This is intentional: releases created
by the automatic `GITHUB_TOKEN` do not trigger follow-on release workflows, so
the SQL/docs/package publish work has to happen in one release run.

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

## CI-native release workflow

Use `.github/workflows/release.yml` directly. It is the single release
entrypoint:

- `main` runs the production release path.
- `eql_v3` runs the prerelease path only when the push commit is an explicit
  conventional release marker such as `chore(release): ...`.
- `workflow_dispatch` is available for manual testing on any ref.

Release-relevant work happens in CI, not locally. For a prerelease test, push a
marker commit on `eql_v3`, or dispatch the workflow manually against a branch
that already contains the marker commit.

Language binding package tags remain:

- Rust: `eql-bindings-v<identity>`
- TypeScript: `eql-typescript-v<identity>`

The prerelease path publishes the npm package directly from `release.yml` and
dispatches `release-plz.yml` for the Rust crate after SQL and docs are built.
The release commit must already carry the prerelease package version and
generated SQL/doc assets.

Examples:

```bash
# Dispatch the unified release workflow on the prerelease branch.
gh workflow run release.yml --ref eql_v3

# Test the same release flow on a scratch branch that contains the marker commit.
gh workflow run release.yml --ref <scratch-branch>
```

## Identity and lockstep

Prerelease identity is `<version>-alpha.<N>`, for example `3.0.0-alpha.2`.
`release.yml` derives `N` server-side from freshly fetched tags across all
three namespaces:

- SQL tags: `eql-<identity>`
- Rust tags: `eql-bindings-v<identity>`
- TypeScript tags: `eql-typescript-v<identity>`

The release identity is still `<version>-alpha.<N>` for prereleases. The
workflow derives `N` from the relevant tags and validates that the prerelease
version is already pinned in `packages/eql/package.json`.

The workflow builds SQL and docs in the same run, publishes the npm package
directly, and dispatches `release-plz.yml` for the crate so all release-facing
artifacts come from the same source commit.

## Coordinator checks

Before mutating anything, `release.yml` validates the explicit release marker,
fetches tags, derives the identity, and runs the drift gates:

```bash
mise run types:check
mise run codegen:parity
```

For prereleases, the workflow rejects commits on `eql_v3` unless the commit
subject is an explicit release marker. It also rejects prerelease commits whose
package version is not already prerelease-shaped.

## Verification note

The durable PR gate is `.github/workflows/lint-release.yml`. It runs actionlint
over the release workflows, ShellCheck over the release wrappers and identity
helper, and `.github/scripts/derive-identity.test.sh`.

The SQL-to-docs-to-publish ordering can be exercised safely only on a scratch
branch, because a real package publish is irreversible. For a scratch
validation, temporarily force the docs reusable to fail, dispatch
`release.yml` against the prerelease branch, and confirm that no package
publish is dispatched when docs attachment fails. Revert the scratch change
before any real prerelease.

## Smoke-test the alpha

Install the standalone v3 surface into a clean database (no `eql_v2`) and confirm
it loads:

```bash
gh release download eql-3.0.0-alpha.N -p 'cipherstash-encrypt.sql'
psql "$DATABASE_URL" -f cipherstash-encrypt.sql
psql "$DATABASE_URL" -c "\dn eql_v3"                 # eql_v3 schema present
psql "$DATABASE_URL" -c "SELECT eql_v3.version();"   # released semver
```

For a lockstep release, also confirm all tags point at the same commit:

```bash
git fetch --tags
git rev-list -n1 eql-3.0.0-alpha.N
git rev-list -n1 eql-bindings-v3.0.0-alpha.N
git rev-list -n1 eql-typescript-v3.0.0-alpha.N
```

## Promoting to a final release later

When the alpha graduates to a real release, follow `CLAUDE.md` -> **"Cutting a
release"**: rename `## [Unreleased]` to `## [<version>] - YYYY-MM-DD`, add a
fresh empty `[Unreleased]`, update the link references at the bottom of
`CHANGELOG.md`, then cut a **non-prerelease** GitHub release whose body is the
new versioned section verbatim. The `verify-changelog` job then enforces that
the `## [<version>]` section exists at the tag.
