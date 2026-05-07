-- REQUIRE: src/schema.sql

--! @brief CLWW OPE index term type for fixed-width numeric range queries
--!
--! Composite type for CLWW (Chenette, Lewi, Weis, Wu) Order-Preserving Encryption
--! over 64-bit integers. Ciphertexts are 65 bytes (8 bytes per plaintext byte,
--! plus one reserved carry byte).
--!
--! Ciphertexts compare with **standard lexicographic byte ordering** — unlike
--! the ORE variants there is no custom per-byte compare protocol. The ciphertext
--! is stored in the 'opf' field of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.compare_ope_cllw_u64_65
--! @note This is a transient type used only during query execution
CREATE TYPE eql_v2.ope_cllw_u64_65 AS (
  bytes bytea
);
