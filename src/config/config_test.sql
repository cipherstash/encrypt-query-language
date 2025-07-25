\set ON_ERROR_STOP on


--
-- Helper function for assertions
--
DROP FUNCTION IF EXISTS _search_config_exists(text, text, text, text);
CREATE FUNCTION _search_config_exists(table_name text, column_name text, index_name text, state text DEFAULT 'pending')
  RETURNS boolean
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT EXISTS (SELECT id FROM eql_v2_configuration c
    WHERE c.state = state AND
    c.data #> array['tables', table_name, column_name, 'indexes'] ? index_name);
END;


-- -----------------------------------------------
-- Add and remove multiple indexes
--
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

DO $$
  BEGIN

    -- Add indexes
    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);
    ASSERT (SELECT _search_config_exists('users', 'name', 'match'));

    -- Add index with cast
    PERFORM eql_v2.add_search_config('users', 'name', 'unique', 'int', migrating => true);
    ASSERT (SELECT _search_config_exists('users', 'name', 'unique'));

    ASSERT (SELECT EXISTS (SELECT id FROM eql_v2_configuration c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name'] ? 'cast_as'));

    -- Match index removed
    PERFORM eql_v2.remove_search_config('users', 'name', 'match', migrating => true);
    ASSERT NOT (SELECT _search_config_exists('users', 'name', 'match'));

    -- All indexes removed, but column config preserved
    PERFORM eql_v2.remove_search_config('users', 'name', 'unique', migrating => true);
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'));
    ASSERT (SELECT data #> array['tables', 'users', 'name', 'indexes'] = '{}' FROM eql_v2_configuration c WHERE c.state = 'pending');

  END;
$$ LANGUAGE plpgsql;



-- -----------------------------------------------
-- Add and remove multiple indexes from multiple tables
--
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;


DO $$
  BEGIN

    -- Add indexes
    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);
    ASSERT (SELECT _search_config_exists('users', 'name', 'match'));

    ASSERT (SELECT EXISTS (SELECT id FROM eql_v2_configuration c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name', 'indexes'] ? 'match'));

    -- Add index with cast
    PERFORM eql_v2.add_search_config('blah', 'vtha', 'unique', 'int', migrating => true);
    ASSERT (SELECT _search_config_exists('blah', 'vtha', 'unique'));

    ASSERT (SELECT EXISTS (SELECT id FROM eql_v2_configuration c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name', 'indexes'] ? 'match'));


    ASSERT (SELECT EXISTS (SELECT id FROM eql_v2_configuration c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'blah', 'vtha', 'indexes'] ? 'unique'));


    -- Match index removed
    PERFORM eql_v2.remove_search_config('users', 'name', 'match', migrating => true);
    ASSERT NOT (SELECT _search_config_exists('users', 'name', 'match'));

    -- Match index removed
    PERFORM eql_v2.remove_search_config('blah', 'vtha', 'unique', migrating => true);
    ASSERT NOT (SELECT _search_config_exists('users', 'vtha', 'unique'));

    -- All indexes removed, but column config preserved  
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'));
    ASSERT (SELECT data #> array['tables', 'blah', 'vtha', 'indexes'] = '{}' FROM eql_v2_configuration c WHERE c.state = 'pending');

  END;
$$ LANGUAGE plpgsql;

-- SELECT FROM eql_v2_configuration c WHERE c.state = 'pending';


-- -----------------------------------------------
-- Add & modify index
-- Pending configuration created and contains the path `user/name.match.option`
-- -----------------------------------------------
-- TRUNCATE TABLE eql_v2_configuration;


DO $$
  BEGIN
    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);
    ASSERT (SELECT _search_config_exists('users', 'name', 'match'));

    -- Pending configuration contains the path `user/name.match.option`
    PERFORM eql_v2.modify_search_config('users', 'name', 'match', 'int', '{"option": "value"}'::jsonb, migrating => true);
    ASSERT (SELECT _search_config_exists('users', 'name', 'match'));

    ASSERT (SELECT EXISTS (SELECT id FROM eql_v2_configuration c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name', 'indexes', 'match'] ? 'option'));

    ASSERT (SELECT EXISTS (SELECT id FROM eql_v2_configuration c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name'] ? 'cast_as'));

    -- All indexes removed, but column config preserved
    PERFORM eql_v2.remove_search_config('users', 'name', 'match', migrating => true);
    ASSERT (SELECT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'));
    ASSERT (SELECT data #> array['tables', 'users', 'name', 'indexes'] = '{}' FROM eql_v2_configuration c WHERE c.state = 'pending');
  END;
$$ LANGUAGE plpgsql;


-- -- -----------------------------------------------
-- -- With existing active config
-- -- Adding an index creates a new pending configuration
-- -- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

-- create an active configuration
INSERT INTO eql_v2_configuration (state, data) VALUES (
  'active',
  '{
    "v": 1,
    "tables": {
      "users": {
        "blah": {
           "cast_as": "text",
           "indexes": {
              "match": {}
           }
        },
        "vtha": {
           "cast_as": "text",
           "indexes": {}
        }
      }
    }
  }'::jsonb
);

-- An encrypting config should exist
DO $$
  BEGIN
    ASSERT (SELECT _search_config_exists('users', 'blah', 'match', 'active'));

    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);

    -- index added to name
    ASSERT (SELECT _search_config_exists('users', 'name', 'match' ));

    -- pending is a copy of the active config
    -- and the active index still exists
    ASSERT (SELECT _search_config_exists('users', 'blah', 'match'));

  END;
$$ LANGUAGE plpgsql;


-- -- -----------------------------------------------
-- -- Add and remove column
-- --
-- -- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;
DO $$
  BEGIN

    PERFORM assert_exception(
        'Cannot add index to column that does not exist',
        'SELECT eql_v2.add_column(''user'', ''name'')');

    PERFORM assert_no_result(
        'No configuration was created',
        'SELECT * FROM eql_v2_configuration');
  END;
$$ LANGUAGE plpgsql;



-- -- -----------------------------------------------
-- -- Add and remove column
-- --
-- -- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;
DO $$
  BEGIN
    -- reset the table
    PERFORM create_table_with_encrypted();

    PERFORM eql_v2.add_column('encrypted', 'e', migrating => true);

    PERFORM assert_count(
        'Pending configuration was created',
        'SELECT * FROM eql_v2_configuration c WHERE c.state = ''pending''',
        1);


    PERFORM eql_v2.remove_column('encrypted', 'e', migrating => true);

    PERFORM assert_count(
        'Pending configuration exists but is empty',
        'SELECT * FROM eql_v2_configuration c WHERE c.state = ''pending''',
        1);
    
    -- Verify the config is empty
    ASSERT (SELECT data #> array['tables'] = '{}' FROM eql_v2_configuration c WHERE c.state = 'pending');

  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
---
-- eql_v2_configuration tyoe
-- Validate configuration schema
-- Try and insert many invalid configurations
-- None should exist
--
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

\set ON_ERROR_STOP off
\set ON_ERROR_ROLLBACK on

DO $$
  BEGIN
    RAISE NOTICE '------------------------------------------------------';
    RAISE NOTICE 'eql_v2_configuration constraint tests: 4 errors follow';
  END;
$$ LANGUAGE plpgsql;
--
-- No schema version
INSERT INTO eql_v2_configuration (data) VALUES (
  '{
    "tables": {
      "users": {
        "blah": {
          "cast_as": "text",
          "indexes": {}
        }
      }
    }
  }'::jsonb
);

--
-- Empty tables
INSERT INTO eql_v2_configuration (data) VALUES (
  '{
    "v": 1,
    "tables": {}
  }'::jsonb
);


--
-- invalid cast
INSERT INTO eql_v2_configuration (data) VALUES (
  '{
    "v": 1,
    "tables": {
      "users": {
        "blah": {
          "cast_as": "regex"
        }
      }
    }
  }'::jsonb
);

--
-- invalid index
INSERT INTO eql_v2_configuration (data) VALUES (
  '{
    "v": 1,
    "tables": {
      "users": {
        "blah": {
          "cast_as": "text",
          "indexes": {
            "blah": {}
          }
        }
      }
    }
  }'::jsonb
);


-- Pending configuration should not be created;
DO $$
  BEGIN
    ASSERT (SELECT NOT EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'));
  END;
$$ LANGUAGE plpgsql;

DO $$
  BEGIN
    RAISE NOTICE 'eql_v2_configuration constraint tests: OK';
    RAISE NOTICE '------------------------------------------------------';
  END;
$$ LANGUAGE plpgsql;


\set ON_ERROR_STOP on
\set ON_ERROR_ROLLBACK off




