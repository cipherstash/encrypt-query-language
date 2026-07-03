# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-07-03

### Added

- `DomainPayload` — a catalog-generated enum spanning every stored-payload
  domain type (all scalar binding structs plus `SteVecDocument`), emitted by
  eql-codegen so it cannot drift when the catalog grows a domain.
  Serialize-only (`#[serde(untagged)]` — the wire form is exactly the inner
  struct's) and constructed only from a known `TargetDomain`, never inferred
  from bytes (cross-token payloads are byte-identical on the wire).
- `from_v2_typed(&Value, TargetDomain) -> Result<DomainPayload, FromV2Error>`
  — the typed counterpart to `from_v2`, sharing its conversion core and
  performing the single strict parse as parse-and-keep instead of
  validate-and-discard. `from_v2 -> Value` is unchanged.

## [0.2.0] - 2026-07-03

### Changed

- **BREAKING**: the EQL envelope version is now `v: 3` (was `v: 2`) —
  `EQL_SCHEMA_VERSION`, the `SchemaVersion` newtype, the emitted TypeScript
  alias, and the JSON Schema `const` accept exactly `3`, matching the
  `eql_v3` domain CHECKs.

### Added

- `from_v2` — EQL v2.3 → v3 wire payload conversion: `from_v2(&Value,
  TargetDomain)` for storage payloads (fail-closed on missing terms, drops
  the v2 `k` discriminator, strict-parses through the target binding type),
  `from_v2_query` for jsonb containment needles, and `is_v3_payload` for
  envelope sniffing. Zero cipherstash-client dependency.
- SteVec (encrypted JSONB) document surface: `SteVecDocument` (carrying the
  `k: "sv"` form discriminator), entry/query types, and the `OreCllw` /
  `Selector` term newtypes, with generated inventory, TypeScript bindings,
  and JSON Schemas.
- CLLW-OPE ordering term: the `OpeCllw` newtype (`op` wire key) and the
  `<T>OrdOpe` binding types for every ordered scalar family.
- `TargetDomain::parse` resolving domain names via the catalog-generated
  inventory; `term_json_keys` / `parse_value` threaded through `DomainType`.
