-- REQUIRE: src/v3/schema.sql

--! @file v3/sem/ore_cllw/types.sql
--! @brief CLLW ORE index term type for STE-vec range queries (eql_v3 SEM)
--!
--! Composite type for CLLW (Copyless Logarithmic Width) Order-Revealing
--! Encryption. The ciphertext is stored in the `oc` field of encrypted data
--! payloads (Standard-mode `ste_vec` elements). Used by the range operators
--! (`<`, `<=`, `>`, `>=`) when an sv element carries an `oc` term.
--!
--! The wire-format `oc` value is a hex string with a leading domain-tag byte
--! (`0x00` numeric, `0x01` string) followed by the CLLW ciphertext. The
--! decoded `bytes` field carries the full byte string including the tag — the
--! comparator is variable-length capable, so numeric and string values within
--! the same column order correctly: the domain tag separates the ranges
--! (numeric < string) and the within-domain comparison falls through to the
--! CLLW per-byte protocol.
--!
--! @note This is a transient type used only during query execution.
--! @see eql_v3_internal.compare_ore_cllw_term
CREATE TYPE eql_v3_internal.ore_cllw AS (
  bytes bytea
);
