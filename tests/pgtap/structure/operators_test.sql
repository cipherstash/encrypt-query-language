-- Test EQL operator structure
-- Verifies that operators exist for eql_v2_encrypted type

BEGIN;

-- Plan: count of tests to run
SELECT plan(1);

-- Test that operators exist for eql_v2_encrypted type
-- Operators are defined in the public schema
SELECT ok(
    (SELECT count(*) FROM pg_operator o
     JOIN pg_type t1 ON o.oprleft = t1.oid
     WHERE t1.typname = 'eql_v2_encrypted') >= 10,
    'At least 10 operators should exist for eql_v2_encrypted type'
);

SELECT finish();
ROLLBACK;
