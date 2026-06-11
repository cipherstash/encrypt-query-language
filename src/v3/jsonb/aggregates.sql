-- REQUIRE: src/v3/jsonb/types.sql
-- REQUIRE: src/v3/jsonb/functions.sql
-- REQUIRE: src/v3/sem/ore_cllw/operators.sql

--! @file v3/jsonb/aggregates.sql
--! @brief min / max aggregates over eql_v3.ste_vec_entry.
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

--! @brief State function for min on eql_v3.ste_vec_entry.
--!
--! Keeps whichever entry has the lesser CLLW ORE term. STRICT, so NULL entries
--! (and entries whose `oc` is absent, yielding a NULL `ore_cllw`) are skipped by
--! the aggregate machinery / fall through to `state`.
--!
--! @param state eql_v3.ste_vec_entry Running extremum.
--! @param value eql_v3.ste_vec_entry Candidate entry.
--! @return eql_v3.ste_vec_entry The lesser of the two by `ore_cllw`.
CREATE FUNCTION eql_v3.ste_vec_entry_min_sfunc(
  state eql_v3.ste_vec_entry,
  value eql_v3.ste_vec_entry
)
RETURNS eql_v3.ste_vec_entry
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF eql_v3.ore_cllw(value) < eql_v3.ore_cllw(state) THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief min aggregate over eql_v3.ste_vec_entry.
--! @param input eql_v3.ste_vec_entry
--! @return eql_v3.ste_vec_entry The entry with the smallest CLLW ORE term.
CREATE AGGREGATE eql_v3.min(eql_v3.ste_vec_entry) (
  sfunc = eql_v3.ste_vec_entry_min_sfunc,
  stype = eql_v3.ste_vec_entry,
  combinefunc = eql_v3.ste_vec_entry_min_sfunc,
  parallel = safe
);

--! @brief State function for max on eql_v3.ste_vec_entry.
--!
--! Keeps whichever entry has the greater CLLW ORE term. STRICT, mirroring
--! `ste_vec_entry_min_sfunc`.
--!
--! @param state eql_v3.ste_vec_entry Running extremum.
--! @param value eql_v3.ste_vec_entry Candidate entry.
--! @return eql_v3.ste_vec_entry The greater of the two by `ore_cllw`.
CREATE FUNCTION eql_v3.ste_vec_entry_max_sfunc(
  state eql_v3.ste_vec_entry,
  value eql_v3.ste_vec_entry
)
RETURNS eql_v3.ste_vec_entry
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  IF eql_v3.ore_cllw(value) > eql_v3.ore_cllw(state) THEN
    RETURN value;
  END IF;
  RETURN state;
END;
$$;

--! @brief max aggregate over eql_v3.ste_vec_entry.
--! @param input eql_v3.ste_vec_entry
--! @return eql_v3.ste_vec_entry The entry with the largest CLLW ORE term.
CREATE AGGREGATE eql_v3.max(eql_v3.ste_vec_entry) (
  sfunc = eql_v3.ste_vec_entry_max_sfunc,
  stype = eql_v3.ste_vec_entry,
  combinefunc = eql_v3.ste_vec_entry_max_sfunc,
  parallel = safe
);
