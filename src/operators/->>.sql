-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql



DROP OPERATOR IF EXISTS ->> (eql_v1_encrypted, text);
DROP FUNCTION IF EXISTS eql_v1."->>"(e eql_v1_encrypted, selector text);

CREATE FUNCTION eql_v1."->>"(e eql_v1_encrypted, selector text)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    j jsonb;
    found text;
    ignored text;
	BEGIN
    -- j := e.data->'j';
    -- -- PERFORM eql_v1.log(j::text);
    -- PERFORM eql_v1.log('jsonb_array_length(j)');
    -- PERFORM eql_v1.log(jsonb_array_length(j)::text);

    -- FOR i IN 0..jsonb_array_length(j) LOOP
    --     -- The ELSE part is to help ensure constant time operation.
    --     -- The result is thrown away.
    --     IF j[i]->>'s' = selector THEN
    --       found := eql_v1.ciphertext(j->i);
    --     ELSE
    --       ignored := eql_v1.ciphertext(j->i);
    --     END IF;
    -- END LOOP;

    -- IF found IS NOT NULL THEN
    --   RETURN found;
    -- ELSE
    --   RETURN NULL;
    -- END IF;
    RETURN (
      SELECT eql_v1.ciphertext(elem)
        FROM jsonb_array_elements(e.data->'j') AS elem
        WHERE elem->>'s' = selector
        LIMIT 1
    );
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->> (
  FUNCTION=eql_v1."->>",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=text
);


