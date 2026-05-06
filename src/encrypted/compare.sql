-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql

--! @brief Fallback literal comparison for encrypted values
--! @internal
--!
--! Compares two encrypted values by their raw JSONB representation when no
--! suitable index terms are available. This ensures consistent ordering required
--! for btree correctness and prevents "lock BufferContent is not held" errors.
--!
--! Used as a last resort fallback in eql_v2.compare() when encrypted values
--! lack matching index terms (blake3, hmac_256, ore).
--!
--! @param a eql_v2_encrypted First encrypted value
--! @param b eql_v2_encrypted Second encrypted value
--! @return integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note This compares the encrypted payloads directly, not the plaintext values
--! @note Ordering is consistent but not meaningful for range queries
--! @see eql_v2.compare
CREATE FUNCTION eql_v2.compare_literal(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  LANGUAGE SQL
AS $$
    SELECT CASE
        WHEN a.data < b.data THEN -1
        WHEN a.data > b.data THEN 1
        ELSE 0
    END;
$$;
