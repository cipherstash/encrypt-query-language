-- Test EQL JSONB operators
-- Tests ->, ->>, @>, <@ operators for encrypted data

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

-- Test 1: -> operator extracts encrypted term by selector
DO $$
BEGIN
    PERFORM isnt_empty(
        $$SELECT e->'bca213de9ccce676fa849ff9c4807963'::text FROM encrypted$$,
        'Selector -> operator returns encrypted terms'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 2: -> operator returns correct count
DO $$
BEGIN
    PERFORM cmp_ok(
        (SELECT count(*) FROM encrypted WHERE e->'bca213de9ccce676fa849ff9c4807963'::text IS NOT NULL),
        '>=',
        1::bigint,
        'Selector -> operator returns expected number of results'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 3: -> operator returns NULL for unknown selector
DO $$
BEGIN
    PERFORM is(
        (SELECT e->'blahvtha'::text FROM encrypted LIMIT 1),
        NULL,
        'Unknown selector -> operator returns NULL'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 4: -> operator accepts eql_v2_encrypted as selector
DO $$
DECLARE
    term text;
BEGIN
    term := '{"s": "bca213de9ccce676fa849ff9c4807963"}';

    PERFORM isnt_empty(
        format('SELECT e->%L::jsonb::eql_v2_encrypted FROM encrypted', term),
        'Selector -> operator works with eql_v2_encrypted selector'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 5: ->> operator extracts text value
DO $$
BEGIN
    PERFORM isnt_empty(
        $$SELECT e->>'bca213de9ccce676fa849ff9c4807963'::text FROM encrypted$$,
        'Text extraction operator ->> returns values'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 6: @> operator - eql_v2_encrypted contains itself
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
BEGIN
    a := get_numeric_ste_vec_10()::eql_v2_encrypted;
    b := get_numeric_ste_vec_10()::eql_v2_encrypted;

    PERFORM ok(
        a @> b,
        '@> operator: eql_v2_encrypted contains itself'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 7: @> operator - reverse containment
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
BEGIN
    a := get_numeric_ste_vec_10()::eql_v2_encrypted;
    b := get_numeric_ste_vec_10()::eql_v2_encrypted;

    PERFORM ok(
        b @> a,
        '@> operator: reverse containment works'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 8: @> operator - contains term
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
    term eql_v2_encrypted;
BEGIN
    a := get_numeric_ste_vec_10()::eql_v2_encrypted;
    b := get_numeric_ste_vec_10()::eql_v2_encrypted;

    -- Extract term at $.n
    term := b->'2517068c0d1f9d4d41d2c666211f785e'::text;

    PERFORM ok(
        a @> term,
        '@> operator: eql_v2_encrypted contains term'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 9: @> operator - term does not contain parent
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
    term eql_v2_encrypted;
BEGIN
    a := get_numeric_ste_vec_10()::eql_v2_encrypted;
    b := get_numeric_ste_vec_10()::eql_v2_encrypted;

    -- Extract term at $.n
    term := b->'2517068c0d1f9d4d41d2c666211f785e'::text;

    PERFORM ok(
        NOT (term @> a),
        '@> operator: term does not contain parent'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 10: <@ operator - contained by relationship
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
    term eql_v2_encrypted;
BEGIN
    a := get_numeric_ste_vec_10()::eql_v2_encrypted;
    b := get_numeric_ste_vec_10()::eql_v2_encrypted;

    -- Extract term at $.n
    term := b->'2517068c0d1f9d4d41d2c666211f785e'::text;

    PERFORM ok(
        term <@ a,
        '<@ operator: term is contained by parent'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 11: Extract ciphertext via selector
DO $$
BEGIN
    PERFORM isnt_empty(
        $$SELECT eql_v2.ciphertext(e->'2517068c0d1f9d4d41d2c666211f785e'::text) FROM encrypted$$,
        'Can extract ciphertext via selector'
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
