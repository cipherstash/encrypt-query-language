\set ON_ERROR_STOP on


SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


-- ========================================================================
--
-- Selector &.a[*]
--  -> 33743aed3ae636f6bf05cff11ac4b519
--
DO $$
  BEGIN

    PERFORM seed_encrypted_json();
    PERFORM seed_encrypted(get_array_ste_vec()::eql_v2_encrypted);

    PERFORM assert_result(
      'jsonb_array_elements returns array elements from jsonb_path_query result',
      'SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;');

    PERFORM assert_count(
      'jsonb_array_elements returns the correct number of array elements from jsonb_path_query result',
      'SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;',
      5);

    PERFORM assert_exception(
      'jsonb_array_elements exception if input is not an array',
      'SELECT eql_v2.jsonb_array_elements(eql_v2.jsonb_path_query(e, ''33743aed3ae636f6bf05cff11ac4b519'')) as e FROM encrypted LIMIT 1;');

  END;
$$ LANGUAGE plpgsql;

--
-- Selector &.a[*] as eql_v2_encrypted
--  -> 33743aed3ae636f6bf05cff11ac4b519
--
DO $$
DECLARE
    selector eql_v2_encrypted;

  BEGIN

    PERFORM seed_encrypted_json();
    PERFORM seed_encrypted(get_array_ste_vec()::eql_v2_encrypted);

    selector := '{"s": "f510853730e1c3dbd31b86963f029dd5"}'::jsonb::eql_v2_encrypted;

    PERFORM assert_result(
      'jsonb_array_elements returns array elements from jsonb_path_query result using eql_v2_encrypted selector',
      format('SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, %L::eql_v2_encrypted)) as e FROM encrypted;', selector));

    PERFORM assert_count(
      'jsonb_array_elements returns the correct number of array elements from jsonb_path_query result',
      format('SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, %L::eql_v2_encrypted)) as e FROM encrypted;', selector),
      5);

    selector := '{"s": "33743aed3ae636f6bf05cff11ac4b519"}'::jsonb::eql_v2_encrypted;

    PERFORM assert_exception(
      'jsonb_array_elements exception if input is not an array',
      format('SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, %L::eql_v2_encrypted)) as e FROM encrypted;', selector));

  END;
$$ LANGUAGE plpgsql;


-- -- ========================================================================
-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
DECLARE
    sv eql_v2_encrypted;
    results eql_v2_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();
    PERFORM seed_encrypted(get_array_ste_vec()::eql_v2_encrypted);

    PERFORM assert_result(
      'jsonb_array_elements_text returns array elements from jsonb_path_query result',
      'SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;');

    PERFORM assert_count(
      'jsonb_array_elements_text returns the correct number of array elements from jsonb_path_query result',
      'SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;',
      5);

    PERFORM assert_exception(
      'jsonb_array_elements_text exception if input is not an array',
      'SELECT eql_v2.jsonb_array_elements_text(eql_v2.jsonb_path_query(e, ''33743aed3ae636f6bf05cff11ac4b519'')) as e FROM encrypted LIMIT 1;');

  END;
$$ LANGUAGE plpgsql;


-- ========================================================================
--
-- Selector &.a[*]
--  -> 33743aed3ae636f6bf05cff11ac4b519
--
DO $$
DECLARE
    sv eql_v2_encrypted;
    results eql_v2_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();
    PERFORM seed_encrypted(get_array_ste_vec()::eql_v2_encrypted);

    PERFORM assert_result(
      'jsonb_array_length returns array length of jsonb_path_query result',
      'SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted LIMIT 1;',
      '5');

    PERFORM assert_exception(
      'jsonb_array_length exception if input is not an array',
      'SELECT eql_v2.jsonb_array_length(eql_v2.jsonb_path_query(e, ''33743aed3ae636f6bf05cff11ac4b519'')) as e FROM encrypted LIMIT 1;');

  END;
$$ LANGUAGE plpgsql;



-- -- ========================================================================
--
-- -- "{\"hello\": \"four\", \"n\": 20, \"a\": [1, 2, 3, 4, 5] }",
--
-- Selector &.a[*]
--  -> 33743aed3ae636f6bf05cff11ac4b519
--
DO $$
DECLARE
    sv eql_v2_encrypted;
    results eql_v2_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v2_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v2.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted;',
      4
    );

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v2.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted WHERE eql_v2.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') IS NOT NULL;',
      1
    );

  END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------------------



-- ------------------------------------------------------------------------
--
-- jsonb_path_query
--

-- Paths
-- $       -> bca213de9ccce676fa849ff9c4807963
-- $.hello -> a7cea93975ed8c01f861ccb6bd082784
-- $.n     -> 2517068c0d1f9d4d41d2c666211f785e
--
--
DO $$
  BEGIN
    PERFORM seed_encrypted_json();

    PERFORM assert_result(
      'jsonb_path_query',
      'SELECT eql_v2.jsonb_path_query(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted LIMIT 1;');

      PERFORM assert_count(
      'jsonb_path_query returns count',
      'SELECT eql_v2.jsonb_path_query(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted;',
      3);

  END;
$$ LANGUAGE plpgsql;


DO $$
  BEGIN

    PERFORM seed_encrypted_json();

    PERFORM assert_result(
      'jsonb_path_exists returns true',
      'SELECT eql_v2.jsonb_path_exists(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted LIMIT 1;',
      'true');

    PERFORM assert_result(
      'jsonb_path_exists returns false',
      'SELECT eql_v2.jsonb_path_exists(e, ''blahvtha'') FROM encrypted LIMIT 1;',
      'false');

    PERFORM assert_count(
      'jsonb_path_exists returns count',
      'SELECT eql_v2.jsonb_path_exists(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted;',
      3);
  END;
$$ LANGUAGE plpgsql;



-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
DECLARE
    sv eql_v2_encrypted;
    results eql_v2_encrypted[];
  BEGIN

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v2_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_result(
      'jsonb_path_query with array selector',
      'SELECT eql_v2.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;');

    -- An array should be wrapped and returned as a single element
    PERFORM assert_count(
      'jsonb_path_query with array selector returns one result',
      'SELECT eql_v2.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;',
      1);
  END;
$$ LANGUAGE plpgsql;



-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
  DECLARE
    sv eql_v2_encrypted;
    results eql_v2_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v2_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_result(
      'jsonb_path_exists with array selector',
      'SELECT eql_v2.jsonb_path_exists(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;');

    PERFORM assert_count(
      'jsonb_path_exists with array selector returns correct number of records',
      'SELECT eql_v2.jsonb_path_exists(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;',
      4);
  END;
$$ LANGUAGE plpgsql;



-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
DECLARE
    sv eql_v2_encrypted;
    results eql_v2_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v2_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v2.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted;',
      4
    );

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v2.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted WHERE eql_v2.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') IS NOT NULL;',
      1
    );

  END;
$$ LANGUAGE plpgsql;


