\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


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
      -- json n: 30
      sv := get_numeric_ste_vec_10()::eql_v2_encrypted;
      -- extract the term at $.n returned as eql_v2_encrypted
      term := sv->'2517068c0d1f9d4d41d2c666211f785e'::text;

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e''::text >= %L::eql_v2_encrypted', term));

      PERFORM assert_count(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e''::text >= %L::eql_v2_encrypted', term),
        3);

      -- -- Check the $.hello path
      -- -- Returned encrypted does not have ore_cllw_u64_8
      -- Falls back to jsonb literal comparison
      PERFORM assert_result(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784''::text >= %L::eql_v2_encrypted', term));

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
      -- json n: 30
      sv := get_numeric_ste_vec_10()::eql_v2_encrypted;
      -- extract the term at $.n returned as eql_v2_encrypted
      term := sv->'a7cea93975ed8c01f861ccb6bd082784'::text;

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784''::text >= %L::eql_v2_encrypted', term));

      PERFORM assert_count(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784''::text >= %L::eql_v2_encrypted', term),
        3);

      -- -- Check the $.hello path
      -- -- Returned encrypted does not have ore_cllw_u64_8
      -- Falls back to jsonb literal comparison
      PERFORM assert_result(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e''::text >= %L::eql_v2_encrypted', term));

  END;
$$ LANGUAGE plpgsql;


--
-- ORE - eql_v2_encrypted >= eql_v2_encrypted
--
DO $$
DECLARE
    e eql_v2_encrypted;
    ore_term jsonb;
  BEGIN

      -- Record with a Numeric ORE term of 12
      e := create_encrypted_ore_json(12);
      PERFORM seed_encrypted(e);

      PERFORM assert_result(
        'eql_v2_encrypted >= eql_v2_encrypted',
        format('SELECT e FROM encrypted WHERE e >= %L', e));

      PERFORM assert_count(
          format('eql_v2_encrypted >= eql_v2_encrypted'),
          format('SELECT e FROM encrypted WHERE e >= %L;', e),
          3);

      e := create_encrypted_ore_json(20);

      PERFORM assert_result(
        'eql_v2_encrypted >= eql_v2_encrypted',
        format('SELECT e FROM encrypted WHERE e >= %L::eql_v2_encrypted', e));

      PERFORM assert_count(
        format('eql_v2_encrypted >= eql_v2_encrypted'),
        format('SELECT e FROM encrypted WHERE e >= %L;', e),
        2);
  END;
$$ LANGUAGE plpgsql;


--
-- ORE - eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted)
--
DO $$
DECLARE
    e eql_v2_encrypted;
    ore_term jsonb;
  BEGIN
      -- Reset data
      PERFORM seed_encrypted_json();

      -- Record with a Numeric ORE term of 42
      e := create_encrypted_ore_json(42);
      PERFORM seed_encrypted(e);

     PERFORM assert_result(
        'eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v2.gte(e, %L)', e));

     -- include
     PERFORM assert_count(
        'eql_v2.gte(a eql_v2_encrypted, b eql_v2_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v2.gte(e, %L)', e),
        1);

      -- Record with a Numeric ORE term of 30
      e := create_encrypted_ore_json(30);

      PERFORM assert_result(
        'eql_v2.get(a eql_v2_encrypted, b eql_v2_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v2.gte(e, %L)', e));

     PERFORM assert_count(
        'eql_v2.get(a eql_v2_encrypted, b eql_v2_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v2.gte(e, %L)', e),
        2);
  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();