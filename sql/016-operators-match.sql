-- Operators for match comparisons of cs_encrypted_v1 types
--
-- Support for the following comparisons:
--
--      cs_encrypted_v1 @> cs_encrypted_v1
--      cs_encrypted_v1 @> jsonb
--      cs_encrypted_v1 @> cs_match_index_v1
--

DROP OPERATOR IF EXISTS @> (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_contains_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_contains_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_match_v1(a) @> cs_match_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR @>(
  PROCEDURE="cs_encrypted_contains_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS @> (cs_encrypted_v1, cs_match_index_v1);
DROP FUNCTION IF EXISTS cs_encrypted_contains_v1(a cs_encrypted_v1, b cs_match_index_v1);

CREATE FUNCTION cs_encrypted_contains_v1(a cs_encrypted_v1, b cs_match_index_v1)
RETURNS boolean AS $$
  SELECT cs_match_v1(a) @> b;
$$ LANGUAGE SQL;

CREATE OPERATOR @>(
  PROCEDURE="cs_encrypted_contains_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_match_index_v1,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



DROP OPERATOR IF EXISTS @> (cs_match_index_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_contains_v1(a cs_match_index_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_contains_v1(a cs_match_index_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT a @> cs_match_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR @>(
  PROCEDURE="cs_encrypted_contains_v1",
  LEFTARG=cs_match_index_v1,
  RIGHTARG=cs_encrypted_v1,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-----------------------------------------------------------------------------


DROP OPERATOR IF EXISTS <@ (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_contained_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_contained_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_match_v1(a) <@ cs_match_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <@(
  PROCEDURE="cs_encrypted_contained_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <@ (cs_match_index_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_contained_v1(a cs_match_index_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_contained_v1(a cs_match_index_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT a <@ cs_match_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <@ (
  PROCEDURE="cs_encrypted_contained_v1",
  LEFTARG=cs_match_index_v1,
  RIGHTARG=cs_encrypted_v1,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <@ (cs_encrypted_v1, cs_match_index_v1);
DROP FUNCTION IF EXISTS cs_encrypted_contained_v1(a cs_encrypted_v1, b cs_match_index_v1);

CREATE FUNCTION cs_encrypted_contained_v1(a cs_match_index_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_match_v1(a) <@ b;
$$ LANGUAGE SQL;

CREATE OPERATOR <@ (
  PROCEDURE="cs_encrypted_contained_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_match_index_v1,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-----------------------------------------------------------------------------------------


