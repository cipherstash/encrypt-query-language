-- REQUIRE: src/schema.sql

--! @brief CLLW ORE index term type for range queries
--!
--! Composite type for CLLW (Copyless Logarithmic Width) Order-Revealing Encryption.
--! Each output block is 8-bits. Used for encrypted range queries via the 'ore' index type.
--! The ciphertext is stored in the 'ocf' field of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.compare_ore_cllw_u64_8
--! @note This is a transient type used only during query execution
CREATE TYPE eql_v2.ore_cllw_u64_8 AS (
  bytes bytea
);
