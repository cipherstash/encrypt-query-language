-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql


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

