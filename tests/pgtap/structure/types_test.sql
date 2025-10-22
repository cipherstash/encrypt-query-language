-- Test EQL type structure
-- Verifies that all index term types exist in the eql_v2 schema

BEGIN;

-- Plan: count of tests to run
SELECT plan(7);

-- Test index term types exist
SELECT has_type('eql_v2', 'blake3', 'blake3 index term type should exist');
SELECT has_type('eql_v2', 'hmac_256', 'hmac_256 index term type should exist');
SELECT has_type('eql_v2', 'bloom_filter', 'bloom_filter index term type should exist');
SELECT has_type('eql_v2', 'ore_cllw_u64_8', 'ore_cllw_u64_8 index term type should exist');
SELECT has_type('eql_v2', 'ore_cllw_var_8', 'ore_cllw_var_8 index term type should exist');
SELECT has_type('eql_v2', 'ore_block_u64_8_256', 'ore_block_u64_8_256 index term type should exist');
SELECT has_type('eql_v2', 'ore_block_u64_8_256_term', 'ore_block_u64_8_256_term index term type should exist');

SELECT finish();
ROLLBACK;
