# 1. Remove `eql_v2`, ship only the self-contained `eql_v3` surface

Date: 2026-06-22

## Status

Accepted

## Context

EQL historically shipped a single `eql_v2` PostgreSQL schema: the
`eql_v2_encrypted` composite column type, its operator surface (`=`, `<>`,
`~~`/`~~*` `LIKE`/`ILIKE`, containment, ORE comparisons), database-side
configuration management (`eql_v2_configuration`, `add_search_config`,
`add_column`, …), the `encryptindex` migration machinery, and the SteVec
encrypted-JSONB surface. `eql_v2` was the documented public API.

The `eql_v3` schema was introduced as an additive, namespaced home for the
generated encrypted-domain type families (`eql_v3.int4`, `int8`, `date`,
`timestamptz`, `numeric`, `float4`/`float8`, `text`, `bool`) plus the
self-contained encrypted-JSONB document surface (`eql_v3.json`, SteVec). Over a
series of changes `eql_v3` became **fully self-contained**: it owns its own
copies of the searchable-encrypted-metadata (SEM) index-term types
(`eql_v3.hmac_256`, `eql_v3.ore_block_256`, `eql_v3.ore_cllw`,
`eql_v3.bloom_filter`), has zero runtime dependency on `eql_v2`, and ships as a
standalone installer (`release/cipherstash-encrypt-v3.sql`) that installs into a
database with no `eql_v2` present. CI gates this self-containment
(`mise run test:self_contained_v3`).

With `eql_v3` standing on its own, keeping `eql_v2` in the repository imposes
ongoing cost — two parallel SQL surfaces to build, test, document, and reason
about — for a surface we intend to supersede. The encryption client
(CipherStash Proxy / ProtectJS) now owns the configuration model that the
database-side `eql_v2` config functions previously provided, so the
database no longer needs to manage that state.

## Decision

Remove `eql_v2` entirely. EQL ships only the self-contained `eql_v3`
encrypted-domain surface. The collapsed build produces the canonical
`release/cipherstash-encrypt.sql` (+ uninstaller) from the `eql_v3` surface
alone, so existing install URLs keep working.

The following `eql_v2`-only capabilities are **dropped with no `eql_v3`
replacement** in this change:

- The `eql_v2_encrypted` composite column type and its operator surface.
- Database-side configuration management (`eql_v2_configuration`,
  `add_search_config`, `add_column`, `migrate_config`, `diff_config`,
  `create_encrypted_columns`). The encryption client owns config now.
- The `encryptindex` migration machinery.
- `LIKE` / `ILIKE` (`~~` / `~~*`) on the encrypted column type. (`eql_v3.text`
  match is bloom-filter containment, not SQL `LIKE`.)
- Boolean operators on `eql_v2_encrypted`.
- Operator-class-on-column indexing. (`eql_v3` indexes via functional indexes
  on the `eq_term` / `ord_term` / `match_term` extractors.)
- `GROUP BY` / `grouped_value` on the encrypted column type.

The supported searchable-encryption capabilities (equality, ordered range,
`MIN`/`MAX`, encrypted-JSONB document containment and path access) are all
provided by the `eql_v3` surface.

## Consequences

- **This is a major (3.0.0) break of the public API.** Callers using the
  `eql_v2` schema must migrate to the `eql_v3` encrypted-domain types. Per the
  project decision, **no per-capability upgrade/migration guide is written** for
  the dropped capabilities — the dropped surface has no `eql_v3` equivalent, so
  there is no mechanical migration to document.
- The canonical `release/cipherstash-encrypt.sql` artifact is now the `eql_v3`
  surface. The `-supabase` and `-protect` build variants are removed (they
  existed to subset the `eql_v2` surface).
- The repository ships a single SQL surface, a single build, and a single test
  install path — reducing build/test/maintenance surface area.
- The EQL SQL linter is retained as `eql_v3.lints()` (ported from
  `eql_v2.lints()`), scoped to the `eql_v3` schema, so the inlinability /
  blocker / domain-shape quality gates survive.

## Related

- `CHANGELOG.md` `[Unreleased]` → `Removed` entry.
- Self-containment invariant and gate: `mise run test:self_contained_v3`.
