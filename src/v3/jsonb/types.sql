-- REQUIRE: src/v3/schema.sql

--! @file v3/jsonb/types.sql
--! @brief Domain types for the eql_v3 encrypted-JSONB (SteVec) surface.
--!
--! Three jsonb-backed domains (none over another domain — operators resolve
--! against the ultimate base type jsonb, so the native-jsonb firewall in
--! blockers.sql can attach):
--!   - eql_v3.json     — storage/root: an EQL envelope object ({i, v, ...}).
--!   - eql_v3.jsonb_entry — a single sv element (returned by `->`).
--!   - eql_v3.jsonb_query  — a containment needle (sv elements, no ciphertext).

--! @brief Validate a single SteVec entry payload.
--! @internal
--! @param val jsonb Candidate entry payload.
--! @return boolean True when `val` is an sv entry with string `s`, string `c`,
--!         and exactly one string deterministic term (`hm` XOR `oc`).
CREATE FUNCTION eql_v3.is_valid_ste_vec_entry_payload(val jsonb)
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
CREATE FUNCTION eql_v3.is_valid_ste_vec_query_payload(val jsonb)
  RETURNS boolean
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT COALESCE(
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
  )
$$;

--! @brief Validate a root SteVec document payload.
--! @internal
--! @param val jsonb Candidate document payload.
--! @return boolean True when `val` is an encrypted document envelope with
--!         `v = 3`, `i`, an `sv` array, and valid sv entry elements.
CREATE FUNCTION eql_v3.is_valid_ste_vec_document_payload(val jsonb)
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
       WHERE NOT eql_v3.is_valid_ste_vec_entry_payload(elem)
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
--! what keeps `eql_v3.json` a typed document domain rather than a generic
--! encrypted envelope. The firewall in blockers.sql attaches to this domain to
--! stop native jsonb operators from reaching a column value.
--!
--! @note Constructing from inline JSON uses the standard DOMAIN cast:
--!       `'{"i":{},"v":3,"sv":[...]}'::eql_v3.json`.
CREATE DOMAIN eql_v3.json AS jsonb
  CHECK (
    eql_v3.is_valid_ste_vec_document_payload(VALUE)
  );

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
CREATE DOMAIN eql_v3.jsonb_entry AS jsonb
  CHECK (
    eql_v3.is_valid_ste_vec_entry_payload(VALUE)
  );

--! @brief Domain type for an STE-vec containment needle.
--!
--! A query-shaped payload `{"sv":[...]}` whose elements carry selector + index
--! term but **never** a ciphertext (`c`). Each element must carry `s` and
--! exactly one deterministic term (`hm` XOR `oc`). Typing the needle this way
--! stops selector-only needles from casting and matching every row via bare
--! `jsonb @>`.
--!
--! @note Construct from inline JSON via the DOMAIN cast:
--!       `'{"sv":[{"s":"<sel>","hm":"<hm>"}]}'::eql_v3.jsonb_query`.
--! @see eql_v3.to_ste_vec_query
CREATE DOMAIN eql_v3.jsonb_query AS jsonb
  CHECK (
    eql_v3.is_valid_ste_vec_query_payload(VALUE)
  );

--! @brief Convert an eql_v3.json to a jsonb_query needle.
--!
--! Normalises each sv element down to the matching-relevant fields: `s` plus
--! exactly one of `hm` / `oc`. Other fields (`c`, `a`, `i`/`v`, anything else)
--! are stripped. This is the canonical needle shape for `@>` containment.
--! Designed for use as a functional GIN index expression:
--!   `GIN (eql_v3.to_ste_vec_query(col)::jsonb jsonb_path_ops)`.
--!
--! @param e eql_v3.json Source encrypted payload
--! @return eql_v3.jsonb_query Query-shaped needle, sv elements normalised.
--! @see eql_v3.jsonb_query
CREATE FUNCTION eql_v3.to_ste_vec_query(e eql_v3.json)
  RETURNS eql_v3.jsonb_query
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
  )::eql_v3.jsonb_query
$$;

CREATE CAST (eql_v3.json AS eql_v3.jsonb_query)
  WITH FUNCTION eql_v3.to_ste_vec_query
  AS ASSIGNMENT;
