-- REQUIRE: src/ore_cllw_var_8/types.sql
-- REQUIRE: src/ore_cllw_var_8/functions.sql



-- Lexical comparison operators


CREATE OR REPLACE FUNCTION eql_v2.ore_cllw_var_8_eq(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8) RETURNS boolean AS $$
  SELECT eql_v2.bytea_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION eql_v2.ore_cllw_var_8_neq(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8) RETURNS boolean AS $$
  SELECT NOT eql_v2.bytea_eq(a.bytes, b.bytes)
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION eql_v2.ore_cllw_var_8_lt(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8)
RETURNS boolean
-- AS $$
--   SELECT eql_v2.compare_ore_cllw_var_8(a, b) = -1
-- $$ LANGUAGE SQL;
AS $$
  BEGIN
    RETURN eql_v2.compare_ore_cllw_var_8(a, b) = -1;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION eql_v2.ore_cllw_var_8_lte(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8) RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_cllw_var_8(a, b) != 1
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION eql_v2.ore_cllw_var_8_gt(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8) RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_cllw_var_8(a, b) = 1
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION eql_v2.ore_cllw_var_8_gte(a eql_v2.ore_cllw_var_8, b eql_v2.ore_cllw_var_8) RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_cllw_var_8(a, b) != -1
$$ LANGUAGE SQL;


CREATE OPERATOR = (
  FUNCTION=eql_v2.ore_cllw_var_8_eq,
  LEFTARG=eql_v2.ore_cllw_var_8,
  RIGHTARG=eql_v2.ore_cllw_var_8,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR <> (
  FUNCTION=eql_v2.ore_cllw_var_8_neq,
  LEFTARG=eql_v2.ore_cllw_var_8,
  RIGHTARG=eql_v2.ore_cllw_var_8,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR > (
  FUNCTION=eql_v2.ore_cllw_var_8_gt,
  LEFTARG=eql_v2.ore_cllw_var_8,
  RIGHTARG=eql_v2.ore_cllw_var_8,
  NEGATOR = <=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR < (
  FUNCTION=eql_v2.ore_cllw_var_8_lt,
  LEFTARG=eql_v2.ore_cllw_var_8,
  RIGHTARG=eql_v2.ore_cllw_var_8,
  NEGATOR = >=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR >= (
  FUNCTION=eql_v2.ore_cllw_var_8_gte,
  LEFTARG=eql_v2.ore_cllw_var_8,
  RIGHTARG=eql_v2.ore_cllw_var_8,
  NEGATOR = <,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR <= (
  FUNCTION=eql_v2.ore_cllw_var_8_lte,
  LEFTARG=eql_v2.ore_cllw_var_8,
  RIGHTARG=eql_v2.ore_cllw_var_8,
  NEGATOR = >,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel,
  HASHES,
  MERGES
);
