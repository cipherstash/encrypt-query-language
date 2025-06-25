\set ON_ERROR_STOP on

DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN
    a := create_encrypted_json(1, 'b3');
    b := create_encrypted_json(2, 'b3');
    c := create_encrypted_json(3, 'b3');

    ASSERT eql_v2.compare_blake3(a, a) = 0;
    ASSERT eql_v2.compare_blake3(a, b) = -1;
    ASSERT eql_v2.compare_blake3(a, c) = -1;

    ASSERT eql_v2.compare_blake3(b, b) = 0;
    ASSERT eql_v2.compare_blake3(b, a) = 1;
    ASSERT eql_v2.compare_blake3(b, c) = -1;

    ASSERT eql_v2.compare_blake3(c, c) = 0;
    ASSERT eql_v2.compare_blake3(c, b) = 1;
    ASSERT eql_v2.compare_blake3(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;

