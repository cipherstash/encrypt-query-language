-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql

--! @brief JSONB field accessor operator for encrypted values (->)
--!
--! Implements the -> operator to access fields/elements from encrypted JSONB data.
--! Returns encrypted value matching the provided selector without decryption.
--!
--! Encrypted JSON is represented as an array of eql_v2_encrypted values in the ste_vec format.
--! Each element has a selector, ciphertext, and index terms:
--!     {"sv": [{"c": "", "s": "", "b3": ""}]}
--!
--! Provides three overloads:
--! - (eql_v2_encrypted, text) - Field name selector
--! - (eql_v2_encrypted, eql_v2_encrypted) - Encrypted selector
--! - (eql_v2_encrypted, integer) - Array index selector (0-based)
--!
--! @note Operator resolution: Assignment casts are considered (PostgreSQL standard behavior).
--! To use text selector, parameter may need explicit cast to text.
--!
--! @see eql_v2.ste_vec
--! @see eql_v2.selector
--! @see eql_v2."->>"

--! @brief -> operator with text selector
--! @param e eql_v2_encrypted Encrypted JSONB data
--! @param selector text Field name to extract
--! @return eql_v2_encrypted Encrypted value at selector
--! @example
--! SELECT encrypted_json -> 'field_name' FROM table;
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector text)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    meta jsonb;
    sv eql_v2_encrypted[];
    found jsonb;
	BEGIN

    IF e IS NULL THEN
      RETURN NULL;
    END IF;

    -- Column identifier and version
    meta := eql_v2.meta_data(e);

    sv := eql_v2.ste_vec(e);

    FOR idx IN 1..array_length(sv, 1) LOOP
      if eql_v2.selector(sv[idx]) = selector THEN
        found := sv[idx];
      END IF;
    END LOOP;

    RETURN (meta || found)::eql_v2_encrypted;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=text
);

---------------------------------------------------

--! @brief -> operator with encrypted selector
--! @param e eql_v2_encrypted Encrypted JSONB data
--! @param selector eql_v2_encrypted Encrypted field selector
--! @return eql_v2_encrypted Encrypted value at selector
--! @see eql_v2."->"(eql_v2_encrypted, text)
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector eql_v2_encrypted)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
	BEGIN
    RETURN eql_v2."->"(e, eql_v2.selector(selector));
  END;
$$ LANGUAGE plpgsql;



CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);


---------------------------------------------------

--! @brief -> operator with integer array index
--! @param e eql_v2_encrypted Encrypted array data
--! @param selector integer Array index (0-based, JSONB convention)
--! @return eql_v2_encrypted Encrypted value at array index
--! @note Array index is 0-based (JSONB standard) despite PostgreSQL arrays being 1-based
--! @example
--! SELECT encrypted_array -> 0 FROM table;
--! @see eql_v2.is_ste_vec_array
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector integer)
  RETURNS eql_v2_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v2_encrypted[];
    found eql_v2_encrypted;
	BEGIN
    IF NOT eql_v2.is_ste_vec_array(e) THEN
      RETURN NULL;
    END IF;

    sv := eql_v2.ste_vec(e);

    -- PostgreSQL arrays are 1-based
    -- JSONB arrays are 0-based and so the selector is 0-based
    FOR idx IN 1..array_length(sv, 1) LOOP
      if (idx-1) = selector THEN
        found := sv[idx];
      END IF;
    END LOOP;

    RETURN found;
  END;
$$ LANGUAGE plpgsql;





CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=integer
);

