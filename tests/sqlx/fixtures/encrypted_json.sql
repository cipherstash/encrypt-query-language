-- Fixture: encrypted_json.sql
--
-- Creates base test data with three encrypted records
-- Plaintext structure: {"hello": "world", "n": N}
-- where N is 10, 20, or 30 for records 1, 2, 3
--
-- Selectors:
-- $ (root)       -> bca213de9ccce676fa849ff9c4807963
-- $.hello        -> a7cea93975ed8c01f861ccb6bd082784
-- $.n            -> 2517068c0d1f9d4d41d2c666211f785e

-- Create table
CREATE TABLE IF NOT EXISTS encrypted (
    id bigint GENERATED ALWAYS AS IDENTITY,
    e eql_v2_encrypted,
    PRIMARY KEY(id)
);

-- Insert three base records using test helper
-- These call the existing SQL helper functions
SELECT seed_encrypted(create_encrypted_json(1));
SELECT seed_encrypted(create_encrypted_json(2));
SELECT seed_encrypted(create_encrypted_json(3));
