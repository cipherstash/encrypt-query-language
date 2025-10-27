-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql


--! @brief Compare two encrypted values using CLLW ORE index terms
--!
--! Performs a three-way comparison (returns -1/0/1) of encrypted values using
--! their CLLW ORE ciphertext index terms. Used internally by range operators
--! (<, <=, >, >=) for order-revealing comparisons without decryption.
--!
--! @param a eql_v2_encrypted First encrypted value to compare
--! @param b eql_v2_encrypted Second encrypted value to compare
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note NULL values are sorted before non-NULL values
--! @note Uses CLLW ORE cryptographic protocol for secure comparisons
--!
--! @see eql_v2.ore_cllw_u64_8
--! @see eql_v2.has_ore_cllw_u64_8
--! @see eql_v2.compare_ore_cllw_term_bytes
--! @see eql_v2."<"
--! @see eql_v2.">"
CREATE FUNCTION eql_v2.compare_ore_cllw_u64_8(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_term eql_v2.ore_cllw_u64_8;
    b_term eql_v2.ore_cllw_u64_8;
  BEGIN

    -- PERFORM eql_v2.log('eql_v2.compare_ore_cllw_u64_8');
    -- PERFORM eql_v2.log('a', a::text);
    -- PERFORM eql_v2.log('b', b::text);

    IF a IS NULL AND b IS NULL THEN
      RETURN 0;
    END IF;

    IF a IS NULL THEN
      RETURN -1;
    END IF;

    IF b IS NULL THEN
      RETURN 1;
    END IF;

    IF eql_v2.has_ore_cllw_u64_8(a) THEN
      a_term := eql_v2.ore_cllw_u64_8(a);
    END IF;

    IF eql_v2.has_ore_cllw_u64_8(a) THEN
      b_term := eql_v2.ore_cllw_u64_8(b);
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

    RETURN eql_v2.compare_ore_cllw_term_bytes(a_term.bytes, b_term.bytes);
  END;
$$ LANGUAGE plpgsql;

