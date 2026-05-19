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
--! `{"sv": [...]}` payload and explicitly forbids `c` on any
--! element. The implementation of `ste_vec_contains` ignores `c`
--! either way, but typing the needle as `stevec_query` documents
--! the contract at the API surface.
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
    AND NOT jsonb_path_exists(VALUE, '$.sv[*] ? (exists(@.c))'::jsonpath)
  );


--! @brief Convert an `eql_v2_encrypted` to a `stevec_query` needle
--!
--! Strips the `c` (ciphertext) field from each sv element and rewraps
--! the result as a `stevec_query`. Useful for "does this payload
--! contain a row's sv shape?" style queries where the right-hand side
--! is sourced from another encrypted column.
--!
--! @param e eql_v2_encrypted Source encrypted payload
--! @return eql_v2.stevec_query Query-shaped needle with all `c` fields removed
--!
--! @example
--! SELECT a.*
--!   FROM docs a, docs b
--!  WHERE a.encrypted_doc @> b.encrypted_doc::eql_v2.stevec_query
--!    AND b.id = 42;
--!
--! @see eql_v2.stevec_query
CREATE FUNCTION eql_v2.to_stevec_query(e eql_v2_encrypted)
  RETURNS eql_v2.stevec_query
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT jsonb_build_object(
    'sv',
    coalesce(
      (SELECT jsonb_agg(elem - 'c')
       FROM jsonb_array_elements((e).data -> 'sv') AS elem),
      '[]'::jsonb
    )
  )::eql_v2.stevec_query
$$;

CREATE CAST (eql_v2_encrypted AS eql_v2.stevec_query)
  WITH FUNCTION eql_v2.to_stevec_query
  AS ASSIGNMENT;
