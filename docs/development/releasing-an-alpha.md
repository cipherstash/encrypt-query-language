# Releasing an `eql_v3` alpha

A concise runbook for cutting a **prerelease** (alpha/beta/rc) of the EQL SQL
surface, its language binding packages (the `eql-bindings` crate and the
`@cipherstash/eql` npm package), or all of them in lockstep. For a final
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
| `mise run release:all` | `all` | Pins Rust + TypeScript package versions, builds and releases SQL + docs, then dispatches Rust and TypeScript package publishes from the same release identity. |
| `mise run release:eql` | `eql` | Builds and releases SQL + docs only. No language package publish. |
| `mise run release:bindings` | `bindings` | Publishes all missing language binding packages for an existing same-source SQL prerelease. |
| `mise run release:rust` | `rust` | Publishes only the Rust `eql-bindings` crate for an existing same-source SQL prerelease. |
| `mise run release:typescript` | `typescript` | Publishes only the TypeScript `@cipherstash/eql` npm package for an existing same-source SQL prerelease. |

`release:all`, `release:bindings`, `release:rust`, and `release:typescript`
require `--ref <branch>` because the coordinator pushes the package-version pin.
`release:eql` can run against any ref because it does not push.

Language binding package tags:

- Rust: `eql-bindings-v<identity>`
- TypeScript: `eql-typescript-v<identity>`

`target=bindings` means all language bindings, not only the Rust crate. Specific
language targets use language names (`rust`, `typescript`) rather than
package-manager names (`crate`, `npm`) so the operator interface remains stable
if packaging changes later.

The TypeScript publish workflow uses npm trusted publishing and must run on
GitHub-hosted `ubuntu-latest`. Do not move `release-typescript.yml` to a
Blacksmith/self-hosted runner: npm provenance rejects self-hosted runners. The
workflow intentionally has `id-token: write`, upgrades npm to `^11.5.1`, and
does not use `NPM_TOKEN`.

Common flags:

| Flag | Meaning | Default |
|------|---------|---------|
| `--version` | Base SemVer (`X.Y.Z`) | `3.0.0` |
| `--channel` | Prerelease channel: `alpha` \| `beta` \| `rc` | `alpha` |
| `--pre` | Exact identity (`X.Y.Z-(alpha\|beta\|rc).N`), bypassing derivation | derived |
| `--ref` | GitHub ref for `workflow_dispatch` | required explicitly for `release:all`, `release:bindings`, `release:rust`, and `release:typescript`; current branch for `release:eql` |
| `--dry-run` | Resolve, verify, and print the plan without mutating anything | off |

Examples:

```bash
# Always start here: derive identity and run drift gates without publishing.
mise run release:all --ref eql_v3 --dry-run

# Ship SQL + docs and all language packages in lockstep.
mise run release:all --ref eql_v3

# Ship only the SQL surface + docs.
mise run release:eql --channel beta

# Publish all language packages for an already-existing SQL alpha, same source.
mise run release:bindings --pre 3.0.0-alpha.2 --ref eql_v3

# Publish only one language package (crate-only / npm-only) for an existing SQL alpha.
mise run release:rust --pre 3.0.0-alpha.2 --ref eql_v3
mise run release:typescript --pre 3.0.0-alpha.2 --ref eql_v3
```

## Identity and lockstep

The release identity is `<version>-<channel>.<N>`, for example
`3.0.0-alpha.2`. The coordinator derives `N` server-side from freshly fetched
tags across all three namespaces:

- SQL tags: `eql-<identity>`
- Rust tags: `eql-bindings-v<identity>`
- TypeScript tags: `eql-typescript-v<identity>`

For `release:all` and `release:eql`, `N` is one greater than the maximum matching
counter found in **any** of the three namespaces. For `release:bindings`, the
coordinator finds the newest SQL alpha still missing a Rust **or** TypeScript
binding tag. For `release:rust` / `release:typescript`, it finds the newest SQL
alpha still missing that specific language's tag.

`release:all` is the normal lockstep path. The coordinator pins the requested
package version(s) — the crate (`release-plz set-version`) and/or the npm package
(`package.json` + lockfile) — commits that metadata change as commit `S`, builds
SQL + docs at `S`, creates `eql-<identity>` at `S`, and dispatches
`release-plz.yml` and `release-typescript.yml` against that immutable SQL tag.
The resulting `eql-<identity>`, `eql-bindings-v<identity>`, and
`eql-typescript-v<identity>` tags all land on the same commit.

`release:bindings` catches up the language packages after an existing SQL alpha;
`release:rust` and `release:typescript` are the single-language equivalents. The
branch must currently point at the SQL tag commit. The coordinator verifies that
`HEAD == eql-<identity>`, adds the metadata-only package pin commit on top, then
dispatches the language-specific publish workflow(s). This guarantees the
packages ship the same generated source as the SQL release, not later product
code.

## Coordinator checks

Before mutating anything, the coordinator validates inputs, fetches tags, derives
the identity, checks target-specific tag existence, and runs the drift gates:

```bash
mise run types:check
mise run codegen:parity
```

For `release:all`, `release:bindings`, `release:rust`, and `release:typescript`,
it also rejects non-branch refs because the package-version pin must be pushed.
For `release:bindings`, `release:rust`, and `release:typescript`, it rejects a
branch that has advanced past the SQL tag. For any binding target, it also fails
fast if every requested language tag already exists for that identity (nothing
left to publish).

The Rust crate publish remains a separate `release-plz.yml` run because crates.io
Trusted Publishing validates the entry-point workflow identity; the TypeScript
publish is likewise a separate `release-typescript.yml` run (npm trusted
publishing requires OIDC on a GitHub-hosted runner). The coordinator dispatches
each workflow only after SQL and docs have been built and attached.

## Verification note

The durable PR gate is `.github/workflows/lint-release.yml`. It runs actionlint
over the release workflows, ShellCheck over the release wrappers and identity
helper, and `.github/scripts/derive-identity.test.sh`.

The SQL to docs to package ordering can be exercised safely only on a scratch
branch, because a real package publish (Rust or TypeScript) is irreversible. For
a scratch validation, temporarily force the docs reusable to fail, run `mise run
release:eql --ref <scratch-branch>` or `mise run release:all --ref
<scratch-branch>`, and confirm that no package publish (Rust or TypeScript) is
dispatched when docs attachment fails. Revert the scratch change before any real
alpha.

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
