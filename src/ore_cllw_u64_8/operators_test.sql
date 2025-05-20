\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- ore_cllw_u64_8 < ore_cllw_u64_8
--
-- Test data is '{"hello": "world", "n": 42}'

-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
--
DO $$
DECLARE
    sv eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

      -- json n: 20
      sv := get_numeric_ste_vec_20()::eql_v2_encrypted;
      -- extract the term at $.n
      term := sv->'2517068c0d1f9d4d41d2c666211f785e';

      PERFORM eql_v2.log('term', term::text);

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted < eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') < eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

      PERFORM assert_count(
        format('eql_v2_encrypted < eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') < eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term),
        1);

      -- Check the $.hello path
      -- Returned encrypted does not have ore_cllw_u64_8
      PERFORM assert_exception(
        format('eql_v2_encrypted < eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''a7cea93975ed8c01f861ccb6bd082784'') < eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

  END;
$$ LANGUAGE plpgsql;




-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- ore_cllw_u64_8 <= ore_cllw_u64_8
--
-- Test data is '{"hello": "world", "n": 42}'

-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
--
DO $$
DECLARE
    sv eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

      -- json n: 20
      sv := get_numeric_ste_vec_20()::eql_v2_encrypted;

      -- extract the term at $.n
      term := sv->'2517068c0d1f9d4d41d2c666211f785e';

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted <= eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') <= eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

      PERFORM assert_count(
        format('eql_v2_encrypted <= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') <= eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term),
        2);

      -- Check the $.hello path
      -- Returned encrypted does not have ore_cllw_u64_8
      PERFORM assert_exception(
        format('eql_v2_encrypted <= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''a7cea93975ed8c01f861ccb6bd082784'') <= eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

  END;
$$ LANGUAGE plpgsql;



-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- ore_cllw_u64_8 >= ore_cllw_u64_8
--
-- Test data is '{"hello": "world", "n": 42}'

-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
--
DO $$
DECLARE
    sv eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

      -- json n: 30
      sv := get_numeric_ste_vec_30()::eql_v2_encrypted;

      -- extract the term at $.n
      term := sv->'2517068c0d1f9d4d41d2c666211f785e';

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') >= eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

      PERFORM assert_count(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') >= eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term),
        1);

      -- Check the $ path
      -- Returned encrypted does not have ore_cllw_u64_8
      PERFORM assert_exception(
        format('eql_v2_encrypted >= eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''bca213de9ccce676fa849ff9c4807963'') >= eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

  END;
$$ LANGUAGE plpgsql;



-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- ore_cllw_u64_8 > ore_cllw_u64_8
--
-- Test data is '{"hello": "world", "n": 42}'

-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
--
DO $$
DECLARE
    sv eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

      -- json n: 20
      sv := get_numeric_ste_vec_20()::eql_v2_encrypted;

      -- extract the term at $.n
      term := sv->'2517068c0d1f9d4d41d2c666211f785e';

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted > eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') > eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

      PERFORM assert_count(
        format('eql_v2_encrypted > eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') > eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term),
        1);

      -- Check the $ path
      -- Returned encrypted does not have ore_cllw_u64_8
      PERFORM assert_exception(
        format('eql_v2_encrypted > eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''bca213de9ccce676fa849ff9c4807963'') > eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

  END;
$$ LANGUAGE plpgsql;




-- -- ------------------------------------------------------------------------
-- -- ------------------------------------------------------------------------
-- --
-- -- ore_cllw_u64_8 = ore_cllw_u64_8
-- --
-- -- Test data is '{"hello": "world", "n": 42}'

-- -- Paths
-- -- $       -> bca213de9ccce676fa849ff9c4807963
-- -- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- -- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
-- --
-- --
DO $$
DECLARE
    sv eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

      -- json n: 20
      sv := get_numeric_ste_vec_10()::eql_v2_encrypted;
      -- extract the term at $.n
      term := sv->'2517068c0d1f9d4d41d2c666211f785e';

      PERFORM assert_result(
        format('eql_v2_encrypted = eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') = eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

      PERFORM assert_count(
        format('eql_v2_encrypted = eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''2517068c0d1f9d4d41d2c666211f785e'') = eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term),
        1);

      -- Check the $.n path
      -- Returned encrypted does not have ore_cllw_u64_8 and raises exception
      PERFORM assert_exception(
        format('eql_v2_encrypted = eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE eql_v2.ore_cllw_u64_8(e->''a7cea93975ed8c01f861ccb6bd082784'') = eql_v2.ore_cllw_u64_8(%L::eql_v2_encrypted)', term));

  END;
$$ LANGUAGE plpgsql;
