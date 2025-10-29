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
AS $$
  DECLARE
    a_data jsonb;
    b_data jsonb;
  BEGIN

    IF a IS NULL AND b IS NULL THEN
      RETURN 0;
    END IF;

    IF a IS NULL THEN
      RETURN -1;
    END IF;

    IF b IS NULL THEN
      RETURN 1;
    END IF;

    a_data := a.data;
    b_data := b.data;

    IF a_data < b_data THEN
      RETURN -1;
    END IF;

    IF a_data > b_data THEN
      RETURN 1;
    END IF;

    RETURN 0;
  END;
$$ LANGUAGE plpgsql;
