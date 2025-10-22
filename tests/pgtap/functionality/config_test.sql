-- Test EQL configuration management
-- Tests add_search_config, remove_search_config, modify_search_config functions

BEGIN;

-- Plan: count of tests to run
SELECT plan(12);

-- Helper function for checking if search config exists
CREATE OR REPLACE FUNCTION _search_config_exists(table_name text, column_name text, index_name text, state text DEFAULT 'pending')
RETURNS boolean
LANGUAGE sql STRICT PARALLEL SAFE
BEGIN ATOMIC
  SELECT EXISTS (SELECT id FROM eql_v2_configuration c
    WHERE c.state = _search_config_exists.state AND
    c.data #> array['tables', table_name, column_name, 'indexes'] ? index_name);
END;

-- Clean configuration table
SELECT lives_ok(
    'TRUNCATE TABLE eql_v2_configuration',
    'Should truncate configuration table'
);

-- Test 1: Add search config creates pending configuration
DO $$
BEGIN
    PERFORM eql_v2.add_search_config('users', 'name', 'match', migrating => true);

    PERFORM ok(
        _search_config_exists('users', 'name', 'match'),
        'add_search_config creates pending configuration with match index'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 2: Add search config with cast
DO $$
BEGIN
    PERFORM eql_v2.add_search_config('users', 'age', 'unique', 'int', migrating => true);

    PERFORM ok(
        _search_config_exists('users', 'age', 'unique'),
        'add_search_config creates configuration with cast'
    );

    PERFORM ok(
        EXISTS (SELECT id FROM eql_v2_configuration c
                WHERE c.state = 'pending' AND
                c.data #> array['tables', 'users', 'age'] ? 'cast_as'),
        'Configuration includes cast_as field'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 3: Remove search config
DO $$
BEGIN
    PERFORM eql_v2.remove_search_config('users', 'name', 'match', migrating => true);

    PERFORM ok(
        NOT _search_config_exists('users', 'name', 'match'),
        'remove_search_config removes match index'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 4: Configuration preserved after removing all indexes
DO $$
BEGIN
    PERFORM eql_v2.remove_search_config('users', 'age', 'unique', migrating => true);

    PERFORM ok(
        EXISTS (SELECT FROM eql_v2_configuration c WHERE c.state = 'pending'),
        'Pending configuration still exists after removing all indexes'
    );

    PERFORM ok(
        (SELECT data #> array['tables', 'users', 'age', 'indexes'] = '{}'
         FROM eql_v2_configuration c WHERE c.state = 'pending'),
        'Indexes object is empty after removal'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 5: Modify search config
SELECT lives_ok(
    'TRUNCATE TABLE eql_v2_configuration',
    'Should truncate configuration table for modify test'
);

DO $$
BEGIN
    PERFORM eql_v2.add_search_config('users', 'email', 'match', migrating => true);
    PERFORM eql_v2.modify_search_config('users', 'email', 'match', 'text', '{"option": "value"}'::jsonb, migrating => true);

    PERFORM ok(
        EXISTS (SELECT id FROM eql_v2_configuration c
                WHERE c.state = 'pending' AND
                c.data #> array['tables', 'users', 'email', 'indexes', 'match'] ? 'option'),
        'modify_search_config adds options to index configuration'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 6: Add column to existing table
SELECT lives_ok(
    'TRUNCATE TABLE eql_v2_configuration',
    'Should truncate configuration table for column test'
);

DO $$
BEGIN
    PERFORM create_table_with_encrypted();

    PERFORM eql_v2.add_column('encrypted', 'e', migrating => true);

    PERFORM cmp_ok(
        (SELECT count(*) FROM eql_v2_configuration c WHERE c.state = 'pending'),
        '=',
        1::bigint,
        'add_column creates pending configuration'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 7: Remove column
DO $$
BEGIN
    PERFORM eql_v2.remove_column('encrypted', 'e', migrating => true);

    PERFORM ok(
        (SELECT data #> array['tables'] = '{}'
         FROM eql_v2_configuration c WHERE c.state = 'pending'),
        'remove_column empties tables configuration'
    );

    PERFORM drop_table_with_encrypted();
END;
$$ LANGUAGE plpgsql;

-- Cleanup helper function
DROP FUNCTION _search_config_exists(text, text, text, text);

SELECT finish();
ROLLBACK;
