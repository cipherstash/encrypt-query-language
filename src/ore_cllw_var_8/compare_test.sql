\set ON_ERROR_STOP on

DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN

    -- {"hello": "world{N}"}
    -- $.hello: d90b97b5207d30fe867ca816ed0fe4a7
    a := eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(1), 'd90b97b5207d30fe867ca816ed0fe4a7');
    b := eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(2), 'd90b97b5207d30fe867ca816ed0fe4a7');
    c := eql_v2.jsonb_path_query(create_encrypted_ste_vec_json(3), 'd90b97b5207d30fe867ca816ed0fe4a7');

    ASSERT eql_v2.compare_ore_cllw_var_8(a, a) = 0;
    ASSERT eql_v2.compare_ore_cllw_var_8(a, b) = -1;
    ASSERT eql_v2.compare_ore_cllw_var_8(a, c) = -1;

    ASSERT eql_v2.compare_ore_cllw_var_8(b, b) = 0;
    ASSERT eql_v2.compare_ore_cllw_var_8(b, a) = 1;
    ASSERT eql_v2.compare_ore_cllw_var_8(b, c) = -1;

    ASSERT eql_v2.compare_ore_cllw_var_8(c, c) = 0;
    ASSERT eql_v2.compare_ore_cllw_var_8(c, b) = 1;
    ASSERT eql_v2.compare_ore_cllw_var_8(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;

