\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- ore_cllw_u64_8 equality
--
-- Test data is in form '{"hello": "{one | two | three}", "n": {10 | 20 | 30} }'
--
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

      -- This extracts the data associated with the field from the test eql_v2_encrypted
      sv := get_numeric_ste_vec_10()::eql_v2_encrypted;
      -- extract the term at $.n returned as eql_v2_encrypted
      term := sv->'a7cea93975ed8c01f861ccb6bd082784'::text;

      -- -- -- -- $.n
      PERFORM assert_result(
        format('eql_v2_encrypted = eql_v2_encrypted with ore_cllw_u64_8 index term'),
        format('SELECT e FROM encrypted WHERE %L::eql_v2_encrypted <@ e', term));

      PERFORM assert_count(
        format('eql_v2_encrypted = eql_v2_encrypted with ore index term'),
        format('SELECT e FROM encrypted WHERE %L::eql_v2_encrypted <@ e', term),
        1);

  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();