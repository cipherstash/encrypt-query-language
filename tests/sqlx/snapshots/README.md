# Matrix coverage inventory snapshots

This directory holds one committed snapshot per scalar encrypted-domain type:

- `int4_matrix_tests.txt`
- `int2_matrix_tests.txt`

Each file is a sorted, byte-stable list of every `scalars::<T>::*` test name in
the `encrypted_domain` SQLx binary. They are a **committed test baseline**, not
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

The task (`mise.toml`, `[tasks."test:matrix:inventory"]`) enumerates the binary
with `cargo test --test encrypted_domain -- --list`, greps each
`scalars::<T>` matrix into its own file, and `LC_ALL=C sort`s for ordering
that is byte-stable across locales. No database is required — `--list` only
enumerates; the suite uses runtime queries.

It pins `--no-default-features` so the inventory is deterministic regardless of
the caller's local flags. That deliberately excludes the `scale` feature arm
(`#[cfg(feature = "scale")]`) — a known blind spot of this inventory, covered
instead by the scale gate plus the `family::mutations` negative controls.

## CI enforcement

The `matrix-coverage` job in `.github/workflows/test-eql.yml` regenerates with
the same pinned feature set and runs `git diff --exit-code` against every
snapshot in this directory. A divergence fails the job with:

> Coverage inventory stale — run 'mise run test:matrix:inventory' and commit.

## When you must update these

- **Adding a new scalar type** → a new `<T>_matrix_tests.txt` appears; commit it.
- **Adding / removing / renaming matrix tests** → regenerate and commit the
  affected snapshot in the same change.

See `docs/reference/encrypted-domain-implementation-spec.md` §2 and §8.
