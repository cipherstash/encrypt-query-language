\set ON_ERROR_STOP on


SELECT create_table_with_encrypted();


-- DO $$
--   BEGIN
--     PERFORM assert_result(
--         'Fetch ciphertext from encrypted column',
--         'SELECT e->>''selector.1'' FROM encrypted;');
--   END;
-- $$ LANGUAGE plpgsql;


-- DO $$
--   BEGIN
--     PERFORM assert_result(
--         'Fetch ciphertext from encrypted column',
--         'SELECT e->>''selector.1'' FROM encrypted;');
--   END;
-- $$ LANGUAGE plpgsql;