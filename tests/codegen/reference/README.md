# Codegen reference

The SQL files under `<token>/` (`int4/`, `int2/`, `int8/`, `date/`, `timestamptz/`, `text/`) are the committed reference SQL files for the encrypted-domain scalar generator, the Rust crate `crates/eql-codegen` (embedded minijinja templates in `crates/eql-codegen/templates/*.j2`). **Every catalog type has a reference**, generated once from a known-good run and committed. Although the generator is type-generic — its templates are pure token substitution driven by the `eql_domains::CATALOG` rows (`crates/eql-domains/src/lib.rs`) — the per-type domain *shapes* differ (ordered types carry `_ord`/`_ord_ore` + aggregates; `timestamptz` is equality-only; `text` carries the Bloom `text_match` domain whose `@>`/`<@` render as supported containment operators), so anchoring every type catches a regression in any shape, not just the ordered one.

Each reference file's first line is a `-- REFERENCE:` provenance marker; everything after it is the generated body verbatim, starting with the template-owned `-- AUTOMATICALLY GENERATED FILE.` header.

The parity gate runs the generator (`cargo run -p eql-codegen`, which writes the real `src/v3/scalars/<token>/` trees) and asserts its output matches these files **byte-for-byte** after dropping that single provenance line. It runs three ways, all on the same references:

- `mise run codegen:parity` (`tasks/codegen-parity.sh`) — the CI shell gate. It discovers the reference token dirs, and for each first compares the generated SQL *file set* against the reference `*.sql` set (`comm -23` against `git ls-files` excludes any committed, hand-written `<token>_extensions.sql`, which has no reference counterpart) to catch extra/dropped files, then `diff`s each reference file against its generated counterpart after `tail -n +2` drops the provenance line. Any whitespace or blank-line drift fails — there is no normalization.
- `crates/eql-codegen/tests/parity.rs` — `rust_generator_matches_reference_files` runs `generate_all` into a temp dir and byte-compares every materialised token surface against its reference; `generate_all_is_deterministic_across_runs` asserts two runs are byte-identical; `reference_dirs_match_catalog_tokens` asserts the committed reference dir set **equals** the `eql_domains::CATALOG` token set.
- the in-crate reference test in `crates/eql-codegen/src/generate.rs` (`generator_matches_reference_files`) — byte-compares each `render_*_file` output against the corresponding reference, for every token.

The reference SQL files, not any retired generator, are the sole oracle. If the generator diverges, either it regressed (fix `crates/eql-codegen`) or the reference is being updated deliberately (regenerate and commit the new references in the same PR).

See `docs/reference/adding-a-scalar-encrypted-domain-type.md` §6 for the full generator story (catalog source of truth, minijinja templates, term capabilities).

## Adding or updating a reference

Every catalog token **must** have a committed `tests/codegen/reference/<token>/` dir — `reference_dirs_match_catalog_tokens` fails CI if a catalog row has no reference, or a reference has no catalog row. To (re)generate:

1. `cargo run -p eql-codegen` — writes the real `src/v3/scalars/<token>/` tree (gitignored).
2. For each generated `*.sql`, copy it into `tests/codegen/reference/<token>/` with a single `-- REFERENCE:` provenance line prepended as line 1.
3. Run `mise run codegen:parity` (or `cargo test -p eql-codegen`) to confirm byte-for-byte parity.

A deliberate generator change (template/term/catalog edit) regenerates the affected references in the same PR.

## No committed fixture values

Plaintext fixture lists are **not** generated and **not** committed as `<T>_values.rs` files — there are none in the tree. They live in the catalog as `eql_domains::INT4_VALUES` / `INT2_VALUES`, materialised at compile time by the `int_values!` macro in `crates/eql-domains/src/lib.rs` from each `CATALOG` row, and pinned by `eql-domains`'s own `values_tests`. The parity gate only globs `*.sql`; it does not check any `values.rs`.
