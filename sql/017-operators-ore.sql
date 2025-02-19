-- Operators for match comparisons of cs_encrypted_v1 types
--
-- Support for the following comparisons:
--
--      cs_encrypted_v1 > >= < <=  cs_encrypted_v1
--      cs_encrypted_v1 > jsonb
--      cs_encrypted_v1 > ore_64_8_v1
--

DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_compare_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_compare_v1(a cs_encrypted_v1, b cs_encrypted_v1)
  RETURNS integer AS $$
    SELECT cs_encrypted_ore_64_8_compare_v1(a::jsonb, b::jsonb)
$$ LANGUAGE sql;


DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_compare_v1(a jsonb, b jsonb);

CREATE FUNCTION cs_encrypted_ore_64_8_compare_v1(a jsonb, b jsonb)
  RETURNS integer AS $$
   DECLARE
    a_ore ore_64_8_index_v1;
    b_ore ore_64_8_index_v1;
    result integer;
  BEGIN

    SELECT cs_ore_64_8_v1(a) INTO a_ore;
    SELECT cs_ore_64_8_v1(b) INTO b_ore;

    SELECT compare_ore_64_8_v1(a_ore, b_ore) INTO result;

    RETURN result;
  END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------


DROP OPERATOR IF EXISTS > (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_gt_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_gt_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = 1
$$ LANGUAGE sql;

CREATE OPERATOR >(
  PROCEDURE="cs_encrypted_ore_64_8_v1_gt_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


DROP OPERATOR IF EXISTS > (cs_encrypted_v1, jsonb);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_gt_v1(a cs_encrypted_v1, b jsonb);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_gt_v1(a cs_encrypted_v1, b jsonb)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = 1
$$ LANGUAGE sql;

CREATE OPERATOR >(
  PROCEDURE="cs_encrypted_ore_64_8_v1_gt_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=jsonb,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);



DROP OPERATOR IF EXISTS > (jsonb, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_gt_v1(a jsonb, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_gt_v1(a jsonb, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = 1
$$ LANGUAGE sql;

CREATE OPERATOR >(
  PROCEDURE="cs_encrypted_ore_64_8_v1_gt_v1",
  LEFTARG=jsonb,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


-----------------------------------------------------------------------------------------
-- LT


DROP OPERATOR IF EXISTS < (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_lt_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_lt_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  DECLARE
    result integer;
  BEGIN
    SELECT cs_encrypted_ore_64_8_compare_v1(a, b) INTO result;
    RETURN result = -1;
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR <(
  PROCEDURE="cs_encrypted_ore_64_8_v1_lt_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


DROP OPERATOR IF EXISTS < (cs_encrypted_v1, jsonb);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_lt_v1(a cs_encrypted_v1, b jsonb);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_lt_v1(a cs_encrypted_v1, b jsonb)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = -1
$$ LANGUAGE sql;

CREATE OPERATOR <(
  PROCEDURE="cs_encrypted_ore_64_8_v1_lt_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=jsonb,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


DROP OPERATOR IF EXISTS < (jsonb, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_lt_v1(a jsonb, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_lt_v1(a jsonb, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) = -1
$$ LANGUAGE sql;

CREATE OPERATOR <(
  PROCEDURE="cs_encrypted_ore_64_8_v1_lt_v1",
  LEFTARG=jsonb,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



-----------------------------------------------------------------------------------------


DROP OPERATOR IF EXISTS >=(cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_gte_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_gte_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) != -1
$$ LANGUAGE sql;

CREATE OPERATOR >=(
  PROCEDURE="cs_encrypted_ore_64_8_v1_gte_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS >= (cs_encrypted_v1, jsonb);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_gte_v1(a cs_encrypted_v1, b jsonb);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_gte_v1(a cs_encrypted_v1, b jsonb)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) != -1;
$$ LANGUAGE sql;

CREATE OPERATOR >=(
  PROCEDURE="cs_encrypted_ore_64_8_v1_gte_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=jsonb,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);



DROP OPERATOR IF EXISTS >= (jsonb, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_gte_v1(a jsonb, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_gte_v1(a jsonb, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) != -1
$$ LANGUAGE sql;

CREATE OPERATOR >=(
  PROCEDURE="cs_encrypted_ore_64_8_v1_gte_v1",
  LEFTARG=jsonb,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


-----------------------------------------------------------------------------------------


DROP OPERATOR IF EXISTS <= (cs_encrypted_v1, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_lte_v1(a cs_encrypted_v1, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_lte_v1(a cs_encrypted_v1, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) != 1
$$ LANGUAGE sql;

CREATE OPERATOR <=(
  PROCEDURE="cs_encrypted_ore_64_8_v1_lte_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS <= (cs_encrypted_v1, jsonb);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_lte_v1(a cs_encrypted_v1, b jsonb);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_lte_v1(a cs_encrypted_v1, b jsonb)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) != 1
$$ LANGUAGE sql;

CREATE OPERATOR <=(
  PROCEDURE="cs_encrypted_ore_64_8_v1_lte_v1",
  LEFTARG=cs_encrypted_v1,
  RIGHTARG=jsonb,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


DROP OPERATOR IF EXISTS <= (jsonb, cs_encrypted_v1);
DROP FUNCTION IF EXISTS cs_encrypted_ore_64_8_v1_lte_v1(a jsonb, b cs_encrypted_v1);

CREATE FUNCTION cs_encrypted_ore_64_8_v1_lte_v1(a jsonb, b cs_encrypted_v1)
RETURNS boolean AS $$
  SELECT cs_encrypted_ore_64_8_compare_v1(a, b) != 1
$$ LANGUAGE sql;

CREATE OPERATOR <=(
  PROCEDURE="cs_encrypted_ore_64_8_v1_lte_v1",
  LEFTARG=jsonb,
  RIGHTARG=cs_encrypted_v1,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


-----------------------------------------------------------------------------------------


DROP OPERATOR FAMILY IF EXISTS cs_encrypted_ore_64_8_v1_btree_ops_v1 USING btree;

CREATE OPERATOR FAMILY cs_encrypted_ore_64_8_v1_btree_ops_v1 USING btree;

DROP OPERATOR CLASS IF EXISTS cs_encrypted_ore_64_8_v1_btree_ops_v1 USING btree;

CREATE OPERATOR CLASS cs_encrypted_ore_64_8_v1_btree_ops_v1 DEFAULT
FOR TYPE cs_encrypted_v1 USING btree
  FAMILY cs_encrypted_ore_64_8_v1_btree_ops_v1 AS
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 cs_encrypted_ore_64_8_compare_v1(a cs_encrypted_v1, b cs_encrypted_v1);
