
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql



DROP OPERATOR IF EXISTS -> (eql_v1_encrypted, text);
DROP FUNCTION IF EXISTS eql_v1."->"(e eql_v1_encrypted, selector text);

--
-- Returns
--
CREATE FUNCTION eql_v1."->"(e eql_v1_encrypted, selector text)
  RETURNS eql_v1_encrypted
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  -- DECLARE
  --   j jsonb;
  --   found: text;
  --   ignored: text;
	BEGIN

    -- j := e->'j';
    -- PERFORM eql_v1.log(j);

    -- FOR i IN 1..jsonb_array_length(j, 1) LOOP
    -- --     -- The ELSE part is to help ensure constant time operation.
    -- --     -- The result is thrown away.
    --     IF j[i]->'s' = selector THEN
    --       found := j[i]->'c';
    --     ELSE
    --       ignored := j[i]->'c';
    --     END IF;
    -- END LOOP;

    -- IF found IS NOT NULL THEN
    --   RETURN found;
    -- ELSE
    --   RETURN NULL;
    -- END IF;

    RETURN (
      SELECT elem::eql_v1_encrypted
        FROM jsonb_array_elements(e.data->'j') AS elem
        WHERE elem->>'s' = selector
        LIMIT 1
    );

  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ->(
  FUNCTION=eql_v1."->",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=text
);


--   ste_vec_index := eql_v1.ste_vec(col);

--   IF ste_vec_index IS NULL THEN
--     RETURN NULL;
--   END IF;

--   target_selector := selector->>'svs';

--   FOR i IN 1..array_length(ste_vec_index.entries, 1) LOOP
--       -- The ELSE part is to help ensure constant time operation.
--       -- The result is thrown away.
--       IF ste_vec_index.entries[i].tokenized_selector = target_selector THEN
--         found := ste_vec_index.entries[i].ciphertext;
--       ELSE
--         ignored := ste_vec_index.entries[i].ciphertext;
--       END IF;
--   END LOOP;

--   IF found IS NOT NULL THEN
--     RETURN jsonb_build_object(
--       'k', 'ct',
--       'c', found,
--       'o', NULL,
--       'm', NULL,
--       'u', NULL,
--       'i', col->'i',
--       'v', 1
--     );
--   ELSE
--     RETURN NULL;
--   END IF;
