-- REQUIRE: src/v3/jsonb/types.sql
-- REQUIRE: src/v3/jsonb/functions.sql
-- REQUIRE: src/v3/sem/ore_cllw/operators.sql

--! @file v3/jsonb/aggregates.sql
--! @brief min / max aggregates over public.jsonb_entry.
--!
--! SteVec document entries extracted at a selector (`doc -> 'sel'`) order by
--! their CLLW ORE (`oc`) term, so the extremum is picked by comparing
--! `eql_v3.ore_cllw(entry)` rather than the scalar Block-ORE `ord_term` the
--! generated scalar ord aggregates use. Same STRICT + PARALLEL SAFE shape as the
--! generated scalar `min`/`max` so partial/parallel aggregation is available on
--! large GROUP BY workloads.
--!
--! Per the encrypted-domain footgun rules the state functions are
--! `LANGUAGE plpgsql` with the pinned `search_path` — a `LANGUAGE sql` body would
--! be inlinable and the planner could elide it.
--!
--! @note **Only `oc`-carrying entries are orderable.** `eql_v3.ore_cllw(entry)`
--!   returns NULL when an entry has no `oc` (CLLW ORE) term — the same entries a
--!   `eql_v3.ore_cllw` btree NULL-filters from range scans. The state functions
--!   therefore IGNORE `oc`-less entries (they never become or survive as the
--!   extremum), so `min`/`max` is well-defined over a mix of `oc`-carrying and
--!   `oc`-less entries and is not corrupted by an `oc`-less seed. A naive
--!   `ore_cllw(value) < ore_cllw(state)` would be NULL whenever either side
--!   lacks `oc`, pinning a wrong (`oc`-less) extremum when the first aggregated
--!   row is `oc`-less. An all-`oc`-less input has no orderable extremum and
--!   returns the (arbitrary) STRICT seed.

--! @brief State function for min on public.jsonb_entry.
--!
--! Keeps whichever orderable entry has the lesser CLLW ORE term. STRICT, so SQL
--! NULL entries are skipped by the aggregate machinery; `oc`-less (non-orderable)
--! entries are skipped explicitly (see the @note on this file).
--!
--! @param state public.jsonb_entry Running extremum.
--! @param value public.jsonb_entry Candidate entry.
--! @return public.jsonb_entry The lesser orderable entry by `ore_cllw`.
CREATE FUNCTION eql_v3_internal.jsonb_entry_min_sfunc(
  state public.jsonb_entry,
  value public.jsonb_entry
)
RETURNS public.jsonb_entry
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
  value_ore eql_v3_internal.ore_cllw := eql_v3.ore_cllw(value);
  state_ore eql_v3_internal.ore_cllw := eql_v3.ore_cllw(state);
BEGIN
  -- A non-orderable (oc-less) candidate never replaces the running extremum.
  IF value_ore IS NULL THEN
    RETURN state;
  END IF;
  -- Adopt the candidate when the running extremum is itself non-orderable
  -- (e.g. an oc-less STRICT seed) or strictly greater.
  IF state_ore IS NULL OR value_ore < state_ore THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief min aggregate over public.jsonb_entry.
--! @param input public.jsonb_entry
--! @return public.jsonb_entry The entry with the smallest CLLW ORE term.
CREATE AGGREGATE eql_v3.min(public.jsonb_entry) (
  sfunc = eql_v3_internal.jsonb_entry_min_sfunc,
  stype = public.jsonb_entry,
  combinefunc = eql_v3_internal.jsonb_entry_min_sfunc,
  parallel = safe
);

--! @brief State function for max on public.jsonb_entry.
--!
--! Keeps whichever orderable entry has the greater CLLW ORE term. `oc`-less
--! entries are skipped, mirroring `jsonb_entry_min_sfunc` (see the file @note).
--!
--! @param state public.jsonb_entry Running extremum.
--! @param value public.jsonb_entry Candidate entry.
--! @return public.jsonb_entry The greater orderable entry by `ore_cllw`.
CREATE FUNCTION eql_v3_internal.jsonb_entry_max_sfunc(
  state public.jsonb_entry,
  value public.jsonb_entry
)
RETURNS public.jsonb_entry
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
DECLARE
  value_ore eql_v3_internal.ore_cllw := eql_v3.ore_cllw(value);
  state_ore eql_v3_internal.ore_cllw := eql_v3.ore_cllw(state);
BEGIN
  -- A non-orderable (oc-less) candidate never replaces the running extremum.
  IF value_ore IS NULL THEN
    RETURN state;
  END IF;
  -- Adopt the candidate when the running extremum is itself non-orderable
  -- (e.g. an oc-less STRICT seed) or strictly lesser.
  IF state_ore IS NULL OR value_ore > state_ore THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief max aggregate over public.jsonb_entry.
--! @param input public.jsonb_entry
--! @return public.jsonb_entry The entry with the largest CLLW ORE term.
CREATE AGGREGATE eql_v3.max(public.jsonb_entry) (
  sfunc = eql_v3_internal.jsonb_entry_max_sfunc,
  stype = public.jsonb_entry,
  combinefunc = eql_v3_internal.jsonb_entry_max_sfunc,
  parallel = safe
);
