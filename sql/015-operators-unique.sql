-- Operators for unique comparisons of cs_encrypted_v1 types
--
-- Support for the following comparisons:
--
--      cs_encrypted_v1 = cs_encrypted_v1
--      cs_encrypted_v1 <> cs_encrypted_v1
--      cs_encrypted_v1 = jsonb
--      cs_encrypted_v1 <> jsonb
--      cs_encrypted_v1 = text
--      cs_encrypted_v1 <> text
--

DROP OPERATOR IF EXISTS = (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_unique_v1(a) = cs_unique_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR = (
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS = (cs_encrypted_v1, cs_unique_index_v1);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_unique_index_v1);

CREATE FUNCTION cs_encrypted_eq_v1(a cs_encrypted_v1, b cs_unique_index_v1)
RETURNS boolean AS $$
  SELECT cs_unique_v1(a) = b;
$$ LANGUAGE SQL;

CREATE OPERATOR = (
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_unique_index_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS = (cs_unique_index_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_eq_v1(a cs_unique_index_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_eq_v1(a cs_unique_index_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT a = cs_unique_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR =(
  PROCEDURE="cs_encrypted_eq_v1",
  LEFTARG=cs_unique_index_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



--- ------------------------------------------------------------

DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_unique_v1(a) <> cs_unique_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

DROP OPERATOR IF EXISTS <> (cs_encrypted_v1, cs_unique_index_v1);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_unique_index_v1);

CREATE FUNCTION cs_encrypted_neq_v1(a cs_encrypted_v1, b cs_unique_index_v1)
RETURNS boolean AS $$
  SELECT cs_unique_v1(a) <> b;
$$ LANGUAGE SQL;

CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_unique_index_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


DROP OPERATOR IF EXISTS <> (cs_unique_index_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_neq_v1(a cs_unique_index_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_neq_v1(a cs_unique_index_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT a <> cs_unique_v1(b);
$$ LANGUAGE SQL;

CREATE OPERATOR <> (
  PROCEDURE="cs_encrypted_neq_v1",
  LEFTARG=cs_unique_index_v1,
  RIGHTARG=cs_encrypted_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);
