
-- REQUIRE: src/encrypted/types.sql


--
-- Convert jsonb to eql_v1.encrypted
--
-- DROP FUNCTION IF EXISTS eql_v1.to_encrypted(data jsonb);

CREATE FUNCTION eql_v1.to_encrypted(data jsonb)
RETURNS public.eql_v1_encrypted AS $$
BEGIN
    RETURN ROW(data)::public.eql_v1_encrypted;
END;
$$ LANGUAGE plpgsql;

--
-- Cast jsonb to eql_v1.encrypted
--
-- DROP CAST IF EXISTS (jsonb AS public.eql_v1_encrypted);

CREATE CAST (jsonb AS public.eql_v1_encrypted)
	WITH FUNCTION eql_v1.to_encrypted(jsonb) AS IMPLICIT;


--
-- Convert text to eql_v1.encrypted
--
-- DROP FUNCTION IF EXISTS eql_v1.to_encrypted(data text);

CREATE FUNCTION eql_v1.to_encrypted(data text)
RETURNS public.eql_v1_encrypted AS $$
BEGIN
    RETURN ROW(data::jsonb)::public.eql_v1_encrypted;
END;
$$ LANGUAGE plpgsql;

--
-- Cast text to eql_v1.encrypted
--
-- DROP CAST IF EXISTS (text AS public.eql_v1_encrypted);

CREATE CAST (text AS public.eql_v1_encrypted)
	WITH FUNCTION eql_v1.to_encrypted(text) AS IMPLICIT;



--
-- Convert eql_v1.encrypted to jsonb
--
-- DROP FUNCTION IF EXISTS eql_v1.to_jsonb(e public.eql_v1_encrypted);

CREATE FUNCTION eql_v1.to_jsonb(e public.eql_v1_encrypted)
RETURNS jsonb AS $$
BEGIN
    RETURN e.data;
END;
$$ LANGUAGE plpgsql;

--
-- Cast eql_v1.encrypted to jsonb
--
-- DROP CAST IF EXISTS (public.eql_v1_encrypted AS jsonb);

CREATE CAST (public.eql_v1_encrypted AS jsonb)
	WITH FUNCTION eql_v1.to_jsonb(public.eql_v1_encrypted) AS ASSIGNMENT;



