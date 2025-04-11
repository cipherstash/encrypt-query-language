\set ON_ERROR_STOP on


-- Create a table with a plaintext column
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name_encrypted eql_v1_encrypted,
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



-- MATCH ~~ OPERATORS
DO $$
  BEGIN
    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE eql_v1.match(name_encrypted) ~~ eql_v1.match('{"m":[1,2]}')));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE eql_v1.match(name_encrypted) ~~* eql_v1.match('{"m":[1,2]}')));

    -- eql_v1_encrypted = jsonb
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~ '{"m":[1,2]}'::jsonb));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~* '{"m":[1,2]}'::jsonb));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{"m":[1,2,3,6,7,8,9]}'::jsonb ~~ name_encrypted));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{"m":[1,2,3,6,7,8,9]}'::jsonb ~~* name_encrypted));

    -- eql_v1_encrypted = text
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~ ARRAY[1,2]::smallint[]));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~* ARRAY[1,2]::smallint[]));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~ ARRAY[1,2]::eql_v1.match_index));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~* ARRAY[1,2]::eql_v1.match_index));

    -- eql_v1_encrypted = eql_v1_encrypted
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~ '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2]
        }'::eql_v1_encrypted));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ~~* '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2]
        }'::eql_v1_encrypted));

      ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2, 3, 4, 5]
        }'::eql_v1_encrypted ~~ name_encrypted));


      ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2, 3, 4, 5]
        }'::eql_v1_encrypted ~~* name_encrypted));

  END;
$$ LANGUAGE plpgsql;




-- MATCH ~~ OPERATORS
DO $$
  BEGIN
    -- SANITY CHECK
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE eql_v1.match(name_encrypted) LIKE eql_v1.match('{"m":[1,2]}')));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE eql_v1.match(name_encrypted) ILIKE eql_v1.match('{"m":[1,2]}')));

    -- eql_v1_encrypted = jsonb
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted LIKE '{"m":[1,2]}'::jsonb));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ILIKE '{"m":[1,2]}'::jsonb));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{"m":[1,2,3,6,7,8,9]}'::jsonb LIKE name_encrypted));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{"m":[1,2,3,6,7,8,9]}'::jsonb ILIKE name_encrypted));

    -- eql_v1_encrypted = text
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted LIKE ARRAY[1,2]::smallint[]));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ILIKE ARRAY[1,2]::smallint[]));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted LIKE ARRAY[1,2]::eql_v1.match_index));
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ILIKE ARRAY[1,2]::eql_v1.match_index));

    -- eql_v1_encrypted = eql_v1_encrypted
    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted LIKE '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2]
        }'::eql_v1_encrypted));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE name_encrypted ILIKE '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2]
        }'::eql_v1_encrypted));

      ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2, 3, 4, 5]
        }'::eql_v1_encrypted LIKE name_encrypted));


      ASSERT (SELECT EXISTS (SELECT id FROM users WHERE '{
            "v": 1,
            "k": "ct",
            "c": "ciphertext",
            "i": {
            "t": "users",
            "c": "name"
            },
            "m": [1, 2, 3, 4, 5]
        }'::eql_v1_encrypted ILIKE name_encrypted));

  END;
$$ LANGUAGE plpgsql;