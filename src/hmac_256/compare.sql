-- REQUIRE: src/schema.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql


--! @brief Compare two encrypted values using HMAC-SHA256 index terms
--!
--! Performs a three-way comparison (returns -1/0/1) of encrypted values using
--! their HMAC-SHA256 hash index terms. Used internally by the equality operator (=)
--! for exact-match queries without decryption.
--!
--! @param a eql_v2_encrypted First encrypted value to compare
--! @param b eql_v2_encrypted Second encrypted value to compare
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note NULL values are sorted before non-NULL values
--! @note Comparison uses underlying text type ordering of HMAC-SHA256 hashes
--!
--! @see eql_v2.hmac_256
--! @see eql_v2.has_hmac_256
--! @see eql_v2."="
CREATE FUNCTION eql_v2.compare_hmac_256(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_term eql_v2.hmac_256;
    b_term eql_v2.hmac_256;
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

    IF eql_v2.has_hmac_256(a) THEN
      a_term = eql_v2.hmac_256(a);
    END IF;

    IF eql_v2.has_hmac_256(b) THEN
      b_term = eql_v2.hmac_256(b);
    END IF;

    IF a_term IS NULL AND b_term IS NULL THEN
      RETURN 0;
    END IF;

    IF a_term IS NULL THEN
      RETURN -1;
    END IF;

    IF b_term IS NULL THEN
      RETURN 1;
    END IF;

    -- Using the underlying text type comparison
    IF a_term = b_term THEN
      RETURN 0;
    END IF;

    IF a_term < b_term THEN
      RETURN -1;
    END IF;

    IF a_term > b_term THEN
      RETURN 1;
    END IF;

  END;
$$ LANGUAGE plpgsql;
