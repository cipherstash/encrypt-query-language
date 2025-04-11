-- Aggregate functions for ORE
DROP FUNCTION IF EXISTS eql_v1.min_encrypted;
CREATE FUNCTION eql_v1.min_encrypted(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS eql_v1_encrypted
LANGUAGE plpgsql
STRICT
AS $$
  BEGIN
    IF eql_v1.ore_64_8_v1(a) < eql_v1.ore_64_8_v1(b) THEN
      RETURN  a;
    ELSE
      RETURN b;
    END IF;
  END;
$$;

CREATE AGGREGATE eql_v1.min(eql_v1_encrypted)
(
  sfunc = eql_v1.min_encrypted,
  stype = eql_v1_encrypted
);

DROP FUNCTION IF EXISTS eql_v1.max_encrypted;
CREATE FUNCTION eql_v1.max_encrypted(a eql_v1_encrypted, b eql_v1_encrypted)
RETURNS eql_v1_encrypted
LANGUAGE plpgsql
STRICT
AS $$
  BEGIN
    IF eql_v1.ore_64_8_v1(a) > eql_v1.ore_64_8_v1(b) THEN
      RETURN  a;
    ELSE
      RETURN b;
    END IF;
  END;
$$;

CREATE AGGREGATE eql_v1.max(eql_v1_encrypted)
(
  sfunc = eql_v1.max_encrypted,
  stype = eql_v1_encrypted
);
