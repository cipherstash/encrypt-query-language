-- Migration: 007_install_bench_data.sql
--
-- Creates benchmark table for performance testing.
-- DDL only — data is loaded by the bench_data.sql fixture so that
-- only bench tests pay the 10K-row seeding cost, not the entire suite.
--
-- Columns:
--   encrypted_text   - text equality (hmac), pattern match (bloom), ordering (ore)
--   encrypted_int    - integer ORE range/equality/ordering
--   encrypted_bigint - bigint ORE at scale

CREATE TABLE bench (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_text eql_v2_encrypted,
    encrypted_int eql_v2_encrypted,
    encrypted_bigint eql_v2_encrypted
);

-- Apply the production CHECK constraint to every encrypted column. The
-- bench fixture (`tests/sqlx/fixtures/bench_data.sql`) loads 10K rows via
-- `create_encrypted_json()`, which emits real EQL payloads with the
-- required `c`, `i`, and `v=2` envelope; the constraint catches any
-- future regression that would let a payload missing those fields through
-- the bench seed path. See the note in 003_install_ste_vec_data.sql.
SELECT eql_v2.add_encrypted_constraint('bench', 'encrypted_text');
SELECT eql_v2.add_encrypted_constraint('bench', 'encrypted_int');
SELECT eql_v2.add_encrypted_constraint('bench', 'encrypted_bigint');
