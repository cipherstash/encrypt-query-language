-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql


DROP OPERATOR IF EXISTS @> (eql_v1_encrypted, eql_v1_encrypted);
DROP FUNCTION IF EXISTS eql_v1."@>"(e eql_v1_encrypted, b eql_v1_encrypted);

--
-- Returns the element that
--
CREATE FUNCTION eql_v1."@>"(a eql_v1_encrypted, b eql_v1_encrypted)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
AS $$
  DECLARE
    selector text;
    term text;
  BEGIN
    selector := b.data->>'s';
    term := b.data->>'t';

    IF selector IS NULL THEN
      RETURN false;
    END IF;

    IF term IS NULL THEN
      RETURN false;
    END IF;

    RETURN (
        SELECT exists (
            SELECT elem::eql_v1_encrypted
                FROM jsonb_array_elements(a.data->'j') AS elem
                WHERE elem->>'s' = selector AND
                      elem->>'t' = term
                LIMIT 1
        )
    );

  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR @>(
  FUNCTION=eql_v1."@>",
  LEFTARG=eql_v1_encrypted,
  RIGHTARG=eql_v1_encrypted
);




-- -- Determine if a contains b (ignoring ciphertext values)
-- DROP FUNCTION IF EXISTS eql_v1.ste_vec_logical_contains(a eql_v1.ste_vec_index, b eql_v1.ste_vec_index);

-- CREATE FUNCTION eql_v1.ste_vec_logical_contains(a eql_v1.ste_vec_index, b eql_v1.ste_vec_index)
-- RETURNS boolean AS $$
-- DECLARE
--     result boolean;
--     intermediate_result boolean;
-- BEGIN
--     result := true;
--     IF array_length(b.entries, 1) IS NULL THEN
--         RETURN result;
--     END IF;
--     FOR i IN 1..array_length(b.entries, 1) LOOP
--         intermediate_result := eql_v1.ste_vec_entry_array_contains_entry(a.entries, b.entries[i]);
--         result := result AND intermediate_result;
--     END LOOP;
--     RETURN result;
-- END;
-- $$ LANGUAGE plpgsql;

-- -- Determine if a contains b (ignoring ciphertext values)
-- DROP FUNCTION IF EXISTS eql_v1.ste_vec_entry_array_contains_entry(a eql_v1.ste_vec_entry[], b eql_v1.ste_vec_entry);

-- CREATE FUNCTION eql_v1.ste_vec_entry_array_contains_entry(a eql_v1.ste_vec_entry[], b eql_v1.ste_vec_entry)
-- RETURNS boolean AS $$
-- DECLARE
--     result boolean;
--     intermediate_result boolean;
-- BEGIN
--     IF array_length(a, 1) IS NULL THEN
--         RETURN false;
--     END IF;

--     result := false;
--     FOR i IN 1..array_length(a, 1) LOOP
--         intermediate_result := a[i].tokenized_selector = b.tokenized_selector AND a[i].term = b.term;
--         result := result OR intermediate_result;
--     END LOOP;
--     RETURN result;
-- END;
-- $$ LANGUAGE plpgsql;