-- Test EQL equality operators
-- Tests the = operator and eq() function for encrypted data

BEGIN;

-- Plan: count of tests to run
SELECT plan(13);

-- Setup test data
SELECT lives_ok(
    'SELECT create_table_with_encrypted()',
    'Should create table with encrypted column'
);

SELECT lives_ok(
    'SELECT seed_encrypted_json()',
    'Should seed encrypted data'
);

-- Test 1: eql_v2_encrypted = eql_v2_encrypted with unique index term (HMAC)
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(1, 'hm');

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE e = %L', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'eql_v2_encrypted = eql_v2_encrypted finds matching record with HMAC index'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 2: eql_v2_encrypted = eql_v2_encrypted with no match
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(91347, 'hm');

    PERFORM is_empty(
        format('SELECT e FROM encrypted WHERE e = %L', e),
        'eql_v2_encrypted = eql_v2_encrypted returns no result for non-matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 3: eql_v2.eq() function test
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(1)::jsonb-'ob';

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE eql_v2.eq(e, %L)', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'eql_v2.eq() finds matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 4: eql_v2.eq() with no match
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(91347)::jsonb-'ob';

    PERFORM is_empty(
        format('SELECT e FROM encrypted WHERE eql_v2.eq(e, %L)', e),
        'eql_v2.eq() returns no result for non-matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 5: eql_v2_encrypted = jsonb
DO $$
DECLARE
    e jsonb;
BEGIN
    e := create_encrypted_json(1)::jsonb-'ob';

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE e = %L::jsonb', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'eql_v2_encrypted = jsonb finds matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 6: jsonb = eql_v2_encrypted
DO $$
DECLARE
    e jsonb;
BEGIN
    e := create_encrypted_json(1)::jsonb-'ob';

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'jsonb = eql_v2_encrypted finds matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 7: Blake3 equality - eql_v2_encrypted = eql_v2_encrypted
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(1, 'b3');

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE e = %L', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'Blake3: eql_v2_encrypted = eql_v2_encrypted finds matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 8: Blake3 equality with no match
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(91347, 'b3');

    PERFORM is_empty(
        format('SELECT e FROM encrypted WHERE e = %L', e),
        'Blake3: eql_v2_encrypted = eql_v2_encrypted returns no result for non-matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 9: Blake3 eql_v2.eq() function
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(1, 'b3');

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE eql_v2.eq(e, %L)', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'Blake3: eql_v2.eq() finds matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 10: Blake3 eql_v2_encrypted = jsonb
DO $$
DECLARE
    e jsonb;
BEGIN
    e := create_encrypted_json(1, 'b3');

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE e = %L::jsonb', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'Blake3: eql_v2_encrypted = jsonb finds matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 11: Blake3 jsonb = eql_v2_encrypted
DO $$
DECLARE
    e jsonb;
BEGIN
    e := create_encrypted_json(1, 'b3');

    PERFORM results_eq(
        format('SELECT e FROM encrypted WHERE %L::jsonb = e', e),
        format('SELECT e FROM encrypted WHERE id = 1'),
        'Blake3: jsonb = eql_v2_encrypted finds matching record'
    );
END;
$$ LANGUAGE plpgsql;

-- Cleanup
SELECT lives_ok(
    'SELECT drop_table_with_encrypted()',
    'Should drop test table'
);

SELECT finish();
ROLLBACK;
