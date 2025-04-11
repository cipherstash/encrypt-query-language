\set ON_ERROR_STOP on

DO $$
  BEGIN
    ASSERT (SELECT true WHERE eql_v1.version() = 'DEV');

  END;
$$ LANGUAGE plpgsql;
