-- Fixture: bench_data.sql
--
-- Seeds 10K rows into the bench table for performance testing.
-- Each column cycles through 100 distinct encrypted values (from ore ids 1-100).
--
-- Index terms per row: hm (hmac), b3 (blake3), bf (bloom filter), ob (ORE blocks), sv (STE vec)
-- Data generated via create_encrypted_json() from 004_install_test_helpers.sql.
--
-- Cycling offsets create varied distributions:
--   encrypted_text:   ids 1, 2, ..., 100, 1, 2, ... (offset 0)
--   encrypted_int:    ids 35, 36, ..., 100, 1, ..., 34 (offset +33)
--   encrypted_bigint: ids 68, 69, ..., 100, 1, ..., 67 (offset +66)

INSERT INTO bench (encrypted_text, encrypted_int, encrypted_bigint)
SELECT
    create_encrypted_json(((gs - 1) % 100) + 1),
    create_encrypted_json(((gs + 33) % 100) + 1),
    create_encrypted_json(((gs + 66) % 100) + 1)
FROM generate_series(1, 10000) AS gs;
