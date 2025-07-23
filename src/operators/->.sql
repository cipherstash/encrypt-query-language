
-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql


--
-- The -> operator returns an encrypted matching the provided selector
--
-- Encyprted JSON is represented as an array of `eql_v2_encrypted`.
-- Each `eql_v2_encrypted` value has a selector, ciphertext, and an index term
--
--     {
--       "sv": [ {"c": "", "s": "", "b3": "" } ]
--     }
--
-- Note on oeprator resolution:
--   Assignment casts are considered for operator resolution (see PostgreSQL docs),
--   the system may pick the "more specific" one, which is the one with both arguments of the same type.
--
-- This means that to use the text operator, the parameter will need to be cast to text
--
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

