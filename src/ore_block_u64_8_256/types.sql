-- REQUIRE: src/schema.sql


--! @brief ORE block term type for Order-Revealing Encryption
--!
--! Composite type representing a single ORE (Order-Revealing Encryption) block term.
--! Stores encrypted data as bytea that enables range comparisons without decryption.
--!
--! @see eql_v2.ore_block_u64_8_256
--! @see eql_v2.compare_ore_block_u64_8_256_term
CREATE TYPE eql_v2.ore_block_u64_8_256_term AS (
  bytes bytea
);


--! @brief ORE block index term type for range queries
--!
--! Composite type containing an array of ORE block terms. Used for encrypted
--! range queries via the 'ore' index type. The array is stored in the 'ob' field
--! of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.compare_ore_block_u64_8_256_terms
--! @note This is a transient type used only during query execution
CREATE TYPE eql_v2.ore_block_u64_8_256 AS (
  terms eql_v2.ore_block_u64_8_256_term[]
);
