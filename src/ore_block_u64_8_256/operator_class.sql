-- NOTE FILE IS DISABLED
-- REPLACE `!REQUIRE` with `REQUIRE` to enable in the build

-- !REQUIRE: src/schema.sql
-- !REQUIRE: src/ore_block_u64_8_256/types.sql


--! @brief B-tree operator family for ORE block types
--!
--! Defines the operator family for creating B-tree indexes on ORE block types.
--!
--! @note FILE IS DISABLED - Not included in build
--! @see eql_v2.ore_block_u64_8_256_operator_class
CREATE OPERATOR FAMILY eql_v2.ore_block_u64_8_256_operator_family USING btree;

--! @brief B-tree operator class for ORE block encrypted values
--!
--! Defines the operator class required for creating B-tree indexes on columns
--! using the ore_block_u64_8_256 type. Enables range queries and ORDER BY on
--! ORE-encrypted data without decryption.
--!
--! Supports operators: <, <=, =, >=, >
--! Uses comparison function: compare_ore_block_u64_8_256_terms
--!
--! @note FILE IS DISABLED - Not included in build
--!
--! @example
--! -- Would be used like (if enabled):
--! CREATE INDEX ON events USING btree (
--!   (encrypted_timestamp::jsonb->'ob')::eql_v2.ore_block_u64_8_256
--! );
--!
--! @see CREATE OPERATOR CLASS in PostgreSQL documentation
--! @see eql_v2.compare_ore_block_u64_8_256_terms
CREATE OPERATOR CLASS eql_v2.ore_block_u64_8_256_operator_class DEFAULT FOR TYPE eql_v2.ore_block_u64_8_256 USING btree FAMILY eql_v2.ore_block_u64_8_256_operator_family  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v2.compare_ore_block_u64_8_256_terms(a eql_v2.ore_block_u64_8_256, b eql_v2.ore_block_u64_8_256);
