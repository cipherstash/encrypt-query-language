-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql
-- REQUIRE: src/operators/<.sql
-- REQUIRE: src/operators/<=.sql
-- REQUIRE: src/operators/=.sql
-- REQUIRE: src/operators/>=.sql
-- REQUIRE: src/operators/>.sql


CREATE FUNCTION eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_ore eql_v2.ore_block_u64_8_256;
    b_ore eql_v2.ore_block_u64_8_256;
  BEGIN

    a_ore := eql_v2.ore_block_u64_8_256(a);
    b_ore := eql_v2.ore_block_u64_8_256(b);

    RETURN eql_v2.compare_ore_array(a_ore.terms, b_ore.terms);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR FAMILY eql_v2.encrypted_operator USING btree;

CREATE OPERATOR CLASS eql_v2.encrypted_operator DEFAULT FOR TYPE eql_v2_encrypted USING btree FAMILY eql_v2.encrypted_operator AS
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted);

