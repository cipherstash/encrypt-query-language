-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/ste_vec/types.sql
-- REQUIRE: src/ste_vec/functions.sql

--! @brief Contains operator for encrypted values (@>)
--!
--! Implements the @> (contains) operator for testing if left encrypted value
--! contains the right encrypted value. Uses ste_vec (secure tree encoding vector)
--! index terms for containment testing without decryption.
--!
--! Primarily used for encrypted array or set containment queries.
--!
--! @param a eql_v2_encrypted Left operand (container)
--! @param b eql_v2_encrypted Right operand (contained value)
--! @return Boolean True if a contains b
--!
--! @example
--! -- Check if encrypted array contains value
--! SELECT * FROM documents
--! WHERE encrypted_tags @> '["security"]'::jsonb::eql_v2_encrypted;
--!
--! @note Requires ste_vec index configuration
--! @see eql_v2.ste_vec_contains
--! @see eql_v2.add_search_config
-- Marked IMMUTABLE STRICT PARALLEL SAFE so the planner inlines the body
-- and a functional GIN index on `eql_v2.ste_vec(col)` can match
-- `WHERE col @> val`. The previous default-VOLATILE declaration prevented
-- inlining and forced seq scan even on Supabase installs that have the
-- ste_vec functional index in place.
CREATE FUNCTION eql_v2."@>"(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ste_vec_contains(a, b)
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v2."@>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);


--! @brief Contains operator (@>) with an `eql_v2.stevec_query` needle
--!
--! Type-safe containment for the recommended recipe: the right-hand
--! side is an `stevec_query` (sv-shaped payload, no `c` fields), making
--! it explicit at the API surface that containment matches indexes
--! (selector + `hm`/`oc`) rather than ciphertexts. The
--! `ste_vec_contains` body ignores `c` either way; the typed needle
--! documents and enforces the contract.
--!
--! @param a eql_v2_encrypted Left operand (container)
--! @param b eql_v2.stevec_query Right operand (query payload)
--! @return Boolean True if a contains b
--!
--! @example
--! SELECT * FROM users
--! WHERE encrypted_doc @> '{"sv":[{"s":"<sel>","hm":"<hm>"}]}'::eql_v2.stevec_query;
--!
--! @see eql_v2.stevec_query
--! @see eql_v2.ste_vec_contains
CREATE FUNCTION eql_v2."@>"(a eql_v2_encrypted, b eql_v2.stevec_query)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ste_vec_contains(a, eql_v2.to_encrypted(b::jsonb))
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v2."@>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2.stevec_query
);


--! @brief Contains operator (@>) with an `eql_v2.ste_vec_entry` needle
--!
--! Convenience overload for the common pattern "does this encrypted
--! payload include this specific sv entry?". Wraps the entry into a
--! single-element sv array (stripping its `c` field, which the
--! containment logic ignores anyway) so it can dispatch through the
--! standard `ste_vec_contains` machinery. Inlinable.
--!
--! @param a eql_v2_encrypted Left operand (container)
--! @param b eql_v2.ste_vec_entry Right operand (single entry)
--! @return Boolean True if a contains an sv entry matching `b`
--!
--! @example
--! -- Does this row's encrypted doc contain the same name as this other doc?
--! SELECT a.* FROM docs a, docs b
--!  WHERE a.doc @> (b.doc -> '<name-sel>');
--!
--! @see eql_v2.ste_vec_entry
--! @see eql_v2."@>"(eql_v2_encrypted, eql_v2.stevec_query)
CREATE FUNCTION eql_v2."@>"(a eql_v2_encrypted, b eql_v2.ste_vec_entry)
RETURNS boolean
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT eql_v2.ste_vec_contains(
    a,
    eql_v2.to_encrypted(jsonb_build_object('sv', jsonb_build_array(b - 'c')))
  )
$$;

CREATE OPERATOR @>(
  FUNCTION=eql_v2."@>",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2.ste_vec_entry
);
