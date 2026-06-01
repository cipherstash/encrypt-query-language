--! @file schema-v3.sql
--! @brief EQL v3 schema creation
--!
--! Creates the eql_v3 schema, which houses the encrypted-domain type
--! families (eql_v3.int4 and future scalar domains): their domains, index-term
--! extractors, comparison wrappers, blockers, and aggregates. The core
--! index-term types these reuse (eql_v2.hmac_256, eql_v2.ore_block_u64_8_256)
--! remain in the eql_v2 schema and are referenced cross-schema.
--!
--! Drops existing schema if present to support clean reinstallation.
--!
--! @warning DROP SCHEMA CASCADE will remove all objects in the schema
--! @note eql_v3 is a new, additional schema for domain families; the eql_v2
--!       schema name is unchanged.

--! @brief Drop existing EQL v3 schema
--! @warning CASCADE will drop all dependent objects
DROP SCHEMA IF EXISTS eql_v3 CASCADE;

--! @brief Create EQL v3 schema
--! @note Houses the encrypted-domain type families
CREATE SCHEMA eql_v3;
