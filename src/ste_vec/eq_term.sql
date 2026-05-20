-- REQUIRE: src/schema.sql
-- REQUIRE: src/ste_vec/types.sql

--! @file src/ste_vec/eq_term.sql
--! @brief XOR-aware equality term extractor for `eql_v2.ste_vec_entry`
--!
--! Returns the bytea representation of whichever deterministic term
--! the sv entry carries — `hm` (HMAC-256) for bool leaves / array
--! roots / object roots, or `oc` (CLLW ORE) for string / number
--! leaves. The two byte distributions are disjoint by construction
--! (different keys, different protocols), so byte equality on the
--! coalesce is unambiguous: equal terms imply equal plaintexts under
--! the same selector, and unequal terms imply different plaintexts
--! (or different protocols, which can't happen for a single
--! selector).
--!
--! This is the canonical equality extractor used by `=` and `<>` on
--! `eql_v2.ste_vec_entry` — see `src/operators/ste_vec_entry.sql`.
--! The recipe for field-level equality on encrypted JSON is:
--!
--! @example
--! -- Functional hash index covers both hm-bearing and oc-bearing selectors
--! CREATE INDEX ON users USING hash (eql_v2.eq_term(data -> '<selector>'));
--! -- Bare-form predicate matches via the inlined `=` on ste_vec_entry
--! SELECT * FROM users WHERE data -> '<selector>' = $1::eql_v2.ste_vec_entry;
--!
--! @param entry eql_v2.ste_vec_entry STE-vec entry (extracted via `->`)
--! @return bytea Decoded `hm` or `oc` bytes (NULL if entry is NULL).
--!
--! @note The XOR contract (each sv entry carries exactly one of `hm`
--!       or `oc` — enforced by the `ste_vec_entry` DOMAIN CHECK) means
--!       the coalesce always picks the one present term.
--!
--! @see eql_v2.hmac_256(eql_v2.ste_vec_entry)
--! @see eql_v2.ore_cllw(eql_v2.ste_vec_entry)
--! @see src/operators/ste_vec_entry.sql
CREATE FUNCTION eql_v2.eq_term(entry eql_v2.ste_vec_entry)
  RETURNS bytea
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT decode(coalesce(entry ->> 'hm', entry ->> 'oc'), 'hex')
$$;
