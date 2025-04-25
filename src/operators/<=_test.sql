\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

SELECT e FROM encrypted WHERE e->'a7cea93975ed8c01f861ccb6bd082784' <= '("{""c"": ""mBbM0#UZON2jQ3@LiWcvns2Yf6y3L;hykEh`}*fX#aF;n*=>+*o5Uarod39C7TF-SiCD-NgkG)l%Vw=l!tX>H*P<PfE$+0Szy"", ""s"": ""2517068c0d1f9d4d41d2c666211f785e"", ""ocf"": ""b0c13d4a4a9ffcb2ef853959fb2d26236337244ed86d66470d08963ed703356a1cee600a9a75a70aaefc1b4ca03b7918a7df25b7cd4ca774fd5b8616e6b9adb8""}")'::eql_v1_encrypted;


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- eql_v1_encrypted < eql_v1_encrypted with ore_cllw_u64_8 index
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
    sv eql_v1_encrypted;
    term eql_v1_encrypted;
  BEGIN

      -- This extracts the data associated with the field from the test eql_v1_encrypted
      -- json n: 30
      sv := get_numeric_ste_vec_30()::eql_v1_encrypted;
      -- extract the term at $.n returned as eql_v1_encrypted
      term := sv->'2517068c0d1f9d4d41d2c666211f785e';

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v1_encrypted <= eql_v1_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e'' <= %L::eql_v1_encrypted', term));

      PERFORM assert_count(
        format('eql_v1_encrypted <= eql_v1_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e'' <= %L::eql_v1_encrypted', term),
        3);

      -- -- Check the $.hello path
      -- -- Returned encrypted does not have ore_cllw_u64_8
      PERFORM assert_no_result(
        format('eql_v1_encrypted <= eql_v1_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784'' <= %L::eql_v1_encrypted', term));

  END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- eql_v1_encrypted < eql_v1_encrypted with ore_cllw_var_8 index
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
    sv eql_v1_encrypted;
    term eql_v1_encrypted;
  BEGIN

      -- This extracts the data associated with the field from the test eql_v1_encrypted
      -- json n: 30
      sv := get_numeric_ste_vec_30()::eql_v1_encrypted;
      -- extract the term at $.n returned as eql_v1_encrypted
      term := sv->'a7cea93975ed8c01f861ccb6bd082784';

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v1_encrypted <= eql_v1_encrypted with ore_cllw_var_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784'' <= %L::eql_v1_encrypted', term));

      PERFORM assert_count(
        format('eql_v1_encrypted <= eql_v1_encrypted with ore_cllw_var_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''a7cea93975ed8c01f861ccb6bd082784'' <= %L::eql_v1_encrypted', term),
        2);

      -- -- Check the $.n path
      -- -- Returned encrypted does not have ore_cllw_u64_8
      PERFORM assert_no_result(
        format('eql_v1_encrypted <= eql_v1_encrypted with ore_cllw_var_8 index term'),
        format('SELECT e FROM encrypted WHERE e->''2517068c0d1f9d4d41d2c666211f785e'' <= %L::eql_v1_encrypted', term));

  END;
$$ LANGUAGE plpgsql;



--
-- ORE - eql_v1_encrypted <= eql_v1_encrypted
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN

      -- Record with a Numeric ORE term of 42
      e := create_encrypted_ore_json(42);
      PERFORM seed_encrypted(e);

      PERFORM assert_result(
        'eql_v1_encrypted <= eql_v1_encrypted',
        format('SELECT e FROM encrypted WHERE e <= %L::eql_v1_encrypted', e));

      PERFORM assert_count(
          format('eql_v1_encrypted <= eql_v1_encrypted'),
          format('SELECT e FROM encrypted WHERE e <= %L;', e),
          4);

      e := create_encrypted_ore_json(20);

      PERFORM assert_result(
        'eql_v1_encrypted <= eql_v1_encrypted',
        format('SELECT e FROM encrypted WHERE e <= %L::eql_v1_encrypted', e));

      PERFORM assert_count(
        format('eql_v1_encrypted <= eql_v1_encrypted'),
        format('SELECT e FROM encrypted WHERE e <= %L;', e),
        2);
  END;
$$ LANGUAGE plpgsql;


--
-- ORE - eql_v1.gte(a eql_v1_encrypted, b eql_v1_encrypted)
--
DO $$
DECLARE
    e eql_v1_encrypted;
    ore_term jsonb;
  BEGIN
      -- Reset data
      PERFORM seed_encrypted_json();

      -- Record with a Numeric ORE term of 42
      e := create_encrypted_ore_json(42);
      PERFORM seed_encrypted(e);

     PERFORM assert_result(
        'eql_v1.lte(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.lte(e, %L)', e));

     -- include
     PERFORM assert_count(
        'eql_v1.lte(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.lte(e, %L)', e),
        4);

      -- Record with a Numeric ORE term of 30
      e := create_encrypted_ore_json(30);

      PERFORM assert_result(
        'eql_v1.get(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.lte(e, %L)', e));

     PERFORM assert_count(
        'eql_v1.get(a eql_v1_encrypted, b eql_v1_encrypted)',
        format('SELECT e FROM encrypted WHERE eql_v1.lte(e, %L)', e),
        3);
  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();