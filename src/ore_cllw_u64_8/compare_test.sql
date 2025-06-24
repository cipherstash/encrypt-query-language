\set ON_ERROR_STOP on

DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN

    -- {"number": {N}}
    -- $.number: 3dba004f4d7823446e7cb71f6681b344
    a := eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), '3dba004f4d7823446e7cb71f6681b344');
    b := eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(5), '3dba004f4d7823446e7cb71f6681b344');
    c := eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(10), '3dba004f4d7823446e7cb71f6681b344');

    ASSERT eql_v2.compare_ore_cllw_u64_8(a, a) = 0;
    ASSERT eql_v2.compare_ore_cllw_u64_8(a, b) = -1;
    ASSERT eql_v2.compare_ore_cllw_u64_8(a, c) = -1;

    ASSERT eql_v2.compare_ore_cllw_u64_8(b, b) = 0;
    ASSERT eql_v2.compare_ore_cllw_u64_8(b, a) = 1;
    ASSERT eql_v2.compare_ore_cllw_u64_8(b, c) = -1;

    ASSERT eql_v2.compare_ore_cllw_u64_8(c, c) = 0;
    ASSERT eql_v2.compare_ore_cllw_u64_8(c, b) = 1;
    ASSERT eql_v2.compare_ore_cllw_u64_8(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;

