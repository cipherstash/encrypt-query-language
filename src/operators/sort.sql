-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/operators/compare.sql

--! @file operators/sort.sql
--! @brief Comparison-based sorting functions for encrypted values without operator classes
--!
--! Provides O(n log n) quicksort-based sorting using eql_v2.compare() for environments
--! where btree operator classes are unavailable (e.g., Supabase). This is significantly
--! faster than the O(n^2) correlated subquery workaround.


--! @internal
--! @brief In-place quicksort on parallel id/value arrays using encrypted comparison
--!
--! Sorts both arrays simultaneously using Hoare partition with median-of-three pivot
--! selection. The median-of-three strategy avoids O(n^2) degradation on already-sorted
--! input, which is common with sequential test data.
--!
--! @param ids bigint[] Array of row identifiers (reordered in place)
--! @param vals eql_v2_encrypted[] Array of encrypted values to compare (reordered in place)
--! @param lo integer Lower bound index (1-based, inclusive)
--! @param hi integer Upper bound index (1-based, inclusive)
--!
--! @return ids bigint[] Sorted array of row identifiers
--! @return vals eql_v2_encrypted[] Sorted array of encrypted values
CREATE FUNCTION eql_v2._quicksort_compare(
    INOUT ids bigint[],
    INOUT vals eql_v2_encrypted[],
    lo integer,
    hi integer
)
AS $$
DECLARE
    pivot eql_v2_encrypted;
    mid integer;
    i integer;
    j integer;
    tmp_id bigint;
    tmp_val eql_v2_encrypted;
BEGIN
    IF lo >= hi THEN
        RETURN;
    END IF;

    -- Median-of-three pivot selection: sort lo, mid, hi then use mid as pivot
    mid := lo + (hi - lo) / 2;

    IF eql_v2.compare(vals[lo], vals[mid]) > 0 THEN
        tmp_id := ids[lo]; ids[lo] := ids[mid]; ids[mid] := tmp_id;
        tmp_val := vals[lo]; vals[lo] := vals[mid]; vals[mid] := tmp_val;
    END IF;
    IF eql_v2.compare(vals[lo], vals[hi]) > 0 THEN
        tmp_id := ids[lo]; ids[lo] := ids[hi]; ids[hi] := tmp_id;
        tmp_val := vals[lo]; vals[lo] := vals[hi]; vals[hi] := tmp_val;
    END IF;
    IF eql_v2.compare(vals[mid], vals[hi]) > 0 THEN
        tmp_id := ids[mid]; ids[mid] := ids[hi]; ids[hi] := tmp_id;
        tmp_val := vals[mid]; vals[mid] := vals[hi]; vals[hi] := tmp_val;
    END IF;

    pivot := vals[mid];

    -- Hoare partition
    i := lo;
    j := hi;

    LOOP
        WHILE eql_v2.compare(vals[i], pivot) < 0 LOOP
            i := i + 1;
        END LOOP;
        WHILE eql_v2.compare(vals[j], pivot) > 0 LOOP
            j := j - 1;
        END LOOP;

        EXIT WHEN i >= j;

        tmp_id := ids[i]; ids[i] := ids[j]; ids[j] := tmp_id;
        tmp_val := vals[i]; vals[i] := vals[j]; vals[j] := tmp_val;

        i := i + 1;
        j := j - 1;
    END LOOP;

    -- Recurse on both partitions
    SELECT q.ids, q.vals INTO ids, vals
        FROM eql_v2._quicksort_compare(ids, vals, lo, j) q;
    SELECT q.ids, q.vals INTO ids, vals
        FROM eql_v2._quicksort_compare(ids, vals, j + 1, hi) q;
END;
$$ LANGUAGE plpgsql;


--! @brief Sort encrypted values using comparison-based quicksort
--!
--! Sorts parallel arrays of identifiers and encrypted values using O(n log n)
--! quicksort with eql_v2.compare(). Returns sorted rows as a table, avoiding
--! the need for unnest() or other array manipulation by callers.
--!
--! This function is designed for environments without operator classes (e.g., Supabase)
--! where direct ORDER BY on encrypted columns is not available.
--!
--! @param ids bigint[] Array of row identifiers
--! @param vals eql_v2_encrypted[] Array of encrypted values (must be same length as ids)
--! @param direction text Sort direction: 'ASC' (default) or 'DESC'
--! @return TABLE(id bigint, val eql_v2_encrypted) Sorted rows
--!
--! @example
--! -- Sort all rows from an encrypted table
--! SELECT * FROM eql_v2.sort_compare(
--!   (SELECT array_agg(id) FROM ore),
--!   (SELECT array_agg(e) FROM ore),
--!   'ASC'
--! );
--!
--! -- Sort with a filter
--! SELECT * FROM eql_v2.sort_compare(
--!   (SELECT array_agg(id) FROM ore WHERE id > 42),
--!   (SELECT array_agg(e) FROM ore WHERE id > 42),
--!   'DESC'
--! );
--!
--! -- Compose with LIMIT
--! SELECT * FROM eql_v2.sort_compare(
--!   (SELECT array_agg(id) FROM ore),
--!   (SELECT array_agg(e) FROM ore)
--! ) LIMIT 5;
--!
--! @see eql_v2.compare
--! @see eql_v2.order_by_compare
CREATE FUNCTION eql_v2.sort_compare(
    ids bigint[],
    vals eql_v2_encrypted[],
    direction text DEFAULT 'ASC'
)
RETURNS TABLE(id bigint, val eql_v2_encrypted)
IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
    n integer;
    sorted_ids bigint[];
    sorted_vals eql_v2_encrypted[];
    i integer;
BEGIN
    n := array_length(ids, 1);

    IF n IS NULL OR n = 0 THEN
        RETURN;
    END IF;

    IF n = 1 THEN
        id := ids[1];
        val := vals[1];
        RETURN NEXT;
        RETURN;
    END IF;

    SELECT q.ids, q.vals INTO sorted_ids, sorted_vals
        FROM eql_v2._quicksort_compare(ids, vals, 1, n) q;

    IF upper(direction) = 'DESC' THEN
        FOR i IN REVERSE n..1 LOOP
            id := sorted_ids[i];
            val := sorted_vals[i];
            RETURN NEXT;
        END LOOP;
    ELSE
        FOR i IN 1..n LOOP
            id := sorted_ids[i];
            val := sorted_vals[i];
            RETURN NEXT;
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;


--! @brief Sort encrypted values from a query using comparison-based quicksort
--!
--! Convenience wrapper that accepts a SQL query string, executes it, collects the
--! results, and returns them sorted using eql_v2.compare(). The query must return
--! exactly two columns: a bigint identifier and an eql_v2_encrypted value.
--!
--! @param query text SQL query returning (bigint, eql_v2_encrypted) columns
--! @param direction text Sort direction: 'ASC' (default) or 'DESC'
--! @return TABLE(id bigint, val eql_v2_encrypted) Sorted rows
--!
--! @note Uses dynamic SQL (EXECUTE) so cannot be IMMUTABLE or PARALLEL SAFE
--! @warning The query parameter is executed as dynamic SQL. Use only with trusted input.
--!
--! @example
--! -- Sort all rows
--! SELECT * FROM eql_v2.order_by_compare('SELECT id, e FROM ore');
--!
--! -- Sort with WHERE clause
--! SELECT * FROM eql_v2.order_by_compare(
--!   'SELECT id, e FROM ore WHERE id > 42',
--!   'DESC'
--! );
--!
--! @see eql_v2.sort_compare
--! @see eql_v2.compare
CREATE FUNCTION eql_v2.order_by_compare(
    query text,
    direction text DEFAULT 'ASC'
)
RETURNS TABLE(id bigint, val eql_v2_encrypted)
AS $$
DECLARE
    all_ids bigint[];
    all_vals eql_v2_encrypted[];
BEGIN
    EXECUTE format(
        'SELECT array_agg(sub.id), array_agg(sub.val) FROM (%s) sub(id, val)',
        query
    ) INTO all_ids, all_vals;

    RETURN QUERY SELECT sc.id, sc.val
        FROM eql_v2.sort_compare(all_ids, all_vals, direction) sc;
END;
$$ LANGUAGE plpgsql;
