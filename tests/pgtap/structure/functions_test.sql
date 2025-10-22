-- Test EQL function structure
-- Verifies that key EQL functions exist with correct signatures

BEGIN;

-- Plan: count of tests to run
SELECT plan(9);

-- Test comparison functions
SELECT has_function(
    'eql_v2',
    'compare_blake3',
    ARRAY['eql_v2_encrypted', 'eql_v2_encrypted'],
    'compare_blake3 function should exist with correct signature'
);

SELECT function_returns(
    'eql_v2',
    'compare_blake3',
    ARRAY['eql_v2_encrypted', 'eql_v2_encrypted'],
    'integer',
    'compare_blake3 should return integer'
);

-- Test configuration management functions
SELECT has_function(
    'eql_v2',
    'diff_config',
    ARRAY['jsonb', 'jsonb'],
    'diff_config function should exist'
);

SELECT has_function(
    'eql_v2',
    'select_pending_columns',
    ARRAY[]::text[],
    'select_pending_columns function should exist'
);

SELECT has_function(
    'eql_v2',
    'select_target_columns',
    ARRAY[]::text[],
    'select_target_columns function should exist'
);

SELECT has_function(
    'eql_v2',
    'ready_for_encryption',
    ARRAY[]::text[],
    'ready_for_encryption function should exist'
);

SELECT function_returns(
    'eql_v2',
    'ready_for_encryption',
    ARRAY[]::text[],
    'boolean',
    'ready_for_encryption should return boolean'
);

-- Test table management functions
SELECT has_function(
    'eql_v2',
    'create_encrypted_columns',
    ARRAY[]::text[],
    'create_encrypted_columns function should exist'
);

-- Verify eql_v2 schema has functions
SELECT isnt_empty(
    $$SELECT p.proname
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'eql_v2'$$,
    'eql_v2 schema should contain functions'
);

SELECT finish();
ROLLBACK;
