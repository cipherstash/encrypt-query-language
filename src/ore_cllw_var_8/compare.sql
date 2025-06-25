-- REQUIRE: src/schema.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql


CREATE FUNCTION eql_v2.compare_ore_cllw_var_8(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_term eql_v2.ore_cllw_var_8;
    b_term eql_v2.ore_cllw_var_8;
  BEGIN

    -- PERFORM eql_v2.log('eql_v2.compare_ore_cllw_var_8');
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

    IF eql_v2.has_ore_cllw_var_8(a) THEN
      a_term := eql_v2.ore_cllw_var_8(a);
    END IF;

    IF eql_v2.has_ore_cllw_var_8(a) THEN
      b_term := eql_v2.ore_cllw_var_8(b);
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

    RETURN eql_v2.compare_ore_cllw_var_8_term(a_term, b_term);
  END;
$$ LANGUAGE plpgsql;

