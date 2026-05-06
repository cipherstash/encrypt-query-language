-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/operators/compare.sql
-- REQUIRE: src/operators/order_by.sql

--! @file operators/sort.sql
--! @brief Comparison-based sorting functions for encrypted values without operator classes
--!
--! Provides O(n log n) quicksort-based sorting using eql_v2.compare() for environments
--! where btree operator classes are unavailable (e.g., Supabase). This is significantly
--! faster than the O(n^2) correlated subquery workaround.


--! @internal
--! @brief Compare pre-extracted ORE order keys with encrypted NULL semantics
--!
--! Mirrors eql_v2.compare() for NULL handling, then delegates to the
--! ore_block_u64_8_256 comparator when both keys are present.
--!
--! @param a eql_v2.ore_block_u64_8_256 First order key
--! @param b eql_v2.ore_block_u64_8_256 Second order key
--! @return integer -1 if a < b, 0 if a = b, 1 if a > b
CREATE FUNCTION eql_v2._compare_order_key(
    a eql_v2.ore_block_u64_8_256,
    b eql_v2.ore_block_u64_8_256
)
RETURNS integer
IMMUTABLE PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
    IF a IS NULL AND b IS NULL THEN
        RETURN 0;
    END IF;

    IF a IS NULL THEN
        RETURN -1;
    END IF;

    IF b IS NULL THEN
        RETURN 1;
    END IF;

    RETURN eql_v2.compare_ore_block_u64_8_256_terms(a, b);
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief Compare two elements from aligned arrays using generic or ORE-key ordering
CREATE FUNCTION eql_v2._compare_sort_elements(
    vals eql_v2_encrypted[],
    keys eql_v2.ore_block_u64_8_256[],
    left_idx integer,
    right_idx integer,
    use_ore boolean
)
RETURNS integer
IMMUTABLE PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
    IF use_ore THEN
        RETURN eql_v2._compare_order_key(keys[left_idx], keys[right_idx]);
    END IF;

    RETURN eql_v2.compare(vals[left_idx], vals[right_idx]);
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief Compare an array element against a captured pivot value or ORE key
--!
--! @param vals eql_v2_encrypted[] Array of encrypted values
--! @param keys eql_v2.ore_block_u64_8_256[] Array of pre-extracted ORE order keys
--! @param idx integer Index of the element to compare
--! @param pivot_val eql_v2_encrypted Pivot encrypted value (used when use_ore is false)
--! @param pivot_key eql_v2.ore_block_u64_8_256 Pivot ORE key (used when use_ore is true)
--! @param use_ore boolean When true compare ORE keys, otherwise compare encrypted values
--! @return integer -1 if element < pivot, 0 if equal, 1 if element > pivot
CREATE FUNCTION eql_v2._compare_sort_pivot(
    vals eql_v2_encrypted[],
    keys eql_v2.ore_block_u64_8_256[],
    idx integer,
    pivot_val eql_v2_encrypted,
    pivot_key eql_v2.ore_block_u64_8_256,
    use_ore boolean
)
RETURNS integer
IMMUTABLE PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
    IF use_ore THEN
        RETURN eql_v2._compare_order_key(keys[idx], pivot_key);
    END IF;

    RETURN eql_v2.compare(vals[idx], pivot_val);
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief In-place insertion sort on parallel id/value/key arrays
--!
--! @param ids bigint[] Array of row identifiers (reordered in place)
--! @param vals eql_v2_encrypted[] Array of encrypted values (reordered in place)
--! @param keys eql_v2.ore_block_u64_8_256[] Array of pre-extracted ORE order keys (reordered in place)
--! @param lo integer Lower bound index (1-based, inclusive)
--! @param hi integer Upper bound index (1-based, inclusive)
--! @param use_ore boolean When true compare ORE keys, otherwise compare encrypted values
--! @return ids bigint[] Sorted array of row identifiers
--! @return vals eql_v2_encrypted[] Sorted array of encrypted values
--! @return keys eql_v2.ore_block_u64_8_256[] Sorted array of pre-extracted order keys
CREATE FUNCTION eql_v2._insertion_sort(
    INOUT ids bigint[],
    INOUT vals eql_v2_encrypted[],
    INOUT keys eql_v2.ore_block_u64_8_256[],
    lo integer,
    hi integer,
    use_ore boolean
)
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    i integer;
    j integer;
    key_id bigint;
    key_val eql_v2_encrypted;
    sort_key eql_v2.ore_block_u64_8_256;
BEGIN
    IF lo >= hi THEN
        RETURN;
    END IF;

    FOR i IN lo + 1..hi LOOP
        key_id := ids[i];
        key_val := vals[i];
        sort_key := keys[i];
        j := i - 1;

        WHILE j >= lo LOOP
            EXIT WHEN use_ore = FALSE AND eql_v2.compare(vals[j], key_val) <= 0;
            EXIT WHEN use_ore = TRUE AND eql_v2._compare_order_key(keys[j], sort_key) <= 0;

            ids[j + 1] := ids[j];
            vals[j + 1] := vals[j];
            keys[j + 1] := keys[j];
            j := j - 1;
        END LOOP;

        ids[j + 1] := key_id;
        vals[j + 1] := key_val;
        keys[j + 1] := sort_key;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief In-place quicksort on parallel id/value/key arrays
--!
--! Sorts aligned arrays simultaneously using Hoare partition with median-of-three pivot
--! selection. The median-of-three strategy avoids O(n^2) degradation on already-sorted
--! input, which is common with sequential test data.
--!
--! @param ids bigint[] Array of row identifiers (reordered in place)
--! @param vals eql_v2_encrypted[] Array of encrypted values to compare (reordered in place)
--! @param keys eql_v2.ore_block_u64_8_256[] Optional pre-extracted order keys (reordered in place)
--! @param lo integer Lower bound index (1-based, inclusive)
--! @param hi integer Upper bound index (1-based, inclusive)
--! @param use_ore boolean When true compare keys, otherwise compare vals
--!
--! @return ids bigint[] Sorted array of row identifiers
--! @return vals eql_v2_encrypted[] Sorted array of encrypted values
--! @return keys eql_v2.ore_block_u64_8_256[] Sorted array of pre-extracted order keys
CREATE FUNCTION eql_v2._quicksort_sorter(
    INOUT ids bigint[],
    INOUT vals eql_v2_encrypted[],
    INOUT keys eql_v2.ore_block_u64_8_256[],
    lo integer,
    hi integer,
    use_ore boolean
)
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    insertion_threshold CONSTANT integer := 16;
    pivot_val eql_v2_encrypted;
    pivot_key eql_v2.ore_block_u64_8_256;
    mid integer;
    i integer;
    j integer;
    left_hi integer;
    right_lo integer;
    tmp_id bigint;
    tmp_val eql_v2_encrypted;
    tmp_key eql_v2.ore_block_u64_8_256;
BEGIN
    WHILE lo < hi LOOP
        IF hi - lo <= insertion_threshold THEN
            SELECT q.ids, q.vals, q.keys INTO ids, vals, keys
                FROM eql_v2._insertion_sort(ids, vals, keys, lo, hi, use_ore) q;
            RETURN;
        END IF;

        -- Median-of-three pivot selection: sort lo, mid, hi then use mid as pivot
        mid := lo + (hi - lo) / 2;

        IF eql_v2._compare_sort_elements(vals, keys, lo, mid, use_ore) > 0 THEN
            tmp_id := ids[lo]; ids[lo] := ids[mid]; ids[mid] := tmp_id;
            tmp_val := vals[lo]; vals[lo] := vals[mid]; vals[mid] := tmp_val;
            tmp_key := keys[lo]; keys[lo] := keys[mid]; keys[mid] := tmp_key;
        END IF;
        IF eql_v2._compare_sort_elements(vals, keys, lo, hi, use_ore) > 0 THEN
            tmp_id := ids[lo]; ids[lo] := ids[hi]; ids[hi] := tmp_id;
            tmp_val := vals[lo]; vals[lo] := vals[hi]; vals[hi] := tmp_val;
            tmp_key := keys[lo]; keys[lo] := keys[hi]; keys[hi] := tmp_key;
        END IF;
        IF eql_v2._compare_sort_elements(vals, keys, mid, hi, use_ore) > 0 THEN
            tmp_id := ids[mid]; ids[mid] := ids[hi]; ids[hi] := tmp_id;
            tmp_val := vals[mid]; vals[mid] := vals[hi]; vals[hi] := tmp_val;
            tmp_key := keys[mid]; keys[mid] := keys[hi]; keys[hi] := tmp_key;
        END IF;

        pivot_val := vals[mid];
        pivot_key := keys[mid];
        i := lo;
        j := hi;

        LOOP
            WHILE eql_v2._compare_sort_pivot(vals, keys, i, pivot_val, pivot_key, use_ore) < 0 LOOP
                i := i + 1;
            END LOOP;
            WHILE eql_v2._compare_sort_pivot(vals, keys, j, pivot_val, pivot_key, use_ore) > 0 LOOP
                j := j - 1;
            END LOOP;

            EXIT WHEN i >= j;

            tmp_id := ids[i]; ids[i] := ids[j]; ids[j] := tmp_id;
            tmp_val := vals[i]; vals[i] := vals[j]; vals[j] := tmp_val;
            tmp_key := keys[i]; keys[i] := keys[j]; keys[j] := tmp_key;

            i := i + 1;
            j := j - 1;
        END LOOP;

        left_hi := j;
        right_lo := j + 1;

        IF left_hi - lo < hi - right_lo THEN
            IF lo < left_hi THEN
                SELECT q.ids, q.vals, q.keys INTO ids, vals, keys
                    FROM eql_v2._quicksort_sorter(ids, vals, keys, lo, left_hi, use_ore) q;
            END IF;
            lo := right_lo;
        ELSE
            IF right_lo < hi THEN
                SELECT q.ids, q.vals, q.keys INTO ids, vals, keys
                    FROM eql_v2._quicksort_sorter(ids, vals, keys, right_lo, hi, use_ore) q;
            END IF;
            hi := left_hi;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief Emit aligned arrays as rows in ASC or DESC order
--!
--! @param ids bigint[] Array of sorted row identifiers
--! @param vals eql_v2_encrypted[] Array of sorted encrypted values
--! @param direction text Sort direction: 'ASC' (default) or 'DESC'
--! @return TABLE(id bigint, val eql_v2_encrypted) Rows emitted in the requested order
CREATE FUNCTION eql_v2._emit_sorted_rows(
    ids bigint[],
    vals eql_v2_encrypted[],
    direction text DEFAULT 'ASC'
)
RETURNS TABLE(id bigint, val eql_v2_encrypted)
IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    n integer;
    i integer;
BEGIN
    n := coalesce(array_length(ids, 1), 0);

    IF upper(direction) = 'DESC' THEN
        FOR i IN REVERSE n..1 LOOP
            id := ids[i];
            val := vals[i];
            RETURN NEXT;
        END LOOP;
    ELSE
        FOR i IN 1..n LOOP
            id := ids[i];
            val := vals[i];
            RETURN NEXT;
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief Sort encrypted values using precomputed ORE keys when available
--!
--! Shared implementation for public sorting entrypoints. When `use_ore` is true
--! the caller must provide an aligned `keys` array; otherwise `eql_v2.compare()`
--! is used on the encrypted values directly.
CREATE FUNCTION eql_v2._sort_compare_precomputed(
    ids bigint[],
    vals eql_v2_encrypted[],
    keys eql_v2.ore_block_u64_8_256[],
    direction text DEFAULT 'ASC',
    use_ore boolean DEFAULT true
)
RETURNS TABLE(id bigint, val eql_v2_encrypted)
IMMUTABLE PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    n integer;
    m integer;
    k integer;
    sorted_ids bigint[];
    sorted_vals eql_v2_encrypted[];
    sorted_keys eql_v2.ore_block_u64_8_256[];
BEGIN
    n := coalesce(array_length(ids, 1), 0);
    m := coalesce(array_length(vals, 1), 0);

    IF n <> m THEN
        RAISE EXCEPTION 'ids and vals must have the same length';
    END IF;

    IF use_ore THEN
        k := coalesce(array_length(keys, 1), 0);
        IF n <> k THEN
            RAISE EXCEPTION 'ids and keys must have the same length when use_ore is true';
        END IF;
    END IF;

    IF n = 0 THEN
        RETURN;
    END IF;

    IF n = 1 THEN
        id := ids[1];
        val := vals[1];
        RETURN NEXT;
        RETURN;
    END IF;

    SELECT q.ids, q.vals, q.keys INTO sorted_ids, sorted_vals, sorted_keys
        FROM eql_v2._quicksort_sorter(ids, vals, keys, 1, n, use_ore) q;

    RETURN QUERY
        SELECT emitted.id, emitted.val
        FROM eql_v2._emit_sorted_rows(sorted_ids, sorted_vals, direction) emitted;
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
--!   (SELECT array_agg(id ORDER BY id) FROM ore),
--!   (SELECT array_agg(e ORDER BY id) FROM ore),
--!   'ASC'
--! );
--!
--! -- Sort with a filter
--! SELECT * FROM eql_v2.sort_compare(
--!   (SELECT array_agg(id ORDER BY id) FROM ore WHERE id > 42),
--!   (SELECT array_agg(e ORDER BY id) FROM ore WHERE id > 42),
--!   'DESC'
--! );
--!
--! -- Compose with LIMIT
--! SELECT * FROM eql_v2.sort_compare(
--!   (SELECT array_agg(id ORDER BY id) FROM ore),
--!   (SELECT array_agg(e ORDER BY id) FROM ore)
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
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    n integer;
    sorted_keys eql_v2.ore_block_u64_8_256[];
    i integer;
    use_ore boolean := true;
BEGIN
    n := coalesce(array_length(ids, 1), 0);

    FOR i IN 1..n LOOP
        IF vals[i] IS NULL THEN
            sorted_keys[i] := NULL;
        ELSIF eql_v2.has_ore_block_u64_8_256(vals[i]) THEN
            sorted_keys[i] := eql_v2.order_by(vals[i]);
        ELSE
            use_ore := false;
            EXIT;
        END IF;
    END LOOP;

    RETURN QUERY
        SELECT sc.id, sc.val
        FROM eql_v2._sort_compare_precomputed(ids, vals, sorted_keys, direction, use_ore) sc;
END;
$$ LANGUAGE plpgsql;


--! @brief Sort encrypted values from a table using column and table references
--!
--! Convenience overload that accepts column names, a table name, and an optional
--! filter clause instead of pre-aggregated arrays. Internally constructs the
--! query and delegates to eql_v2.order_by_compare().
--!
--! @param id_column text Name of the bigint identifier column
--! @param val_column text Name of the eql_v2_encrypted value column
--! @param tbl text Table name (may be schema-qualified)
--! @param direction text Sort direction: 'ASC' (default) or 'DESC'
--! @param filter text Optional WHERE clause (without the WHERE keyword)
--! @return TABLE(id bigint, val eql_v2_encrypted) Sorted rows
--!
--! @note The id column must be castable to bigint. Uses dynamic SQL internally.
--! @warning The filter parameter is executed as dynamic SQL. Use only with trusted input.
--!
--! @example
--! -- Sort all rows ascending (default)
--! SELECT * FROM eql_v2.sort_compare('id', 'e', 'ore');
--!
--! -- Sort descending
--! SELECT * FROM eql_v2.sort_compare('id', 'e', 'ore', 'DESC');
--!
--! -- Sort with a filter
--! SELECT * FROM eql_v2.sort_compare('id', 'e', 'ore', 'ASC', 'id > 42');
--!
--! -- Compose with LIMIT
--! SELECT * FROM eql_v2.sort_compare('id', 'e', 'ore') LIMIT 10;
--!
--! @see eql_v2.sort_compare(bigint[], eql_v2_encrypted[], text)
--! @see eql_v2.order_by_compare
CREATE FUNCTION eql_v2.sort_compare(
    id_column text,
    val_column text,
    tbl text,
    direction text DEFAULT 'ASC',
    filter text DEFAULT NULL
)
RETURNS TABLE(id bigint, val eql_v2_encrypted)
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    query text;
    resolved_tbl regclass;
BEGIN
    resolved_tbl := to_regclass(tbl);

    IF resolved_tbl IS NULL THEN
        RAISE EXCEPTION 'table "%" does not exist', tbl;
    END IF;

    query := format('SELECT %I, %I FROM %s', id_column, val_column, resolved_tbl);

    IF filter IS NOT NULL THEN
        query := query || ' WHERE ' || filter;
    END IF;

    RETURN QUERY
        SELECT sc.id, sc.val
        FROM eql_v2.order_by_compare(query, direction) sc;
END;
$$ LANGUAGE plpgsql;


--! @brief Sort encrypted values from a query using comparison-based quicksort
--!
--! Convenience wrapper that accepts a SQL query string, executes it, collects the
--! results, and returns them sorted. For ORE-backed values this pre-extracts the
--! order key once per row and sorts on that key; other values fall back to
--! eql_v2.compare(). The query must return
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
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    all_ids bigint[];
    all_vals eql_v2_encrypted[];
    all_keys eql_v2.ore_block_u64_8_256[];
    all_have_order_keys boolean;
BEGIN
    EXECUTE format(
        'WITH input_rows AS (
            SELECT row_number() OVER () AS ord,
                   sub.id,
                   sub.val,
                   CASE
                       WHEN sub.val IS NULL THEN NULL
                       WHEN eql_v2.has_ore_block_u64_8_256(sub.val) THEN eql_v2.order_by(sub.val)
                       ELSE NULL
                   END AS sort_key,
                   CASE
                       WHEN sub.val IS NULL THEN TRUE
                       ELSE eql_v2.has_ore_block_u64_8_256(sub.val)
                   END AS has_order_key
            FROM (%s) sub(id, val)
         )
         SELECT array_agg(id ORDER BY ord),
                array_agg(val ORDER BY ord),
                array_agg(sort_key ORDER BY ord),
                coalesce(bool_and(has_order_key), TRUE)
         FROM input_rows',
        query
    ) INTO all_ids, all_vals, all_keys, all_have_order_keys;

    IF all_ids IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
        SELECT sc.id, sc.val
        FROM eql_v2._sort_compare_precomputed(
            all_ids,
            all_vals,
            all_keys,
            direction,
            all_have_order_keys
        ) sc;
END;
$$ LANGUAGE plpgsql;
