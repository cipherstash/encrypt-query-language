-- AUTOMATICALLY GENERATED FILE
-- REQUIRE: src/schema.sql



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
