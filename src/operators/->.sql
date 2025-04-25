
-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql


--
-- The -> operator returns an encrypted matching the selector
-- Encyprted JSON is represented as an array of `eql_v1_encrypted`.
-- Each `eql_v1_encrypted` value has a selector, ciphertext, and an index term of
--   - blake3
--   - ore_cllw_u64_8
--   - ore_cllw_var_8
--
--     {
--       "sv": [ {"c": "", "s": "", "b": "" } ]
--     }
--
DROP OPERATOR IF EXISTS -> (eql_v1_encrypted, text);

DROP FUNCTION IF EXISTS eql_v1."->"(e eql_v1_encrypted, selector text);

CREATE FUNCTION eql_v1."->"(e eql_v1_encrypted, selector text)
  RETURNS eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    sv eql_v1_encrypted[];
    found eql_v1_encrypted;
	BEGIN

    IF e IS NULL THEN
      RETURN NULL;
    END IF;

    sv := eql_v1.ste_vec(e);

    FOR idx IN 1..array_length(sv, 1) LOOP
      if eql_v1.selector(sv[idx]) = selector THEN
        found := sv[idx];
      END IF;
    END LOOP;

    RETURN found;
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->(
  FUNCTION=eql_v1."->",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=text
);

