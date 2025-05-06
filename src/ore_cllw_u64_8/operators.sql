-- REQUIRE: src/schema.sql
-- REQUIRE: src/common.sql
-- REQUIRE: src/ore_cllw_u64_8/types.sql
-- REQUIRE: src/ore_cllw_u64_8/functions.sql

-- DROP FUNCTION IF EXISTS eql_v1.ore_cllw_u64_8_eq(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8);

CREATE FUNCTION eql_v1.ore_cllw_u64_8_eq(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8)
RETURNS boolean AS $$
  SELECT eql_v1.bytea_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_cllw_u64_8_neq(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8);

CREATE FUNCTION eql_v1.ore_cllw_u64_8_neq(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8)
RETURNS boolean AS $$
  SELECT NOT eql_v1.bytea_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_cllw_u64_8_lt(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8);

CREATE FUNCTION eql_v1.ore_cllw_u64_8_lt(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8)
RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v1.compare_ore_cllw_u64_8(a, b) = -1;
  END
$$ LANGUAGE plpgsql;


-- DROP FUNCTION IF EXISTS eql_v1.ore_cllw_u64_8_lte(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8);

CREATE FUNCTION eql_v1.ore_cllw_u64_8_lte(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_cllw_u64_8(a, b) != 1
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_cllw_u64_8_gt(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8);

CREATE FUNCTION eql_v1.ore_cllw_u64_8_gt(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_cllw_u64_8(a, b) = 1
$$ LANGUAGE SQL;


-- DROP FUNCTION IF EXISTS eql_v1.ore_cllw_u64_8_gte(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8);

CREATE FUNCTION eql_v1.ore_cllw_u64_8_gte(a eql_v1.ore_cllw_u64_8, b eql_v1.ore_cllw_u64_8)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_cllw_u64_8(a, b) != -1
$$ LANGUAGE SQL;


-- DROP OPERATOR IF EXISTS = (eql_v1.ore_cllw_u64_8, eql_v1.ore_cllw_u64_8);

CREATE OPERATOR = (
  FUNCTION=eql_v1.ore_cllw_u64_8_eq,
  LEFTARG=eql_v1.ore_cllw_u64_8,
  RIGHTARG=eql_v1.ore_cllw_u64_8,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-- DROP OPERATOR IF EXISTS <> (eql_v1.ore_cllw_u64_8, eql_v1.ore_cllw_u64_8);

CREATE OPERATOR <> (
  FUNCTION=eql_v1.ore_cllw_u64_8_neq,
  LEFTARG=eql_v1.ore_cllw_u64_8,
  RIGHTARG=eql_v1.ore_cllw_u64_8,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-- DROP OPERATOR IF EXISTS > (eql_v1.ore_cllw_u64_8, eql_v1.ore_cllw_u64_8);

CREATE OPERATOR > (
  FUNCTION=eql_v1.ore_cllw_u64_8_gt,
  LEFTARG=eql_v1.ore_cllw_u64_8,
  RIGHTARG=eql_v1.ore_cllw_u64_8,
  NEGATOR = <=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);


-- DROP OPERATOR IF EXISTS < (eql_v1.ore_cllw_u64_8, eql_v1.ore_cllw_u64_8);

CREATE OPERATOR < (
  FUNCTION=eql_v1.ore_cllw_u64_8_lt,
  LEFTARG=eql_v1.ore_cllw_u64_8,
  RIGHTARG=eql_v1.ore_cllw_u64_8,
  NEGATOR = >=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);


-- DROP OPERATOR IF EXISTS >= (eql_v1.ore_cllw_u64_8, eql_v1.ore_cllw_u64_8);

CREATE OPERATOR >= (
  FUNCTION=eql_v1.ore_cllw_u64_8_gte,
  LEFTARG=eql_v1.ore_cllw_u64_8,
  RIGHTARG=eql_v1.ore_cllw_u64_8,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);


-- DROP OPERATOR IF EXISTS <= (eql_v1.ore_cllw_u64_8, eql_v1.ore_cllw_u64_8);

CREATE OPERATOR <= (
  FUNCTION=eql_v1.ore_cllw_u64_8_lte,
  LEFTARG=eql_v1.ore_cllw_u64_8,
  RIGHTARG=eql_v1.ore_cllw_u64_8,
  NEGATOR = >,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);



