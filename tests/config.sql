\set ON_ERROR_STOP on




--
-- Helper function for assertions
--
DROP FUNCTION IF EXISTS _index_exists(text, text, text);
CREATE FUNCTION _index_exists(table_name text, column_name text, index_name text, state text DEFAULT 'pending')
  RETURNS boolean
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT EXISTS (SELECT id FROM cs_configuration_v1 c
    WHERE c.state = state AND
    c.data #> array['tables', table_name, column_name, 'indexes'] ? index_name);
END;


-- -----------------------------------------------
-- Add and remove multiple indexes
--
-- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;


DO $$
  BEGIN

    -- Add indexes
    PERFORM cs_add_index_v1('users', 'name', 'match');
    ASSERT (SELECT _index_exists('users', 'name', 'match'));

    -- Add index with cast
    PERFORM cs_add_index_v1('users', 'name', 'unique', 'int');
    ASSERT (SELECT _index_exists('users', 'name', 'unique'));

    ASSERT (SELECT EXISTS (SELECT id FROM cs_configuration_v1 c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name'] ? 'cast_as'));

    -- Match index removed
    PERFORM cs_remove_index_v1('users', 'name', 'match');
    ASSERT NOT (SELECT _index_exists('users', 'name', 'match'));

    -- All indexes removed, delete the emtpty pending config
    PERFORM cs_remove_index_v1('users', 'name', 'unique');
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));

  END;
$$ LANGUAGE plpgsql;



-- -----------------------------------------------
-- Add and remove multiple indexes from multiple tables
--
-- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;


DO $$
  BEGIN

    -- Add indexes
    PERFORM cs_add_index_v1('users', 'name', 'match');
    ASSERT (SELECT _index_exists('users', 'name', 'match'));

    ASSERT (SELECT EXISTS (SELECT id FROM cs_configuration_v1 c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name', 'indexes'] ? 'match'));

    -- Add index with cast
    PERFORM cs_add_index_v1('blah', 'vtha', 'unique', 'int');
    ASSERT (SELECT _index_exists('blah', 'vtha', 'unique'));

    ASSERT (SELECT EXISTS (SELECT id FROM cs_configuration_v1 c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name', 'indexes'] ? 'match'));


    ASSERT (SELECT EXISTS (SELECT id FROM cs_configuration_v1 c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'blah', 'vtha', 'indexes'] ? 'unique'));


    -- Match index removed
    PERFORM cs_remove_index_v1('users', 'name', 'match');
    ASSERT NOT (SELECT _index_exists('users', 'name', 'match'));

    -- Match index removed
    PERFORM cs_remove_index_v1('blah', 'vtha', 'unique');
    ASSERT NOT (SELECT _index_exists('users', 'vtha', 'unique'));

    -- All indexes removed, delete the emtpty pending config
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));

  END;
$$ LANGUAGE plpgsql;

SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending';


-- -----------------------------------------------
-- Add & modify index
-- Pending configuration created and contains the path `user/name.match.option`
-- -----------------------------------------------
-- TRUNCATE TABLE cs_configuration_v1;


DO $$
  BEGIN
    PERFORM cs_add_index_v1('users', 'name', 'match');
    ASSERT (SELECT _index_exists('users', 'name', 'match'));

    -- Pending configuration contains the path `user/name.match.option`
    PERFORM cs_modify_index_v1('users', 'name', 'match', 'int', '{"option": "value"}'::jsonb);
    ASSERT (SELECT _index_exists('users', 'name', 'match'));

    ASSERT (SELECT EXISTS (SELECT id FROM cs_configuration_v1 c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name', 'indexes', 'match'] ? 'option'));

    ASSERT (SELECT EXISTS (SELECT id FROM cs_configuration_v1 c
            WHERE c.state = 'pending' AND
            c.data #> array['tables', 'users', 'name'] ? 'cast_as'));

    -- All indexes removed, delete the emtpty pending config
    PERFORM cs_remove_index_v1('users', 'name', 'match');
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));
  END;
$$ LANGUAGE plpgsql;


-- -- -----------------------------------------------
-- -- With existing active config
-- -- Adding an index creates a new pending configuration
-- -- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;

-- create an active configuration
INSERT INTO cs_configuration_v1 (state, data) VALUES (
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
    ASSERT (SELECT _index_exists('users', 'blah', 'match', 'active'));

    PERFORM cs_add_index_v1('users', 'name', 'match');

    -- index added to name
    ASSERT (SELECT _index_exists('users', 'name', 'match' ));

    -- pending is a copy of the active config
    -- and the active index still exists
    ASSERT (SELECT _index_exists('users', 'blah', 'match'));

  END;
$$ LANGUAGE plpgsql;


-- -- -----------------------------------------------
-- -- Add and remove column
-- --
-- -- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;
DO $$
  BEGIN
    -- Create pending configuration
    PERFORM cs_add_column_v1('user', 'name');
    ASSERT (SELECT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));

    PERFORM cs_remove_column_v1('user', 'name');

    -- Config now empty and removed
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));
  END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------
---
-- cs_configuration_v1 tyoe
-- Validate configuration schema
-- Try and insert many invalid configurations
-- None should exist
--
-- -----------------------------------------------
TRUNCATE TABLE cs_configuration_v1;

\set ON_ERROR_STOP off
\set ON_ERROR_ROLLBACK on

DO $$
  BEGIN
    RAISE NOTICE 'cs_configuration_v1 constraint tests: 4 errors expected here';
  END;
$$ LANGUAGE plpgsql;
--
-- No schema version
INSERT INTO cs_configuration_v1 (data) VALUES (
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
INSERT INTO cs_configuration_v1 (data) VALUES (
  '{
    "v": 1,
    "tables": {}
  }'::jsonb
);


--
-- invalid cast
INSERT INTO cs_configuration_v1 (data) VALUES (
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
INSERT INTO cs_configuration_v1 (data) VALUES (
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
    ASSERT (SELECT NOT EXISTS (SELECT FROM cs_configuration_v1 c WHERE c.state = 'pending'));
  END;
$$ LANGUAGE plpgsql;


\set ON_ERROR_STOP on
\set ON_ERROR_ROLLBACK off




