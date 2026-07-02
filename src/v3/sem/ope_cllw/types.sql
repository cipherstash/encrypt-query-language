-- REQUIRE: src/v3/schema.sql

--! @file v3/sem/ope_cllw/types.sql
--! @brief CLLW OPE index term type for scalar range queries (eql_v3 SEM)
--!
--! Composite type for CLLW (Copyless Logarithmic Width) Order-Preserving
--! Encryption. The ciphertext is stored in the `op` field of encrypted scalar
--! payloads (the `_ord_ope` domains). The wire-format `op` value is a
--! hex-encoded ciphertext; the decoded `bytes` field carries the raw byte
--! string.
--!
--! Unlike the CLLW ORE term (`oc`, eql_v3.ore_cllw, compared by a custom
--! per-byte protocol), the OPE ciphertext is order-preserving under plain
--! byte comparison: hex-decode to bytea and native bytea ordering IS the
--! plaintext ordering. No custom comparison protocol is required — the
--! operators and the btree comparator reduce to native bytea comparisons.
--!
--! @note This is a transient type used only during query execution.
--! @see eql_v3.compare_ope_cllw_term
CREATE TYPE eql_v3.ope_cllw AS (
  bytes bytea
);
