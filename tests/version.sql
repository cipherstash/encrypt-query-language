\set ON_ERROR_STOP on

DO $$
  BEGIN
    ASSERT (SELECT true WHERE cs_eql_version() = 'DEV');

  END;
$$ LANGUAGE plpgsql;
