-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: ore_block_u64_8_256types.sql
-- REQUIRE: ore_block_u64_8_256functions.sql
-- REQUIRE: src/operators/=.sql

-- Operators for equality comparisons of eql_v2_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v2_encrypted <> eql_v2_encrypted
--      eql_v2_encrypted <> jsonb
--      jsonb <> eql_v2_encrypted
--
-- There are multiple index terms that provide equality comparisons
--   - hmac_256
--   - ore_64_8_v2
--   - ore_cllw_8_v2
--
-- We check these index terms in this order and use the first one that exists for both parameters
--
--

CREATE FUNCTION eql_v2.neq(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN NOT eql_v2.eq(a, b );
  END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION eql_v2."<>"(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.neq(a, b );
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR <> (
  FUNCTION=eql_v2."<>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


CREATE FUNCTION eql_v2."<>"(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.neq(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v2."<>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



CREATE FUNCTION eql_v2."<>"(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  BEGIN
    RETURN eql_v2.neq(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <> (
  FUNCTION=eql_v2."<>",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);




