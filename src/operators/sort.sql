-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ore_block_u64_8_256/types.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ope_cllw_u64_65/types.sql
-- REQUIRE: src/ope_cllw_u64_65/functions.sql
-- REQUIRE: src/ope_cllw_var_8/types.sql
-- REQUIRE: src/ope_cllw_var_8/functions.sql
-- REQUIRE: src/operators/compare.sql
-- REQUIRE: src/operators/order_by.sql

--! @file operators/sort.sql
--! @brief Comparison-based sorting functions for encrypted values without operator classes
--!
--! Provides O(n log n) quicksort-based sorting using eql_v2.compare() for environments
--! where btree operator classes are unavailable (e.g., Supabase). This is significantly
--! faster than the O(n^2) correlated subquery workaround.
--!
--! When all input rows share an ORE term (`ob`) the sort path pre-extracts the
--! ORE order key once per row and compares those keys directly. When all rows
--! share an OPE term (`opf` or `opv`) the OPE ciphertext is pre-extracted as
--! `bytea` and compared lexicographically (OPE ciphertexts are designed to be
--! ordered that way). Mixed inputs fall back to `eql_v2.compare()` per pair.


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
--! @brief Compare pre-extracted OPE ciphertext bytes with encrypted NULL semantics
--!
--! OPE ciphertexts are ordered lexicographically by construction, so once the
--! bytea has been extracted (via eql_v2.order_by_ope) we can dispatch directly
--! to the native bytea comparison operators.
--!
--! @param a bytea First OPE ciphertext (or NULL)
--! @param b bytea Second OPE ciphertext (or NULL)
--! @return integer -1 if a < b, 0 if a = b, 1 if a > b
CREATE FUNCTION eql_v2._compare_ope_key(
    a bytea,
    b bytea
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

    IF a < b THEN
        RETURN -1;
    ELSIF a > b THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief Compare two elements from aligned arrays using the selected sort strategy
--!
--! @param vals eql_v2_encrypted[] Encrypted values (used when strategy = 'compare')
--! @param ore_keys eql_v2.ore_block_u64_8_256[] Pre-extracted ORE keys (strategy = 'ore')
--! @param ope_keys bytea[] Pre-extracted OPE ciphertext bytes (strategy = 'ope')
--! @param left_idx integer Index of the left element
--! @param right_idx integer Index of the right element
--! @param strategy text One of 'ore', 'ope', or 'compare'
CREATE FUNCTION eql_v2._compare_sort_elements(
    vals eql_v2_encrypted[],
    ore_keys eql_v2.ore_block_u64_8_256[],
    ope_keys bytea[],
    left_idx integer,
    right_idx integer,
    strategy text
)
RETURNS integer
IMMUTABLE PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
    IF strategy = 'ore' THEN
        RETURN eql_v2._compare_order_key(ore_keys[left_idx], ore_keys[right_idx]);
    END IF;

    IF strategy = 'ope' THEN
        RETURN eql_v2._compare_ope_key(ope_keys[left_idx], ope_keys[right_idx]);
    END IF;

    RETURN eql_v2.compare(vals[left_idx], vals[right_idx]);
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief Compare an array element against a captured pivot using the selected strategy
--!
--! @param vals eql_v2_encrypted[] Array of encrypted values
--! @param ore_keys eql_v2.ore_block_u64_8_256[] Array of pre-extracted ORE keys
--! @param ope_keys bytea[] Array of pre-extracted OPE ciphertext bytes
--! @param idx integer Index of the element to compare
--! @param pivot_val eql_v2_encrypted Pivot encrypted value (strategy = 'compare')
--! @param pivot_ore_key eql_v2.ore_block_u64_8_256 Pivot ORE key (strategy = 'ore')
--! @param pivot_ope_key bytea Pivot OPE ciphertext bytes (strategy = 'ope')
--! @param strategy text One of 'ore', 'ope', or 'compare'
--! @return integer -1 if element < pivot, 0 if equal, 1 if element > pivot
CREATE FUNCTION eql_v2._compare_sort_pivot(
    vals eql_v2_encrypted[],
    ore_keys eql_v2.ore_block_u64_8_256[],
    ope_keys bytea[],
    idx integer,
    pivot_val eql_v2_encrypted,
    pivot_ore_key eql_v2.ore_block_u64_8_256,
    pivot_ope_key bytea,
    strategy text
)
RETURNS integer
IMMUTABLE PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
    IF strategy = 'ore' THEN
        RETURN eql_v2._compare_order_key(ore_keys[idx], pivot_ore_key);
    END IF;

    IF strategy = 'ope' THEN
        RETURN eql_v2._compare_ope_key(ope_keys[idx], pivot_ope_key);
    END IF;

    RETURN eql_v2.compare(vals[idx], pivot_val);
END;
$$ LANGUAGE plpgsql;


--! @internal
--! @brief In-place insertion sort on parallel id/value/key arrays
--!
--! @param ids bigint[] Array of row identifiers (reordered in place)
--! @param vals eql_v2_encrypted[] Array of encrypted values (reordered in place)
--! @param ore_keys eql_v2.ore_block_u64_8_256[] Array of pre-extracted ORE keys (reordered in place)
--! @param ope_keys bytea[] Array of pre-extracted OPE bytes (reordered in place)
--! @param lo integer Lower bound index (1-based, inclusive)
--! @param hi integer Upper bound index (1-based, inclusive)
--! @param strategy text One of 'ore', 'ope', or 'compare'
--! @return ids bigint[] Sorted array of row identifiers
--! @return vals eql_v2_encrypted[] Sorted array of encrypted values
--! @return ore_keys eql_v2.ore_block_u64_8_256[] Sorted array of pre-extracted ORE keys
--! @return ope_keys bytea[] Sorted array of pre-extracted OPE bytes
CREATE FUNCTION eql_v2._insertion_sort(
    INOUT ids bigint[],
    INOUT vals eql_v2_encrypted[],
    INOUT ore_keys eql_v2.ore_block_u64_8_256[],
    INOUT ope_keys bytea[],
    lo integer,
    hi integer,
    strategy text
)
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    i integer;
    j integer;
    key_id bigint;
    key_val eql_v2_encrypted;
    sort_ore_key eql_v2.ore_block_u64_8_256;
    sort_ope_key bytea;
BEGIN
    IF lo >= hi THEN
        RETURN;
    END IF;

    FOR i IN lo + 1..hi LOOP
        key_id := ids[i];
        key_val := vals[i];
        sort_ore_key := ore_keys[i];
        sort_ope_key := ope_keys[i];
        j := i - 1;

        WHILE j >= lo LOOP
            EXIT WHEN strategy = 'compare'
                AND eql_v2.compare(vals[j], key_val) <= 0;
            EXIT WHEN strategy = 'ore'
                AND eql_v2._compare_order_key(ore_keys[j], sort_ore_key) <= 0;
            EXIT WHEN strategy = 'ope'
                AND eql_v2._compare_ope_key(ope_keys[j], sort_ope_key) <= 0;

            ids[j + 1] := ids[j];
            vals[j + 1] := vals[j];
            ore_keys[j + 1] := ore_keys[j];
            ope_keys[j + 1] := ope_keys[j];
            j := j - 1;
        END LOOP;

        ids[j + 1] := key_id;
        vals[j + 1] := key_val;
        ore_keys[j + 1] := sort_ore_key;
        ope_keys[j + 1] := sort_ope_key;
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
--! @param ore_keys eql_v2.ore_block_u64_8_256[] Pre-extracted ORE keys (reordered in place)
--! @param ope_keys bytea[] Pre-extracted OPE ciphertext bytes (reordered in place)
--! @param lo integer Lower bound index (1-based, inclusive)
--! @param hi integer Upper bound index (1-based, inclusive)
--! @param strategy text One of 'ore', 'ope', or 'compare'
--!
--! @return ids bigint[] Sorted array of row identifiers
--! @return vals eql_v2_encrypted[] Sorted array of encrypted values
--! @return ore_keys eql_v2.ore_block_u64_8_256[] Sorted array of pre-extracted ORE keys
--! @return ope_keys bytea[] Sorted array of pre-extracted OPE bytes
CREATE FUNCTION eql_v2._quicksort_sorter(
    INOUT ids bigint[],
    INOUT vals eql_v2_encrypted[],
    INOUT ore_keys eql_v2.ore_block_u64_8_256[],
    INOUT ope_keys bytea[],
    lo integer,
    hi integer,
    strategy text
)
  SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
    insertion_threshold CONSTANT integer := 16;
    pivot_val eql_v2_encrypted;
    pivot_ore_key eql_v2.ore_block_u64_8_256;
    pivot_ope_key bytea;
    mid integer;
    i integer;
    j integer;
    left_hi integer;
    right_lo integer;
    tmp_id bigint;
    tmp_val eql_v2_encrypted;
    tmp_ore_key eql_v2.ore_block_u64_8_256;
    tmp_ope_key bytea;
BEGIN
    WHILE lo < hi LOOP
        IF hi - lo <= insertion_threshold THEN
            SELECT q.ids, q.vals, q.ore_keys, q.ope_keys
                INTO ids, vals, ore_keys, ope_keys
                FROM eql_v2._insertion_sort(ids, vals, ore_keys, ope_keys, lo, hi, strategy) q;
            RETURN;
        END IF;

        -- Median-of-three pivot selection: sort lo, mid, hi then use mid as pivot
        mid := lo + (hi - lo) / 2;

        IF eql_v2._compare_sort_elements(vals, ore_keys, ope_keys, lo, mid, strategy) > 0 THEN
            tmp_id := ids[lo]; ids[lo] := ids[mid]; ids[mid] := tmp_id;
            tmp_val := vals[lo]; vals[lo] := vals[mid]; vals[mid] := tmp_val;
            tmp_ore_key := ore_keys[lo]; ore_keys[lo] := ore_keys[mid]; ore_keys[mid] := tmp_ore_key;
            tmp_ope_key := ope_keys[lo]; ope_keys[lo] := ope_keys[mid]; ope_keys[mid] := tmp_ope_key;
        END IF;
        IF eql_v2._compare_sort_elements(vals, ore_keys, ope_keys, lo, hi, strategy) > 0 THEN
            tmp_id := ids[lo]; ids[lo] := ids[hi]; ids[hi] := tmp_id;
            tmp_val := vals[lo]; vals[lo] := vals[hi]; vals[hi] := tmp_val;
            tmp_ore_key := ore_keys[lo]; ore_keys[lo] := ore_keys[hi]; ore_keys[hi] := tmp_ore_key;
            tmp_ope_key := ope_keys[lo]; ope_keys[lo] := ope_keys[hi]; ope_keys[hi] := tmp_ope_key;
        END IF;
        IF eql_v2._compare_sort_elements(vals, ore_keys, ope_keys, mid, hi, strategy) > 0 THEN
            tmp_id := ids[mid]; ids[mid] := ids[hi]; ids[hi] := tmp_id;
            tmp_val := vals[mid]; vals[mid] := vals[hi]; vals[hi] := tmp_val;
            tmp_ore_key := ore_keys[mid]; ore_keys[mid] := ore_keys[hi]; ore_keys[hi] := tmp_ore_key;
            tmp_ope_key := ope_keys[mid]; ope_keys[mid] := ope_keys[hi]; ope_keys[hi] := tmp_ope_key;
        END IF;

        pivot_val := vals[mid];
        pivot_ore_key := ore_keys[mid];
        pivot_ope_key := ope_keys[mid];
        i := lo;
        j := hi;

        LOOP
            WHILE eql_v2._compare_sort_pivot(
                vals, ore_keys, ope_keys, i,
                pivot_val, pivot_ore_key, pivot_ope_key, strategy
            ) < 0 LOOP
                i := i + 1;
            END LOOP;
            WHILE eql_v2._compare_sort_pivot(
                vals, ore_keys, ope_keys, j,
                pivot_val, pivot_ore_key, pivot_ope_key, strategy
            ) > 0 LOOP
                j := j - 1;
            END LOOP;

            EXIT WHEN i >= j;

            tmp_id := ids[i]; ids[i] := ids[j]; ids[j] := tmp_id;
            tmp_val := vals[i]; vals[i] := vals[j]; vals[j] := tmp_val;
            tmp_ore_key := ore_keys[i]; ore_keys[i] := ore_keys[j]; ore_keys[j] := tmp_ore_key;
            tmp_ope_key := ope_keys[i]; ope_keys[i] := ope_keys[j]; ope_keys[j] := tmp_ope_key;

            i := i + 1;
            j := j - 1;
        END LOOP;

        left_hi := j;
        right_lo := j + 1;

        IF left_hi - lo < hi - right_lo THEN
            IF lo < left_hi THEN
                SELECT q.ids, q.vals, q.ore_keys, q.ope_keys
                    INTO ids, vals, ore_keys, ope_keys
                    FROM eql_v2._quicksort_sorter(ids, vals, ore_keys, ope_keys, lo, left_hi, strategy) q;
            END IF;
            lo := right_lo;
        ELSE
            IF right_lo < hi THEN
                SELECT q.ids, q.vals, q.ore_keys, q.ope_keys
                    INTO ids, vals, ore_keys, ope_keys
                    FROM eql_v2._quicksort_sorter(ids, vals, ore_keys, ope_keys, right_lo, hi, strategy) q;
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
--! @brief Sort encrypted values using precomputed ORE or OPE keys when available
--!
--! Shared implementation for public sorting entrypoints. The `strategy`
--! parameter selects the comparison path: `'ore'` uses the aligned `ore_keys`
--! array; `'ope'` uses the aligned `ope_keys` array (lex bytea comparison);
--! `'compare'` falls back to `eql_v2.compare()` on the encrypted values directly.
CREATE FUNCTION eql_v2._sort_compare_precomputed(
    ids bigint[],
    vals eql_v2_encrypted[],
    ore_keys eql_v2.ore_block_u64_8_256[],
    ope_keys bytea[],
    direction text DEFAULT 'ASC',
    strategy text DEFAULT 'ore'
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
    sorted_ore_keys eql_v2.ore_block_u64_8_256[];
    sorted_ope_keys bytea[];
BEGIN
    n := coalesce(array_length(ids, 1), 0);
    m := coalesce(array_length(vals, 1), 0);

    IF n <> m THEN
        RAISE EXCEPTION 'ids and vals must have the same length';
    END IF;

    IF strategy = 'ore' THEN
        k := coalesce(array_length(ore_keys, 1), 0);
        IF n <> k THEN
            RAISE EXCEPTION 'ids and ore_keys must have the same length when strategy = ''ore''';
        END IF;
    ELSIF strategy = 'ope' THEN
        k := coalesce(array_length(ope_keys, 1), 0);
        IF n <> k THEN
            RAISE EXCEPTION 'ids and ope_keys must have the same length when strategy = ''ope''';
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

    SELECT q.ids, q.vals, q.ore_keys, q.ope_keys
        INTO sorted_ids, sorted_vals, sorted_ore_keys, sorted_ope_keys
        FROM eql_v2._quicksort_sorter(ids, vals, ore_keys, ope_keys, 1, n, strategy) q;

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
--! When all input rows share an `ore` term the sort uses pre-extracted ORE
--! keys; when all rows share an `ope` term (`opf` or `opv`) the sort uses
--! pre-extracted OPE ciphertexts compared as `bytea`. Mixed inputs fall back
--! to `eql_v2.compare()` per pair.
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
    sorted_ore_keys eql_v2.ore_block_u64_8_256[];
    sorted_ope_keys bytea[];
    i integer;
    use_ore boolean := true;
    use_ope boolean := true;
    has_ope_term boolean;
    strategy text;
BEGIN
    n := coalesce(array_length(ids, 1), 0);

    FOR i IN 1..n LOOP
        IF vals[i] IS NULL THEN
            sorted_ore_keys[i] := NULL;
            sorted_ope_keys[i] := NULL;
        ELSE
            IF use_ore THEN
                IF eql_v2.has_ore_block_u64_8_256(vals[i]) THEN
                    sorted_ore_keys[i] := eql_v2.order_by(vals[i]);
                ELSE
                    use_ore := false;
                END IF;
            END IF;

            IF use_ope THEN
                has_ope_term := eql_v2.has_ope_cllw_u64_65(vals[i])
                                OR eql_v2.has_ope_cllw_var_8(vals[i]);
                IF has_ope_term THEN
                    sorted_ope_keys[i] := eql_v2.order_by_ope(vals[i]);
                ELSE
                    use_ope := false;
                END IF;
            END IF;

            EXIT WHEN NOT use_ore AND NOT use_ope;
        END IF;
    END LOOP;

    IF use_ore THEN
        strategy := 'ore';
    ELSIF use_ope THEN
        strategy := 'ope';
    ELSE
        strategy := 'compare';
    END IF;

    RETURN QUERY
        SELECT sc.id, sc.val
        FROM eql_v2._sort_compare_precomputed(
            ids, vals, sorted_ore_keys, sorted_ope_keys, direction, strategy
        ) sc;
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
--! order key once per row and sorts on that key; for OPE-backed values the OPE
--! ciphertext is pre-extracted as `bytea` and compared lexicographically. Other
--! values fall back to eql_v2.compare(). The query must return exactly two
--! columns: a bigint identifier and an eql_v2_encrypted value.
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
    all_ore_keys eql_v2.ore_block_u64_8_256[];
    all_ope_keys bytea[];
    all_have_ore_keys boolean;
    all_have_ope_keys boolean;
    strategy text;
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
                   END AS ore_key,
                   CASE
                       WHEN sub.val IS NULL THEN NULL
                       WHEN eql_v2.has_ope_cllw_u64_65(sub.val) OR eql_v2.has_ope_cllw_var_8(sub.val)
                           THEN eql_v2.order_by_ope(sub.val)
                       ELSE NULL
                   END AS ope_key,
                   CASE
                       WHEN sub.val IS NULL THEN TRUE
                       ELSE eql_v2.has_ore_block_u64_8_256(sub.val)
                   END AS has_ore_key,
                   CASE
                       WHEN sub.val IS NULL THEN TRUE
                       ELSE eql_v2.has_ope_cllw_u64_65(sub.val)
                            OR eql_v2.has_ope_cllw_var_8(sub.val)
                   END AS has_ope_key
            FROM (%s) sub(id, val)
         )
         SELECT array_agg(id ORDER BY ord),
                array_agg(val ORDER BY ord),
                array_agg(ore_key ORDER BY ord),
                array_agg(ope_key ORDER BY ord),
                coalesce(bool_and(has_ore_key), TRUE),
                coalesce(bool_and(has_ope_key), TRUE)
         FROM input_rows',
        query
    ) INTO all_ids, all_vals, all_ore_keys, all_ope_keys,
           all_have_ore_keys, all_have_ope_keys;

    IF all_ids IS NULL THEN
        RETURN;
    END IF;

    IF all_have_ore_keys THEN
        strategy := 'ore';
    ELSIF all_have_ope_keys THEN
        strategy := 'ope';
    ELSE
        strategy := 'compare';
    END IF;

    RETURN QUERY
        SELECT sc.id, sc.val
        FROM eql_v2._sort_compare_precomputed(
            all_ids,
            all_vals,
            all_ore_keys,
            all_ope_keys,
            direction,
            strategy
        ) sc;
END;
$$ LANGUAGE plpgsql;
