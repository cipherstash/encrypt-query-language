\set ON_ERROR_STOP on

SELECT create_table_with_encrypted();
SELECT seed_encrypted_json();

SELECT * FROM encrypted;

SELECT e @> '{
        "c": "ciphertext",
        "i": {
            "t": "encrypted",
            "c": "e"
        },
        "s": "selector.1",
        "t": "term.1"
    }'::jsonb::eql_v1_encrypted FROM encrypted;


\set ON_ERROR_STOP on


SELECT create_table_with_encrypted();


DO $$
  BEGIN
    PERFORM assert_result(
        'Fetch ciphertext from encrypted column',
        'SELECT e->>''selector.1'' FROM encrypted;');
  END;
$$ LANGUAGE plpgsql;


DO $$
  BEGIN
    PERFORM assert_result(
        'Fetch ciphertext from encrypted column',
        'SELECT e->>''selector.1'' FROM encrypted;');
  END;
$$ LANGUAGE plpgsql;


DO $$
  BEGIN
    PERFORM assert_result(
        'Fetch encrypted using selected',
        'SELECT e->''selector.1'' FROM encrypted;');


    PERFORM assert_no_result(
        '-> operator only works on top level of encrypted column',
        'SELECT e->''selector.1''->''blah'' FROM encrypted;');
  END;
$$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();

-- DO $$
-- DECLARE
--     e eql_v1_encrypted;
--   BEGIN
--     e := '{
--         "c": "ciphertext",
--         "i": {
--             "t": "encrypted",
--             "c": "e"
--         },
--         "s": "selector.1",
--         "t": "term.1"
--     }'::jsonb::eql_v1_encrypted;

--     PERFORM eql_v1.log('Encrypted', e::text);


--     PERFORM assert_result(
--         'Fetch ciphertext from encrypted column',
--         format('SELECT e @> %s FROM encrypted;', e));

--   END;
-- $$ LANGUAGE plpgsql;


-- -- DO $$
-- --   BEGIN
-- --     PERFORM assert_result(
-- --         'Fetch encrypted using selected',
-- --         'SELECT e->''selector.1'' FROM encrypted;');


-- --     PERFORM assert_no_result(
-- --         '-> operator only works on top level of encrypted column',
-- --         'SELECT e->''selector.1''->''blah'' FROM encrypted;');
-- --   END;
-- -- $$ LANGUAGE plpgsql;


SELECT drop_table_with_encrypted();