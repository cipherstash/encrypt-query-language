# Matrix coverage inventory snapshots

This directory holds one committed snapshot per scalar encrypted-domain type,
named `<T>_matrix_tests.txt` (one per type manifest in
`tasks/codegen/types/` that declares a `[fixture]` table — currently `int2`,
`int4`, `int8`, but the set is **not** hand-listed anywhere). Each file is a
sorted, byte-stable list of every `scalars::<T>::*` test name in the
`encrypted_domain` SQLx binary. They are a **committed test baseline**, not
gitignored generated SQL — keep them in version control.

## What they guard

The SQLx assertions verify that the tests which run produce the right results.
They cannot see a test that *stops running* — a matrix test that is deleted,
renamed, or hidden behind a `#[cfg]` gate simply vanishes silently, quietly
shrinking coverage. These snapshots close that gap: they pin the *set of test
names* so any such change shows up as an added/removed line in the PR diff.

## How they are generated

Run:

```bash
mise run test:matrix:inventory
```

The task (`mise.toml`, `[tasks."test:matrix:inventory"]`) enumerates the
`encrypted_domain` binary **once** with
`cargo test --no-default-features --test encrypted_domain -- --list`, then loops
over every manifest in `tasks/codegen/types/*.toml` that declares a `[fixture]`
table — the SAME source of truth `fixture:generate:all` and `codegen:domain:all`
use — derives the type token from the manifest filename, greps that
`scalars::<T>::` matrix into its own file, and `LC_ALL=C sort`s for ordering
that is byte-stable across locales. Adding a new scalar type is picked up
automatically; no list of types is maintained in the task or in CI. No database
is required — `--list` only enumerates; the suite uses runtime queries.

The task also reconciles both directions and fails if a manifest with a
`[fixture]` table produces no `scalars::<T>::*` tests, or if a
`<T>_matrix_tests.txt` snapshot has no matching manifest (a stale snapshot left
behind when a type is removed).

It pins `--no-default-features` so the inventory is deterministic regardless of
the caller's local flags. That deliberately excludes the `scale` feature arm
(`#[cfg(feature = "scale")]`) — a known blind spot of this inventory, covered
instead by the scale gate plus the `family::mutations` negative controls.

## CI enforcement

The `matrix-coverage` job in `.github/workflows/test-eql.yml` regenerates with
the same pinned feature set, runs `git add -N tests/sqlx/snapshots`, then
`git diff --exit-code -- tests/sqlx/snapshots` over the whole directory (no
per-type file is hardcoded in CI). The `git add -N` makes a brand-new,
never-committed snapshot trip the diff too. A divergence fails the job with:

> Coverage inventory stale or uncommitted — run 'mise run test:matrix:inventory' and commit tests/sqlx/snapshots.

## When you must update these

- **Adding a new scalar type** → add its `tasks/codegen/types/<T>.toml` manifest
  (with a `[fixture]` table), run `mise run test:matrix:inventory`, and commit
  the new `<T>_matrix_tests.txt` it generates. No task or CI edit is needed —
  the type set is enumerated from the manifests.
- **Removing a scalar type** → delete its manifest and the matching snapshot in
  the same change; the reconciliation check fails on a stale snapshot otherwise.
- **Adding / removing / renaming matrix tests** → regenerate and commit the
  affected snapshot in the same change.

See `docs/reference/encrypted-domain-implementation-spec.md` §2 and §8.
