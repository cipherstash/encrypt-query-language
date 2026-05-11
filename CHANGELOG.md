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

Targeting `2.3.0`. See [`docs/upgrading/v2.3.md`](docs/upgrading/v2.3.md) for the consolidated upgrade notes.

### Changed

- **`=`, `<>`, `~~` (`LIKE`), `~~*` (`ILIKE`) on `eql_v2_encrypted` are now inlinable SQL functions.** The planner can structurally match these operators against the documented functional indexes (`eql_v2.hmac_256(col)` for equality, `eql_v2.bloom_filter(col)` for `LIKE`/`ILIKE`), so bare-form queries (`WHERE col = $1`) engage the index without per-query rewriting. Previously these operators wrapped multi-branch PL/pgSQL bodies that the planner could not inline, forcing seq scans on Supabase / managed Postgres installations that lack operator-class indexes. ([#193](https://github.com/cipherstash/encrypt-query-language/pull/193), [#196](https://github.com/cipherstash/encrypt-query-language/pull/196))
- **`eql_v2_encrypted = eql_v2_encrypted` is now strictly hmac-based at the root.** Equality requires both sides to carry `hm` (hmac); otherwise the operator raises with a clear message. Previously, equality could silently fall through to a `NULL` comparison or to Blake3 on synthetic fixtures. Blake3 continues to be used internally inside ste_vec element comparisons, where it has always lived. **Behaviour to be aware of:** queries against columns that lack `hm` will now raise rather than silently returning zero rows — see [U-002](docs/upgrading/v2.3.md#u-002-equality-and-hashing-require-hmac). ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))
- **`eql_v2.hash_encrypted(eql_v2_encrypted)` is now hmac-only.** Hash operations (`GROUP BY`, `DISTINCT`, hash joins) require the column to carry an `hm` index term; the previous Blake3 fallback has been removed. The function raises a clear error directing the caller to configure a `unique` index. ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))

### Removed

- **Root-level Blake3 fallback in `eql_v2.compare()`.** The compare priority list is now (1) ORE block, (2) ORE CLLW u64, (3) ORE CLLW var, (4) OPE CLLW, (5) hmac equality, (6) literal-jsonb tiebreaker. Blake3 is no longer consulted at the root. ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))
- **Root-level `b3` from synthetic test fixtures.** `create_encrypted_json` no longer emits `"b3": "blake3.…"` at the payload root, matching production [`@cipherstash/protect`](https://github.com/cipherstash/protect-js) output. Tests that asserted on root-level Blake3 behaviour have been removed as fictional-shape tests with no production analogue. ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))

### Fixed

- **`@>` and `<@` on encrypted ste_vec columns now match by Blake3 when present.** `ste_vec_contains` previously routed element comparison through `eql_v2.eq`, which (after the root-level Blake3 removal above) falls through to literal JSONB comparison for elements that only carry `b3`. That meant a freshly-built query payload — same plaintext, same `b3`, but different ciphertext bytes — would no longer match a stored row. Restored explicit `compare_blake3` matching for elements where both sides carry `b3`, with `eql_v2.eq` retained as the fallback for OPE-only / future-index cases. The existing tests didn't catch this because they extracted query terms straight from the database (byte-identical); the regression test added in this PR constructs the payload by hand. ([#196](https://github.com/cipherstash/encrypt-query-language/pull/196))

### Deprecated

- **Operator-class indexes (`CREATE INDEX … (col eql_v2.encrypted_operator_class)`) are discouraged for the equality / `LIKE` query path.** They will continue to function for the lifetime of `2.x` and are not slated for removal in this minor. Functional indexes (`eql_v2.hmac_256(col)`, `eql_v2.bloom_filter(col)`, `eql_v2.ste_vec(col)`) are now the canonical path because they (a) work on Supabase and managed Postgres without superuser, (b) avoid the btree row-size limit (`index row size N exceeds btree version 4 maximum 2704`) that opclass indexes hit on full-payload encryption, and (c) give the planner a structurally matchable extractor. The narrow exception is `ORDER BY` over Block ORE columns, where a custom comparator is strictly required — keep opclass indexes on those columns. See [U-001](docs/upgrading/v2.3.md#u-001-functional-indexes-as-the-canonical-recipe).

### Upgrade notes

See [`docs/upgrading/v2.3.md`](docs/upgrading/v2.3.md). Three numbered notes cover the indexing recipe shift (U-001), the hmac requirement for equality and hashing (U-002), and the formalisation of Blake3 as ste_vec-internal (U-003).

## [2.2.1] — 2026-04

(Backfill pending — entries for tagged 2.x releases will be added retroactively from `git log` in a follow-up.)

[Unreleased]: https://github.com/cipherstash/encrypt-query-language/compare/eql-2.2.1...HEAD
[2.2.1]: https://github.com/cipherstash/encrypt-query-language/releases/tag/eql-2.2.1
