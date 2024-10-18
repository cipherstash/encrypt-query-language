\set ON_ERROR_STOP on

-- -----------------------------------------------
--
-- Alter table from config
--
-- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;

-- Create a table with a plaintext column
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    PRIMARY KEY(id)
);

INSERT INTO cs_configuration_v1 (data) VALUES (
  '{
    "v": 1,
    "tables": {
      "users": {
        "name": {
          "cast_as": "text",
          "indexes": {
            "ore": {}
          }
        }
      }
    }
  }'::jsonb
);

DO $$
  BEGIN

    -- the column is pending encryptindexing
    ASSERT (SELECT EXISTS (SELECT * FROM cs_select_pending_columns_v1() AS c WHERE c.column_name = 'name'));

    -- the target column does not exist
    ASSERT (SELECT EXISTS (SELECT * FROM cs_select_target_columns_v1() AS c WHERE c.target_column IS NULL));

    -- Add the vtha_encrypted column to the table
    PERFORM cs_create_encrypted_columns_v1();

    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_encrypted'));

    -- rename columns
    PERFORM cs_rename_encrypted_columns_v1();

    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_plaintext'));
    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name' and s.domain_name = 'cs_encrypted_v1'));
    ASSERT (SELECT NOT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_encrypted'));
  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- Create multiple columns
--
-- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;

-- Create a table with multiple plaintext columns
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    email INT,
    PRIMARY KEY(id)
);

INSERT INTO cs_configuration_v1 (data) VALUES (
  '{
    "v": 1,
    "tables": {
      "users": {
        "name": {
          "cast_as": "text",
          "indexes": {
            "ore": {},
            "unique": {}
          }
        },
        "email": {
          "cast_as": "text",
          "indexes": {
            "match": {}
          }
        }
      }
    }
  }'::jsonb
);

DO $$
  BEGIN

    -- the column is pending encryptindexing
    ASSERT (SELECT EXISTS (SELECT * FROM cs_select_pending_columns_v1() AS c WHERE c.column_name = 'name'));

    -- the target column does not exisgt
    ASSERT (SELECT EXISTS (SELECT * FROM cs_select_target_columns_v1() AS c WHERE c.target_column IS NULL));

    -- create column
    PERFORM cs_create_encrypted_columns_v1();

    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_encrypted'));
    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'email_encrypted'));
  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- Start encryptindexing
-- The schema is validated first.
-- The pending config should now be encrypting
-- -----------------------------------------------
DROP TABLE IF EXISTS users;
TRUNCATE TABLE cs_configuration_v1;

-- SELECT cs_add_index_v1('users', 'name', 'match');
-- SELECT cs_encrypt_v1();

-- SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending';

DO $$
  BEGIN
    PERFORM cs_add_index_v1('users', 'name', 'match');

    BEGIN
      PERFORM cs_encrypt_v1();
      ASSERT false; -- skipped by exception
    EXCEPTION
      WHEN OTHERS THEN
        ASSERT true;
    END;
    ASSERT (SELECT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'encrypting'));

  END;
$$ LANGUAGE plpgsql;



-- -----------------------------------------------
-- With existing active config
-- and an updated schema
-- Start encryptindexing
-- The active config is unchanged
-- The pending config should now be encrypting
-- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;

-- create an active configuration
INSERT INTO cs_configuration_v1 (state, data) VALUES (
  'active',
  '{
    "v": 1,
    "tables": {
      "users": {
        "name": {
          "cast_as": "text",
          "indexes": {
            "unique": {}
          }
        }
      }
    }
  }'::jsonb
);

-- Create a table with multiple plaintext columns
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    name_encrypted cs_encrypted_v1,
    PRIMARY KEY(id)
);


-- An encrypting config should exist
DO $$
  BEGIN
    PERFORM cs_add_index_v1('users', 'name', 'match');
    PERFORM cs_encrypt_v1();

    ASSERT (SELECT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'active'));
    ASSERT (SELECT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'encrypting'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));
  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- With existing active config
-- Activate encrypting config
-- The active config is now inactive
-- The encrypting config should now be active
-- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;

-- create an active configuration
INSERT INTO cs_configuration_v1 (state, data) VALUES (
  'active',
  '{
    "v": 1,
    "tables": {
      "users": {
        "name": {
          "cast_as": "text",
          "indexes": {
            "unique": {}
          }
        }
      }
    }
  }'::jsonb
);


-- Create a table with multiple plaintext columns
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    name_encrypted cs_encrypted_v1,
    PRIMARY KEY(id)
);

-- An encrypting config should exist
DO $$
  BEGIN
    PERFORM cs_add_index_v1('users', 'name', 'match');

    PERFORM cs_encrypt_v1(); -- need to encrypt first
    PERFORM cs_activate_v1();

    ASSERT (SELECT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'active'));
    ASSERT (SELECT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'inactive'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'encrypting'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));

  END;
$$ LANGUAGE plpgsql;
