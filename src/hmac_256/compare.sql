-- REQUIRE: src/schema.sql
-- REQUIRE: src/hmac_256/types.sql
-- REQUIRE: src/hmac_256/functions.sql


CREATE FUNCTION eql_v2.compare_hmac_256(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_term eql_v2.hmac_256;
    b_term eql_v2.hmac_256;
  BEGIN

    IF a IS NULL AND b IS NULL THEN
      RETURN 0;
    END IF;

    IF a IS NULL THEN
      RETURN -1;
    END IF;

    IF b IS NULL THEN
      RETURN 1;
    END IF;

    IF eql_v2.has_hmac_256(a) THEN
      a_term = eql_v2.hmac_256(a);
    END IF;

    IF eql_v2.has_hmac_256(b) THEN
      b_term = eql_v2.hmac_256(b);
    END IF;

    IF a_term IS NULL AND b_term IS NULL THEN
      RETURN 0;
    END IF;

    IF a_term IS NULL THEN
      RETURN -1;
    END IF;

    IF b_term IS NULL THEN
      RETURN 1;
    END IF;

    -- Using the underlying text type comparison
    IF a_term = b_term THEN
      RETURN 0;
    END IF;

    IF a_term < b_term THEN
      RETURN -1;
    END IF;

    IF a_term > b_term THEN
      RETURN 1;
    END IF;

  END;
$$ LANGUAGE plpgsql;
