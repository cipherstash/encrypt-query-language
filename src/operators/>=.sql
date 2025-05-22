-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql
-- REQUIRE: src/ore/operators.sql


-- Operators for < less than comparisons of eql_v2_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v2_encrypted = eql_v2_encrypted
--      eql_v2_encrypted = jsonb
--      jsonb = eql_v2_encrypted
--
-- There are multiple index terms that provide equality comparisons
--   - ore_64_8_v2
--   - ore_cllw_8_v2
--
-- We check these index terms in this order and use the first one that exists for both parameters
--
--


CREATE FUNCTION eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN

    BEGIN
      RETURN eql_v2.ore_cllw_u64_8(a) >= eql_v2.ore_cllw_u64_8(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v2.log('eql_v2.gte no ore_cllw_u64_8 index');
    END;

    BEGIN
      RETURN eql_v2.ore_cllw_var_8(a) >= eql_v2.ore_cllw_var_8(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v2.log('eql_v2.gte no ore_cllw_var_8 index');
    END;

    BEGIN
      RETURN eql_v2.ore_block_u64_8_256(a) >= eql_v2.ore_block_u64_8_256(b);
    EXCEPTION WHEN OTHERS THEN
      -- PERFORM eql_v2.log('eql_v2.gte no ore_64_8_v2 index');
    END;

    RETURN false;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.gte(a, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR >=(
  FUNCTION = eql_v2.">=",
  LEFTARG = eql_v2_encrypted,
  RIGHTARG = eql_v2_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



CREATE FUNCTION eql_v2.">="(a eql_v2_encrypted, b jsonb)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.gte(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR >=(
  FUNCTION = eql_v2.">=",
  LEFTARG = eql_v2_encrypted,
  RIGHTARG=jsonb,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



CREATE FUNCTION eql_v2.">="(a jsonb, b eql_v2_encrypted)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.gte(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR >=(
  FUNCTION = eql_v2.">=",
  LEFTARG = jsonb,
  RIGHTARG =eql_v2_encrypted,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


