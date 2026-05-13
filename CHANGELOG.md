# Changelog

All notable changes to EQL are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and EQL adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The `eql_v2` schema name is part of the public API and is independent of the EQL release version — bumping EQL's major version does not rename the schema.

Tags follow `eql-<version>` (e.g. `eql-2.3.0`); the GitHub release for that tag drives the release workflow.

## How to read this file

- **Added** — new functions, operators, indexes, or developer-facing surfaces.
- **Changed** — behaviour changes that callers may notice but that don't require action.
- **Deprecated** — still works, will be removed in a future release. The entry names the planned removal version.
- **Removed** — no longer present. Migration notes describe the replacement.
- **Fixed** — bug fixes.
- **Security** — fixes that affect confidentiality, integrity, or availability.
- **Upgrade notes** — for releases that change behaviour callers should be aware of (even when no API breaks), a pointer to `docs/upgrading/<version>.md` with numbered notes (`U-NNN`) and a verification checklist.

Each entry that ships in a published release links to the PR that introduced it. Unreleased work lives in the `[Unreleased]` section at the top; entries are promoted into a versioned section when a release is cut.

## [Unreleased]

Targeting `2.3.0` as a breaking release. Customers re-encrypt their data as part of the upgrade — the crypto-side counterpart (`@cipherstash/protect` / `protect-ffi` / proxy) emits a new ste_vec element shape. See [`docs/upgrading/v2.3.md`](docs/upgrading/v2.3.md) for the consolidated upgrade notes.

### Added

- **`eql_v2.hmac_256(val eql_v2_encrypted, selector text)` overload for field-level equality.** Returns the `hm` term from the sv element whose selector matches, as an inlinable single-statement SQL function defined in `src/jsonb/functions.sql`. Mirrors the root-level `eql_v2.hmac_256(val)` recipe at the field level, so a functional hash index on `eql_v2.hmac_256(col, '<selector>')` engages structurally for `WHERE` / `GROUP BY` / `DISTINCT` / hash-join on values extracted from encrypted JSON documents. ([#205](https://github.com/cipherstash/encrypt-query-language/issues/205))
- **`eql_v2.hmac_256_terms(val eql_v2_encrypted) RETURNS jsonb`.** Returns a jsonb array of `{"s": <selector>, "hm": <hmac>}` objects across every sv element that carries an `hm`. Built for GIN-indexed containment: a single index on `eql_v2.hmac_256_terms(col)` covers field-level equality across every selector in the encrypted document, not just one. Query shape: `WHERE eql_v2.hmac_256_terms(col) @> '[{"s":"<sel>","hm":"<hash>"}]'::jsonb`. ([#205](https://github.com/cipherstash/encrypt-query-language/issues/205))
- **`eql_v2.jsonb_path_query`, `jsonb_path_query_first`, `jsonb_path_exists` are now inlinable SQL functions.** The planner can fold the body — `jsonb_array_elements((val).data -> 'sv') WHERE elem ->> 's' = selector` — into the calling query, eliminating the per-row plpgsql call overhead that previously dominated field-level access on large tables. ([#205](https://github.com/cipherstash/encrypt-query-language/issues/205))
- **Formal JSON Schema for the EQL payload format.** Two files under `docs/reference/schema/`: `eql-payload-v2.2.schema.json` captures the on-the-wire shape as of release 2.2 (baseline), and `eql-payload-v2.3.schema.json` captures the target shape for 2.3. The 2.3 schema makes three breaking changes to the payload format: the root-level `b3` term is gone (already reflected in the equality / hashing entries below) and is also dropped from `sv` elements, which now carry `hm` instead; `opf` (fixed-width OPE) and `opv` (variable-width OPE) collapse into a single `op` field with the width carried in the value; OPE (`op`) and ORE (`ob`, `ocf`, `ocv`) are now mutually exclusive within a single payload or `sv` element. Both files use JSON Schema 2020-12 and share a single `IndexTerms` catalogue between root and `sv`-element shapes so that field semantics are described in exactly one place. ([#208](https://github.com/cipherstash/encrypt-query-language/pull/208))

### Changed

- **`=`, `<>`, `~~` (`LIKE`), `~~*` (`ILIKE`) on `eql_v2_encrypted` are now inlinable SQL functions.** The planner can structurally match these operators against the documented functional indexes (`eql_v2.hmac_256(col)` for equality, `eql_v2.bloom_filter(col)` for `LIKE`/`ILIKE`), so bare-form queries (`WHERE col = $1`) engage the index without per-query rewriting. Previously these operators wrapped multi-branch PL/pgSQL bodies that the planner could not inline, forcing seq scans on Supabase / managed Postgres installations that lack operator-class indexes. ([#193](https://github.com/cipherstash/encrypt-query-language/pull/193), [#196](https://github.com/cipherstash/encrypt-query-language/pull/196))
- **`<`, `<=`, `>`, `>=` on `eql_v2_encrypted` are now inlinable SQL functions.** Same precedent as the `=` inlining above: the operator bodies reduce to `eql_v2.ore_block_u64_8_256(a) <op> eql_v2.ore_block_u64_8_256(b)`, so bare-form range queries (`WHERE col < $1`, `WHERE col > $1`, …) structurally match a functional btree index on `eql_v2.ore_block_u64_8_256(col)` (using the existing `eql_v2.ore_block_u64_8_256_operator_class`). Top-N sorts under `ORDER BY col LIMIT n` still need a Sort node (the natural-form sort key doesn't syntactically match the index expression), but each comparison now uses the inlined ORE-term path rather than a plpgsql `eql_v2.compare()` dispatch. The inner `eql_v2.ore_block_u64_8_256_{eq,neq,lt,lte,gt,gte}` helpers backing the ORE-term type's own operators are now declared `IMMUTABLE STRICT PARALLEL SAFE` and allowlisted in the post-build search-path pin so that the chain inlines cleanly through to index matching. **Behaviour to be aware of:** range queries against columns that carry only `ore_cllw_u64_8` / `ore_cllw_var_8` (CLLW ORE) or OPE terms now raise from the `ore_block_u64_8_256` extractor instead of dispatching through the old `eql_v2.compare()` priority list. Callers in that situation must rewrite to the relevant extractor form (e.g. `WHERE eql_v2.ore_cllw_u64_8(col) < eql_v2.ore_cllw_u64_8($1::jsonb)`) — see [U-005](docs/upgrading/v2.3.md#u-005-range-operators-are-block-ore-only).
- **`eql_v2.hmac_256(val jsonb)` and `eql_v2.hmac_256(val eql_v2_encrypted)` are now inlinable SQL.** Both 1-arg overloads flipped from plpgsql-with-RAISE to single-statement SQL returning NULL when `hm` is absent. This restores per-row extractor inlining inside the `=` / `<>` operator bodies. **Behaviour to be aware of:** `WHERE col = $1` on a column lacking `hm` now silently returns zero rows where it previously raised — see the amended [U-002](docs/upgrading/v2.3.md#u-002-equality-and-hashing-require-hmac). The loud RAISE-on-missing-hm path is retained in `eql_v2.hash_encrypted`, so `GROUP BY` / `DISTINCT` / hash joins still surface misconfiguration. ([#205](https://github.com/cipherstash/encrypt-query-language/issues/205))
- **`eql_v2_encrypted = eql_v2_encrypted` is now strictly hmac-based at the root.** Equality requires both sides to carry `hm` (hmac); otherwise the operator returns NULL (and the query returns zero rows). Previously, equality could silently fall through to a `NULL` comparison or to Blake3 on synthetic fixtures. **Behaviour to be aware of:** see [U-002](docs/upgrading/v2.3.md#u-002-equality-and-hashing-require-hmac). ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196), [#205](https://github.com/cipherstash/encrypt-query-language/issues/205))
- **`eql_v2.hash_encrypted(eql_v2_encrypted)` is now hmac-only.** Hash operations (`GROUP BY`, `DISTINCT`, hash joins) require the column to carry an `hm` index term; the previous Blake3 fallback has been removed. The function raises a clear error directing the caller to configure a `unique` index. ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))
- **`ste_vec_contains` now requires `hm` on sv elements.** Element comparison uses `compare_hmac_256` when both sides carry `hm`, falling through to `eq`/`compare` for non-hash-indexed elements (e.g. future OPE-only shapes). The Blake3 path that previously lived inside `ste_vec_contains` is gone — every sv element now carries `hm` post-migration. See [U-004](docs/upgrading/v2.3.md#u-004-sv-element-equality-term-is-hm-not-b3). ([#205](https://github.com/cipherstash/encrypt-query-language/issues/205))

### Removed

- **The entire `eql_v2.blake3` family.** `eql_v2.blake3()`, `eql_v2.has_blake3()`, `eql_v2.compare_blake3()`, and the `eql_v2.blake3` domain type are deleted. The `src/blake3/` module is gone from the source tree. ste_vec elements no longer emit `b3` — the canonical field-level equality term is `hm` (hmac_256). Custom indexes built on `eql_v2.blake3(col)` must be dropped before upgrading; see [U-004](docs/upgrading/v2.3.md#u-004-sv-element-equality-term-is-hm-not-b3) for the migration recipe. ([#205](https://github.com/cipherstash/encrypt-query-language/issues/205))
- **Root-level Blake3 fallback in `eql_v2.compare()`.** The compare priority list is now (1) ORE block, (2) ORE CLLW u64, (3) ORE CLLW var, (4) OPE CLLW, (5) hmac equality, (6) literal-jsonb tiebreaker. ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))
- **Root-level `b3` from synthetic test fixtures.** `create_encrypted_json` no longer emits `"b3": "blake3.…"` at the payload root, matching production [`@cipherstash/protect`](https://github.com/cipherstash/protect-js) output. ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))

### Deprecated

- **Operator-class indexes (`CREATE INDEX … (col eql_v2.encrypted_operator_class)`) are discouraged for the equality / `LIKE` query path.** They will continue to function for the lifetime of `2.x` and are not slated for removal in this minor. Functional indexes (`eql_v2.hmac_256(col)`, `eql_v2.bloom_filter(col)`, `eql_v2.ste_vec(col)`) are now the canonical path because they (a) work on Supabase and managed Postgres without superuser, (b) avoid the btree row-size limit (`index row size N exceeds btree version 4 maximum 2704`) that opclass indexes hit on full-payload encryption, and (c) give the planner a structurally matchable extractor. The narrow exception is `ORDER BY` over Block ORE columns, where a custom comparator is strictly required — keep opclass indexes on those columns. See [U-001](docs/upgrading/v2.3.md#u-001-functional-indexes-as-the-canonical-recipe).

### Upgrade notes

See [`docs/upgrading/v2.3.md`](docs/upgrading/v2.3.md). Four numbered notes cover the indexing recipe shift (U-001), the hmac requirement for equality and hashing (U-002), the formalisation of Blake3 as ste_vec-internal (U-003 — now historical, see U-004), and the breaking ste_vec element shape migration plus the new `eql_v2.hmac_256(col, '<selector>')` recipe (U-004).

## [2.2.1] — 2026-04

(Backfill pending — entries for tagged 2.x releases will be added retroactively from `git log` in a follow-up.)

[Unreleased]: https://github.com/cipherstash/encrypt-query-language/compare/eql-2.2.1...HEAD
[2.2.1]: https://github.com/cipherstash/encrypt-query-language/releases/tag/eql-2.2.1
