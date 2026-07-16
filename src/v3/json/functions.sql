-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/json/types.sql
-- REQUIRE: src/v3/sem/ope_cllw/types.sql
-- REQUIRE: src/v3/sem/ope_cllw/functions.sql

--! @file v3/json/functions.sql
--! @brief Extractors, containment engine, and path/array functions for the
--!        eql_v3 encrypted-JSONB (SteVec) surface.
--!
--! `selector` parameters here are *encrypted-side* selector hashes — the
--! deterministic hash the crypto layer emits in the `s` field of each sv
--! element. Plaintext JSONPaths are never accepted at runtime.

------------------------------------------------------------------------------
-- Envelope helpers (eql_v3 owns these; jsonb-only)
------------------------------------------------------------------------------

--! @brief Extract metadata (i, v) from a raw jsonb encrypted value.
--! @param val jsonb encrypted EQL payload
--! @return jsonb Metadata object with `i` and `v` fields.
CREATE FUNCTION eql_v3.meta_data(val jsonb)
  RETURNS jsonb
  IMMUTABLE STRICT PARALLEL SAFE
  LANGUAGE SQL
AS $$
  SELECT jsonb_build_object('i', val->'i', 'v', val->'v');
$$;

COMMENT ON FUNCTION eql_v3.meta_data(jsonb) IS
  'eql-inline-critical: raw-jsonb envelope helper used by v3 jsonb wrappers; must stay inlinable (unpinned search_path)';

--! @brief Extract ciphertext (c) from a raw jsonb encrypted value.
--! @param val jsonb encrypted EQL payload
--! @return text Base64-encoded ciphertext.
--! @throws Exception if `c` is absent.
CREATE FUNCTION eql_v3.ciphertext(val jsonb)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    IF val ? 'c' THEN
      RETURN val->>'c';
    END IF;
    RAISE 'Expected a ciphertext (c) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Selector extractors
------------------------------------------------------------------------------

--! @brief Extract selector (s) from a raw jsonb encrypted value.
--! @param val jsonb encrypted EQL payload
--! @return text The selector value.
--! @throws Exception if `s` is absent.
CREATE FUNCTION eql_v3.selector(val jsonb)
  RETURNS text
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    IF val ? 's' THEN
      RETURN val->>'s';
    END IF;
    RAISE 'Expected a selector index (s) value in json: %', val;
  END;
$$ LANGUAGE plpgsql;

--! @brief Extract selector (s) from a ste_vec entry. The DOMAIN CHECK
--!        guarantees `s` is present, so this is a simple field access.
--! @param entry public.eql_v3_json_entry
--! @return text The selector value.
CREATE FUNCTION eql_v3.selector(entry public.eql_v3_json_entry)
  RETURNS text
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT entry ->> 's'
$$;

------------------------------------------------------------------------------
-- Equality-term extractor (XOR-aware: coalesce(hm, op))
------------------------------------------------------------------------------

--! @brief XOR-aware equality term extractor for public.eql_v3_json_entry.
--!
--! Returns the bytea of whichever deterministic term the sv entry carries —
--! `hm` (HMAC-256) or `op` (CLLW OPE). The two byte distributions are disjoint
--! by construction, so byte equality on the coalesce is unambiguous. Canonical
--! equality extractor used by `=` / `<>` on jsonb_entry.
--!
--! @param entry public.eql_v3_json_entry
--! @return bytea Decoded `hm` or `op` bytes (NULL if entry is NULL).
CREATE FUNCTION eql_v3.eq_term(entry public.eql_v3_json_entry)
  RETURNS bytea
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT decode(coalesce(entry ->> 'hm', entry ->> 'op'), 'hex')
$$;

------------------------------------------------------------------------------
-- CLLW OPE per-entry overload (converged with the scalar ord_term)
------------------------------------------------------------------------------

--! @brief Extract the CLLW OPE index term from a ste_vec entry.
--!
--! An sv-element `op` term is only ever present on an sv element, never at a
--! root encrypted value, so the typed overload accepts public.eql_v3_json_entry —
--! the jsonb_entry twin of the generated scalar `eql_v3.ord_term`
--! extractors. Returns SQL NULL when `op` is absent (the strict `->>` /
--! `decode` chain propagates it), so btree NULL-filters such rows from range
--! queries. The returned eql_v3_internal.ope_cllw is a bytea domain: it orders
--! under native byte comparison with the DEFAULT btree opclass, so a
--! functional index on `eql_v3.ord_term(col -> 'selector')` engages
--! structurally with no custom operator class (Supabase/managed-Postgres
--! safe).
--!
--! @param entry public.eql_v3_json_entry
--! @return eql_v3_internal.ope_cllw Hex-decoded CLLW OPE term, or NULL when
--!         `op` is absent.
CREATE FUNCTION eql_v3.ord_term(entry public.eql_v3_json_entry)
  RETURNS eql_v3_internal.ope_cllw
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v3_internal.ope_cllw(entry::jsonb)
$$;

------------------------------------------------------------------------------
-- sv-array helpers
------------------------------------------------------------------------------

--! @brief Extract the sv element array as raw jsonb[].
--!
--! Returns the elements of `sv` (or a single-element array wrapping the value
--! when there is no `sv`). No envelope re-wrapping — raw jsonb elements.
--!
--! @param val jsonb encrypted EQL payload
--! @return jsonb[] Array of sv elements.
CREATE FUNCTION eql_v3.ste_vec(val jsonb)
  RETURNS jsonb[]
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    sv jsonb;
    ary jsonb[];
  BEGIN
    IF val ? 'sv' THEN
      sv := val->'sv';
    ELSE
      sv := jsonb_build_array(val);
    END IF;

    SELECT array_agg(elem)
      INTO ary
      FROM jsonb_array_elements(sv) AS elem;

    RETURN ary;
  END;
$$ LANGUAGE plpgsql;

--! @brief Check if a jsonb payload is marked as an sv array (`a` flag true).
--! @param val jsonb encrypted EQL payload
--! @return boolean True if `a` is present and true.
CREATE FUNCTION eql_v3_internal.is_ste_vec_array(val jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  BEGIN
    IF val ? 'a' THEN
      RETURN (val->>'a')::boolean;
    END IF;
    RETURN false;
  END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Deterministic-fields array for GIN containment
------------------------------------------------------------------------------

--! @brief Extract deterministic search fields (s, hm, op) per sv element.
--!
--! Excludes non-deterministic ciphertext so PostgreSQL's native jsonb `@>` can
--! compare for containment. Use for GIN indexes and containment queries.
--!
--! @param val jsonb encrypted EQL payload
--! @return jsonb[] Array of objects with only deterministic fields.
CREATE FUNCTION eql_v3.jsonb_array(val jsonb)
RETURNS jsonb[]
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT ARRAY(
    SELECT jsonb_object_agg(kv.key, kv.value)
    FROM jsonb_array_elements(
      CASE WHEN val ? 'sv' THEN val->'sv' ELSE jsonb_build_array(val) END
    ) AS elem,
    LATERAL jsonb_each(elem) AS kv(key, value)
    WHERE kv.key IN ('s', 'hm', 'op')
    GROUP BY elem
  );
$$;

COMMENT ON FUNCTION eql_v3.jsonb_array(jsonb) IS
  'eql-inline-critical: raw-jsonb deterministic-field array helper; must stay inlinable (unpinned search_path)';

------------------------------------------------------------------------------
-- Containment
------------------------------------------------------------------------------

--! @brief GIN-indexable containment check: does `a` contain all of `b`?
--! @param a jsonb Container payload.
--! @param b jsonb Search payload.
--! @return boolean True if a contains all deterministic elements of b.
--! @note Public raw-`jsonb[]` containment helper over the extracted
--!       deterministic fields — the function-form entrypoint for containment on
--!       platforms without operator support (Supabase/PostgREST). The typed
--!       `public.eql_v3_json_search` `@>` operator does NOT call this function — it binds to
--!       `eql_v3.ste_vec_contains` instead — but both agree on the result (a
--!       parity test pins this). Also the documented GIN index expression
--!       (`eql_v3.jsonb_array(col)`); see docs/reference/database-indexes.md.
CREATE FUNCTION eql_v3.jsonb_contains(a jsonb, b jsonb)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v3.jsonb_array(a) @> eql_v3.jsonb_array(b);
$$;

COMMENT ON FUNCTION eql_v3.jsonb_contains(jsonb, jsonb) IS
  'eql-inline-critical: raw-jsonb containment helper; must stay inlinable (unpinned search_path)';

--! @brief GIN-indexable "is contained by" check.
--! @param a jsonb Payload to check.
--! @param b jsonb Container payload.
--! @return boolean True if all elements of a are contained in b.
--! @note Public raw-`jsonb[]` reverse-containment helper — the function-form
--!       entrypoint for `<@` on platforms without operator support. The typed
--!       `public.eql_v3_json_search` `<@` operator binds to `eql_v3.ste_vec_contains` instead,
--!       but both agree on the result.
CREATE FUNCTION eql_v3.jsonb_contained_by(a jsonb, b jsonb)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
LANGUAGE SQL
AS $$
  SELECT eql_v3.jsonb_array(a) <@ eql_v3.jsonb_array(b);
$$;

COMMENT ON FUNCTION eql_v3.jsonb_contained_by(jsonb, jsonb) IS
  'eql-inline-critical: raw-jsonb contained-by helper; must stay inlinable (unpinned search_path)';

--! @brief Check if an sv array contains a specific sv element.
--!
--! Match = selector equal AND eq_term equal (byte-equality over coalesce(hm,
--! op)). This collapses the v2 hm/oc CASE: under the XOR contract both terms
--! are deterministic and byte-disjoint, so either one is a valid equality
--! discriminator and a single byte comparison is correct.
--!
--! ASSUMPTION (locked by a negative test in v3_jsonb_tests.rs): hm and op byte
--! distributions never collide at a given selector. The crypto layer configures
--! a selector for eq XOR ordered, so both sides of a real comparison carry the
--! same term type — an hm needle never meets an op leaf at the same selector.
--! This collapse would wrongly match an hm needle against an op leaf if their
--! hex bytes were ever identical — which the contract prevents (an hm is a
--! fixed 32-byte HMAC; an op is a CLLW OPE ciphertext whose length is a
--! function of the plaintext bit width, never 32 bytes for the supported
--! domains). The negative-containment test guards against regression.
--!
--! @param a jsonb[] sv array to search within.
--! @param b jsonb sv element to search for.
--! @return boolean True if b is found in any element of a.
CREATE FUNCTION eql_v3.ste_vec_contains(a jsonb[], b jsonb)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    result boolean;
    _a jsonb;
  BEGIN
    result := false;

    FOR idx IN 1..array_length(a, 1) LOOP
      _a := a[idx];
      result := result OR (
        eql_v3.selector(_a) = eql_v3.selector(b)
        AND eql_v3.eq_term(_a::public.eql_v3_json_entry) = eql_v3.eq_term(b::public.eql_v3_json_entry)
      );
      EXIT WHEN result;
    END LOOP;

    RETURN result;
  END;
$$ LANGUAGE plpgsql;

--! @brief Does encrypted value `a` contain all sv elements of `b`?
--!
--! Empty b is always contained. Each element of b must match selector + eq_term
--! in some element of a.
--!
--! @param a public.eql_v3_json_search Container.
--! @param b public.eql_v3_json_search Elements to find.
--! @return boolean True if all elements of b are contained in a.
--! @see eql_v3.ste_vec_contains(jsonb[], jsonb)
CREATE FUNCTION eql_v3.ste_vec_contains(a public.eql_v3_json_search, b public.eql_v3_json_search)
  RETURNS boolean
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    result boolean;
    sv_a jsonb[];
    sv_b jsonb[];
    _b jsonb;
  BEGIN
    sv_a := eql_v3.ste_vec(a);
    sv_b := eql_v3.ste_vec(b);

    IF array_length(sv_b, 1) IS NULL THEN
      RETURN true;
    END IF;

    IF array_length(sv_a, 1) IS NULL THEN
      RETURN false;
    END IF;

    result := true;

    FOR idx IN 1..array_length(sv_b, 1) LOOP
      _b := sv_b[idx];
      result := result AND eql_v3.ste_vec_contains(sv_a, _b);
    END LOOP;

    RETURN result;
  END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Path queries (text selector only)
------------------------------------------------------------------------------

--! @brief Query encrypted JSONB for sv elements matching `selector`.
--!
--! Returns one jsonb_entry row per matching encrypted element. Returns empty
--! set on no match. It deliberately does not wrap multiple matches as an
--! public.eql_v3_json_search document, because the root document domain requires an `sv`
--! array and single leaves belong to public.eql_v3_json_entry.
--!
--! @param val jsonb encrypted EQL payload with `sv`.
--! @param selector text Selector hash (`s` value).
--! @return SETOF public.eql_v3_json_entry Matching encrypted entries.
--! @see eql_v3.jsonb_path_query_first
CREATE FUNCTION eql_v3.jsonb_path_query(val jsonb, selector text)
  RETURNS SETOF public.eql_v3_json_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (eql_v3.meta_data(val) || elem)::public.eql_v3_json_entry
  FROM jsonb_array_elements(val -> 'sv') elem
  WHERE elem ->> 's' = selector
$$;

COMMENT ON FUNCTION eql_v3.jsonb_path_query(jsonb, text) IS
  'eql-inline-critical: raw-jsonb path query helper; must stay inlinable (unpinned search_path)';

--! @brief Check if a selector path exists in encrypted JSONB.
--! @param val jsonb encrypted EQL payload.
--! @param selector text Selector hash to test.
--! @return boolean True if a matching element exists.
CREATE FUNCTION eql_v3.jsonb_path_exists(val jsonb, selector text)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM jsonb_array_elements(val -> 'sv') elem
    WHERE elem ->> 's' = selector
  );
$$;

COMMENT ON FUNCTION eql_v3.jsonb_path_exists(jsonb, text) IS
  'eql-inline-critical: raw-jsonb path exists helper; must stay inlinable (unpinned search_path)';

--! @brief Get the first sv element matching `selector`, or NULL.
--! @param val jsonb encrypted EQL payload.
--! @param selector text Selector hash to match.
--! @return public.eql_v3_json_entry First matching element or NULL.
CREATE FUNCTION eql_v3.jsonb_path_query_first(val jsonb, selector text)
  RETURNS public.eql_v3_json_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (eql_v3.meta_data(val) || elem)::public.eql_v3_json_entry
  FROM jsonb_array_elements(val -> 'sv') elem
  WHERE elem ->> 's' = selector
  LIMIT 1
$$;

COMMENT ON FUNCTION eql_v3.jsonb_path_query_first(jsonb, text) IS
  'eql-inline-critical: raw-jsonb path first helper; must stay inlinable (unpinned search_path)';

------------------------------------------------------------------------------
-- Array functions
------------------------------------------------------------------------------

--! @brief Get the length of an encrypted JSONB array.
--! @param val jsonb encrypted EQL payload (must have `a` flag true).
--! @return integer Number of elements.
--! @throws Exception 'cannot get array length of a non-array' if not an array.
CREATE FUNCTION eql_v3.jsonb_array_length(val jsonb)
  RETURNS integer
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    sv jsonb[];
  BEGIN
    IF eql_v3_internal.is_ste_vec_array(val) THEN
      sv := eql_v3.ste_vec(val);
      RETURN array_length(sv, 1);
    END IF;

    RAISE 'cannot get array length of a non-array';
  END;
$$ LANGUAGE plpgsql;

--! @brief Extract elements of an encrypted JSONB array as rows.
--! @param val jsonb encrypted EQL payload (must have `a` flag true).
--! @return SETOF public.eql_v3_json_entry One row per element (metadata preserved).
--! @throws Exception 'cannot extract elements from non-array' if not an array.
CREATE FUNCTION eql_v3.jsonb_array_elements(val jsonb)
  RETURNS SETOF public.eql_v3_json_entry
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    sv jsonb[];
    meta jsonb;
    item jsonb;
  BEGIN
    IF NOT eql_v3_internal.is_ste_vec_array(val) THEN
      RAISE 'cannot extract elements from non-array';
    END IF;

    meta := eql_v3.meta_data(val);
    sv := eql_v3.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      item = sv[idx];
      RETURN NEXT (meta || item)::public.eql_v3_json_entry;
    END LOOP;

    RETURN;
  END;
$$ LANGUAGE plpgsql;

--! @brief Extract elements of an encrypted JSONB array as ciphertext text.
--! @param val jsonb encrypted EQL payload (must have `a` flag true).
--! @return SETOF text One ciphertext per element.
--! @throws Exception 'cannot extract elements from non-array' if not an array.
CREATE FUNCTION eql_v3.jsonb_array_elements_text(val jsonb)
  RETURNS SETOF text
  IMMUTABLE STRICT PARALLEL SAFE
  SET search_path = pg_catalog, extensions, public
AS $$
  DECLARE
    sv jsonb[];
  BEGIN
    IF NOT eql_v3_internal.is_ste_vec_array(val) THEN
      RAISE 'cannot extract elements from non-array';
    END IF;

    sv := eql_v3.ste_vec(val);

    FOR idx IN 1..array_length(sv, 1) LOOP
      RETURN NEXT eql_v3.ciphertext(sv[idx]);
    END LOOP;

    RETURN;
  END;
$$ LANGUAGE plpgsql;
