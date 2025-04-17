\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
      'eql_v1.version()',
      'SELECT true WHERE eql_v1.version() = ''DEV''');
  END;
$$ LANGUAGE plpgsql;
