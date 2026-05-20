-- REQUIRE: src/schema.sql

--! @file src/ste_vec/types.sql
--! @brief Domain type for individual STE-vec entries
--!
--! Defines `eql_v2.ste_vec_entry` as a DOMAIN over `jsonb` constrained to the
--! shape of a single element inside an `sv` array — a JSON object that
--! carries at minimum a selector field (`s`). This is the type returned by
--! the `->` operator on `eql_v2_encrypted` (a single sv element extracted by
--! selector) and the type accepted by sv-element extractors such as
--! `eql_v2.ore_cllw(eql_v2.ste_vec_entry)` and
--! `eql_v2.hmac_256(eql_v2.ste_vec_entry)`.
--!
--! Why a separate type. Before #219, the `(eql_v2_encrypted)` overloads of
--! sv-element extractors read fields like `oc` off the root `data` jsonb,
--! which is misleading: a root `EncryptedPayload` or `SteVecPayload` (the
--! shapes that an actual `eql_v2_encrypted` column value carries) never has
--! `oc` at the root. The previous pattern only worked because the `->`
--! operator merged ste-vec entry fields into a fake root-shaped payload
--! before the extractor ran. This domain type makes the distinction
--! explicit: `eql_v2_encrypted` is the root shape; `eql_v2.ste_vec_entry`
--! is the per-entry shape; extractors are typed accordingly.
--!
--! @note The CHECK constraint reflects the cipherstash-suite emission
--!       contract:
--!         - `s` (selector — column-name HMAC) and `c` (ciphertext) are
--!           emitted on every sv element.
--!         - Each sv element carries **exactly one** of `hm` (HMAC-256, for
--!           hash-equality queries) or `oc` (CLLW ORE, for ordered queries)
--!           — they are mutually exclusive. A given selector / field is
--!           configured for one mode or the other; the crypto layer emits
--!           the corresponding term and only that term.
--!       Other fields (`a` for array marker, etc.) are allowed but not
--!       required.
--!
--! @see src/operators/->.sql
--! @see src/ore_cllw/functions.sql
--! @see src/hmac_256/functions.sql
CREATE DOMAIN eql_v2.ste_vec_entry AS jsonb
  CHECK (
    jsonb_typeof(VALUE) = 'object'
    AND VALUE ? 's'
    AND VALUE ? 'c'
    AND (VALUE ? 'hm') <> (VALUE ? 'oc')
  );


--! @brief Domain type for an STE-vec containment needle
--!
--! `eql_v2.stevec_query` is a query-shaped sv payload: a top-level
--! `{"sv": [...]}` object whose elements carry selector + index
--! terms but **never** a ciphertext (`c`) field. Containment (`@>`)
--! against an `eql_v2_encrypted` column is structurally typed
--! through this domain so the call site reads as "match against an
--! sv query", not "compare two encrypted values".
--!
--! Compared to `eql_v2.ste_vec_entry` (single sv element with `s`,
--! `c`, and `hm` XOR `oc`), `stevec_query` is the wrapping
--! `{"sv": [...]}` payload: it forbids `c` on every element but
--! otherwise keeps the same per-element contract — each element must
--! carry a selector `s` and exactly one deterministic term (`hm` XOR
--! `oc`). This mirrors the `SteVecQueryElement` JSON schema and stops
--! selector-only needles (e.g. `{"sv":[{"s":"x"}]}`) from casting and
--! then matching every row through the bare `jsonb @>` implementation.
--! The implementation of `ste_vec_contains` ignores `c` either way,
--! but typing the needle as `stevec_query` documents the contract at
--! the API surface.
--!
--! @note Constructing a `stevec_query` literal from inline JSON works
--!       via the standard DOMAIN cast:
--!         `'{"sv":[{"s":"<sel>","hm":"<hm>"}]}'::eql_v2.stevec_query`
--!       Casting an `eql_v2_encrypted` value strips `c` fields from
--!       each sv element — see `eql_v2.to_stevec_query`.
--!
--! @see eql_v2.to_stevec_query
--! @see src/operators/@>.sql
CREATE DOMAIN eql_v2.stevec_query AS jsonb
  CHECK (
    jsonb_typeof(VALUE) = 'object'
    AND VALUE ? 'sv'
    AND jsonb_typeof(VALUE -> 'sv') = 'array'
    -- No element may carry a ciphertext (`c`) — this is a query, not a value.
    AND NOT jsonb_path_exists(VALUE, '$.sv[*] ? (exists(@.c))'::jsonpath)
    -- Every element must carry a selector (`s`) ...
    AND NOT jsonb_path_exists(VALUE, '$.sv[*] ? (!exists(@.s))'::jsonpath)
    -- ... and exactly one deterministic term — `hm` XOR `oc` — matching
    -- the `ste_vec_entry` emission contract and the `SteVecQueryElement`
    -- JSON schema. Rejects selector-only needles that would otherwise
    -- cast and then match every row via the bare `jsonb @>` body.
    AND NOT jsonb_path_exists(VALUE, '$.sv[*] ? (exists(@.hm) && exists(@.oc))'::jsonpath)
    AND NOT jsonb_path_exists(VALUE, '$.sv[*] ? (!exists(@.hm) && !exists(@.oc))'::jsonpath)
  );


--! @brief Convert an `eql_v2_encrypted` to a `stevec_query` needle
--!
--! Normalises each sv element down to the matching-relevant fields:
--! `s` (selector) plus exactly one of `hm` / `oc`. Other fields
--! (`c` ciphertext, `a` array marker, `i`/`v` envelope metadata, anything
--! else cipherstash-client might emit) are stripped. This is the
--! canonical needle shape for `@>` containment — matching the contract
--! that containment compares by selector + deterministic term and
--! ignores everything else.
--!
--! Designed for use as a functional GIN index expression: a single
--! `GIN (eql_v2.to_stevec_query(col)::jsonb jsonb_path_ops)` index
--! covers containment queries against any selector (both hm-bearing
--! and oc-bearing — XOR-aware), and the typed `@>` overloads inline
--! to a native `jsonb @>` on the same expression so the planner
--! engages Bitmap Index Scan structurally.
--!
--! @param e eql_v2_encrypted Source encrypted payload
--! @return eql_v2.stevec_query Query-shaped needle, sv elements
--!         normalised to `{s, hm}` or `{s, oc}`.
--!
--! @example
--! -- Functional GIN index — canonical containment recipe
--! CREATE INDEX ON users USING gin (
--!   eql_v2.to_stevec_query(encrypted_doc)::jsonb jsonb_path_ops
--! );
--!
--! -- Cross-row containment
--! SELECT a.*
--!   FROM docs a, docs b
--!  WHERE a.encrypted_doc @> b.encrypted_doc::eql_v2.stevec_query
--!    AND b.id = 42;
--!
--! @see eql_v2.stevec_query
--! @see eql_v2."@>"(eql_v2_encrypted, eql_v2.stevec_query)
CREATE FUNCTION eql_v2.to_stevec_query(e eql_v2_encrypted)
  RETURNS eql_v2.stevec_query
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT jsonb_build_object(
    'sv',
    coalesce(
      (SELECT jsonb_agg(
                jsonb_strip_nulls(
                  jsonb_build_object(
                    's',  elem -> 's',
                    'hm', elem -> 'hm',
                    'oc', elem -> 'oc'
                  )
                )
              )
       FROM jsonb_array_elements((e).data -> 'sv') AS elem),
      '[]'::jsonb
    )
  )::eql_v2.stevec_query
$$;

CREATE CAST (eql_v2_encrypted AS eql_v2.stevec_query)
  WITH FUNCTION eql_v2.to_stevec_query
  AS ASSIGNMENT;
