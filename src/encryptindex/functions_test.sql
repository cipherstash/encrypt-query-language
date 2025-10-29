\set ON_ERROR_STOP on

-- -----------------------------------------------
--
-- Alter table from config
--
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

-- Create a table with a plaintext column
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    PRIMARY KEY(id)
);

INSERT INTO eql_v2_configuration (data) VALUES (
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
    ASSERT (SELECT EXISTS (SELECT * FROM eql_v2.select_pending_columns() AS c WHERE c.column_name = 'name'));

    -- the target column does not exist
    ASSERT (SELECT EXISTS (SELECT * FROM eql_v2.select_target_columns() AS c WHERE c.target_column IS NULL));

    -- Add the vtha_encrypted column to the table
    PERFORM eql_v2.create_encrypted_columns();

    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_encrypted'));

    -- -- rename columns
    PERFORM eql_v2.rename_encrypted_columns();

    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_plaintext'));
    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name' and s.udt_name = 'eql_v2_encrypted'));
    ASSERT (SELECT NOT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_encrypted'));
  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- Create multiple columns
--
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

-- Create a table with multiple plaintext columns
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    email INT,
    PRIMARY KEY(id)
);

INSERT INTO eql_v2_configuration (data) VALUES (
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
    ASSERT (SELECT EXISTS (SELECT * FROM eql_v2.select_pending_columns() AS c WHERE c.column_name = 'name'));

    -- the target column does not exisgt
    ASSERT (SELECT EXISTS (SELECT * FROM eql_v2.select_target_columns() AS c WHERE c.target_column IS NULL));

    -- create column
    PERFORM eql_v2.create_encrypted_columns();

    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'name_encrypted'));
    ASSERT (SELECT EXISTS (SELECT * FROM information_schema.columns s WHERE s.column_name = 'email_encrypted'));
  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- With existing active config
-- and an updated schema
-- Start encryptindexing
-- The active config is unchanged
-- The pending config should now be encrypting
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

-- create an active configuration
INSERT INTO eql_v2_configuration (state, data) VALUES (
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

-- Create a table with plaintext and encrypted columns
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    name_encrypted eql_v2_encrypted,
    PRIMARY KEY(id)
);


-- An encrypting config should exist
DO $$
  BEGIN
    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);
    PERFORM eql_v2.migrate_config();
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'active'));
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'encrypting'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'));
  END;
$$ LANGUAGE plpgsql;


-- Encrypting config without `migrating = true` is immediately active
DO $$
  BEGIN
    TRUNCATE TABLE eql_v2_configuration;
    PERFORM eql_v2.add_search_config('users', 'name', 'match');
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'active'));
  END;
$$ LANGUAGE plpgsql;


-- migrate_config() should raise an exception when no pending configuration exists
DO $$
  BEGIN
    TRUNCATE TABLE eql_v2_configuration;
    PERFORM eql_v2.add_search_config('users', 'name', 'match');

    PERFORM assert_exception(
        'eql_v2.migrate_config() should raise an exception when no pending configuration exists',
        'SELECT eql_v2.migrate_config()'
    );
  END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------
-- With existing active config and an updated schema using a raw JSONB column
-- Start encryptindexing
-- The active config is unchanged
-- The pending config should now be encrypting
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

-- create an active configuration
INSERT INTO eql_v2_configuration (state, data) VALUES (
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

-- Create a table with plaintext and jsonb column
DROP TABLE IF EXISTS users;
CREATE TABLE users
(
    id bigint GENERATED ALWAYS AS IDENTITY,
    name TEXT,
    name_encrypted eql_v2_encrypted,
    PRIMARY KEY(id)
);


-- An encrypting config should exist
DO $$
  BEGIN
    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);
    PERFORM eql_v2.migrate_config();

    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'active'));
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'encrypting'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'));
  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- With existing active config
-- Activate encrypting config
-- The active config is now inactive
-- The encrypting config should now be active
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

-- create an active configuration
INSERT INTO eql_v2_configuration (state, data) VALUES (
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
    name_encrypted eql_v2_encrypted,
    PRIMARY KEY(id)
);

-- An encrypting config should exist
DO $$
  BEGIN
    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);

    PERFORM eql_v2.migrate_config(); -- need to encrypt first
    PERFORM eql_v2.activate_config();

    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'active'));
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'inactive'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'encrypting'));
    ASSERT (SELECT NOT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'));

  END;
$$ LANGUAGE plpgsql;
