-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ste_vec/functions.sql


DROP OPERATOR IF EXISTS <@ (eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1."<@"(e eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1."<@"(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS boolean AS $$
  -- Contains with reversed arguments
  SELECT eql_v1.ste_vec_contains(b, a)
$$ LANGUAGE SQL;

CREATE OPERATOR <@(
  FUNCTION=eql_v1."<@",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted
);
