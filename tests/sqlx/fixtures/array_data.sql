-- Fixture: array_data.sql
--
-- DEPENDS ON: encrypted_json.sql (requires 'encrypted' table to exist)
--
-- Adds encrypted record with array field to existing 'encrypted' table
-- Plaintext: {"hello": "four", "n": 20, "a": [1, 2, 3, 4, 5]}
--
-- Array selectors:
-- $.a[*] (elements) -> f510853730e1c3dbd31b86963f029dd5
-- $.a (array root)  -> 33743aed3ae636f6bf05cff11ac4b519
--
-- Note: This fixture adds one additional record (ID 4) to the three base records
--       created by encrypted_json.sql

-- Insert array data using test helper
SELECT seed_encrypted(get_array_ste_vec()::eql_v2_encrypted);
