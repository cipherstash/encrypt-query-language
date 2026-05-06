-- REQUIRE: src/schema.sql

--! @brief Variable-width CLLW ORE index term type for range queries
--!
--! Composite type for variable-width CLLW (Copyless Logarithmic Width) Order-Revealing Encryption.
--! Each output block is 8-bits. Unlike ore_cllw_u64_8, supports variable-length ciphertexts.
--! Used for encrypted range queries via the 'ore' index type.
--! The ciphertext is stored in the 'ocv' field of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.compare_ore_cllw_var_8
--! @note This is a transient type used only during query execution
CREATE TYPE eql_v2.ore_cllw_var_8 AS (
  bytes bytea
);
