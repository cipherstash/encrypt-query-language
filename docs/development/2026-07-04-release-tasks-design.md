# Design: unified `mise run release:*` tasks (SQL surface + `eql-bindings` crate)

**Date:** 2026-07-04
**Status:** Approved design, ready for implementation plan
**Scope:** Add mise tasks to release the two EQL artefacts individually and in lockstep, with a consistent API and approach.

## Problem

EQL ships two artefacts generated from the same `eql-domains::CATALOG`:

1. The **SQL surface** — `release/cipherstash-encrypt.sql` (+ uninstaller), attached to a GitHub Release tagged `eql-<semver>`, built by `.github/workflows/release-eql.yml`.
2. The **`eql-bindings` crate** — published to crates.io by release-plz (`.github/workflows/release-plz.yml`), tagged `eql-bindings-v<semver>`.

Today only the SQL side is scripted (`mise run release:preview` → `tasks/release/preview.sh`). The crate side is only documented as a manual procedure. We want:

- A task to release **the SQL surface** alone.
- A task to release **the crate** alone.
- A task to release **both in version lockstep**, internally composing the two individual tasks.
- A **consistent API and approach** across all three.

We release in lockstep so a published `eql-bindings-v3.0.0-alpha.N` always corresponds to the SQL surface tagged `eql-3.0.0-alpha.N` at the same commit — both are regenerated from the same catalog, so their versions must not diverge.

### Hard constraint: alphas are cut from the `eql_v3` branch

The v3 code is not yet on `main`. Alpha releases must be cut from the **`eql_v3`** branch. Once v3 merges, `main` becomes the release channel. Therefore **the branch/ref is a parameter, defaulting to the current branch** — no task changes when the channel moves from `eql_v3` to `main`.

## Verified mechanism facts (load-bearing)

These are verified against the actual tooling (release-plz source, the workflows in this repo, and `gh` against the live repo), not assumed:

1. **The SQL release is fully local-driven.** `gh release create eql-<id> --target <ref>` is the entire trigger; `release-eql.yml` reacts on `release: published`, builds, and attaches artefacts. `--target` accepts any branch/commit, so cutting from `eql_v3` already works. `release-eql.yml`'s `verify-changelog` job is gated to `prerelease == false`, so prereleases keep their entries under `[Unreleased]`.

2. **The crate publish happens in CI, not locally.** crates.io auth is OIDC Trusted Publishing (no `CARGO_REGISTRY_TOKEN`), so `cargo publish` cannot run from a laptop. The local task's job is to *initiate*; CI's `release` job publishes.

3. **`release-plz release` is branch-agnostic.** Its `should_release()` / per-package logic publishes purely on `(version not on crates.io) && (git tag absent)`; there is no default-branch gate in the release path (`release_always` defaults `true`). It tags the **current HEAD** commit via the GitHub API and creates a GitHub Release, auto-marked as a pre-release for a `-alpha.N` version (default `git_release_type = auto`). **No release-plz config change is required.**

4. **`workflow_dispatch --ref eql_v3` operates on `eql_v3`.** The `release-plz/action` is a composite action that does no internal re-checkout; it runs against whatever `actions/checkout` fetched, which under a dispatched ref is that ref. `fetch-depth: 0` (already set) is required for changelog/tag generation. **`--ref` is a branch/tag name, not a raw SHA** — so the task dispatches by branch and guards the branch-head SHA separately (see Release-safety invariants). It tags whatever commit the branch head points at, hence the guard.

5. **`main` is not branch-protected**, but we deliberately do not rely on direct-push-to-main; the ref-parameterised dispatch model is what generalises across branches.

6. **release-plz publishes the committed `Cargo.toml` version verbatim** and has **no config field that sets an absolute version**. Pinning is done with `release-plz set-version eql-bindings@<version>`. From a prerelease base, release-plz's default next bump is `-alpha.(N+1)`; to jump to a stable `3.0.0` you must `set-version` explicitly.

### Required companion change (not a task, but in scope)

`.github/workflows/release-plz.yml`'s `release-pr` job, when the workflow is dispatched from `eql_v3`, would open a release PR **based on `eql_v3`** (release-plz uses the checked-out branch as the PR base, verified in source). That is needless noise for an alpha. Gate it:

```yaml
release-pr:
  needs: release
  if: github.ref == 'refs/heads/main'   # skip on eql_v3 (and any non-main) dispatch
```

This is harmless on `main` (unchanged behaviour) and suppresses the stray PR on alpha dispatches.

## Design

### Consistent model

Every task follows one lifecycle:

> **resolve version identity → verify locally → initiate on `--ref` → CI completes → print watch command**

`--ref` defaults to the current branch (`git rev-parse --abbrev-ref HEAD`).

### Shared API

All three tasks accept the identical flag set:

| Flag | Meaning | Default |
|------|---------|---------|
| `--version` | base SemVer (the `<version>` in the identity) | `3.0.0` |
| `--channel` | preview channel: `alpha` \| `beta` \| `rc` | `alpha` |
| `--pre` | exact prerelease identity (e.g. `3.0.0-alpha.2`), bypassing N-derivation | (derived) |
| `--ref` | branch or commit to release from | current branch |
| `--dry-run` | print the plan, create/publish nothing | off |

The **canonical shared identity** is `<version>-<channel>.<N>`, e.g. `3.0.0-alpha.2`. From it:

- SQL tag: `eql-<identity>` → `eql-3.0.0-alpha.2`
- Crate `Cargo.toml` version: `<identity>` → `3.0.0-alpha.2`; release-plz tag: `eql-bindings-v<identity>` → `eql-bindings-v3.0.0-alpha.2`

**Same N ⇒ lockstep.** This preserves the current `eql-<version>-<channel>.<N>` tag scheme that `preview.sh` already produces.

### Shared library — the "consistent approach" backbone

A sourced `tasks/release/_lib.sh` holds the logic common to all three tasks, so they cannot drift:

- `channel` validation against the `alpha|beta|rc` allowlist.
- `gh` presence + `gh auth status` preflight.
- `--ref` defaulting to the current branch.
- **Identity derivation from REMOTE tags, across BOTH namespaces, for every task.** Release tags are created remotely (`gh release create` for SQL; the GitHub API via release-plz for the crate), so local tags are unreliable/stale. The lib first refreshes remote tag state (`git ls-remote --tags origin`, or `git fetch --tags --prune`), then computes `N = 1 + max(N across the SQL `eql-<v>-<ch>.N` namespace AND the crate `eql-bindings-v<v>-<ch>.N` namespace)`. **All tasks derive across both namespaces** — including single-artefact ones — so a bindings-only release can never pick an `N` that collides with or trails the SQL namespace (or vice versa). This directly upholds the lockstep invariant; the previous "derive from your own namespace" rule is rejected because it permits divergence (`eql-bindings-v…-alpha.2` published while `eql-…-alpha.5` exists). An explicit `--pre` bypasses derivation entirely.
- **Tag-exists guards query remote too**, not just local tags, for the same staleness reason.
- Dry-run echo helpers.

`preview.sh` currently derives `N` from **local** `git tag --list` (line 46) — a latent staleness bug the refactor fixes by moving to remote derivation.

### Release-safety invariants (apply to all tasks)

These cross-cutting rules live in `_lib.sh` and are non-negotiable — the review that shaped this spec flagged each as a real hole:

1. **Remote-derived versions & guards** (above): never trust local tags for `N` or existence checks.
2. **Local build verification matches CI's version string exactly.** CI builds with the `eql-`-stripped identity (`mise run build --version "${TAG#eql-}"`, `release-eql.yml`), so the local verify must also build with the **bare** `<identity>` (e.g. `3.0.0-alpha.2`), NOT `eql-<identity>`. `preview.sh` currently build-verifies the prefixed tag (line 67) — a mismatch that would miss version-string regressions; the refactor corrects it.
3. **Clean worktree + constrained staging before any commit.** The bindings prepare step must fail if the worktree has uncommitted/untracked changes to release-relevant paths, and must stage **only** `crates/eql-bindings/Cargo.toml`, `crates/eql-bindings/CHANGELOG.md`, and `Cargo.lock` (if `set-version` touched it) — never a blanket `git add -A` that could sweep unrelated work into a release commit.
4. **Dispatch by branch ref with a remote-head SHA guard.** `gh workflow run --ref` takes a **branch or tag name, not a raw SHA** (verified). So crate publish dispatches on the **branch** (`--ref <branch>`), but immediately before dispatching, assert `git ls-remote origin refs/heads/<branch>` still equals the intended release SHA. If another push moved the branch head, abort rather than publish an unintended commit. (The SQL side has no such constraint: `gh release create --target` *does* accept a full SHA, so the SQL tag pins the exact release commit directly.)

### Task 1 — `release:eql` (SQL surface)

**File:** `tasks/release/eql.sh` (this is today's `preview.sh`, renamed).

1. Resolve identity (remote-derived N), validate channel, preflight `gh`.
2. Verify the build with the **bare** identity to match CI: `mise run clean && mise run build --version <identity>` (e.g. `3.0.0-alpha.2`, NOT `eql-3.0.0-alpha.2`); assert `release/cipherstash-encrypt.sql` and `-uninstall.sql` are non-empty.
3. Refuse if the `eql-<identity>` tag already exists **on the remote**.
4. `gh release create eql-<identity> --target <ref-or-sha> --prerelease --title eql-<identity> --notes "<preview notes>"`. (`--target` accepts a full SHA, used by `release:all` to pin the exact release commit.)
5. Print `gh run watch` / `gh release view` hints.

Reversible (a GitHub prerelease can be deleted). Does **not** touch `CHANGELOG.md`.

### Task 2 — `release:bindings` (crate)

**File:** `tasks/release/bindings.sh`. Two internal phases so `release:all` can interleave the SQL step between them:

**prepare:**
1. Resolve identity (remote-derived N), validate, preflight `gh`.
2. **Require a clean worktree** for release-relevant paths (fail on uncommitted/untracked changes under `crates/eql-bindings/` or the lockfile) so nothing unrelated is swept into the release commit.
3. Verify the generated surface is in sync on this ref — `mise run types:check` and `mise run codegen:parity` must be clean (guarantees the published crate `src/v3` matches the shipped SQL surface).
4. Refuse if the `eql-bindings-v<identity>` tag already exists **on the remote** (release-plz is idempotent, but fail early with a clear message).
5. `release-plz set-version eql-bindings@<identity>` (edits `Cargo.toml` + crate `CHANGELOG.md`).
6. **Stage only** `crates/eql-bindings/Cargo.toml`, `crates/eql-bindings/CHANGELOG.md`, and `Cargo.lock` (if `set-version` changed it) — never `git add -A`. Commit (`release: eql-bindings <identity>`) and `git push origin <ref>`; the commit must be on the remote before dispatch. Record the pushed SHA.

**publish:**
7. **SHA guard:** assert `git ls-remote origin refs/heads/<branch>` still equals the SHA recorded in step 6; abort if the branch head moved.
8. Dispatch **by branch** (`--ref` takes a branch/tag, not a SHA): `gh workflow run release-plz.yml --ref <branch>` → CI's `release` job publishes to crates.io, tags `eql-bindings-v<identity>` on that commit, and cuts a pre-release GitHub Release.
9. Print `gh run watch` hint.

Standalone `release:bindings` runs prepare then publish back-to-back. Publish is **irreversible** (a crates.io version is burned even if yanked).

`--dry-run` stops after printing the resolved identity and the `set-version` / dispatch commands it *would* run; it makes no commit, push, or dispatch.

### Task 3 — `release:all` (lockstep)

**File:** `tasks/release/all.sh`. Resolves **one** shared `N`, verifies once, then composes the individual tasks in an order that gives both tags the **same commit** with the irreversible step **last**:

1. Resolve shared identity `<version>-<channel>.<N>` (remote-derived, max-N across both namespaces).
2. Verify once: drift gates (`types:check`, `codegen:parity`) + SQL clean build with the **bare** identity. Abort on any failure before mutating anything.
3. **`bindings.prepare`** — clean-worktree check → `set-version` → stage only the crate files → commit → push `<branch>`. **Record the pushed SHA** `S`; this is the release commit.
4. **`release:eql --target S --pre <identity>`** — SQL prerelease pinned to `S` by full SHA (reversible; `gh release create --target` accepts a SHA).
5. **Wait for the `release-eql.yml` run to succeed** — `gh run watch` the triggered run until it completes green, confirming the SQL artefacts actually built and attached. **Do not proceed on failure.** (Creating the GitHub prerelease only *triggers* the build; the irreversible crate publish must wait for confirmed SQL success, not merely a created release.)
6. **`bindings.publish --ref <branch>`** — SHA guard (`ls-remote` head == `S`) → dispatch release-plz by branch (irreversible), tagging the same commit `S`.
7. Print watch hints for both CI runs.

Both `eql-<identity>` and `eql-bindings-v<identity>` end up on the one set-version commit `S`. Rationale for ordering: the only tree delta introduced by the set-version commit is `Cargo.toml` + the crate changelog (+ maybe the lockfile) — none of which affect the SQL surface — so pinning the SQL tag to `S` and letting release-plz tag `S` is exact. The reversible SQL prerelease goes first **and is confirmed green** before the irreversible crate publish, so no failure path leaves a published crate without a working SQL counterpart.

`--dry-run` threads through to both children (no commit, tag, push, or dispatch).

## Non-goals

- **No final-release automation.** These tasks cut **prereleases** only (alpha/beta/rc). Promoting `[Unreleased]` → `[<version>]` and cutting a non-prerelease stays the manual `CLAUDE.md` "Cutting a release" flow. (`release:eql` always passes `--prerelease`.)
- **No change to the crate's crates.io Trusted Publishing / OIDC setup**, GPG signing, or the `release`-before-`release-pr` ordering.
- **No auto-merge / branch-protection changes.** We use `workflow_dispatch`, not direct-push-to-main.
- **No `jsonb` domain surface work** (out of scope for the scalar materialiser generally).

## Documentation updates (in scope for the implementation)

- **`docs/development/releasing-an-alpha.md`** — replace the manual `set-version`/dispatch steps in the "Releasing `eql-bindings` in lockstep" section with the scripted tasks; **remove the incorrect `git_release_type = "auto"` one-time-config note** (default `auto` already marks `-alpha` GitHub releases as pre-releases — verified in release-plz source). Keep the caveats (no absolute-version config; prerelease auto-increments to `-alpha.(N+1)`; pin via `set-version`; idempotent re-runs).
- **`CLAUDE.md`** — update the release callout so `mise run release:preview` becomes `release:eql`, and add `release:bindings` / `release:all` to the "release is scripted" list.
- **Any reference to `release:preview`** (the rename) — grep and update.

## Verification

- **Dry-run each task** (`--dry-run`) and confirm the derived identity, resolved ref, and the exact commands it would run — with nothing mutated.
- **Remote-derivation:** create a remote-only tag the local clone doesn't have, then confirm `N` derivation and the tag-exists guard both see it (i.e. local staleness can't cause a collision).
- **Cross-namespace N:** with `eql-…-alpha.5` present but no crate alpha tag, confirm `release:bindings` derives `alpha.6` (not `alpha.1`).
- **Version-string parity:** confirm the local verify build uses the bare `<identity>` and that `eql_v3.version()` in the built artefact matches what CI would produce.
- **Clean-worktree guard:** with a stray edit under `crates/eql-bindings/`, confirm `release:bindings` prepare aborts and stages nothing.
- **SHA guard:** simulate a branch-head move between prepare and publish; confirm dispatch aborts.
- **`release:eql`** end-to-end on `eql_v3`: confirm the GitHub prerelease appears with both `.sql` artefacts attached (existing behaviour, must survive the rename).
- **`release:bindings`** end-to-end on `eql_v3`: confirm the workflow dispatch runs the `release` job only (not `release-pr`), publishes to crates.io, and tags `eql-bindings-v<identity>` on the pushed commit.
- **`release:all`**: confirm both tags land on the **same** commit `S`, that the SQL CI run is awaited green before the crate dispatch, and that the crate publish is the last irreversible action.
- **Idempotency:** re-running a task for an already-released identity fails fast (remote tag-exists guard) rather than double-publishing.

## Alternatives considered

**A single `workflow_dispatch` "alpha release" GitHub Actions workflow** with inputs (version, channel), doing the whole sequence — version pin, commit, SQL release, crate publish — inside CI. This is **more auditable and insensitive to laptop state** (no dependence on the operator's local tags, worktree cleanliness, or branch head), which addresses the root concern behind every safeguard above rather than patching each locally. It is deferred because it is a **larger change** (a new workflow that mutates the repo and orchestrates two publish paths, with its own secrets/permissions surface) and because the mise-task entrypoints are wanted as the operator-facing interface regardless. The safeguards in this spec make the local-orchestration form solid in the interim; **the CI-native workflow is the recommended evolution** once the task API has settled, and the mise tasks could then become thin wrappers that trigger it.

## Open questions

None blocking. Decisions locked during design:

- **Rename `release:preview` → `release:eql`** for API symmetry (accept the doc churn).
- **Individual tasks are first-class**, not just internal helpers — SQL-only and bindings-only alphas are supported; `release:all` composes them.
- **`release-pr` job gated to `main`** as the one required workflow change.

A design review hardened the orchestration against local-state hazards: remote-tag derivation, cross-namespace `N`, clean-worktree + constrained staging, branch-dispatch with a SHA guard, CI-success wait before the irreversible crate publish, and CI-matching build version. These are captured as **Release-safety invariants** and folded into each task above; several also fix latent bugs in today's `preview.sh` (local-tag `N`, prefixed build version). The **CI-native single-workflow** form (see Alternatives) remains the recommended longer-term evolution.
