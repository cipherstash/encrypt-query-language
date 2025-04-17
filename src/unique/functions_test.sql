\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
        'Extract unique index term from encrypted',
        'SELECT eql_v1.unique(''{"u": "u"}''::jsonb)');

    PERFORM assert_exception(
        'Missing unique index term in encrypted raises exception',
        'SELECT eql_v1.unique(''{}''::jsonb)');

  END;
$$ LANGUAGE plpgsql;
