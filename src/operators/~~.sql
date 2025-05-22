-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/match/types.sql
-- REQUIRE: src/match/functions.sql

-- Operators for match comparisons of eql_v2_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v2_encrypted ~~ eql_v2_encrypted
--      eql_v2_encrypted ~~ jsonb
--      eql_v2_encrypted ~~ eql_v2.bloom_filter_index
--



CREATE FUNCTION eql_v2.like(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean AS $$
  SELECT eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b);
$$ LANGUAGE SQL;


--
-- Case sensitivity depends on the index term configuration
-- Function preserves the SQL semantics
--
CREATE FUNCTION eql_v2.ilike(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean AS $$
  SELECT eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b);
$$ LANGUAGE SQL;





CREATE FUNCTION eql_v2."~~"(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.like(a, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ~~(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR ~~*(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



CREATE FUNCTION eql_v2."~~"(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.like(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ~~(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);




CREATE FUNCTION eql_v2."~~"(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.like(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ~~(
  FUNCTION=eql_v2."~~",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v2."~~",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-- -----------------------------------------------------------------------------
