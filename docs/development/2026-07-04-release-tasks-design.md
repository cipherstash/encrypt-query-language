# Design: CI-native alpha releases (SQL surface + `eql-bindings` crate)

**Date:** 2026-07-04
**Status:** Approved design (CI-native), ready for implementation plan
**Scope:** Release the two EQL artefacts — individually and in version lockstep — from a single `workflow_dispatch` GitHub Actions workflow, with thin `mise run release:*` tasks that only *trigger and watch* CI.

## Problem

EQL ships two artefacts generated from the same `eql-domains::CATALOG`:

1. The **SQL surface** — `release/cipherstash-encrypt.sql` (+ uninstaller), attached to a GitHub Release tagged `eql-<semver>`, built by `.github/workflows/release-eql.yml`.
2. The **`eql-bindings` crate** — published to crates.io by release-plz (`.github/workflows/release-plz.yml`), tagged `eql-bindings-v<semver>`.

We want to cut alpha (prerelease) versions of **the SQL surface alone**, **the crate alone**, and **both in version lockstep**, with a consistent interface.

We release in lockstep so a published `eql-bindings-v3.0.0-alpha.N` always corresponds to the SQL surface tagged `eql-3.0.0-alpha.N` at the **same commit** — both are regenerated from the same catalog, so their versions must not diverge.

### Decision: CI-native, not laptop-orchestrated

The orchestration runs **in GitHub Actions**, triggered by `workflow_dispatch`. The `mise run release:*` tasks do nothing but call `gh workflow run … && gh run watch`.

The rejected alternative was a laptop-driven bash orchestrator (`mise` task pins the version, commits, pushes, cuts the SQL release, dispatches the crate publish). It required a stack of defensive safeguards — remote-tag derivation, clean-worktree checks, a branch-head SHA guard, "build with the exact string CI uses" — **all of which exist only because a laptop is an unreliable conductor.** CI removes the root cause:

| Laptop hazard | Safeguard it needed | CI-native outcome |
|---|---|---|
| Local tags go stale | derive `N` from remote tags | checkout fetches remote tags fresh — no staleness |
| Dirty/leftover worktree | clean-worktree check + constrained staging | runner checkout is always clean |
| Concurrent push races the release | `ls-remote` SHA guard before dispatch | single actor; a concurrency group serialises runs |
| Local build ≠ CI build | build with the `eql-`-stripped identity to match | the build **is** the CI build |

So CI-native is not "the same work plus a workflow" — it's *less* work, because the safeguards become unnecessary.

### Hard constraint: alphas are cut from the `eql_v3` branch

The v3 code is not yet on `main`. Alphas are cut from **`eql_v3`**; once v3 merges, `main` becomes the channel. The workflow **runs on the dispatched ref**, so the branch is just the `--ref` of the dispatch — `eql_v3` now, `main` later. (Main-channel branch protection is a future constraint; see [Future: the `main` channel](#future-the-main-channel).)

## Verified mechanism facts (load-bearing)

Verified against release-plz source, the workflows in this repo, and `gh` against the live repo:

1. **`release-plz release` is branch-agnostic.** It publishes purely on `(version not on crates.io) && (git tag absent)` — no default-branch gate (`release_always` defaults `true`). It tags the **current HEAD** via the GitHub API and cuts a GitHub Release, auto-marked pre-release for a `-alpha.N` version (default `git_release_type = auto`). **No release-plz config change is required** to publish an alpha from `eql_v3`.
2. **The crate publish must happen in CI.** crates.io auth is OIDC Trusted Publishing (no `CARGO_REGISTRY_TOKEN`), so `cargo publish` cannot run off-CI — reinforcing the CI-native decision.
3. **release-plz publishes the committed `Cargo.toml` version verbatim** and has **no config field that sets an absolute version**. Pinning is `release-plz set-version eql-bindings@<version>`. From a prerelease base its default next bump is `-alpha.(N+1)`; jumping to stable `3.0.0` needs an explicit `set-version`.
4. **The SQL release trigger is a published GitHub Release.** `release-eql.yml` reacts on `release: published`, builds, and attaches the two `.sql` artefacts. It builds with the `eql-`-stripped identity (`mise run build --version "${TAG#eql-}"`), so `eql_v3.version()` reports bare semver. Its `verify-changelog` job is gated to `prerelease == false`, so alphas keep their entries under `[Unreleased]`.
5. **`workflow_dispatch --ref <branch>` runs the workflow on that branch** (`--ref` is a branch/tag name, not a raw SHA). A checkout with `fetch-depth: 0` gives the workflow full history + all remote tags.

## Architecture

Two layers: a **coordinator workflow** (does everything, server-side) and **thin mise triggers**.

### The coordinator workflow — `.github/workflows/release-alpha.yml`

`on: workflow_dispatch`, running on the dispatched ref. Inputs:

| Input | Meaning | Default |
|-------|---------|---------|
| `target` | `eql` \| `bindings` \| `all` — which artefact(s) to release | `all` |
| `version` | base SemVer | `3.0.0` |
| `channel` | `alpha` \| `beta` \| `rc` | `alpha` |
| `pre` | exact prerelease identity (e.g. `3.0.0-alpha.2`), bypassing `N` derivation | (derived) |
| `dry_run` | resolve + verify + print the plan; mutate nothing | `false` |

`concurrency: { group: release, cancel-in-progress: false }` — serialises all release runs (and must share a group with `release-plz.yml`'s crate-publish path so the two never race a tag/publish).

**Sequence** (a step is skipped when `target` excludes its artefact):

1. **Resolve identity.** Checkout (`fetch-depth: 0`) → tags are fresh. `identity = pre` if given, else `<version>-<channel>.<N>` where `N = 1 + max(N across BOTH tag namespaces: SQL `eql-<v>-<ch>.N` and crate `eql-bindings-v<v>-<ch>.N`)`. Deriving across **both** namespaces (even for a single-artefact release) is what keeps them from diverging — a bindings-only release can never pick an `N` that trails or collides with the SQL namespace. Fail fast if the target tag(s) already exist.
2. **Verify.** Drift gates `types:check` + `codegen:parity` (guarantee the crate `src/v3` matches the shipped SQL); the SQL build itself is the release-eql build (step 4), so no separate "does it build" check is needed. Abort before any mutation on failure.
3. **Pin crate version** *(bindings/all)*. `release-plz set-version eql-bindings@<identity>`, commit (GPG-signed, reusing the release-plz signing key), staging **only** the crate files release-plz touched. `git push` to the branch. This is the release commit **S = HEAD**.
4. **SQL release** *(eql/all)*. Create the `eql-<identity>` prerelease on **S**; `release-eql.yml` builds + attaches the artefacts. For `all`, **wait for that run to finish green** before step 5.
5. **Crate publish** *(bindings/all)*. Publish + tag `eql-bindings-v<identity>` on **S**. Irreversible; runs last.
6. **Summary.** Emit both tags / release URLs to the run summary.

**Same commit, for free.** Because one runner executes steps 3–5 sequentially and is the only actor, **S** is HEAD throughout: the crate is pinned at S, the SQL release targets S, the crate tag lands on S. No SHA guard, no interleaving push to defend against. Lockstep ordering ("reversible SQL confirmed green before irreversible crate publish") is just step order.

**The canonical identity** `<version>-<channel>.<N>` yields the SQL tag `eql-<identity>`, the crate `Cargo.toml` version `<identity>`, and the crate tag `eql-bindings-v<identity>`. Same `N` ⇒ lockstep. This preserves the `eql-<version>-<channel>.<N>` scheme `preview.sh` produces today.

### The thin mise triggers

`tasks/release/{eql,bindings,all}.sh` — each is a few lines: preflight `gh`, then dispatch the coordinator with the matching `target` and forward `--version` / `--channel` / `--pre` / `--dry-run`, then watch.

```bash
# release:all  (release:eql and release:bindings differ only in target=)
gh workflow run release-alpha.yml --ref "$ref" \
  -f target=all -f version="$version" -f channel="$channel" ${pre:+-f pre="$pre"} ${dry:+-f dry_run=true}
gh run watch "$(gh run list --workflow=release-alpha.yml --branch "$ref" -L1 --json databaseId -q '.[0].databaseId')"
```

`--ref` defaults to the current branch. No identity resolution, no tag reads, no build happen locally — the task is a remote-control button. This is the "consistent API and approach": all three tasks are the same wrapper with a different `target`.

### Two implementation decisions to settle in the plan

1. **How the coordinator produces SQL artefacts vs `release-eql.yml`.** Creating the prerelease (step 4) fires `release-eql.yml` (`on: release: published`), which is the single SQL-build authority — good (DRY), but the coordinator must then **wait cross-workflow** for that run for the `all` ordering. *Recommended:* extract `release-eql.yml`'s build into a **reusable `workflow_call` workflow** that both `release-eql.yml` (final releases) and the coordinator call inline — no double-build, no cross-workflow polling. *Pragmatic fallback:* keep `release-eql.yml` as-is; the coordinator creates the release and `gh run watch`es the resulting `release-eql.yml` run.
2. **How the coordinator publishes the crate.** *Recommended:* **inline** the `release-plz/action` `command: release` step (single self-contained run, one log, no nested dispatch), reusing the OIDC + GPG setup. Because the coordinator pushes the set-version commit to `eql_v3` (not `main`), `release-plz.yml`'s `push: main` trigger does **not** fire, so no stray `release-pr` is opened — which means the previously-planned `release-pr` gate (`if: github.ref == 'refs/heads/main'`) is **only needed if** we instead dispatch `release-plz.yml`. Settle 1 and 2 together.

## Future: the `main` channel

Once v3 merges, alphas (and eventually finals) come from `main`. Two things change:

- **Branch protection.** A workflow pushing the set-version commit directly to a protected `main` will be blocked. Options: allow the release bot to push to `main`, or route the crate version bump through the standard release-plz PR flow for the `main` channel. To be decided when v3 merges — out of scope now.
- **`release-plz.yml` on `push: main`.** A set-version commit landing on `main` triggers `release-plz.yml`. release-plz is idempotent (skips an already-published version), but the interaction with the coordinator's inline publish must be reconciled then.

## Non-goals

- **No final-release automation.** The coordinator cuts **prereleases** only. Promoting `[Unreleased]` → `[<version>]` and cutting a non-prerelease stays the manual `CLAUDE.md` "Cutting a release" flow.
- **No change to the crate's Trusted Publishing / OIDC / GPG setup.**
- **No solution for the protected-`main` push** (documented as a future constraint above).
- **No `jsonb` domain surface work.**

## Documentation updates (in scope for the implementation)

- **`docs/development/releasing-an-alpha.md`** — replace the manual `set-version`/dispatch runbook with "dispatch `release-alpha.yml` (or run `mise run release:*`)". Keep the release-plz caveats that remain true (no absolute-version config; prerelease auto-increments to `-alpha.(N+1)`; pin via `set-version`; idempotent re-runs). The `git_release_type` note is already corrected (default `auto` marks `-alpha` as pre-release).
- **`CLAUDE.md`** — replace the `release:preview` reference with `release:eql` / `release:bindings` / `release:all`, and note that they trigger the `release-alpha.yml` coordinator.
- **Retire/rename `tasks/release/preview.sh`** → the three thin triggers; grep for `release:preview`.

## Verification

- **`dry_run`** each target: confirm the resolved identity, ref, and planned actions appear in the run summary with nothing mutated (no tag, release, commit, push, or publish).
- **Cross-namespace `N`:** with `eql-…-alpha.5` present and no crate alpha tag, confirm `target=bindings` resolves `alpha.6` (not `alpha.1`).
- **Tag-exists guard:** dispatching an already-released identity fails fast.
- **`target=eql`** on `eql_v3`: prerelease appears with both `.sql` artefacts attached; no crate commit/tag.
- **`target=bindings`** on `eql_v3`: crate publishes to crates.io, tag `eql-bindings-v<identity>` on the pushed commit; **no stray `release-pr`** opened.
- **`target=all`**: both tags land on the **same** commit `S`; the SQL run is awaited green before the crate publish; the crate publish is the last (irreversible) action.
- **Concurrency:** two overlapping dispatches serialise (shared group with `release-plz.yml`), never racing a publish.
- **mise triggers:** each dispatches the coordinator with the correct `target` and forwards flags; nothing release-relevant runs locally.

## Open decisions

- **Coordinator SQL-build factoring** (reusable `workflow_call` vs create-and-wait) and **crate-publish invocation** (inline `release-plz` step vs dispatch `release-plz.yml`) — settle together in the plan; recommendations above.
- **Locked:** CI-native coordinator; thin mise triggers; one identity across both namespaces; prereleases-only; branch as the dispatched ref.
