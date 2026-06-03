# Codegen reference

The SQL files under `int4/` are the hand-maintained golden reference for the encrypted-domain scalar generator, the Rust crate `crates/eql-codegen` (embedded minijinja templates in `crates/eql-codegen/templates/*.j2`). `int4` is the **single golden master**: the generator is type-generic — its templates are pure token substitution driven by the `eql_scalars::CATALOG` rows (`crates/eql-scalars/src/lib.rs`) — so one anchored type detects all template/term drift for every current and future scalar.

Each reference file's first line is a `-- REFERENCE:` provenance marker; everything after it is the generated body verbatim, starting with the template-owned `-- AUTOMATICALLY GENERATED FILE.` header.

The parity gate runs the generator (`cargo run -p eql-codegen`, which writes the real `src/encrypted_domain/int4/` tree) and asserts its output matches these files **byte-for-byte** after dropping that single provenance line. It runs three ways, all on the same reference:

- `mise run codegen:parity` (`tasks/codegen-parity.sh`) — the CI shell gate. It first compares the generated `int4` SQL *file set* against the golden `*.sql` set (`comm -23` against `git ls-files` excludes the committed, hand-written `int4_extensions.sql`, which has no golden counterpart) to catch extra/dropped files, then `diff`s each golden file against its generated counterpart after `tail -n +2` drops the provenance line. Any whitespace or blank-line drift fails — there is no normalization.
- `crates/eql-codegen/tests/parity.rs` (`rust_generator_matches_int4_golden_files`) — runs `generate_all` into a temp dir and byte-compares the materialised `int4` SQL surface against the same golden.
- the in-crate golden tests in `crates/eql-codegen/src/generate.rs` — byte-compare each `render_*_file` output against the corresponding reference.

The golden reference, not any retired generator, is the sole oracle. If the generator diverges, either it regressed (fix `crates/eql-codegen`) or the reference is being updated deliberately (commit the new `int4` reference in the same PR).

See `docs/reference/encrypted-domain-generator.md` for the full generator story (manifest-free catalog, templates, term capabilities).

## No committed fixture values

Plaintext fixture lists are **not** generated and **not** committed as `<T>_values.rs` files — there are none in the tree. They live in the catalog as `eql_scalars::INT4_VALUES` / `INT2_VALUES`, materialised at compile time by the `int_values!` macro in `crates/eql-scalars/src/lib.rs` from each `CATALOG` row, and pinned by `eql-scalars`'s own `values_tests`. The parity gate only globs `*.sql`; it does not check any `values.rs`.

## New scalar types do not add a reference

Adding a scalar type (`int2`, `int8`, …) does **not** add a `tests/codegen/reference/<T>/` directory. A per-type baseline would be redundant: the SQL is byte-identical to `int4` modulo the type token, so it can only fail when `int4`'s baseline already would. New types are guaranteed three other ways:

- the `int4` reference here anchors the shared generator (templates + the `Term` enum's capability `impl`s in `crates/eql-scalars`);
- a catalog row plus the compiler and `eql-scalars`'s `#[test]`/`values_tests` over `CATALOG` validate the new type's spec and materialised value list;
- the SQLx `ordered_numeric_matrix!` suite exercises the generated SQL's *behaviour* against a real database — a far stronger guarantee than a byte comparison — and `mise run test:matrix:inventory` reconciles the matrix test-name set against the single canonical, token-normalized `tests/sqlx/snapshots/matrix_tests.txt` (cross-checked against `eql-codegen list-types`) with no database required.
