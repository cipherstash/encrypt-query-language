-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql

--
-- Compare two eql_v2_encrypted values as literal jsonb values
-- Used as a fallback when no suitable search term is available
--
CREATE FUNCTION eql_v2.compare_literal(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    a_data jsonb;
    b_data jsonb;
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

    a_data := a.data;
    b_data := b.data;

    IF a_data < b_data THEN
      RETURN -1;
    END IF;

    IF a_data > b_data THEN
      RETURN 1;
    END IF;

    RETURN 0;
  END;
$$ LANGUAGE plpgsql;
