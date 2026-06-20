# CI workflows

This directory holds every GitHub Actions workflow for EQL. This README is the
authoritative **inventory** (what workflows exist and when they fire) and
**coverage map** (which job runs which checks, and where each test suite
actually runs).

- [Workflow inventory](#workflow-inventory)
- [`test-eql.yml` — the merge gate](#test-eqlyml--the-merge-gate)
- [Coverage map: job → task → what it checks](#coverage-map-job--task--what-it-checks)
- [Where each test suite runs](#where-each-test-suite-runs)
- [Known gaps](#known-gaps)

---

## Workflow inventory

| Workflow | Triggers | What it does | Gates merge? |
|---|---|---|---|
| **test-eql.yml** | `pull_request`, `merge_group`, `workflow_dispatch` | Full test/lint/validate matrix; the one required check | **Yes** — `ci-required` |
| **release-eql.yml** | `release: published`, `pull_request` (paths), `workflow_dispatch` | Build release SQL + docs; PR runs everything **but** the publish step | No |
| **release-postgres-eql-image.yml** | `release: published`, `workflow_dispatch` | Build & push the Postgres+EQL Docker image to GHCR | No |
| **bench-eql.yml** | `push: main` (paths), `schedule` 02:00 UTC daily, `workflow_dispatch` | `test:bench` (bench cargo feature). **Never runs on PRs** | No |
| **macro-expand-eql.yml** | `schedule` 03:00 UTC daily, `workflow_dispatch` | Regenerate the int4 `cargo expand` matrix snapshot; needs pinned nightly | **No — explicitly non-blocking** |
| **rebuild-docs.yml** | `push: tags` | Fire a docs-site rebuild webhook | N/A |

Only **test-eql.yml** gates merges. Bench regressions and stale `cargo expand`
snapshots surface on the nightly schedule, not on the PR that caused them.

---

## `test-eql.yml` — the merge gate

Fast PR feedback + a thorough pre-merge gate, using a merge queue and a single
aggregated required check.

### Two run shapes

`setup` derives the matrix from the event:

| Event | Trigger | Matrix | Purpose |
|---|---|---|---|
| `pull_request` | push to a PR | PG17 × 4 shards | fast developer feedback |
| `merge_group` | "Merge when ready" → queued | PG14–17 × 2 shards | full pre-merge gate on the real merged state |
| `workflow_dispatch` | manual run | PG17 × 4 shards (PR shape) | ad-hoc |

The PR run is feedback only. The merge-queue run is the gate.

> **No `push` trigger.** Under a required merge queue, push-to-main validation is
> redundant — the queue already validated the exact merge commit, and branch
> protection blocks direct pushes.

### Relevance skip applies to PRs only

Each heavy job runs when:
`merge_group || workflow_dispatch || (pull_request && relevant == 'true')`.

So the `changes` relevance filter only gates the **`pull_request`** event — a
docs-only PR skips the heavy jobs on its PR run. On `merge_group` (and
`workflow_dispatch`) every job runs **unconditionally**: a queued PR always pays
the full gate regardless of which files it touched.

The relevance filter (`changes` job) marks a PR relevant when any of these
changed: `.github/workflows/test-eql.yml`, `src/**`, `sql/**`, `tests/**`,
`tasks/**`, `crates/**`, `Cargo.toml`, `Cargo.lock`, `mise.toml`. Note `docs/**`
is **not** in the filter — see [Known gaps](#known-gaps).

### How the queue works

1. Click **Merge when ready** — the PR is queued, not merged.
2. GitHub builds a temporary branch = `main` + this PR (+ any PRs ahead in the
   queue) and fires `merge_group`, so CI tests the **post-merge state**.
3. The full PG14–17 × 2 matrix (plus the single-run jobs) runs and feeds
   `ci-required`.
4. `ci-required` green → PR is **merged**. Red → PR is **removed from the
   queue**; `main` is untouched.

This catches semantic conflicts — two PRs that each pass alone but break
together — which PR-only checks never test.

### The `ci-required` aggregator

Per-event matrices make leaf job names unstable (`Shard PG17 1/4` on a PR vs.
`Shard PG14 1/2` in the queue), so leaf names can't be named as required checks.
Instead, one aggregator job (id and display name `ci-required`) `needs:` every
job, runs with `if: always()`, and passes only if each needed result is
`success` **or** `skipped`. Mark **only `ci-required`** as the required status
check.

- `if: always()` — runs even when dependencies fail/skip, so the check always
  reports (a never-reported required check leaves the queue stuck *Pending*).
- `skipped` counts as pass — a docs-only PR skips the heavy jobs on its PR run
  but must still report Success so the PR stays eligible to queue.

---

## Coverage map: job → task → what it checks

All jobs run on `blacksmith-16vcpu-ubuntu-2204`. "PG set" follows the event
(PG17 on PR / dispatch, PG14–17 in the queue).

| Job | mise task(s) | Checks | DB | `CS_*` creds |
|---|---|---|---|---|
| **changes** | — | compute relevance | no | no |
| **setup** | — | compute PG × shard matrix | no | no |
| **build-archive** | `test:sqlx:archive` | Build EQL, run prep, **generate fixtures**, compile every `tests/sqlx` binary (**default features**) into a nextest archive; upload archive + `release/*.sql` | yes (PG17) | **yes (sole holder)** |
| **test** (sharded) | `test:sqlx:partition` | Run the archived sqlx binaries (default features), hash-partitioned across shards | yes (per PG) | no (replays archive) |
| **e2e** | `test:sqlx:e2e` | The `proptest-e2e` fresh-encryption property suite (`e2e_oracle`) — PG17 only, version-independent | yes (PG17) | **yes** |
| **validate** (per PG) | `docs:validate:documented-sql` + `test:clean_install_v3` | DB-backed SQL doc-syntax check; clean-DB `eql_v3` install smoke | yes | no |
| **docs-static** | `docs:validate:source` | SQL doxygen coverage + required-tags (DB-free); relevance-gated like the other heavy jobs (its inputs — `src/**`, the `crates/**` codegen build, `tasks/docs/**` — are a subset of the `relevant` filter) | no | no |
| **schema** | `test:schema` | v2.2 / v2.3 payload JSON-schema validation | no | no |
| **rust-crates** | `test:crates` + `types:check` | `cargo fmt --check`, clippy + `cargo test` for `eql-scalars` / `eql-codegen` / `eql-tests-macros` / `eql-types`; verify TS bindings + JSON schemas are fresh | no | no |
| **codegen** | `codegen:parity` | Generated encrypted-domain SQL matches the golden output | no | no |
| **self-contained-v3** | `test:self_contained_v3` | `eql_v3` surface has no `eql_v2` dependency | no | no |
| **matrix-coverage** | `test:matrix:inventory` (+`:jsonb_entry`, `:v3-jsonb`) + `test:matrix:catalog-coverage` | Scalar-matrix test-name snapshots are not silently dropped; catalog surface is covered | no | no |
| **splinter** | `test:splinter` | Supabase/Splinter lints over the installed EQL | yes (PG17) | no |
| **ci-required** | — | aggregator: every needed job is `success`/`skipped` | no | no |

---

## Where each test suite runs

The `eql_v3` property-test suites (see
`tests/sqlx/tests/encrypted_domain/property/README.md`) land in three different
CI jobs:

| Suite | Job | Trigger coverage | DB | `CS_*` | Notes |
|---|---|---|---|---|---|
| **catalog** (`eql-scalars` `proptest_invariants`) | **rust-crates** (`cargo test -p eql-scalars`; proptest is a dev-dep) | relevant PR + queue | no | no | pure-Rust catalog invariants; shrinking enabled |
| **fixture** (function-double oracles, extractor identity, `match_smoke`, `edge_cases`) | **test** shards (default features) | relevant PR (PG17×4) + queue (PG14–17×2) | yes | no | oracle over the **committed** real-ciphertext fixtures |
| **e2e** (`e2e_oracle`, `#[cfg(feature = "proptest-e2e")]`) | **e2e** job (`test:sqlx:e2e`) | relevant PR (PG17) + queue (PG17) | yes | yes | oracle over **fresh** ZeroKMS encryption; PG-version-independent, so one PG17 run |

The wider sqlx suite (everything under `tests/sqlx/tests/`) runs in the **test**
shards, which replay the default-feature archive — so any
`#[cfg(feature = …)]`-gated test that isn't in the default feature set does not
run there. The `proptest-e2e` suite is the one such gate, and it has its own
**e2e** job (it can't reuse the credential-free archive: it both compiles with a
non-default feature and needs `CS_*` at run time).

---

## Known gaps

1. **bench + macro-expand are nightly / non-blocking** — a bench regression or a
   stale `cargo expand` snapshot surfaces on the daily schedule, not on the PR
   that introduced it. Accepted trade-off.

2. **`docs/**` markdown is not content-validated.** The `docs-static` job checks
   the SQL `--!` doxygen comments under `src/**`, not the prose/links in `docs/**`
   itself. A markdown-only PR leaves `relevant` false, so `docs-static` is skipped
   along with the other heavy jobs — and that loses no coverage, because the job's
   inputs (`src/**` `.sql`/`.template`, the `crates/**` codegen build, the
   `tasks/docs/**` scripts) are all in the `relevant` filter, so a PR that doesn't
   trip `relevant` cannot change its outcome. Linting the markdown the PR actually
   changed (prose/links) is a separate, unfilled capability.

### Recently closed

- *The e2e (fresh-encryption) suite never ran in CI.* Now covered by the **e2e**
  job (`test:sqlx:e2e`), PG17, on relevant PRs + the queue.
- *`docs-static` ran unconditionally on every PR.* It is now relevance-gated like
  every other heavy job. Because its inputs are a strict subset of the `relevant`
  filter, gating it both makes the workflow consistent (one uniform `if:`) and
  drops a redundant codegen build on markdown-only PRs without losing any
  coverage. A narrower bespoke `src/**`-only filter was rejected: it would risk a
  silent false-green (`ci-required` counts `skipped` as pass) by skipping on a
  real input change in `crates/**` or `tasks/docs/**`.

---

## Operator setup (one-time, GitHub UI)

Settings → Branches → rule for `main`:

1. **Require merge queue.**
2. **Require status checks to pass** → add **`ci-required` only** (not the
   per-shard leaf names).

Then verify (see `docs/plans/2026-06-09-ci-pr-feedback-sharding-rollout.md`):

- **Queue a relevant PR** → `merge_group` runs the full gate (8 `Shard …` jobs +
  4 `Validate …` jobs + `build-archive`, `e2e`, `docs-static`, `schema`,
  `rust-crates`, `codegen`, `self-contained-v3`, `matrix-coverage`, `splinter`) →
  `ci-required` green → PR merges.
- **Open a docs-only PR** → on its `pull_request` run every relevance-gated heavy
  job skips (`docs-static` included); `ci-required` reports **Success** (not stuck
  *Pending*) because it counts `skipped` as pass, so the PR can be queued.

## References

- Merge queue: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue>
- `merge_group` event: <https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#merge_group>
- Required status checks: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging>
- `needs` / `always()` / `join()`: <https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/evaluate-expressions-in-workflows-and-actions>
- Path filtering (`dorny/paths-filter`): <https://github.com/dorny/paths-filter>
- nextest archive + partitioning: <https://nexte.st/docs/ci-features/archiving/> · <https://nexte.st/docs/ci-features/partitioning/>
