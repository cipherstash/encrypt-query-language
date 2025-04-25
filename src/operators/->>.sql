-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql


DROP OPERATOR IF EXISTS ->> (eql_v1_encrypted, text);
DROP FUNCTION IF EXISTS eql_v1."->>"(e eql_v1_encrypted, selector text);

CREATE FUNCTION eql_v1."->>"(e eql_v1_encrypted, selector text)
  RETURNS text
IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    found eql_v1_encrypted;
	BEGIN

    found = eql_v1."->"(e, selector);

    RETURN eql_v1.ciphertext(found);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->> (
  FUNCTION=eql_v1."->>",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=text
);


