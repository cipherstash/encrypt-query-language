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
    id SERIAL PRIMARY KEY,
    encrypted_text eql_v2_encrypted,
    encrypted_int eql_v2_encrypted,
    encrypted_bigint eql_v2_encrypted
);
