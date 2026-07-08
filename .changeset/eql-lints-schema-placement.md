---
'@cipherstash/eql': minor
---

**`eql_v3.lints()` gains a `schema_placement` category.** `SELECT * FROM eql_v3.lints() WHERE category = 'schema_placement'` reports, at severity `error`, any naked composite or enum TYPE that has been created in the public `eql_v3` schema — an internal index-term type (e.g. `ore_block_256_term`) that belongs in `eql_v3_internal`. Why: the `eql_v3` / `eql_v3_internal` split exists to keep index-term-only types out of the Supabase Table Builder type picker; this lint makes a placement regression self-detecting at runtime (the CI-side net is the placement invariant in `tests/sqlx/tests/v3_public_surface_tests.rs`). A clean install reports zero `schema_placement` rows.
