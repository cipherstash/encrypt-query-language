-- AUTOMATICALLY GENERATED FILE
-- REQUIRE: src/schema.sql


-- Constant time comparison of 2 bytea values
DROP FUNCTION IF EXISTS eql_v1.bytea_eq(a bytea, b bytea);

CREATE FUNCTION eql_v1.bytea_eq(a bytea, b bytea) RETURNS boolean AS $$
DECLARE
    result boolean;
    differing bytea;
BEGIN

    -- Check if the bytea values are the same length
    IF LENGTH(a) != LENGTH(b) THEN
        RETURN false;
    END IF;

    -- Compare each byte in the bytea values
    result := true;
    FOR i IN 1..LENGTH(a) LOOP
        IF SUBSTRING(a FROM i FOR 1) != SUBSTRING(b FROM i FOR 1) THEN
            result := result AND false;
        END IF;
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS eql_v1.jsonb_array_to_bytea_array(val jsonb);

-- Casts a jsonb array of hex-encoded strings to an array of bytea.
CREATE FUNCTION eql_v1.jsonb_array_to_bytea_array(val jsonb)
RETURNS bytea[] AS $$
DECLARE
  terms_arr bytea[];
BEGIN
  IF jsonb_typeof(val) = 'null' THEN
    RETURN NULL;
  END IF;

  SELECT array_agg(decode(value::text, 'hex')::bytea)
    INTO terms_arr
  FROM jsonb_array_elements_text(val) AS value;

  RETURN terms_arr;
END;
$$ LANGUAGE plpgsql;



--
-- Convenience function to log a message
--
DROP FUNCTION IF EXISTS eql_v1.log(text);
CREATE FUNCTION eql_v1.log(s text)
    RETURNS void
AS $$
  BEGIN
    RAISE NOTICE '[LOG] %', s;
END;
$$ LANGUAGE plpgsql;


--
-- Convenience function to describe a test
--
DROP FUNCTION IF EXISTS eql_v1.log(text, text);
CREATE FUNCTION eql_v1.log(ctx text, s text)
    RETURNS void
AS $$
  BEGIN
    RAISE NOTICE '[LOG] % %', ctx, s;
END;
$$ LANGUAGE plpgsql;
