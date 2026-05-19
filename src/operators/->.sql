-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/encrypted/functions.sql
-- REQUIRE: src/ste_vec/types.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @brief JSONB field accessor operator for encrypted values (->)
--!
--! Implements the -> operator to access fields/elements from encrypted JSONB data.
--! Returns the matching sv entry as `eql_v2.ste_vec_entry` (or NULL on miss).
--!
--! Encrypted JSON is represented as an array of sv elements in the
--! StEVec format. Each element has a selector, ciphertext, and index
--! terms: `{"sv": [{"c": "...", "s": "...", "hm": "..."}, ...]}`.
--!
--! Provides three overloads:
--! - (eql_v2_encrypted, text) - Field name selector
--! - (eql_v2_encrypted, eql_v2_encrypted) - Encrypted selector
--! - (eql_v2_encrypted, integer) - Array index selector (0-based)
--!
--! All three return `eql_v2.ste_vec_entry` and preserve the source
--! payload's root `i` / `v` envelope metadata in the returned entry
--! (the DOMAIN CHECK on `ste_vec_entry` doesn't forbid extra fields).
--!
--! @note Operator resolution: Assignment casts are considered (PostgreSQL standard behavior).
--! To use text selector, parameter may need explicit cast to text.
--!
--! @see eql_v2.ste_vec_entry
--! @see eql_v2.selector
--! @see eql_v2."->>"

--! @brief -> operator with text selector
--!
--! Returns the sv entry whose `s` selector equals @p selector, with
--! the source payload's `i` / `v` metadata merged in. Selectors are
--! deterministic per (path, key) within a document, so at most one
--! entry matches; `jsonb_path_query_first` returns the first match
--! and stops scanning.
--!
--! Inlinable single-statement SQL: the planner folds this body into
--! the calling query, so `WHERE col -> 'sel' = $1` reduces structurally
--! to `eql_v2.eq_term(col -> 'sel') = eql_v2.eq_term($1)` and matches
--! a functional index built on `eql_v2.eq_term(col -> 'sel')`.
--!
--! @param e eql_v2_encrypted Encrypted JSONB payload (root)
--! @param selector text Selector hash (the `s` field value)
--! @return eql_v2.ste_vec_entry Matching entry merged with root meta,
--!         NULL if no element matches.
--!
--! @note The returned entry carries `i` / `v` from the root in addition
--!       to the sv-element fields. This is intentional: per-entry
--!       extractors (`eql_v2.eq_term`, `eql_v2.ore_cllw`, ...) read
--!       only their own fields and ignore `i` / `v`; callers that need
--!       the root envelope (e.g. for decryption) still see it.
--!
--! @example
--! SELECT encrypted_json -> 'field_name' FROM table;
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector text)
  RETURNS eql_v2.ste_vec_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT (
    eql_v2.meta_data(e) ||
    jsonb_path_query_first(
      (e).data,
      '$.sv[*] ? (@.s == $sel)'::jsonpath,
      jsonb_build_object('sel', selector)
    )
  )::eql_v2.ste_vec_entry
$$;


CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=text
);

---------------------------------------------------

--! @brief -> operator with encrypted selector
--!
--! Convenience overload: extracts the selector text from an encrypted
--! selector payload and delegates to the (text) form. Inlinable.
--!
--! @param e eql_v2_encrypted Encrypted JSONB data
--! @param selector eql_v2_encrypted Encrypted selector payload
--! @return eql_v2.ste_vec_entry Matching entry, NULL on miss
--! @see eql_v2."->"(eql_v2_encrypted, text)
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector eql_v2_encrypted)
  RETURNS eql_v2.ste_vec_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2."->"(e, eql_v2._selector(selector))
$$;



CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);


---------------------------------------------------

--! @brief -> operator with integer array index
--!
--! Returns the sv entry at the given (0-based, JSONB-style) array
--! index, merged with the root payload's `i` / `v` metadata. Returns
--! NULL when the underlying value isn't an sv-array payload or when
--! the index is out of bounds.
--!
--! @param e eql_v2_encrypted Encrypted sv-array payload
--! @param selector integer Array index (0-based, JSONB convention)
--! @return eql_v2.ste_vec_entry Matching entry, NULL on miss
--! @note Array index is 0-based (JSONB standard) despite PostgreSQL arrays being 1-based
--! @example
--! SELECT encrypted_array -> 0 FROM table;
--! @see eql_v2.is_ste_vec_array
CREATE FUNCTION eql_v2."->"(e eql_v2_encrypted, selector integer)
  RETURNS eql_v2.ste_vec_entry
  LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT CASE
    WHEN eql_v2.is_ste_vec_array(e) THEN
      (eql_v2.meta_data(e) || ((e).data -> 'sv' -> selector))::eql_v2.ste_vec_entry
    ELSE NULL
  END
$$;





CREATE OPERATOR ->(
  FUNCTION=eql_v2."->",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=integer
);

