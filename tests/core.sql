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
    "m": [1, 1],
    "u": "text",
    "o": ["a"]
  }'::jsonb
);

DO $$
  BEGIN

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_ciphertext_v1(name_encrypted) = 'ciphertext'));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_match_v1(name_encrypted) = '{1,1}'));

    ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_unique_v1(name_encrypted) = 'text'));

    -- ORE PAYLOAD ABOUT TO CHANGE
    -- ASSERT (SELECT EXISTS (SELECT id FROM users WHERE cs_ore_64_8_v1(name_encrypted) = '{a}'));

  END;
$$ LANGUAGE plpgsql;


TRUNCATE TABLE users;

INSERT INTO users DEFAULT VALUES;

SELECT id FROM users;

DO $$
  BEGIN
    ASSERT (SELECT EXISTS (SELECT id FROM users));
  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
---
-- cs_encrypted_v1 type
-- Validate configuration schema
-- Try and insert many invalid configurations
-- None should exist
--
-- -----------------------------------------------
TRUNCATE TABLE users;

\set ON_ERROR_STOP off
\set ON_ERROR_ROLLBACK on

DO $$
  BEGIN
    RAISE NOTICE 'cs_encrypted_v1 constraint tests: 10 errors expected here';
  END;
$$ LANGUAGE plpgsql;


-- no version
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "ct",
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);

-- no ident details
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "ct",
    "c": "ciphertext"
  }'::jsonb
);

-- no kind
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);



-- bad kind
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "vtha",
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);

-- pt
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "pt",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);

--pt with ciphertext
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "pt",
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);

-- ct without ciphertext
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "ct",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);


-- ct with plaintext
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "k": "ct",
    "p": "plaintext",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);


-- ciphertext without ct
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    }
  }'::jsonb
);

-- ciphertext with invalid q
INSERT INTO users (name_encrypted) VALUES (
  '{
    "v": 1,
    "c": "ciphertext",
    "i": {
      "t": "users",
      "c": "name"
    },
    "q": "invalid"
  }'::jsonb
);

-- Nothing should be in the DB
DO $$
  BEGIN
    ASSERT (SELECT NOT EXISTS (SELECT * FROM users c));
  END;
$$ LANGUAGE plpgsql;


\set ON_ERROR_STOP on
\set ON_ERROR_ROLLBACK off




