-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql

-- Aggregate functions for ORE
DROP AGGREGATE IF EXISTS eql_v1.min(eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.min(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.min(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS eql_v1_encrypted
STRICT
AS $$
  BEGIN
    PERFORM eql_v1.log('eql_v1.min');
    IF eql_v1.ore_64_8_v1(a) < eql_v1.ore_64_8_v1(b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
$$ LANGUAGE plpgsql;


CREATE AGGREGATE eql_v1.min(eql_v1_encrypted)
(
  sfunc = eql_v1.min,
  stype = eql_v1_encrypted
);

DROP AGGREGATE IF EXISTS eql_v1.max(eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1.max(a eql_v1_encrypted, b eql_v1_encrypted);

CREATE FUNCTION eql_v1.max(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS eql_v1_encrypted
STRICT
AS $$
  BEGIN
    PERFORM eql_v1.log('eql_v1.max');
    IF eql_v1.ore_64_8_v1(a) > eql_v1.ore_64_8_v1(b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
$$ LANGUAGE plpgsql;


CREATE AGGREGATE eql_v1.max(eql_v1_encrypted)
(
  sfunc = eql_v1.max,
  stype = eql_v1_encrypted
);
