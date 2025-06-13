\set ON_ERROR_STOP on

DO $$
  BEGIN
    PERFORM assert_result(
        'Extract hmac_256 index term from encrypted',
        'SELECT eql_v2.hmac_256(''{"hm": "u"}''::jsonb)');

    PERFORM assert_exception(
        'Missing hmac_256 index term in encrypted raises exception',
        'SELECT eql_v2.hmac_256(''{}''::jsonb)');

  END;
$$ LANGUAGE plpgsql;


DO $$
  DECLARE
   e eql_v2_encrypted;
  BEGIN
    e := create_encrypted_json(1, 'hm');

    ASSERT eql_v2.has_hmac_256(e);
  END;
$$ LANGUAGE plpgsql;

