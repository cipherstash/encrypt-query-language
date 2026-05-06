-- Fixture: order_by_null_data.sql
-- Test data for ORDER BY NULL ordering tests on encrypted columns
--
-- Creates table with NULL and ORE-encrypted values for testing
-- NULLS FIRST / NULLS LAST ordering behavior
--
-- Data layout:
--   ID=1: NULL
--   ID=2: ore value for 42
--   ID=3: ore value for 3
--   ID=4: NULL

DROP TABLE IF EXISTS encrypted;
CREATE TABLE encrypted
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    e eql_v2_encrypted
);

-- Insert NULL (id=1)
INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted);

-- Insert ore value for 42 (id=2)
INSERT INTO encrypted(e) SELECT e FROM ore WHERE id = 42;

-- Insert ore value for 3 (id=3)
INSERT INTO encrypted(e) SELECT e FROM ore WHERE id = 3;

-- Insert NULL (id=4)
INSERT INTO encrypted(e) VALUES (NULL::jsonb::eql_v2_encrypted);
