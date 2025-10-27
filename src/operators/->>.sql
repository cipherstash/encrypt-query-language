-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql

--! @brief JSONB field accessor operator alias (->>)
--!
--! Implements the ->> operator as an alias of -> for encrypted JSONB data. This mirrors
--! PostgreSQL semantics where ->> returns text via implicit casts. The underlying
--! implementation delegates to eql_v2."->" and allows PostgreSQL to coerce the result.
--!
--! Provides two overloads:
--! - (eql_v2_encrypted, text) - Field name selector
--! - (eql_v2_encrypted, eql_v2_encrypted) - Encrypted selector
--!
--! @see eql_v2."->"
--! @see eql_v2.selector

--! @brief ->> operator with text selector
--! @param e eql_v2_encrypted Encrypted JSONB data
--! @param selector text Field name to extract
--! @return text Encrypted value at selector, implicitly cast from eql_v2_encrypted
--! @example
--! SELECT encrypted_json ->> 'field_name' FROM table;
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

--! @brief ->> operator with encrypted selector
--! @param e eql_v2_encrypted Encrypted JSONB data
--! @param selector eql_v2_encrypted Encrypted field selector
--! @return text Encrypted value at selector, implicitly cast from eql_v2_encrypted
--! @see eql_v2."->>"(eql_v2_encrypted, text)
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
