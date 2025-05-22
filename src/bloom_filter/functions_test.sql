\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
        'Extract match index term from encrypted',
        'SELECT eql_v2.bloom_filter(''{"bf": []}''::jsonb)');

    PERFORM assert_exception(
        'Missing match index term in encrypted raises exception',
        'SELECT eql_v2.bloom_filter(''{}''::jsonb)');

  END;
$$ LANGUAGE plpgsql;
