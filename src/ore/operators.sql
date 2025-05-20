-- REQUIRE: src/schema.sql
-- REQUIRE: src/crypto.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql



CREATE FUNCTION eql_v2.ore_64_8_v2_eq(a eql_v2.ore_64_8_v2, b eql_v2.ore_64_8_v2)
RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_64_8_v2(a, b) = 0
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v2.ore_64_8_v2_neq(a eql_v2.ore_64_8_v2, b eql_v2.ore_64_8_v2)
RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_64_8_v2(a, b) <> 0
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v2.ore_64_8_v2_lt(a eql_v2.ore_64_8_v2, b eql_v2.ore_64_8_v2)
RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_64_8_v2(a, b) = -1
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v2.ore_64_8_v2_lte(a eql_v2.ore_64_8_v2, b eql_v2.ore_64_8_v2)
RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_64_8_v2(a, b) != 1
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v2.ore_64_8_v2_gt(a eql_v2.ore_64_8_v2, b eql_v2.ore_64_8_v2)
RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_64_8_v2(a, b) = 1
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v2.ore_64_8_v2_gte(a eql_v2.ore_64_8_v2, b eql_v2.ore_64_8_v2)
RETURNS boolean AS $$
  SELECT eql_v2.compare_ore_64_8_v2(a, b) != -1
$$ LANGUAGE SQL;



CREATE OPERATOR = (
  FUNCTION=eql_v2.ore_64_8_v2_eq,
  LEFTARG=eql_v2.ore_64_8_v2,
  RIGHTARG=eql_v2.ore_64_8_v2,
  NEGATOR = <>,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);



CREATE OPERATOR <> (
  FUNCTION=eql_v2.ore_64_8_v2_neq,
  LEFTARG=eql_v2.ore_64_8_v2,
  RIGHTARG=eql_v2.ore_64_8_v2,
  NEGATOR = =,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


CREATE OPERATOR > (
  FUNCTION=eql_v2.ore_64_8_v2_gt,
  LEFTARG=eql_v2.ore_64_8_v2,
  RIGHTARG=eql_v2.ore_64_8_v2,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);



CREATE OPERATOR < (
  FUNCTION=eql_v2.ore_64_8_v2_lt,
  LEFTARG=eql_v2.ore_64_8_v2,
  RIGHTARG=eql_v2.ore_64_8_v2,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



CREATE OPERATOR <= (
  FUNCTION=eql_v2.ore_64_8_v2_lte,
  LEFTARG=eql_v2.ore_64_8_v2,
  RIGHTARG=eql_v2.ore_64_8_v2,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);



CREATE OPERATOR >= (
  FUNCTION=eql_v2.ore_64_8_v2_gte,
  LEFTARG=eql_v2.ore_64_8_v2,
  RIGHTARG=eql_v2.ore_64_8_v2,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);
