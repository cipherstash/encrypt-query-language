\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
        'Extract match index term from encrypted',
        'SELECT eql_v1.match(''{"m": []}''::jsonb)');

    PERFORM assert_exception(
        'Missing match index term in encrypted raises exception',
        'SELECT eql_v1.match(''{}''::jsonb)');

  END;
$$ LANGUAGE plpgsql;
