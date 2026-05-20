-- REQUIRE: src/schema.sql

--! @brief CLLW ORE index term type for STE-vec range queries
--!
--! Composite type for CLLW (Copyless Logarithmic Width) Order-Revealing
--! Encryption. The ciphertext is stored in the `oc` field of encrypted data
--! payloads (Standard-mode `ste_vec` elements). Used by `eql_v2.compare` and
--! the range operators (`<`, `<=`, `>`, `>=`) when the payload carries an
--! `oc` term.
--!
--! The wire-format `oc` value is a hex string with a leading domain-tag byte
--! (`0x00` numeric, `0x01` string) followed by the CLLW ciphertext. The
--! decoded `bytes` field on this composite carries the full byte string
--! including the tag — the comparator is variable-length capable, so numeric
--! and string values within the same column are ordered correctly: the
--! domain tag separates the two ranges (numeric < string) and the
--! within-domain comparison falls through to the CLLW per-byte protocol.
--!
--! @see eql_v2.add_search_config
--! @see eql_v2.compare_ore_cllw
--! @note This is a transient type used only during query execution
CREATE TYPE eql_v2.ore_cllw AS (
  bytes bytea
);
