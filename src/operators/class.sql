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


-- DROP ORERATOR CLASS & FAMILY BEFORE FUNCTION
-- DROP OPERATOR CLASS IF EXISTS eql_v1.encrypted_operator USING btree;
-- DROP OPERATOR FAMILY IF EXISTS eql_v1.encrypted_operator USING btree;

-- DROP FUNCTION IF EXISTS eql_v1.compare(a eql_v1_encrypted, b eql_v1_encrypted);

--
-- Comparison function for eql_v1_encrypted
-- Extracts ORE indexes and uses the appropriate ore compare function
--
CREATE FUNCTION eql_v1.compare(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_ore eql_v1.ore_64_8_v1;
    b_ore eql_v1.ore_64_8_v1;
  BEGIN

    a_ore := eql_v1.ore_64_8_v1(a);
    b_ore := eql_v1.ore_64_8_v1(b);

    RETURN eql_v1.compare_ore_array(a_ore.terms, b_ore.terms);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR FAMILY eql_v1.encrypted_operator USING btree;

CREATE OPERATOR CLASS eql_v1.encrypted_operator DEFAULT FOR TYPE eql_v1_encrypted USING btree FAMILY eql_v1.encrypted_operator AS
  OPERATOR 1 <,
  OPERATOR 2 <=,
  OPERATOR 3 =,
  OPERATOR 4 >=,
  OPERATOR 5 >,
  FUNCTION 1 eql_v1.compare(a eql_v1_encrypted, b eql_v1_encrypted);

