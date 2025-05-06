-- REQUIRE: src/schema.sql
-- REQUIRE: src/crypto.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql


-- DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_eq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_eq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = 0
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_neq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_neq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) <> 0
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_lt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_lt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = -1
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_lte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_lte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) != 1
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_gt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_gt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = 1
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_64_8_v1_gte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);

CREATE FUNCTION eql_v1.ore_64_8_v1_gte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) != -1
$$ LANGUAGE SQL;


-- DROP OPERATOR IF EXISTS = (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR = (
  FUNCTION=eql_v1.ore_64_8_v1_eq,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-- DROP OPERATOR IF EXISTS <> (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR <> (
  FUNCTION=eql_v1.ore_64_8_v1_neq,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

-- DROP OPERATOR IF EXISTS > (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR > (
  FUNCTION=eql_v1.ore_64_8_v1_gt,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);


-- DROP OPERATOR IF EXISTS < (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR < (
  FUNCTION=eql_v1.ore_64_8_v1_lt,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);


-- DROP OPERATOR IF EXISTS <= (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR <= (
  FUNCTION=eql_v1.ore_64_8_v1_lte,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


-- DROP OPERATOR IF EXISTS >= (eql_v1.ore_64_8_v1, eql_v1.ore_64_8_v1);

CREATE OPERATOR >= (
  FUNCTION=eql_v1.ore_64_8_v1_gte,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);


-- DROP OPERATOR FAMILY IF EXISTS eql_v1.ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR FAMILY eql_v1.ore_64_8_v1_btree_ops USING btree;


-- DROP OPERATOR CLASS IF EXISTS eql_v1.ore_64_8_v1_btree_ops USING btree;

CREATE OPERATOR CLASS eql_v1.ore_64_8_v1_btree_ops DEFAULT FOR TYPE eql_v1.ore_64_8_v1 USING btree FAMILY eql_v1.ore_64_8_v1_btree_ops  AS
        OPERATOR 1 <,
        OPERATOR 2 <=,
        OPERATOR 3 =,
        OPERATOR 4 >=,
        OPERATOR 5 >,
        FUNCTION 1 eql_v1.compare_ore_64_8_v1(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1);
