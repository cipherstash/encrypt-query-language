-- REQUIRE: src/schema.sql

--! @brief CLWW OPE index term type for variable-width range queries
--!
--! Composite type for variable-width CLWW (Chenette, Lewi, Weis, Wu)
--! Order-Preserving Encryption. Unlike ope_cllw_u64_65, supports
--! variable-length ciphertexts (strings / byte slices). Ciphertext length is
--! `8 * plaintext_bytes + 1` (one carry byte + 8 bytes per plaintext bit).
--!
--! Ciphertexts compare with **standard lexicographic byte ordering** — unlike
--! the ORE variants there is no custom per-byte compare protocol. The ciphertext
--! is stored in the 'opv' field of encrypted data payloads.
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.compare_ope_cllw_var_8
--! @note This is a transient type used only during query execution
CREATE TYPE eql_v2.ope_cllw_var_8 AS (
  bytes bytea
);
