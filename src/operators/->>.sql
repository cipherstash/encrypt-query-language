-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql



CREATE FUNCTION eql_v2."->>"(e eql_v2_encrypted, selector text)
  RETURNS text
IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    found eql_v2_encrypted;
	BEGIN
    -- found = eql_v2."->"(e, selector);
    -- RETURN eql_v2.ciphertext(found);
    RETURN eql_v2."->"(e, selector);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->> (
  FUNCTION=eql_v2."->>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=text
);



---------------------------------------------------


CREATE FUNCTION eql_v2."->>"(e eql_v2_encrypted, selector eql_v2_encrypted)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2."->>"(e, eql_v2.selector(selector));
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->> (
  FUNCTION=eql_v2."->>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);