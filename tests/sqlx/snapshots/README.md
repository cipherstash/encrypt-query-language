# Matrix coverage inventory snapshot

This directory holds ONE committed snapshot, `matrix_tests.txt` — the canonical,
token-normalized list of every `scalars::<T>::*` test name in the
`encrypted_domain` SQLx binary, with each type token replaced by the literal
`<T>`. It is a **committed test baseline**, not gitignored generated SQL — keep
it in version control.

The per-type `<T>_matrix_tests.txt` files are gone. They were byte-identical
modulo the type token (the matrix tests are macro-generated from one
`scalar_matrix!` invocation per type with no per-type variation), so a
single canonical set plus a per-type normalize-and-compare carries the same
signal at a fraction of the committed surface.

For equality-only types there is a second committed snapshot,
`matrix_tests_eq_only.txt`. An eq-only scalar (`scalar_matrix! { caps = [eq] }`,
e.g. `timestamptz`) emits exactly the ordered name set MINUS the ord-only lines,
so this file is **derived** from `matrix_tests.txt` (minus every line matching
`_ord` / `order_by` / `routes_through_ob`) — but it is committed and pinned: the
inventory gate re-derives the set at runtime and asserts it equals this
committed file, so a change to the ordered baseline or the strip filter that
alters the eq-only set fails until the snapshot is deliberately regenerated.
Eq-only types are then matched against the committed snapshot. The
`matrix_tests.txt` baseline itself is always the ordered (`caps = [eq, ord]`)
shape. Regenerate the eq-only snapshot with:

```
grep -vE '_ord|order_by|routes_through_ob' snapshots/matrix_tests.txt | LC_ALL=C sort -u > snapshots/matrix_tests_eq_only.txt
```

The "no per-type variation" property is preserved by design: every ordered
scalar sweeps the same three `OrderedScalar` pivots (`min`/`mid`/`max`), so the
`_pivot_mid_*` arms are identical modulo token across `int`/`date`/`text`. The
**signed-only** sign-boundary test (`SignedScalar`, `int`/`date` only) lives
*outside* the `scalars::<T>::` namespace (in `encrypted_domain/signed.rs`,
mirroring the `text_match` suites), so it is deliberately invisible to this
inventory — keeping one canonical set rather than per-capability snapshots.

## What it guards

The SQLx assertions verify that the tests which run produce the right results.
They cannot see a test that *stops running* — a matrix test that is deleted,
renamed, or hidden behind a `#[cfg]` gate simply vanishes silently, quietly
shrinking coverage. This snapshot closes that gap: it pins the *set of test
names* so any such change shows up as an added/removed line in the PR diff.

## How it is generated / checked

Run:

```bash
mise run test:matrix:inventory
```

The task (`mise.toml`, `[tasks."test:matrix:inventory"]`):

1. Lists the `encrypted_domain` binary ONCE with
   `cargo test --no-default-features --test encrypted_domain -- --list`.
2. Discovers the set of scalar types present **from the binary's own output**
   (the `scalars::<X>::` prefixes) — never a directory glob.
3. Normalizes each type's token to `<T>` and asserts that type's set equals
   **either** the canonical `matrix_tests.txt` (ordered shape) **or** the derived
   eq-only subset (`matrix_tests.txt` minus `_ord`/`order_by`/`routes_through_ob`).
   Prints each type's resolved shape (`ordered` / `eq_only`). Asserts at least
   one type is present.
4. **Completeness cross-check:** asserts the discovered type set equals
   `cargo run -p eql-codegen -- list-types` (the catalog is the single source).
   A catalog type added without its matrix wiring — no `scalars::<T>::` tests in
   the binary — fails here.

`LC_ALL=C sort` makes ordering byte-stable across locales. No database is
required — `--list` only enumerates; the suite uses runtime queries.

It pins `--no-default-features` so the inventory is deterministic regardless of
the caller's local flags. That deliberately excludes the `scale` feature arm
(`#[cfg(feature = "scale")]`) — a known blind spot of this inventory, covered
instead by the scale gate plus the `family::mutations` negative controls.

## CI enforcement

The `matrix-coverage` job in `.github/workflows/test-eql.yml` runs the same
task, then `git add -N tests/sqlx/snapshots` and
`git diff --exit-code -- tests/sqlx/snapshots`. The `git add -N` makes a
brand-new, never-committed snapshot trip the diff too. A divergence (or a failed
catalog cross-check) fails the job.

## When you must update this

- **Adding a new scalar type** → add the catalog row in
  `eql-scalars::CATALOG`, wire the SQLx matrix oracle (see
  `docs/reference/adding-a-scalar-encrypted-domain-type.md` §3), then run
  `mise run test:matrix:inventory`. No snapshot edit is needed: an ordered
  (`caps = [eq, ord]`) type matches the canonical baseline, and an equality-only
  (`caps = [eq]`) type matches the derived eq-only subset — both are checked
  against this one file. The cross-check just confirms the type is wired.
- **Removing a scalar type** → remove the catalog row and its matrix wiring; the
  cross-check then sees the type gone from both sides.
- **Changing which matrix tests the macro emits** → regenerate and commit
  `matrix_tests.txt` in the same change:
  ```bash
  cd tests/sqlx
  cargo test --no-default-features --test encrypted_domain -- --list \
    | sed -n 's/: test$//p' | grep '^scalars::int4::' \
    | sed -e 's/^scalars::int4::/scalars::<T>::/' -e 's/_int4_/_<T>_/g' | LC_ALL=C sort > snapshots/matrix_tests.txt
  ```

See `docs/reference/adding-a-scalar-encrypted-domain-type.md` §3 (matrix oracle + inventory snapshot).
