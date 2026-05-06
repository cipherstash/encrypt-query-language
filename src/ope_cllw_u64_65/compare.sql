-- REQUIRE: src/schema.sql
-- REQUIRE: src/ope_cllw_u64_65/types.sql
-- REQUIRE: src/ope_cllw_u64_65/functions.sql


--! @brief Compare two encrypted values using CLWW OPE index terms
--!
--! Performs a three-way comparison (returns -1/0/1) of encrypted values using
--! their fixed-width CLWW OPE ciphertext index terms. Used internally by range
--! operators (<, <=, >, >=) for order-preserving comparisons without decryption.
--!
--! @param a eql_v2_encrypted First encrypted value to compare
--! @param b eql_v2_encrypted Second encrypted value to compare
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note NULL values are sorted before non-NULL values
--! @note OPE ciphertexts compare via standard lexicographic bytea ordering —
--!       no custom per-byte protocol required (unlike the ORE CLWW variants)
--!
--! @see eql_v2.ope_cllw_u64_65
--! @see eql_v2.has_ope_cllw_u64_65
CREATE FUNCTION eql_v2.compare_ope_cllw_u64_65(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_term eql_v2.ope_cllw_u64_65;
    b_term eql_v2.ope_cllw_u64_65;
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

    IF eql_v2.has_ope_cllw_u64_65(a) THEN
      a_term := eql_v2.ope_cllw_u64_65(a);
    END IF;

    IF eql_v2.has_ope_cllw_u64_65(b) THEN
      b_term := eql_v2.ope_cllw_u64_65(b);
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

    -- OPE: standard lex byte compare is exact
    IF a_term.bytes < b_term.bytes THEN
      RETURN -1;
    ELSIF a_term.bytes > b_term.bytes THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END;
$$ LANGUAGE plpgsql;
