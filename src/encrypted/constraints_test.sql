\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();

DO $$
  BEGIN
    -- insert without constraint works
    INSERT INTO encrypted(e) VALUES ('{}'::jsonb::eql_v2_encrypted);

    -- delete the data
    PERFORM create_table_with_encrypted();

    -- add constraint
    PERFORM eql_v2.add_encrypted_constraint('encrypted', 'e');

    PERFORM assert_exception(
        'Constraint catches invalid eql_v2_encrypted',
        'INSERT INTO encrypted (e) VALUES (''{}''::jsonb::eql_v2_encrypted)');

  END;
$$ LANGUAGE plpgsql;


DO $$
  BEGIN
    -- reset the table
    PERFORM create_table_with_encrypted();

    -- add constraint
    PERFORM eql_v2.add_encrypted_constraint('encrypted', 'e');

    PERFORM assert_exception(
        'Constraint catches invalid eql_v2_encrypted',
        'INSERT INTO encrypted (e) VALUES (''{}''::jsonb::eql_v2_encrypted)');

    PERFORM eql_v2.remove_encrypted_constraint('encrypted', 'e');

    PERFORM assert_result(
        'Insert invalid data without constraint',
        'INSERT INTO encrypted (e) VALUES (''{}''::jsonb::eql_v2_encrypted) RETURNING id');

  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- Adding search config adds the constraint
--
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

DO $$
  BEGIN
    -- reset the table
    PERFORM create_table_with_encrypted();

    PERFORM eql_v2.add_search_config('encrypted', 'e', 'match');

    PERFORM assert_exception(
        'Constraint catches invalid eql_v2_encrypted',
        'INSERT INTO encrypted (e) VALUES (''{}''::jsonb::eql_v2_encrypted)');

    -- add constraint without error
    PERFORM eql_v2.add_encrypted_constraint('encrypted', 'e');

    PERFORM eql_v2.remove_encrypted_constraint('encrypted', 'e');

    PERFORM assert_result(
        'Insert invalid data without constraint',
        'INSERT INTO encrypted (e) VALUES (''{}''::jsonb::eql_v2_encrypted) RETURNING id');

  END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------
-- Adding column adds the constraint
--
-- -----------------------------------------------
TRUNCATE TABLE eql_v2_configuration;

DO $$
  BEGIN
    -- reset the table
    PERFORM create_table_with_encrypted();

    PERFORM eql_v2.add_column('encrypted', 'e');

    PERFORM assert_exception(
        'Constraint catches invalid eql_v2_encrypted',
        'INSERT INTO encrypted (e) VALUES (''{}''::jsonb::eql_v2_encrypted)');

    -- add constraint without error
    PERFORM eql_v2.add_encrypted_constraint('encrypted', 'e');

    PERFORM eql_v2.remove_encrypted_constraint('encrypted', 'e');

    PERFORM assert_result(
        'Insert invalid data without constraint',
        'INSERT INTO encrypted (e) VALUES (''{}''::jsonb::eql_v2_encrypted) RETURNING id');

  END;
$$ LANGUAGE plpgsql;


-- EQL version is enforced
DO $$
  DECLARE
    e eql_v2_encrypted;
  BEGIN

    -- reset data
    PERFORM create_table_with_encrypted();

      -- remove the version field
    e := create_encrypted_json(1)::jsonb-'v';

    PERFORM assert_exception(
        'Insert with missing version fails',
        format('INSERT INTO encrypted (e) VALUES (%s::jsonb::eql_v2_encrypted) RETURNING id', e));

    -- set version to 1
    e := create_encrypted_json(1)::jsonb || '{"v": 1}';

    PERFORM assert_exception(
        'Insert with invalid version fails',
        format('INSERT INTO encrypted (e) VALUES (%s::jsonb::eql_v2_encrypted) RETURNING id', e));

    -- set version to 1
    e := create_encrypted_json(1);

    PERFORM assert_result(
        'Insert with valid version is ok',
        format('INSERT INTO encrypted (e) VALUES (%L) RETURNING id', e));


  END;
$$ LANGUAGE plpgsql;

