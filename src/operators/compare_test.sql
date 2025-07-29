\set ON_ERROR_STOP on


-- Compare compare_ore_cllw_var_8
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

    ASSERT eql_v2.compare(a, a) = 0;
    ASSERT eql_v2.compare(a, b) = -1;
    ASSERT eql_v2.compare(a, c) = -1;

    ASSERT eql_v2.compare(b, b) = 0;
    ASSERT eql_v2.compare(b, a) = 1;
    ASSERT eql_v2.compare(b, c) = -1;

    ASSERT eql_v2.compare(c, c) = 0;
    ASSERT eql_v2.compare(c, b) = 1;
    ASSERT eql_v2.compare(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;


-- Compare compare_ore_cllw_var_8
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

    ASSERT eql_v2.compare(a, a) = 0;
    ASSERT eql_v2.compare(a, b) = -1;
    ASSERT eql_v2.compare(a, c) = -1;

    ASSERT eql_v2.compare(b, b) = 0;
    ASSERT eql_v2.compare(b, a) = 1;
    ASSERT eql_v2.compare(b, c) = -1;

    ASSERT eql_v2.compare(c, c) = 0;
    ASSERT eql_v2.compare(c, b) = 1;
    ASSERT eql_v2.compare(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;


-- Compare ore_block_u64_8_256
DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN

    a := create_encrypted_ore_json(1);
    b := create_encrypted_ore_json(21);
    c := create_encrypted_ore_json(42);

    ASSERT eql_v2.compare(a, a) = 0;
    ASSERT eql_v2.compare(a, b) = -1;
    ASSERT eql_v2.compare(a, c) = -1;

    ASSERT eql_v2.compare(b, b) = 0;
    ASSERT eql_v2.compare(b, a) = 1;
    ASSERT eql_v2.compare(b, c) = -1;

    ASSERT eql_v2.compare(c, c) = 0;
    ASSERT eql_v2.compare(c, b) = 1;
    ASSERT eql_v2.compare(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;


-- Compare blake3
DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN
    a := create_encrypted_json(1, 'b3');
    b := create_encrypted_json(2, 'b3');
    c := create_encrypted_json(3, 'b3');

    ASSERT eql_v2.compare(a, a) = 0;
    ASSERT eql_v2.compare(a, b) = -1;
    ASSERT eql_v2.compare(a, c) = -1;

    ASSERT eql_v2.compare(b, b) = 0;
    ASSERT eql_v2.compare(b, a) = 1;
    ASSERT eql_v2.compare(b, c) = -1;

    ASSERT eql_v2.compare(c, c) = 0;
    ASSERT eql_v2.compare(c, b) = 1;
    ASSERT eql_v2.compare(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;


-- Compare hmac_256
DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN
    a := create_encrypted_json(1, 'hm');
    b := create_encrypted_json(2, 'hm');
    c := create_encrypted_json(3, 'hm');

    ASSERT eql_v2.compare(a, a) = 0;
    ASSERT eql_v2.compare(a, b) = -1;
    ASSERT eql_v2.compare(a, c) = -1;

    ASSERT eql_v2.compare(b, b) = 0;
    ASSERT eql_v2.compare(b, a) = 1;
    ASSERT eql_v2.compare(b, c) = -1;

    ASSERT eql_v2.compare(c, c) = 0;
    ASSERT eql_v2.compare(c, b) = 1;
    ASSERT eql_v2.compare(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;



-- Compare with no index terms
-- This is a fallback to literal comparison of the encrypted data
DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN
    a := '{"a": 1}'::jsonb::eql_v2_encrypted;
    b := '{"b": 2}'::jsonb::eql_v2_encrypted;
    c := '{"c": 3}'::jsonb::eql_v2_encrypted;

    ASSERT eql_v2.compare(a, a) = 0;
    ASSERT eql_v2.compare(a, b) = -1;
    ASSERT eql_v2.compare(a, c) = -1;

    ASSERT eql_v2.compare(b, b) = 0;
    ASSERT eql_v2.compare(b, a) = 1;
    ASSERT eql_v2.compare(b, c) = -1;

    ASSERT eql_v2.compare(c, c) = 0;
    ASSERT eql_v2.compare(c, b) = 1;
    ASSERT eql_v2.compare(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;


--
-- Compare hmac_256 when record has a `null` index of higher precedence
-- TEST COVERAGE FOR BUG FIX
--
-- ORE Block indexes `ob` are used in compare before hmac_256 indexes.
-- If the index term is null `{"ob": null}` it should not be used
-- Comparing two `null` values is evaluated as equality and hilarity ensues
--

DO $$
  DECLARE
   a eql_v2_encrypted;
   b eql_v2_encrypted;
   c eql_v2_encrypted;
  BEGIN
    -- generate with `hm` index
    a := create_encrypted_json(1, 'hm');
    -- append `null` index
    a := '{"ob": null}'::jsonb || a::jsonb;

    b := create_encrypted_json(2, 'hm');
    b := '{"ob": null}'::jsonb || b::jsonb;

    c := create_encrypted_json(3, 'hm');
    c := '{"ob": null}'::jsonb || c::jsonb;

    ASSERT eql_v2.compare(a, a) = 0;
    ASSERT eql_v2.compare(a, b) = -1;
    ASSERT eql_v2.compare(a, c) = -1;

    ASSERT eql_v2.compare(b, b) = 0;
    ASSERT eql_v2.compare(b, a) = 1;
    ASSERT eql_v2.compare(b, c) = -1;

    ASSERT eql_v2.compare(c, c) = 0;
    ASSERT eql_v2.compare(c, b) = 1;
    ASSERT eql_v2.compare(c, a) = 1;
  END;
$$ LANGUAGE plpgsql;
