-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore/types.sql
-- REQUIRE: src/ore/functions.sql

-- Aggregate functions for ORE

CREATE FUNCTION eql_v2.min(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS eql_v2_encrypted
STRICT
AS $$
  BEGIN
    PERFORM eql_v2.log('eql_v2.min');
    IF eql_v2.ore_64_8_v2(a) < eql_v2.ore_64_8_v2(b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
$$ LANGUAGE plpgsql;


CREATE AGGREGATE eql_v2.min(eql_v2_encrypted)
(
  sfunc = eql_v2.min,
  stype = eql_v2_encrypted
);


CREATE FUNCTION eql_v2.max(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS eql_v2_encrypted
STRICT
AS $$
  BEGIN
    PERFORM eql_v2.log('eql_v2.max');
    IF eql_v2.ore_64_8_v2(a) > eql_v2.ore_64_8_v2(b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END;
$$ LANGUAGE plpgsql;


CREATE AGGREGATE eql_v2.max(eql_v2_encrypted)
(
  sfunc = eql_v2.max,
  stype = eql_v2_encrypted
);
