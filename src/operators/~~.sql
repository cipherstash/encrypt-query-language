-- REQUIRE: src/operators/drop.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/match/types.sql
-- REQUIRE: src/match/functions.sql

-- Operators for match comparisons of eql_v1_encrypted types
--
-- Support for the following comparisons:
--
--      eql_v1_encrypted ~~ eql_v1_encrypted
--      eql_v1_encrypted ~~ jsonb
--      eql_v1_encrypted ~~ eql_v1.match_index
--


DROP FUNCTION IF EXISTS eql_v1.match(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.match(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.match(a) @> eql_v1.match(b);
$$ LANGUAGE SQL;


-- DROP OPERATOR BEFORE FUNCTION
DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, eql_v1_encrypted);
DROP OPERATOR IF EXISTS ~~* (eql_v1_encrypted, eql_v1_encrypted);

DROP FUNCTION IF EXISTS eql_v1."~~"(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1."~~"(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v1.match(a, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ~~(
  FUNCTION=eql_v1."~~",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR ~~*(
  FUNCTION=eql_v1."~~",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS ~~ (eql_v1_encrypted, jsonb);
DROP OPERATOR IF EXISTS ~~* (eql_v1_encrypted, jsonb);

DROP FUNCTION IF EXISTS eql_v1."~~"(a eql_v1_encrypted, b jsonb);

CREATE FUNCTION eql_v1."~~"(a eql_v1_encrypted, b jsonb)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v1.match(a, b::eql_v1_encrypted);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ~~(
  FUNCTION=eql_v1."~~",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1."~~",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS ~~ (jsonb, eql_v1_encrypted);
DROP OPERATOR IF EXISTS ~~* (jsonb, eql_v1_encrypted);

DROP FUNCTION IF EXISTS eql_v1."~~"(a jsonb, b eql_v1_encrypted);

CREATE FUNCTION eql_v1."~~"(a jsonb, b eql_v1_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v1.match(a::eql_v1_encrypted, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ~~(
  FUNCTION=eql_v1."~~",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v1."~~",
  LEFTARG=jsonb,
  RIGHTARG=eql_v1_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-- -----------------------------------------------------------------------------
