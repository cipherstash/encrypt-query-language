\set ON_ERROR_STOP on


SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();


-- CREATE TABLE unencrypted
-- (
--     id bigint GENERATED ALWAYS AS IDENTITY,
--     u jsonb,
--     PRIMARY KEY(id)
-- );
-- INSERT INTO unencrypted (u)
-- VALUES
--     ('{"a": [1, 2, 3] }'),
--     ('{"a": [1, 2, 3, 4] }'),
--     ('{"a": [1, 2, 3, 4, 5] }');

-- SELECT *
-- FROM unencrypted
-- WHERE EXISTS (
--   SELECT 1
--   FROM jsonb_array_elements(u->'a') AS elem
--   WHERE elem::int < 2
-- );

-- SELECT seed_encrypted(get_array_ste_vec()::eql_v1_encrypted);
-- SELECT *
-- FROM encrypted
-- WHERE EXISTS (
--   SELECT 1
--   FROM eql_v1.jsonb_array_elements(e->'f510853730e1c3dbd31b86963f029dd5') AS elem
--   WHERE elem > '{"ocf": "b0c0a7385cb2f7dfe32a2649a9d8294794b8fc05585a240c1315f1e45ee7d9012616db3f01b43fa94351618670a29c24fc75df1392d52764c757b34495888b1c"}'::jsonb
-- );

-- SELECT eql_v1.jsonb_path_query_first(e, '33743aed3ae636f6bf05cff11ac4b519') as e
-- FROM encrypted
-- WHERE eql_v1.jsonb_path_query(e, '33743aed3ae636f6bf05cff11ac4b519') IS NOT NULL;



-- "ocf": "b0c0a7385cb2f7dfe32a2649a9d8294794b8fc05585a240c1315f1e45ee7d9012616db3f01b43fa94351618670a29c24fc75df1392d52764c757b34495888b1c",

-- SELECT eql_v1.jsonb_array_elements(eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5')) as e FROM encrypted ;




-- -- SELECT eql_v1.jsonb_path_exists(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;
-- -- SELECT eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5') FROM encrypted;

-- -- SELECT eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5') as e FROM encrypted;
-- -- SELECT eql_v1.jsonb_array_length(eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5')) as e FROM encrypted LIMIT 1;
-- -- SELECT eql_v1.jsonb_array_elements(eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5')) as e FROM encrypted ;
-- -- SELECT eql_v1.jsonb_array_elements_text(eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5')) as e FROM encrypted ;
-- -- SELECT eql_v1.jsonb_array_length(eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5')) as e FROM encrypted LIMIT 1;
-- -- SELECT eql_v1.jsonb_path_query(e, 'f510853730e1c3dbd31b86963f029dd5') as e FROM encrypted;




-- ========================================================================
--
-- Selector &.a[*]
--  -> 33743aed3ae636f6bf05cff11ac4b519
--
DO $$
DECLARE
    sv eql_v1_encrypted;
    results eql_v1_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();
    PERFORM seed_encrypted(get_array_ste_vec()::eql_v1_encrypted);

    PERFORM assert_result(
      'jsonb_array_elements returns array elements from jsonb_path_query result',
      'SELECT eql_v1.jsonb_array_elements(eql_v1.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;');

    PERFORM assert_count(
      'jsonb_array_elements returns the correct number of array elements from jsonb_path_query result',
      'SELECT eql_v1.jsonb_array_elements(eql_v1.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;',
      5);

    PERFORM assert_exception(
      'jsonb_array_elements exception if input is not an array',
      'SELECT eql_v1.jsonb_array_elements(eql_v1.jsonb_path_query(e, ''33743aed3ae636f6bf05cff11ac4b519'')) as e FROM encrypted LIMIT 1;');

  END;
$$ LANGUAGE plpgsql;


-- -- ========================================================================
-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
DECLARE
    sv eql_v1_encrypted;
    results eql_v1_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();
    PERFORM seed_encrypted(get_array_ste_vec()::eql_v1_encrypted);

    PERFORM assert_result(
      'jsonb_array_elements_text returns array elements from jsonb_path_query result',
      'SELECT eql_v1.jsonb_array_elements_text(eql_v1.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;');

    PERFORM assert_count(
      'jsonb_array_elements_text returns the correct number of array elements from jsonb_path_query result',
      'SELECT eql_v1.jsonb_array_elements_text(eql_v1.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted;',
      5);

    PERFORM assert_exception(
      'jsonb_array_elements_text exception if input is not an array',
      'SELECT eql_v1.jsonb_array_elements_text(eql_v1.jsonb_path_query(e, ''33743aed3ae636f6bf05cff11ac4b519'')) as e FROM encrypted LIMIT 1;');

  END;
$$ LANGUAGE plpgsql;


-- ========================================================================
--
-- Selector &.a[*]
--  -> 33743aed3ae636f6bf05cff11ac4b519
--
DO $$
DECLARE
    sv eql_v1_encrypted;
    results eql_v1_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();
    PERFORM seed_encrypted(get_array_ste_vec()::eql_v1_encrypted);

    PERFORM assert_result(
      'jsonb_array_length returns array length of jsonb_path_query result',
      'SELECT eql_v1.jsonb_array_length(eql_v1.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'')) as e FROM encrypted LIMIT 1;',
      '5');

    PERFORM assert_exception(
      'jsonb_array_length exception if input is not an array',
      'SELECT eql_v1.jsonb_array_length(eql_v1.jsonb_path_query(e, ''33743aed3ae636f6bf05cff11ac4b519'')) as e FROM encrypted LIMIT 1;');

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
    sv eql_v1_encrypted;
    results eql_v1_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v1_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v1.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted;',
      4
    );

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v1.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted WHERE eql_v1.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') IS NOT NULL;',
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
      'SELECT eql_v1.jsonb_path_query(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted LIMIT 1;');

      PERFORM assert_count(
      'jsonb_path_query returns count',
      'SELECT eql_v1.jsonb_path_query(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted;',
      3);

  END;
$$ LANGUAGE plpgsql;


DO $$
  BEGIN

    PERFORM seed_encrypted_json();

    PERFORM assert_result(
      'jsonb_path_exists returns true',
      'SELECT eql_v1.jsonb_path_exists(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted LIMIT 1;',
      'true');

    PERFORM assert_result(
      'jsonb_path_exists returns false',
      'SELECT eql_v1.jsonb_path_exists(e, ''blahvtha'') FROM encrypted LIMIT 1;',
      'false');

    PERFORM assert_count(
      'jsonb_path_exists returns count',
      'SELECT eql_v1.jsonb_path_exists(e, ''2517068c0d1f9d4d41d2c666211f785e'') FROM encrypted;',
      3);
  END;
$$ LANGUAGE plpgsql;



-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
DECLARE
    sv eql_v1_encrypted;
    results eql_v1_encrypted[];
  BEGIN

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v1_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_result(
      'jsonb_path_query with array selector',
      'SELECT eql_v1.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;');

    -- An array should be wrapped and returned as a single element
    PERFORM assert_count(
      'jsonb_path_query with array selector returns one result',
      'SELECT eql_v1.jsonb_path_query(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;',
      1);
  END;
$$ LANGUAGE plpgsql;



-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
  DECLARE
    sv eql_v1_encrypted;
    results eql_v1_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v1_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_result(
      'jsonb_path_exists with array selector',
      'SELECT eql_v1.jsonb_path_exists(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;');

    PERFORM assert_count(
      'jsonb_path_exists with array selector returns correct number of records',
      'SELECT eql_v1.jsonb_path_exists(e, ''f510853730e1c3dbd31b86963f029dd5'') FROM encrypted;',
      4);
  END;
$$ LANGUAGE plpgsql;



-- --
-- -- Selector &.a[*]
-- --  -> 33743aed3ae636f6bf05cff11ac4b519
-- --
DO $$
DECLARE
    sv eql_v1_encrypted;
    results eql_v1_encrypted[];
  BEGIN

    PERFORM seed_encrypted_json();

    -- Insert a row with array selector
    sv := get_array_ste_vec()::eql_v1_encrypted;
    PERFORM seed_encrypted(sv);

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v1.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted;',
      4
    );

    PERFORM assert_count(
      'jsonb_path_query with array selector returns count',
      'SELECT eql_v1.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') as e FROM encrypted WHERE eql_v1.jsonb_path_query_first(e, ''33743aed3ae636f6bf05cff11ac4b519'') IS NOT NULL;',
      1
    );

  END;
$$ LANGUAGE plpgsql;


