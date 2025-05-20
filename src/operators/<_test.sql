\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- eql_v2_encrypted < eql_v2_encrypted with ore_cllw_u64_8 index
--
-- Test data is in form '{"hello": "{one | two | three}", "n": {10 | 20 | 30} }'
--
-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
-- --
DO $$
DECLARE
    sv eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

      -- This extracts the data associated with the field from the test eql_v2_encrypted
      -- json n: 30
      sv := get_numeric_ste_vec_30()::eql_v2_encrypted;
      -- extract the term at $.n returned as eql_v2_encrypted
      term := sv->'2517068c0d1f9d4d41d2c666211f785e';

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted < eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e'' < %L::eql_v2_encrypted', term));

      PERFORM assert_count(
        format('eql_v2_encrypted < eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e'' < %L::eql_v2_encrypted', term),
        2);

      -- -- Check the $.hello path
      -- -- Returned encrypted does not have ore_cllw_u64_8
      PERFORM assert_no_result(
        format('eql_v2_encrypted < eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784'' < %L::eql_v2_encrypted', term));

  END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- eql_v2_encrypted < eql_v2_encrypted with ore_cllw_var_8 index
--
-- Test data is in form '{"hello": "{one | two | three}", "n": {10 | 20 | 30} }'
--
-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
-- --
DO $$
DECLARE
    sv eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

      -- This extracts the data associated with the field from the test eql_v2_encrypted
      sv := get_numeric_ste_vec_30()::eql_v2_encrypted;
      -- extract the term at $.n returned as eql_v2_encrypted
      term := sv->'a7cea93975ed8c01f861ccb6bd082784';

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted < eql_v2_encrypted with ore_cllw_var_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784'' < %L::eql_v2_encrypted', term));

      PERFORM assert_count(
        format('eql_v2_encrypted < eql_v2_encrypted with ore_cllw_var_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784'' < %L::eql_v2_encrypted', term),
        1);

      -- -- Check the $.n path
      -- -- Returned encrypted does not have ore_cllw_var_8
      PERFORM assert_no_result(
        format('eql_v2_encrypted < eql_v2_encrypted with ore_cllw_var_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e'' < %L::eql_v2_encrypted', term));

  END;
$$ LANGUAGE plpgsql;



--
-- ORE - eql_v2_encrypted < eql_v2_encrypted
--
DO $$
DECLARE
    e eql_v2_encrypted;
    ore_term eql_v2_encrypted;
  BEGIN
      SELECT ore.e FROM ore WHERE id = 42 INTO ore_term;

      PERFORM assert_count(
        'eql_v2_encrypted < eql_v2_encrypted',
        format('SELECT id FROM ore WHERE e < %L ORDER BY e DESC', ore_term),
        41);

      -- Record with a Numeric ORE term of 1
      e := create_encrypted_ore_json(1);

      PERFORM assert_no_result(
        format('eql_v2_encrypted < eql_v2_encrypted'),
        format('SELECT e FROM encrypted WHERE e < %L;', e));

      -- Record with a Numeric ORE term of 42
      e := create_encrypted_ore_json(42);

      PERFORM assert_result(
        'eql_v2_encrypted < eql_v2_encrypted',
        format('SELECT e FROM encrypted WHERE e < %L', e));

     PERFORM assert_count(
        'eql_v2_encrypted < eql_v2_encrypted',
        format('SELECT e FROM encrypted WHERE e < %L', e),
        3);
  END;
$$ LANGUAGE plpgsql;


-- --
-- -- ORE - eql_v2.lt(a eql_v2_encrypted, b eql_v2_encrypted)
-- --
DO $$
DECLARE
    e eql_v2_encrypted;
    ore_term jsonb;
  BEGIN
      -- Record with a Numeric ORE term of 42
      e := create_encrypted_ore_json(42);

      PERFORM assert_result(
        'eql_v2.lt(a eql_v2_encrypted, b eql_v2_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v2.lt(e, %L)', e));

     PERFORM assert_count(
        'eql_v2.lt(a eql_v2_encrypted, b eql_v2_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v2.lt(e, %L)', e),
        3);
  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();