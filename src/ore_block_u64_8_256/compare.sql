-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql


--! @brief Compare two encrypted values using ORE block index terms
--!
--! Performs a three-way comparison (returns -1/0/1) of encrypted values using
--! their ORE block index terms. Used internally by range operators (<, <=, >, >=)
--! for order-revealing comparisons without decryption.
--!
--! @param a eql_v2_encrypted First encrypted value to compare
--! @param b eql_v2_encrypted Second encrypted value to compare
--! @return Integer -1 if a < b, 0 if a = b, 1 if a > b
--!
--! @note NULL values are sorted before non-NULL values
--! @note Uses ORE cryptographic protocol for secure comparisons
--!
--! @see eql_v2.ore_block_u64_8_256
--! @see eql_v2.has_ore_block_u64_8_256
--! @see eql_v2."<"
--! @see eql_v2.">"
CREATE FUNCTION eql_v2.compare_ore_block_u64_8_256(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_term eql_v2.ore_block_u64_8_256;
    b_term eql_v2.ore_block_u64_8_256;
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

    IF eql_v2.has_ore_block_u64_8_256(a) THEN
      a_term := eql_v2.ore_block_u64_8_256(a);
    END IF;

    IF eql_v2.has_ore_block_u64_8_256(a) THEN
      b_term := eql_v2.ore_block_u64_8_256(b);
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

    RETURN eql_v2.compare_ore_block_u64_8_256_terms(a_term.terms, b_term.terms);
  END;
$$ LANGUAGE plpgsql;

