# Matrix coverage inventory snapshot

This directory holds the canonical committed snapshot, `matrix_tests.txt` — the
token-normalized list of every `scalars::<T>::*` test name in the
`encrypted_domain` SQLx binary, with each type token replaced by the literal
`<T>` — plus three shape variants derived from / committed alongside it
(`matrix_tests_eq_only.txt`, `matrix_tests_text.txt`,
`matrix_tests_storage_only.txt`; see below). They are
**committed test baselines**, not gitignored generated SQL — keep them in
version control.

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

```bash
grep -vE '_ord|order_by|routes_through_ob' snapshots/matrix_tests.txt | LC_ALL=C sort -u > snapshots/matrix_tests_eq_only.txt
```

For the **text** shape there is a third committed snapshot,
`matrix_tests_text.txt`. A text scalar (`scalar_matrix! { caps = [eq, ord, search] }`)
runs the combined `_search` domain (equality + ordering + bloom match) through
the matrix in addition to the ordered shape, so its name set is a **superset**
of the ordered baseline: every ordered arm PLUS the text-only `_search` /
`_eqidx` (equality-via-`eq_term` index split) / `_match` (bloom `@>`/`<@`
containment) arms. Unlike eq-only this superset is **not** derivable by a strip
filter, so it is committed directly. The inventory gate pins it two ways: each
discovered type must match it exactly (after `<T>` normalization), and the gate
asserts it is a strict superset of the ordered baseline (no ordered arm may be
missing for text). Regenerate the text snapshot with:

```bash
cd tests/sqlx
cargo test --no-default-features --test encrypted_domain -- --list \
  | sed -n 's/: test$//p' | grep '^scalars::text::' \
  | sed -e 's/^scalars::text::/scalars::<T>::/' -e 's/_text_/_<T>_/g' | LC_ALL=C sort > snapshots/matrix_tests_text.txt
```

For the **storage-only / encryption-only** shape there is a fourth committed
snapshot, `matrix_tests_storage_only.txt`. A storage-only scalar
(`scalar_matrix! { caps = [storage] }`, e.g. `bool`) has a single term-less
domain and **no** comparison/index/order capability, so its name set is neither
a strip-filter subset of the ordered baseline nor a superset — it is the
storage-domain surface arms only (sanity, blocker-raises for every comparison +
containment op, payload-check, path-op, native-absent, typed-column, count,
aggregate-typecheck, fixture-shape). It is committed directly and each
storage-only type must match it exactly (after `<T>` normalization). Regenerate
with:

```bash
cd tests/sqlx
cargo test --no-default-features --test encrypted_domain -- --list \
  | sed -n 's/: test$//p' | grep '^scalars::bool::' \
  | sed -e 's/^scalars::bool::/scalars::<T>::/' -e 's/_bool_/_<T>_/g' | LC_ALL=C sort > snapshots/matrix_tests_storage_only.txt
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
3. Normalizes each type's token to `<T>` and asserts that type's set equals the
   canonical `matrix_tests.txt` (ordered shape), the derived eq-only subset
   (`matrix_tests.txt` minus `_ord`/`order_by`/`routes_through_ob`), the
   committed `matrix_tests_text.txt` superset (text shape), or the committed
   `matrix_tests_storage_only.txt` set (storage-only shape). Prints each type's
   resolved shape (`ordered` / `eq_only` / `text` / `storage_only`). Asserts at
   least one type is present.
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
  `mise run test:matrix:inventory`. No snapshot edit is needed for an ordered
  (`caps = [eq, ord]`) type (matches the canonical baseline) or an equality-only
  (`caps = [eq]`) type (matches the derived eq-only subset). A **storage-only**
  (`caps = [storage]`) type matches `matrix_tests_storage_only.txt`; if it is the
  first such type, commit that snapshot. The cross-check confirms the type is wired.
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

## v3_jsonb_tests.txt

`v3_jsonb_tests.txt` pins the SQLx test-name set for the hand-written
`eql_v3.json` harness and its signature-aware operator-surface guard. It catches
silent coverage shrinkage in macro-generated blocker/NULL/path cases.

Regenerate with:

```bash
cd tests/sqlx
cargo test --test v3_jsonb_tests --test v3_jsonb_operator_surface_tests -- --list \
  | sed -n 's/: test$//p' \
  | LC_ALL=C sort > snapshots/v3_jsonb_tests.txt
```

CI verifies it with `mise run test:v3-jsonb:inventory`.
