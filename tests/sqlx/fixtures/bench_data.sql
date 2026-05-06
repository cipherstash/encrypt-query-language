-- Fixture: bench_data.sql
--
-- Seeds 10K rows into the bench table for performance testing.
-- Each column draws independently from 99 distinct create_encrypted_json() inputs
-- (helper ids 1-99) using a Zipf-like skew so the planner sees realistic histograms.
-- create_encrypted_json(id) maps helper ids to ORE rows at id * 10 (helper ids 1-99 →
-- ORE rows 10, 20, ..., 990).
--
-- Index terms per row: hm (hmac), b3 (blake3), bf (bloom filter), ob (ORE blocks), sv (STE vec)
-- Data generated via create_encrypted_json() from 004_install_test_helpers.sql.
--
-- Distribution:
--   Deterministic via setseed(0.42) — byte-identical across runs.
--   random()^2 produces a power-law skew: P(id=k) is proportional to 1/sqrt(k).
--   Top id gets ~5% of rows (~500); tail ids get ~0.5% each (~50). Ratio ~10x.
--   Three independent draws per row decorrelate the columns.

SELECT setseed(0.42);

INSERT INTO bench (encrypted_text, encrypted_int, encrypted_bigint)
SELECT
    create_encrypted_json(1 + floor(99 * power(random(), 2))::int),
    create_encrypted_json(1 + floor(99 * power(random(), 2))::int),
    create_encrypted_json(1 + floor(99 * power(random(), 2))::int)
FROM generate_series(1, 10000);
