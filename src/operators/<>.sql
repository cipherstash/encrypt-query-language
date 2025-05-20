-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/unique/types.sql
-- REQUIRE: src/unique/functions.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql
-- REQUIRE: src/operators/=.sql

-- Operators for equality comparisons of eql_v1_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v1_encrypted <> eql_v1_encrypted
--      eql_v1_encrypted <> jsonb
--      jsonb <> eql_v1_encrypted
--
-- There are multiple index terms that provide equality comparisons
--   - unique
--   - ore_64_8_v1
--   - ore_cllw_8_v1
--
-- We check these index terms in this order and use the first one that exists for both parameters
--
--

CREATE FUNCTION eql_v1.neq(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN NOT eql_v1.eq(a, b );
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v1."<>"(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v1.neq(a, b );
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <> (
  FUNCTION=eql_v1."<>",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


CREATE FUNCTION eql_v1."<>"(a eql_v1_encrypted, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v1.neq(a, b::eql_v1_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v1."<>",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



CREATE FUNCTION eql_v1."<>"(a jsonb, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v1.neq(a::eql_v1_encrypted, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v1."<>",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);




