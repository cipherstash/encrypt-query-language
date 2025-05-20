-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ste_vec/functions.sql



CREATE FUNCTION eql_v1."@>"(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  SELECT eql_v1.ste_vec_contains(a, b)
$$ LANGUAGE SQL;

CREATE OPERATOR @>(
  FUNCTION=eql_v1."@>",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted
);
