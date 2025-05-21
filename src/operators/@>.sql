-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ste_vec/functions.sql



CREATE FUNCTION eql_v2."@>"(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean AS $$
  SELECT eql_v2.ste_vec_contains(a, b)
$$ LANGUAGE SQL;

CREATE OPERATOR @>(
  FUNCTION=eql_v2."@>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);
