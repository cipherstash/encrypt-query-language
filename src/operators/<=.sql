-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql


-- Operators for <= less than or equal to comparisons of eql_v2_encrypted types
--
-- Uses `eql_v2.compare` for the actual comparison logic.
--
--
CREATE FUNCTION eql_v2.lte(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.compare(a, b) <= 0;
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2."<="(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.lte(a, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <=(
  FUNCTION = eql_v2."<=",
  LEFTARG = eql_v2_encrypted,
  RIGHTARG = eql_v2_encrypted,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



CREATE FUNCTION eql_v2."<="(a eql_v2_encrypted, b jsonb)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.lte(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <=(
  FUNCTION = eql_v2."<=",
  LEFTARG = eql_v2_encrypted,
  RIGHTARG = jsonb,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



CREATE FUNCTION eql_v2."<="(a jsonb, b eql_v2_encrypted)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.lte(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <=(
  FUNCTION = eql_v2."<=",
  LEFTARG = jsonb,
  RIGHTARG = eql_v2_encrypted,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


