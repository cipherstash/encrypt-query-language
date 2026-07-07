-- REQUIRE: src/v3/schema.sql

--! @file v3/jsonb/types.sql
--! @brief Domain types for the eql_v3 encrypted-JSONB (SteVec) surface.
--!
--! Three jsonb-backed domains (none over another domain — operators resolve
--! against the ultimate base type jsonb, so the native-jsonb firewall in
--! blockers.sql can attach):
--!   - public.json     — storage/root: an EQL envelope object ({i, v, ...}).
--!   - public.jsonb_entry — a single sv element (returned by `->`).
--!   - public.query_jsonb  — a containment needle (sv elements, no ciphertext).

--! @brief Validate a single SteVec entry payload.
--! @internal
--! @param val jsonb Candidate entry payload.
--! @return boolean True when `val` is an sv entry with string `s`, string `c`,
--!         and exactly one string deterministic term (`hm` XOR `oc`).
CREATE OR REPLACE FUNCTION public.eql_v3_is_valid_ste_vec_entry_payload(val jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT COALESCE(
    jsonb_typeof(val) = 'object'
     AND jsonb_typeof(val -> 's') = 'string'
     AND jsonb_typeof(val -> 'c') = 'string'
     AND (
       (jsonb_typeof(val -> 'hm') = 'string' AND NOT (val ? 'oc'))
       OR
       (jsonb_typeof(val -> 'oc') = 'string' AND NOT (val ? 'hm'))
     ),
    false
  )
$$;

--! @brief Validate a SteVec containment query payload.
--! @internal
--! @param val jsonb Candidate query payload.
--! @return boolean True when `val` is `{"sv":[...]}` and every element carries
--!         string `s`, no ciphertext, and exactly one string term (`hm` XOR
--!         `oc`).
--! @note plpgsql, not LANGUAGE sql (issues #353/#354): the only caller is the
--!   public.query_jsonb domain CHECK, where a SQL function can never be
--!   inlined (and the CHECK itself cannot absorb this body — it needs a
--!   subquery over the sv elements, which CHECK constraints forbid). plpgsql
--!   caches its plan across calls instead of paying the per-call SQL-function
--!   executor on every needle cast.
CREATE OR REPLACE FUNCTION public.eql_v3_is_valid_ste_vec_query_payload(val jsonb)
  RETURNS boolean
  LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
  RETURN COALESCE(
    jsonb_typeof(val) = 'object'
     AND jsonb_typeof(val -> 'sv') = 'array'
     AND NOT EXISTS (
       SELECT 1
       FROM jsonb_array_elements(
         CASE WHEN jsonb_typeof(val -> 'sv') = 'array' THEN val -> 'sv' ELSE '[]'::jsonb END
       ) AS elem
       WHERE NOT COALESCE((
         jsonb_typeof(elem) = 'object'
         AND jsonb_typeof(elem -> 's') = 'string'
         AND NOT (elem ? 'c')
         AND (
           (jsonb_typeof(elem -> 'hm') = 'string' AND NOT (elem ? 'oc'))
           OR
           (jsonb_typeof(elem -> 'oc') = 'string' AND NOT (elem ? 'hm'))
         )
       ), false)
     ),
    false
  );
END;
$$;

--! @brief Validate a root SteVec document payload.
--! @internal
--! @param val jsonb Candidate document payload.
--! @return boolean True when `val` is an encrypted document envelope with
--!         `v = 3`, `i`, an `sv` array, and valid sv entry elements.
CREATE OR REPLACE FUNCTION public.eql_v3_is_valid_ste_vec_document_payload(val jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT COALESCE(
    jsonb_typeof(val) = 'object'
     AND val ? 'v'
     AND val ->> 'v' = '3'
     AND val ? 'i'
     AND jsonb_typeof(val -> 'sv') = 'array'
     AND NOT EXISTS (
       SELECT 1
       FROM jsonb_array_elements(
         CASE WHEN jsonb_typeof(val -> 'sv') = 'array' THEN val -> 'sv' ELSE '[]'::jsonb END
       ) AS elem
       WHERE NOT public.eql_v3_is_valid_ste_vec_entry_payload(elem)
     ),
    false
  )
$$;

--! @brief Storage/root domain for an encrypted JSONB column.
--!
--! CHECK: a JSON object carrying the EQL envelope (`v = 3` version and `i` index
--! metadata). Root `c` is intentionally NOT required — an sv-array root payload
--! is `{i, v, sv}` with no root ciphertext. The CHECK now also requires an `sv`
--! array, so the domain accepts only SteVec **document** payloads and rejects
--! encrypted *scalar* payloads (which carry `c`/`hm`/`ob` but no `sv`) — this is
--! what keeps `public.json` a typed document domain rather than a generic
--! encrypted envelope. The firewall in blockers.sql attaches to this domain to
--! stop native jsonb operators from reaching a column value.
--!
--! @note Constructing from inline JSON uses the standard DOMAIN cast:
--!       `'{"i":{},"v":3,"sv":[...]}'::public.json`.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'json' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.json AS jsonb
      CHECK (
        public.eql_v3_is_valid_ste_vec_document_payload(VALUE)
      );
  END IF;

  COMMENT ON DOMAIN public.json IS 'EQL encrypted JSONB document (containment, equality, ordering)';
END
$$;

--! @brief Domain type for an individual sv element.
--!
--! A single element inside an `sv` array: a JSON object that carries a selector
--! (`s`), a ciphertext (`c`), and **exactly one** of `hm` (HMAC-256, for
--! hash-equality) or `oc` (CLLW ORE, for ordered queries) — they are mutually
--! exclusive. This is the type returned by `->` and accepted by the per-entry
--! extractors `eql_v3.eq_term` / `eql_v3.ore_cllw`. Extra fields (`a`, root
--! `i`/`v` merged in by `->`) are allowed.
--!
--! @see src/v3/jsonb/operators.sql
--!
--! @internal
--! Implementation note (issue #354): the CHECK is an INLINE expression, not a
--! call to `public.eql_v3_is_valid_ste_vec_entry_payload` — domain
--! constraints cannot inline SQL functions, so the function-call form paid
--! the per-call SQL-function executor (~18 µs) on EVERY cast: the needle
--! cast in every field_eq query (+19% end-to-end vs v2, the entire measured
--! regression on that scenario; see cipherstash/benches#23). The expression
--! mirrors the validator body; the leading `VALUE IS NULL OR` preserves the
--! validator's STRICT NULL-passes semantics (a bare COALESCE(..., false)
--! would reject NULL, which `->` returns for a missing selector). Keep the
--! two in sync — `jsonb_entry_check_matches_validator` in tests/sqlx pins
--! the equivalence.
--! @endinternal
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'jsonb_entry' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.jsonb_entry AS jsonb
      CHECK (
        VALUE IS NULL
        OR COALESCE(
          jsonb_typeof(VALUE) = 'object'
           AND jsonb_typeof(VALUE -> 's') = 'string'
           AND jsonb_typeof(VALUE -> 'c') = 'string'
           AND (
             (jsonb_typeof(VALUE -> 'hm') = 'string' AND NOT (VALUE ? 'oc'))
             OR
             (jsonb_typeof(VALUE -> 'oc') = 'string' AND NOT (VALUE ? 'hm'))
           ),
          false
        )
      );
  END IF;

  COMMENT ON DOMAIN public.jsonb_entry IS 'EQL encrypted JSONB leaf entry (equality, ordering)';
END
$$;

--! @brief Domain type for an STE-vec containment needle.
--!
--! A query-shaped payload `{"sv":[...]}` whose elements carry selector + index
--! term but **never** a ciphertext (`c`). Each element must carry `s` and
--! exactly one deterministic term (`hm` XOR `oc`). Typing the needle this way
--! stops selector-only needles from casting and matching every row via bare
--! `jsonb @>`.
--!
--! @note Construct from inline JSON via the DOMAIN cast:
--!       `'{"sv":[{"s":"<sel>","hm":"<hm>"}]}'::public.query_jsonb`.
--! @see eql_v3.to_ste_vec_query
--!
--! @internal
--! Implementation note (issue #354): this CHECK CANNOT be inlined like
--! public.jsonb_entry's — validating the sv elements requires a subquery
--! (`NOT EXISTS (SELECT ... FROM jsonb_array_elements(...))`), and CHECK
--! constraints forbid subqueries. The validator is plpgsql instead (cached
--! plan; substantially cheaper per call than a non-inlined LANGUAGE sql
--! function — the same finding as issue #353), since this cast sits on the
--! per-query hot path of every containment scenario
--! (`$1::jsonb::public.query_jsonb`).
--! @endinternal
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_jsonb' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_jsonb AS jsonb
      CHECK (
        public.eql_v3_is_valid_ste_vec_query_payload(VALUE)
      );
  END IF;

  COMMENT ON DOMAIN public.query_jsonb IS 'EQL JSONB query operand (containment)';
END
$$;

--! @brief Convert a public.json to a query_jsonb needle.
--!
--! Normalises each sv element down to the matching-relevant fields: `s` plus
--! exactly one of `hm` / `oc`. Other fields (`c`, `a`, `i`/`v`, anything else)
--! are stripped. This is the canonical needle shape for `@>` containment.
--! Designed for use as a functional GIN index expression:
--!   `GIN (eql_v3.to_ste_vec_query(col)::jsonb jsonb_path_ops)`.
--!
--! @param e public.json Source encrypted payload
--! @return public.query_jsonb Query-shaped needle, sv elements normalised.
--! @see public.query_jsonb
CREATE FUNCTION eql_v3.to_ste_vec_query(e public.json)
  RETURNS public.query_jsonb
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
       FROM jsonb_array_elements(e::jsonb -> 'sv') AS elem),
      '[]'::jsonb
    )
  )::public.query_jsonb
$$;

CREATE CAST (public.json AS public.query_jsonb)
  WITH FUNCTION eql_v3.to_ste_vec_query
  AS ASSIGNMENT;
