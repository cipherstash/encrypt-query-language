--! @file v3/schema.sql
--! @brief EQL v3 schema creation
--!
--! Creates the eql_v3 and eql_v3_internal schemas. eql_v3 is the public API:
--! the self-contained encrypted-domain type families (eql_v3.int4, eql_v3.int8,
--! and future scalar domains) — their jsonb-backed domains, index-term
--! extractors, and aggregates. eql_v3_internal houses INTERNAL implementation
--! objects: the searchable-encrypted-metadata (SEM) index-term types
--! (eql_v3_internal.hmac_256, eql_v3_internal.ore_block_256), the comparison
--! wrappers, blockers, and aggregate state functions the eql_v3 surface
--! dispatches into. Together the two schemas are self-contained — they own
--! every type they need and have no runtime dependency on another EQL schema.
--!
--! Drops existing schema if present to support clean reinstallation.
--!
--! @warning DROP SCHEMA CASCADE will remove all objects in the schema
--! @note eql_v3 is a new, additional schema for the encrypted-domain families.

--! @brief Drop existing EQL v3 schema
--! @warning CASCADE will drop all dependent objects
DROP SCHEMA IF EXISTS eql_v3 CASCADE;

--! @brief Create EQL v3 schema
--! @note Houses the encrypted-domain type families
CREATE SCHEMA eql_v3;

--! @brief Drop existing EQL v3 internal schema
--! @warning CASCADE will drop all dependent objects
DROP SCHEMA IF EXISTS eql_v3_internal CASCADE;

--! @brief Create EQL v3 internal implementation schema
--! @note Houses INTERNAL eql_v3 objects only (SEM index-term types + support,
--!       scalar operator-backing wrappers/blockers/state functions, jsonb
--!       containment engine and validators). Kept out of the public `eql_v3`
--!       surface so internal index-term TYPES do not clutter the Supabase
--!       Table Builder type picker.
CREATE SCHEMA eql_v3_internal;
COMMENT ON SCHEMA eql_v3_internal IS
  'EQL internal implementation detail; not a public API surface.';
