--! @file v3/schema.sql
--! @brief EQL v3 schema creation
--!
--! Creates the eql_v3 schema, which houses the self-contained encrypted-domain
--! type families (eql_v3.int4, eql_v3.int8, and future scalar domains): their
--! jsonb-backed domains, the searchable-encrypted-metadata (SEM) index-term
--! types they use (eql_v3.hmac_256, eql_v3.ore_block_256), the index-term
--! extractors, comparison wrappers, blockers, and aggregates. The v3 surface is
--! self-contained — it owns every type it needs and has no runtime dependency
--! on another EQL schema.
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
