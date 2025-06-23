\set ON_ERROR_STOP on

DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN
    a := create_encrypted_json(1, 'hm');
    b := create_encrypted_json(2, 'hm');
    c := create_encrypted_json(3, 'hm');

    ASSERT eql_v2.compare_hmac_256(a, a) = 0;
    ASSERT eql_v2.compare_hmac_256(a, b) = -1;
    ASSERT eql_v2.compare_hmac_256(a, c) = -1;

    ASSERT eql_v2.compare_hmac_256(b, b) = 0;
    ASSERT eql_v2.compare_hmac_256(b, a) = 1;
    ASSERT eql_v2.compare_hmac_256(b, c) = -1;

    ASSERT eql_v2.compare_hmac_256(c, c) = 0;
    ASSERT eql_v2.compare_hmac_256(c, b) = 1;
    ASSERT eql_v2.compare_hmac_256(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;

