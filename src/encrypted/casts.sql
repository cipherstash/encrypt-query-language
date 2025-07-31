
-- REQUIRE: src/encrypted/types.sql


--
-- Convert jsonb to eql_v2.encrypted
--

CREATE FUNCTION eql_v2.to_encrypted(data jsonb)
RETURNS public.eql_v2_encrypted
IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
    IF data IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN ROW(data)::public.eql_v2_encrypted;
END;
$$ LANGUAGE plpgsql;


--
-- Cast jsonb to eql_v2.encrypted
--

CREATE CAST (jsonb AS public.eql_v2_encrypted)
	WITH FUNCTION eql_v2.to_encrypted(jsonb) AS ASSIGNMENT;


--
-- Convert text to eql_v2.encrypted
--

CREATE FUNCTION eql_v2.to_encrypted(data text)
RETURNS public.eql_v2_encrypted
    IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
    IF data IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN eql_v2.to_encrypted(data::jsonb);
END;
$$ LANGUAGE plpgsql;


--
-- Cast text to eql_v2.encrypted
--

CREATE CAST (text AS public.eql_v2_encrypted)
	WITH FUNCTION eql_v2.to_encrypted(text) AS ASSIGNMENT;



--
-- Convert eql_v2.encrypted to jsonb
--

CREATE FUNCTION eql_v2.to_jsonb(e public.eql_v2_encrypted)
RETURNS jsonb AS $$
BEGIN
    IF e IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN e.data;
END;
$$ LANGUAGE plpgsql;

--
-- Cast eql_v2.encrypted to jsonb
--

CREATE CAST (public.eql_v2_encrypted AS jsonb)
	WITH FUNCTION eql_v2.to_jsonb(public.eql_v2_encrypted) AS ASSIGNMENT;



