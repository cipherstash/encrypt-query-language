# CI: `test-eql.yml`

Fast PR feedback + a thorough pre-merge gate, using a merge queue and a single
aggregated required check.

## Two run shapes

`test-eql.yml` triggers on `pull_request`, `merge_group`, and `workflow_dispatch`.
`setup` derives the matrix from the event:

| Event | Trigger | Matrix | Purpose |
|---|---|---|---|
| `pull_request` | push to a PR | PG17 × 4 shards | fast developer feedback |
| `merge_group` | "Merge when ready" → queued | PG14–17 × 2 shards | full pre-merge gate on the real merged state |
| `workflow_dispatch` | manual run | PG17 × 4 shards (PR shape) | ad-hoc |

The PR run is feedback only. The merge-queue run is the gate.

## Relevance skip applies to PRs only

Each job runs when:
`merge_group || workflow_dispatch || (pull_request && relevant == 'true')`.

So the `changes` relevance filter (`relevant:` paths) **only gates the
`pull_request` event** — a docs-only PR skips the heavy jobs on its PR run. On
`merge_group` (and `workflow_dispatch`) every job runs **unconditionally**: a
queued PR always pays the full gate regardless of which files it touched.

## How the queue works

1. Click **Merge when ready** — the PR is queued, not merged.
2. GitHub builds a temporary branch = `main` + this PR (+ any PRs ahead in the
   queue) and fires `merge_group`, so CI tests the **post-merge state**, not the
   stale PR branch.
3. The full PG14–17 × 2 matrix (plus the single-run jobs) runs and feeds
   `ci-required`.
4. `ci-required` green → the PR is **merged into `main` using the queue's
   configured merge method**. Red → the PR is **removed from the queue**; `main`
   is untouched.

This catches semantic conflicts — two PRs that each pass alone but break
together — which PR-only checks never test.

## The `ci-required` aggregator

Per-event matrices make leaf job names unstable (a `test` job is displayed as
`Shard PG17 1/4`, but the queue produces `Shard PG14 1/2` … `Shard PG17 2/2`),
so leaf names can't be named as required checks. Instead, one aggregator job
(id and display name `ci-required`) `needs:` every job, runs with
`if: always()`, and passes only if each needed result is `success` **or**
`skipped`. Mark **only `ci-required`** as the required status check.

- `if: always()` — runs even when dependencies fail/skip, so the check always
  reports (a never-reported required check leaves the queue stuck *Pending*).
- `skipped` counts as pass — a docs-only PR skips the heavy jobs on its PR run
  but must still report Success so the PR stays eligible to queue.

This is the well-known "aggregate / final gate job" pattern for matrix +
merge-queue workflows.

## Operator setup (one-time, GitHub UI)

Settings → Branches → rule for `main`:

1. **Require merge queue.**
2. **Require status checks to pass** → add **`ci-required` only** (not the
   per-shard leaf names).

Then verify (see `docs/plans/2026-06-09-ci-pr-feedback-sharding-rollout.md`):

- **Queue a relevant PR** → `merge_group` runs the full gate — 8 `Shard …` jobs
  + 4 `Validate …` jobs + `build-archive`, `schema`, `rust-crates`, `codegen`,
  `self-contained-v3`, `matrix-coverage`, `splinter` — all green → `ci-required`
  green → PR merges.
- **Open a docs-only PR** → on its `pull_request` run the heavy jobs skip and
  `ci-required` reports **Success** (not stuck *Pending*), so the PR can be
  queued.

## References

- Merge queue: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue>
- `merge_group` event: <https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#merge_group>
- Required status checks: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging>
- `needs` / `always()` / `join()`: <https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/evaluate-expressions-in-workflows-and-actions>
- Path filtering (`dorny/paths-filter`): <https://github.com/dorny/paths-filter>
- nextest archive + partitioning: <https://nexte.st/docs/ci-features/archiving/> · <https://nexte.st/docs/ci-features/partitioning/>
