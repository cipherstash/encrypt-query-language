\set ON_ERROR_STOP on


-- Create a table with a plaintext column
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name_encrypted cs_encrypted_v1,
    PRIMARY KEY(id)
);

TRUNCATE TABLE users;

INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "ct",
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    },
    "m": [1, 2, 3],
    "u": "unique-text",
    "o": ["a"]
  }'::jsonb
);



-- MATCH @> OPERATORS
DO $$
  BEGIN
    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_match_v1(name_encrypted) @> cs_match_v1('{"m":[1,2]}')));

    -- cs_encrypted_v1 = jsonb
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted @> '{"m":[1,2]}'::jsonb));

    -- cs_encrypted_v1 = text
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted @> ARRAY[1,2]::smallint[]));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted @> ARRAY[1,2]::cs_match_index_v1));

    -- cs_encrypted_v1 = cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted @> '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2]
        }'::cs_encrypted_v1));

  END;
$$ LANGUAGE plpgsql;



-- MATCH <@ OPERATORS
DO $$
  BEGIN
    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_match_v1('{"m":[1,2]}') <@ cs_match_v1(name_encrypted)));

    -- cs_encrypted_v1 = jsonb
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{"m":[1,2]}'::jsonb <@ name_encrypted));

    -- cs_encrypted_v1 = text
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE ARRAY[1,2]::smallint[] <@ name_encrypted));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE ARRAY[1,2]::cs_match_index_v1 <@ name_encrypted));

    -- cs_encrypted_v1 = cs_encrypted_v1
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2]
        }'::cs_encrypted_v1 <@ name_encrypted));

  END;
$$ LANGUAGE plpgsql;


