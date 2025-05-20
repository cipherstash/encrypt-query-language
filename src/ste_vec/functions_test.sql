\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


DO $$
  DECLARE
    e eql_v2_encrypted;
    sv eql_v2_encrypted[];
  BEGIN

    SELECT encrypted.e FROM encrypted LIMIT 1 INTO e;

    sv := eql_v2.ste_vec(e);
    ASSERT array_length(sv, 1) = 3;

    -- eql_v2_encrypted that IS a ste_vec element
    e := get_numeric_ste_vec_10()::eql_v2_encrypted;

    sv := eql_v2.ste_vec(e);
    ASSERT array_length(sv, 1) = 3;

  END;
$$ LANGUAGE plpgsql;


DO $$
  DECLARE
    e eql_v2_encrypted;
    sv eql_v2_encrypted[];
  BEGIN
    e := '{ "a": 1 }'::jsonb::eql_v2_encrypted;
    ASSERT eql_v2.is_ste_vec_array(e);


    e := '{ "a": 0 }'::jsonb::eql_v2_encrypted;
    ASSERT NOT eql_v2.is_ste_vec_array(e);

    e := '{ }'::jsonb::eql_v2_encrypted;
    ASSERT NOT eql_v2.is_ste_vec_array(e);
  END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- eql_v2_encrypted contains itself
--
--
DO $$
  DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
  BEGIN

    a := get_numeric_ste_vec_10()::eql_v2_encrypted;
    b := get_numeric_ste_vec_10()::eql_v2_encrypted;

    ASSERT eql_v2.ste_vec_contains(a, b);
    ASSERT eql_v2.ste_vec_contains(b, a);

  END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
--
-- eql_v2_encrypted contains a term
--
--
DO $$
  DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
    term eql_v2_encrypted;
  BEGIN

    a := get_numeric_ste_vec_10()::eql_v2_encrypted;
    b := get_numeric_ste_vec_10()::eql_v2_encrypted;

    -- $.n
    term := b->'2517068c0d1f9d4d41d2c666211f785e';

    ASSERT eql_v2.ste_vec_contains(a, term);

    ASSERT NOT eql_v2.ste_vec_contains(term, a);
  END;
$$ LANGUAGE plpgsql;

