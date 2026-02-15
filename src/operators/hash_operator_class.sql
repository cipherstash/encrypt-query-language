-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/hash.sql
-- REQUIRE: src/operators/=.sql

--! @brief PostgreSQL hash operator class for encrypted value hashing
--!
--! Defines the hash operator family and operator class required for hash-based
--! operations on encrypted values. This enables PostgreSQL to use hash strategies for:
--! - Hash joins (cross-row equality via hash)
--! - GROUP BY (hash aggregation)
--! - DISTINCT (hash-based deduplication)
--! - UNION (hash-based set operations)
--!
--! Only the same-type equality operator (eql_v2_encrypted = eql_v2_encrypted) is
--! registered. Cross-type operators (encrypted/jsonb) are excluded because hash
--! joins require independent hashing of each side before comparison.
--!
--! @note Requires hmac_256 or blake3 index terms for correct hashing
--! @see eql_v2.hash_encrypted
--! @see eql_v2.encrypted_operator_class (btree)

CREATE OPERATOR FAMILY eql_v2.encrypted_hash_operator_family USING hash;

CREATE OPERATOR CLASS eql_v2.encrypted_hash_operator_class
  DEFAULT FOR TYPE eql_v2_encrypted USING hash
  FAMILY eql_v2.encrypted_hash_operator_family AS
    OPERATOR 1 = (eql_v2_encrypted, eql_v2_encrypted),
    FUNCTION 1 eql_v2.hash_encrypted(eql_v2_encrypted);
