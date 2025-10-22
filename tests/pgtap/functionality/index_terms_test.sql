-- Test EQL index term comparison functions
-- Tests blake3, hmac_256, and ORE comparison functions

BEGIN;

-- Plan: count of tests to run
SELECT plan(27);

-- Test 1-9: Blake3 comparison function
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
    c eql_v2_encrypted;
BEGIN
    a := create_encrypted_json(1, 'b3');
    b := create_encrypted_json(2, 'b3');
    c := create_encrypted_json(3, 'b3');

    -- Test equality
    PERFORM is(
        eql_v2.compare_blake3(a, a),
        0,
        'Blake3: compare_blake3(a, a) = 0 (equal)'
    );

    PERFORM is(
        eql_v2.compare_blake3(b, b),
        0,
        'Blake3: compare_blake3(b, b) = 0 (equal)'
    );

    PERFORM is(
        eql_v2.compare_blake3(c, c),
        0,
        'Blake3: compare_blake3(c, c) = 0 (equal)'
    );

    -- Test less than
    PERFORM is(
        eql_v2.compare_blake3(a, b),
        -1,
        'Blake3: compare_blake3(a, b) = -1 (a < b)'
    );

    PERFORM is(
        eql_v2.compare_blake3(a, c),
        -1,
        'Blake3: compare_blake3(a, c) = -1 (a < c)'
    );

    PERFORM is(
        eql_v2.compare_blake3(b, c),
        -1,
        'Blake3: compare_blake3(b, c) = -1 (b < c)'
    );

    -- Test greater than
    PERFORM is(
        eql_v2.compare_blake3(b, a),
        1,
        'Blake3: compare_blake3(b, a) = 1 (b > a)'
    );

    PERFORM is(
        eql_v2.compare_blake3(c, a),
        1,
        'Blake3: compare_blake3(c, a) = 1 (c > a)'
    );

    PERFORM is(
        eql_v2.compare_blake3(c, b),
        1,
        'Blake3: compare_blake3(c, b) = 1 (c > b)'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 10-18: HMAC-256 comparison function
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
    c eql_v2_encrypted;
BEGIN
    a := create_encrypted_json(1, 'hm');
    b := create_encrypted_json(2, 'hm');
    c := create_encrypted_json(3, 'hm');

    -- Test equality
    PERFORM is(
        eql_v2.compare_hmac_256(a, a),
        0,
        'HMAC-256: compare_hmac_256(a, a) = 0 (equal)'
    );

    PERFORM is(
        eql_v2.compare_hmac_256(b, b),
        0,
        'HMAC-256: compare_hmac_256(b, b) = 0 (equal)'
    );

    PERFORM is(
        eql_v2.compare_hmac_256(c, c),
        0,
        'HMAC-256: compare_hmac_256(c, c) = 0 (equal)'
    );

    -- Test less than
    PERFORM is(
        eql_v2.compare_hmac_256(a, b),
        -1,
        'HMAC-256: compare_hmac_256(a, b) = -1 (a < b)'
    );

    PERFORM is(
        eql_v2.compare_hmac_256(a, c),
        -1,
        'HMAC-256: compare_hmac_256(a, c) = -1 (a < c)'
    );

    PERFORM is(
        eql_v2.compare_hmac_256(b, c),
        -1,
        'HMAC-256: compare_hmac_256(b, c) = -1 (b < c)'
    );

    -- Test greater than
    PERFORM is(
        eql_v2.compare_hmac_256(b, a),
        1,
        'HMAC-256: compare_hmac_256(b, a) = 1 (b > a)'
    );

    PERFORM is(
        eql_v2.compare_hmac_256(c, a),
        1,
        'HMAC-256: compare_hmac_256(c, a) = 1 (c > a)'
    );

    PERFORM is(
        eql_v2.compare_hmac_256(c, b),
        1,
        'HMAC-256: compare_hmac_256(c, b) = 1 (c > b)'
    );
END;
$$ LANGUAGE plpgsql;

-- Test 19-27: ORE comparison functions
DO $$
DECLARE
    a eql_v2_encrypted;
    b eql_v2_encrypted;
    c eql_v2_encrypted;
BEGIN
    a := create_encrypted_ore_json(1);
    b := create_encrypted_ore_json(2);
    c := create_encrypted_ore_json(3);

    -- Test equality with compare function
    PERFORM is(
        eql_v2.compare(a, a),
        0,
        'ORE: compare(a, a) = 0 (equal)'
    );

    PERFORM is(
        eql_v2.compare(b, b),
        0,
        'ORE: compare(b, b) = 0 (equal)'
    );

    PERFORM is(
        eql_v2.compare(c, c),
        0,
        'ORE: compare(c, c) = 0 (equal)'
    );

    -- Test less than
    PERFORM is(
        eql_v2.compare(a, b),
        -1,
        'ORE: compare(a, b) = -1 (a < b)'
    );

    PERFORM is(
        eql_v2.compare(a, c),
        -1,
        'ORE: compare(a, c) = -1 (a < c)'
    );

    PERFORM is(
        eql_v2.compare(b, c),
        -1,
        'ORE: compare(b, c) = -1 (b < c)'
    );

    -- Test greater than
    PERFORM is(
        eql_v2.compare(b, a),
        1,
        'ORE: compare(b, a) = 1 (b > a)'
    );

    PERFORM is(
        eql_v2.compare(c, a),
        1,
        'ORE: compare(c, a) = 1 (c > a)'
    );

    PERFORM is(
        eql_v2.compare(c, b),
        1,
        'ORE: compare(c, b) = 1 (c > b)'
    );
END;
$$ LANGUAGE plpgsql;

SELECT finish();
ROLLBACK;
