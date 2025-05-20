
-- REQUIRE: src/encrypted/types.sql


--
-- Convert jsonb to eql_v1.encrypted
--

CREATE FUNCTION eql_v1.to_encrypted(data jsonb)
RETURNS public.eql_v1_encrypted AS $$
BEGIN
    RETURN ROW(data)::public.eql_v1_encrypted;
END;
$$ LANGUAGE plpgsql;

--
-- Cast jsonb to eql_v1.encrypted
--

CREATE CAST (jsonb AS public.eql_v1_encrypted)
	WITH FUNCTION eql_v1.to_encrypted(jsonb) AS ASSIGNMENT;


--
-- Convert text to eql_v1.encrypted
--

CREATE FUNCTION eql_v1.to_encrypted(data text)
RETURNS public.eql_v1_encrypted AS $$
BEGIN
    RETURN ROW(data::jsonb)::public.eql_v1_encrypted;
END;
$$ LANGUAGE plpgsql;

--
-- Cast text to eql_v1.encrypted
--

CREATE CAST (text AS public.eql_v1_encrypted)
	WITH FUNCTION eql_v1.to_encrypted(text) AS ASSIGNMENT;



--
-- Convert eql_v1.encrypted to jsonb
--

CREATE FUNCTION eql_v1.to_jsonb(e public.eql_v1_encrypted)
RETURNS jsonb AS $$
BEGIN
    RETURN e.data;
END;
$$ LANGUAGE plpgsql;

--
-- Cast eql_v1.encrypted to jsonb
--

CREATE CAST (public.eql_v1_encrypted AS jsonb)
	WITH FUNCTION eql_v1.to_jsonb(public.eql_v1_encrypted) AS ASSIGNMENT;



