-- Test EQL schema structure
-- Verifies that the eql_v2 schema, types, and configuration table exist

BEGIN;

-- Plan: count of tests to run
SELECT plan(10);

-- Test 1: Schema exists
SELECT has_schema('eql_v2', 'Schema eql_v2 should exist');

-- Test 2: Encrypted column type exists
SELECT has_type('public', 'eql_v2_encrypted', 'Encrypted column type should exist');

-- Test 3: Configuration table exists
SELECT has_table('public', 'eql_v2_configuration', 'Configuration table should exist');

-- Test 4-6: Configuration table columns exist
SELECT has_column('public', 'eql_v2_configuration', 'id', 'Configuration table has id column');
SELECT has_column('public', 'eql_v2_configuration', 'state', 'Configuration table has state column');
SELECT has_column('public', 'eql_v2_configuration', 'data', 'Configuration table has data column');

-- Test 7-9: Configuration table column types
SELECT col_type_is('public', 'eql_v2_configuration', 'id', 'bigint', 'id column is bigint');
SELECT col_type_is('public', 'eql_v2_configuration', 'state', 'eql_v2_configuration_state', 'state column is eql_v2_configuration_state');
SELECT col_type_is('public', 'eql_v2_configuration', 'data', 'jsonb', 'data column is jsonb');

-- Test 10: eql_v2_encrypted is a composite type
SELECT has_type('public', 'eql_v2_encrypted', 'eql_v2_encrypted type exists');

SELECT finish();
ROLLBACK;
