-- REQUIRE: src/schema.sql
-- REQUIRE: src/ope_cllw_var_8/types.sql
-- REQUIRE: src/ope_cllw_var_8/functions.sql


--! @brief Compare two encrypted values using variable-width CLWW OPE index terms
--!
--! Performs a three-way comparison (returns -1/0/1) of encrypted values using
--! their variable-width CLWW OPE ciphertext index terms. Used internally by
--! range operators (<, <=, >, >=) for order-preserving comparisons without
--! decryption.
--!
--! @param a eql_v2_encrypted First encrypted value to compare (NOT NULL — function is STRICT)
--! @param b eql_v2_encrypted Second encrypted value to compare (NOT NULL — function is STRICT)
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note Declared STRICT, so NULL function inputs short-circuit to NULL before
--!       the body runs. The internal `a_term IS NULL` / `b_term IS NULL`
--!       branches are NOT redundant with STRICT — they handle the case where
--!       a non-NULL `eql_v2_encrypted` payload simply lacks the `opv` field
--!       (i.e. `has_ope_cllw_var_8` returned false). A NULL term sorts before
--!       a present term, mirroring the defensive pattern used in
--!       compare_ore_block_u64_8_256.
--! @note OPE ciphertexts compare via standard lexicographic bytea ordering —
--!       bytea compare handles variable-length inputs (shorter prefix is less).
--!
--! @see eql_v2.ope_cllw_var_8
--! @see eql_v2.has_ope_cllw_var_8
CREATE FUNCTION eql_v2.compare_ope_cllw_var_8(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_term eql_v2.ope_cllw_var_8;
    b_term eql_v2.ope_cllw_var_8;
  BEGIN
    IF eql_v2.has_ope_cllw_var_8(a) THEN
      a_term := eql_v2.ope_cllw_var_8(a);
    END IF;

    IF eql_v2.has_ope_cllw_var_8(b) THEN
      b_term := eql_v2.ope_cllw_var_8(b);
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

    -- OPE: standard lex byte compare is exact (shorter prefix sorts less)
    IF a_term.bytes < b_term.bytes THEN
      RETURN -1;
    ELSIF a_term.bytes > b_term.bytes THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END;
$$ LANGUAGE plpgsql;
