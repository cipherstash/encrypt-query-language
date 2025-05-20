-- REQUIRE: src/schema.sql
-- REQUIRE: src/crypto.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql



CREATE FUNCTION eql_v1.ore_64_8_v1_eq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = 0
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v1.ore_64_8_v1_neq(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) <> 0
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v1.ore_64_8_v1_lt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = -1
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v1.ore_64_8_v1_lte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) != 1
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v1.ore_64_8_v1_gt(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) = 1
$$ LANGUAGE SQL;



CREATE FUNCTION eql_v1.ore_64_8_v1_gte(a eql_v1.ore_64_8_v1, b eql_v1.ore_64_8_v1)
RETURNS boolean AS $$
  SELECT eql_v1.compare_ore_64_8_v1(a, b) != -1
$$ LANGUAGE SQL;



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


CREATE OPERATOR > (
  FUNCTION=eql_v1.ore_64_8_v1_gt,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <,
  NEGATOR = <=,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);



CREATE OPERATOR < (
  FUNCTION=eql_v1.ore_64_8_v1_lt,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >,
  NEGATOR = >=,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);



CREATE OPERATOR <= (
  FUNCTION=eql_v1.ore_64_8_v1_lte,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = >=,
  NEGATOR = >,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);



CREATE OPERATOR >= (
  FUNCTION=eql_v1.ore_64_8_v1_gte,
  LEFTARG=eql_v1.ore_64_8_v1,
  RIGHTARG=eql_v1.ore_64_8_v1,
  COMMUTATOR = <=,
  NEGATOR = <,
  RESTRICT = scalarlesel,
  JOIN = scalarlejoinsel
);
