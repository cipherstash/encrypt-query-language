-- Migration: 007_install_bench_data.sql
--
-- Creates benchmark table with 10K rows for performance testing.
-- Each column cycles through 100 distinct encrypted values (from ore ids 1-100).
--
-- Columns:
--   encrypted_text   - text equality (hmac), pattern match (bloom), ordering (ore)
--   encrypted_int    - integer ORE range/equality/ordering
--   encrypted_bigint - bigint ORE at scale
--
-- Index terms per row: hm (hmac), b3 (blake3), bf (bloom filter), ob (ORE blocks), sv (STE vec)
-- Data generated via create_encrypted_json() from 004_install_test_helpers.sql.

CREATE TABLE bench (
    id SERIAL PRIMARY KEY,
    encrypted_text eql_v2_encrypted,
    encrypted_int eql_v2_encrypted,
    encrypted_bigint eql_v2_encrypted
);

-- Seed 10K rows. Each column uses a different offset to create varied distributions.
-- create_encrypted_json(id) valid for ids 1-100 (ore table lookup at 10*id, max ore.id=1000).
INSERT INTO bench (encrypted_text, encrypted_int, encrypted_bigint)
SELECT
    create_encrypted_json(((gs - 1) % 100) + 1),
    create_encrypted_json(((gs + 33) % 100) + 1),
    create_encrypted_json(((gs + 66) % 100) + 1)
FROM generate_series(1, 10000) AS gs;
