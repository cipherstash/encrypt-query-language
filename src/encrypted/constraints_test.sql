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





