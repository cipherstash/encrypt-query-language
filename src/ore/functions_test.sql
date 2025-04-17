\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
        'Extract ore index term from encrypted',
        'SELECT eql_v1.ore_64_8_v1(''{"o": []}''::jsonb)');

    PERFORM assert_exception(
        'Missing ore index term in encrypted raises exception',
        'SELECT eql_v1.ore_64_8_v1(''{}''::jsonb)');

  END;
$$ LANGUAGE plpgsql;