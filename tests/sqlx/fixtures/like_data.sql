-- Fixture: like_data.sql
--
-- Creates test data for LIKE operator tests (~~ and ~~* operators)
-- Tests encrypted-to-encrypted matching using bloom filter indexes
--
-- Plaintext structure: {"hello": "world", "n": N}
-- where N is 10, 20, or 30 for records 1, 2, 3

-- Create table for LIKE operator tests
DROP TABLE IF EXISTS encrypted CASCADE;
CREATE TABLE encrypted (
    id bigint GENERATED ALWAYS AS IDENTITY,
    e eql_v2_encrypted,
    PRIMARY KEY(id)
);

-- Apply the production CHECK constraint. Rows are loaded via
-- `create_encrypted_json()`, which emits real EQL payloads — the
-- constraint guards against future regressions that would let a malformed
-- payload through the LIKE-test seed path. See the note in
-- `tests/sqlx/migrations/003_install_ste_vec_data.sql`.
SELECT eql_v2.add_encrypted_constraint('encrypted', 'e');

-- Insert three base records using test helper
-- These records contain bloom filter indexes for LIKE operations
SELECT seed_encrypted(create_encrypted_json(1));
SELECT seed_encrypted(create_encrypted_json(2));
SELECT seed_encrypted(create_encrypted_json(3));
