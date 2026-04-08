-- Fixture: bench_setup.sql
--
-- Creates benchmark indexes and refreshes planner statistics.
-- Table and 10K rows created by migration 007_install_bench_data.sql.
--
-- Indexes:
--   bench_text_hmac_idx   - hash on eql_v2.hmac_256(encrypted_text) for equality
--   bench_text_ore_idx    - btree on encrypted_text via operator class for text ordering
--   bench_int_ore_idx     - btree on encrypted_int via operator class for range/ORDER BY
--   bench_bigint_ore_idx  - btree on encrypted_bigint via operator class
--   bench_text_bloom_idx  - GIN on eql_v2.bloom_filter(encrypted_text) for containment
--
-- Pattern follows containment_with_index_tests.rs: indexes in fixture (not migration)
-- so tests can verify before/after index creation.

CREATE INDEX IF NOT EXISTS bench_text_hmac_idx
    ON bench USING hash (eql_v2.hmac_256(encrypted_text));

CREATE INDEX IF NOT EXISTS bench_text_ore_idx
    ON bench USING btree (encrypted_text eql_v2.encrypted_operator_class);

CREATE INDEX IF NOT EXISTS bench_int_ore_idx
    ON bench USING btree (encrypted_int eql_v2.encrypted_operator_class);

CREATE INDEX IF NOT EXISTS bench_bigint_ore_idx
    ON bench USING btree (encrypted_bigint eql_v2.encrypted_operator_class);

CREATE INDEX IF NOT EXISTS bench_text_bloom_idx
    ON bench USING gin (eql_v2.bloom_filter(encrypted_text));

ANALYZE bench;
