# Codegen reference

The SQL files under `int4/` are the hand-written golden reference for the encrypted-domain scalar generator. `int4` is the **single golden master**: the generator in `crates/eql-codegen` is type-generic — its SQL templates are pure token substitution driven by the `eql-scalars::CATALOG` rows — so one anchored type detects all template/term drift for every current and future scalar.

Each reference file's first line is a `-- REFERENCE:` provenance marker; everything after it is the generated body verbatim, starting with the template-owned `-- AUTOMATICALLY GENERATED FILE.` header.

The parity gate renders the generator's output for `int4` and asserts it matches these files **byte-for-byte** after dropping that single provenance line. It runs three ways, all on the same reference:

- `crates/eql-codegen/tests/parity.rs` — runs `generate_all` into a temp dir and byte-compares the materialised `int4` SQL surface;
- the in-crate golden tests in `crates/eql-codegen/src/generate.rs` — byte-compare each `render_*_file` output against the corresponding reference;
- `mise run codegen:parity` (`tasks/codegen-parity.sh`) — the CI shell gate, a plain `diff` of `tail -n +2 <reference>` against the regenerated tree.

If the generator diverges, either it regressed (fix `crates/eql-codegen`) or the reference is being updated deliberately (commit the new `int4` reference in the same PR). Whitespace and blank-line drift now fail the gate — there is no normalization.

## New scalar types do not add a reference

Adding a scalar type (`int2`, `int8`, …) does **not** add a `tests/codegen/reference/<T>/` directory. A per-type baseline would be redundant: the SQL is byte-identical to `int4` modulo the type token, so it can only fail when `int4`'s baseline already would. New types are guaranteed three other ways:

- the `int4` reference here anchors the shared generator (templates + the `Term` enum's capability `impl`s in `crates/eql-scalars`);
- the per-type plaintext fixture list (`eql_scalars::INT4_VALUES` / `INT2_VALUES`, materialised from each `CATALOG` row) is pinned by `eql-scalars`'s own `values_tests` — there is no generated `<T>_values.rs` to diff;
- the SQLx `ordered_numeric_matrix!` suite exercises the generated SQL's *behaviour* against a real database — a far stronger guarantee than a byte comparison.
