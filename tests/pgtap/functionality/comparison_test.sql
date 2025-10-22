-- Test EQL comparison operators
-- Tests <, <=, >, >= operators for encrypted data with ORE indexes

BEGIN;

-- Plan: count of tests to run
SELECT plan(12);

-- Setup test data
SELECT lives_ok(
    'SELECT create_table_with_encrypted()',
    'Should create table with encrypted column'
);

SELECT lives_ok(
    'SELECT seed_encrypted_json()',
    'Should seed encrypted data'
);

-- Test 1: Less than operator with ORE index
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(42);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE e < e) >= 1,
        'Less than operator < works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 2: Less than or equal operator with ORE index
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(42);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE e <= e) >= 1,
        'Less than or equal operator <= works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 3: Greater than operator with ORE index
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(1);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE e > e) >= 1,
        'Greater than operator > works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 4: Greater than or equal operator with ORE index
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(1);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE e >= e) >= 1,
        'Greater than or equal operator >= works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 5: Not equal operator
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(1, 'hm');

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE e <> e) >= 1,
        'Not equal operator <> works with encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 6: eql_v2.lt() function
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(42);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE eql_v2.lt(e, e)) >= 1,
        'eql_v2.lt() function works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 7: eql_v2.lte() function
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(42);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE eql_v2.lte(e, e)) >= 1,
        'eql_v2.lte() function works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 8: eql_v2.gt() function
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(1);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE eql_v2.gt(e, e)) >= 1,
        'eql_v2.gt() function works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 9: eql_v2.gte() function
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_ore_json(1);

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE eql_v2.gte(e, e)) >= 1,
        'eql_v2.gte() function works with ORE encrypted data'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 10: eql_v2.neq() function
DO $$
DECLARE
    e eql_v2_encrypted;
BEGIN
    e := create_encrypted_json(1, 'hm');

    PERFORM ok(
        (SELECT count(*) FROM encrypted WHERE eql_v2.neq(e, e)) >= 1,
        'eql_v2.neq() function works with encrypted data'
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
