-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/bloom_filter/functions.sql
-- REQUIRE: src/ope_cllw_u64_65/functions.sql
-- REQUIRE: src/ste_vec/functions.sql
-- REQUIRE: src/encrypted/casts.sql
-- REQUIRE: src/operators/->.sql
-- REQUIRE: src/operators/->>.sql

--! @file encrypted_domain/functions.sql
--! @brief Prototype functions for high-level encrypted domain operators
--!
--! Defines the shared blocker helper plus the supported and unsupported
--! operator functions for the encrypted_text and encrypted_jsonb domain
--! types. (The eql_v2_int4 variant family is defined under
--! src/encrypted_domain/int4/.)
--! These functions are stored in eql_v2, while the domain types
--! themselves remain durable in
--! public so user schema objects do not follow eql_v2 uninstall
--! lifecycle.
--!
--! Supported hot-path functions are
--! LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE with no SET search_path
--! so they inline into expressions that match the documented functional
--! indexes. Blocker functions are PL/pgSQL and raise type-specific
--! errors so unsupported operators never fall through to native jsonb
--! behavior.

--! @brief Shared blocker helper. Raises a uniform 'operator X is not supported
--!        for TYPE' exception so unsupported domain operators surface a clear
--!        error rather than fall through to native jsonb behaviour.
--! @param type_name Domain type name (encrypted_text / eql_v2_int4* / encrypted_jsonb)
--! @param operator_name Operator symbol (=, <, ~~, @>, ->, etc.)
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_domain_unsupported_bool(type_name text, operator_name text)
RETURNS boolean
IMMUTABLE STRICT PARALLEL SAFE
SET search_path = pg_catalog, extensions, public
AS $$
BEGIN
  RAISE EXCEPTION 'operator % is not supported for %', operator_name, type_name;
END;
$$ LANGUAGE plpgsql;

-- encrypted_text operators

-- =, <> (HMAC equality)

--! @brief Equality wrapper for encrypted_text. Inlines to hmac_256 comparison so functional indexes on (hmac_256(col::jsonb)) engage.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_eq(a encrypted_text, b encrypted_text)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Equality wrapper for encrypted_text. Inlines to hmac_256 comparison so functional indexes on (hmac_256(col::jsonb)) engage.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_eq(a encrypted_text, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b) $$;

--! @brief Equality wrapper for encrypted_text. Inlines to hmac_256 comparison so functional indexes on (hmac_256(col::jsonb)) engage.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_eq(a jsonb, b encrypted_text)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for encrypted_text. Inlines to hmac_256 comparison.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_neq(a encrypted_text, b encrypted_text)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for encrypted_text. Inlines to hmac_256 comparison.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_neq(a encrypted_text, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b) $$;

--! @brief Inequality wrapper for encrypted_text. Inlines to hmac_256 comparison.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_neq(a jsonb, b encrypted_text)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) <> eql_v2.hmac_256(b::jsonb) $$;

-- ~~, ~~* (bloom_filter containment)

--! @brief LIKE / ILIKE wrapper for encrypted_text. Inlines to bloom_filter containment so GIN indexes on (bloom_filter(col::jsonb)) engage.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_like(a encrypted_text, b encrypted_text)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.bloom_filter(a::jsonb) @> eql_v2.bloom_filter(b::jsonb) $$;

--! @brief LIKE / ILIKE wrapper for encrypted_text. Inlines to bloom_filter containment so GIN indexes on (bloom_filter(col::jsonb)) engage.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_like(a encrypted_text, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.bloom_filter(a::jsonb) @> eql_v2.bloom_filter(b) $$;

--! @brief LIKE / ILIKE wrapper for encrypted_text. Inlines to bloom_filter containment so GIN indexes on (bloom_filter(col::jsonb)) engage.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_text_like(a jsonb, b encrypted_text)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b::jsonb) $$;

-- Blocker template: PL/pgSQL bodies that delegate to the shared helper.
-- Three overloads per operator (same-domain + two cross-type) so unsupported
-- operations never resolve to native jsonb behavior.

--! @brief Blocker for < on encrypted_text. Raises 'operator < is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator < is not supported')
CREATE FUNCTION eql_v2.encrypted_text_lt(a encrypted_text, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on encrypted_text. Raises 'operator < is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator < is not supported')
CREATE FUNCTION eql_v2.encrypted_text_lt(a encrypted_text, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on encrypted_text. Raises 'operator < is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator < is not supported')
CREATE FUNCTION eql_v2.encrypted_text_lt(a jsonb, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on encrypted_text. Raises 'operator <= is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator <= is not supported')
CREATE FUNCTION eql_v2.encrypted_text_lte(a encrypted_text, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on encrypted_text. Raises 'operator <= is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator <= is not supported')
CREATE FUNCTION eql_v2.encrypted_text_lte(a encrypted_text, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on encrypted_text. Raises 'operator <= is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator <= is not supported')
CREATE FUNCTION eql_v2.encrypted_text_lte(a jsonb, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on encrypted_text. Raises 'operator > is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator > is not supported')
CREATE FUNCTION eql_v2.encrypted_text_gt(a encrypted_text, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on encrypted_text. Raises 'operator > is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator > is not supported')
CREATE FUNCTION eql_v2.encrypted_text_gt(a encrypted_text, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on encrypted_text. Raises 'operator > is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator > is not supported')
CREATE FUNCTION eql_v2.encrypted_text_gt(a jsonb, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on encrypted_text. Raises 'operator >= is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator >= is not supported')
CREATE FUNCTION eql_v2.encrypted_text_gte(a encrypted_text, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on encrypted_text. Raises 'operator >= is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator >= is not supported')
CREATE FUNCTION eql_v2.encrypted_text_gte(a encrypted_text, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on encrypted_text. Raises 'operator >= is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator >= is not supported')
CREATE FUNCTION eql_v2.encrypted_text_gte(a jsonb, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on encrypted_text. Raises 'operator @> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator @> is not supported')
CREATE FUNCTION eql_v2.encrypted_text_contains(a encrypted_text, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on encrypted_text. Raises 'operator @> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator @> is not supported')
CREATE FUNCTION eql_v2.encrypted_text_contains(a encrypted_text, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on encrypted_text. Raises 'operator @> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator @> is not supported')
CREATE FUNCTION eql_v2.encrypted_text_contains(a jsonb, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on encrypted_text. Raises 'operator <@ is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator <@ is not supported')
CREATE FUNCTION eql_v2.encrypted_text_contained_by(a encrypted_text, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on encrypted_text. Raises 'operator <@ is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator <@ is not supported')
CREATE FUNCTION eql_v2.encrypted_text_contained_by(a encrypted_text, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on encrypted_text. Raises 'operator <@ is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_text
--! @return boolean (never returns; always raises 'operator <@ is not supported')
CREATE FUNCTION eql_v2.encrypted_text_contained_by(a jsonb, b encrypted_text)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_text', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> blockers: text RHS, integer RHS (to block jsonb-int array access),
-- and (jsonb, encrypted_text) for symmetry.

--! @brief Blocker for -> on encrypted_text. Raises 'operator -> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param selector text
--! @return match declared RETURNS type (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_text_arrow(a encrypted_text, selector text)
RETURNS encrypted_text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'encrypted_text'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on encrypted_text. Raises 'operator -> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param selector integer
--! @return match declared RETURNS type (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_text_arrow(a encrypted_text, selector integer)
RETURNS encrypted_text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'encrypted_text'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on encrypted_text. Raises 'operator -> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param selector encrypted_text
--! @return match declared RETURNS type (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_text_arrow(a jsonb, selector encrypted_text)
RETURNS encrypted_text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'encrypted_text'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on encrypted_text. Raises 'operator ->> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param selector text
--! @return match declared RETURNS type (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_text_arrow_text(a encrypted_text, selector text)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'encrypted_text'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on encrypted_text. Raises 'operator ->> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_text
--! @param selector integer
--! @return match declared RETURNS type (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_text_arrow_text(a encrypted_text, selector integer)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'encrypted_text'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on encrypted_text. Raises 'operator ->> is not supported for encrypted_text' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param selector encrypted_text
--! @return match declared RETURNS type (never returns; always raises)
CREATE FUNCTION eql_v2.encrypted_text_arrow_text(a jsonb, selector encrypted_text)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'encrypted_text'; END; $$
LANGUAGE plpgsql;

--! @brief Normalizes a jsonb payload (top-level or per-leaf sv element) into a single-element jsonb suitable for hmac_256 derivation, so encrypted_jsonb equality composes with path access.
--! @param a jsonb
--! @return jsonb (path-local value form, hmac_256-compatible)
CREATE FUNCTION eql_v2.encrypted_jsonb_path_value(a jsonb)
RETURNS encrypted_jsonb LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
-- Synthesise a deterministic hm for payloads / leaves that lack one. The
-- COALESCE chain prefers fields that are stable across re-encryptions:
--   b3   text-leaf blake3 of plaintext (sv text elements)
--   ocv  OPE-CLLW value bytes (sv numeric / float leaves — ordered scalar)
--   ocf  ORE-CLLW value bytes (alternate ORE form for scalar leaves)
-- and only falls back to the per-encryption random ciphertext `c` (and
-- finally the jsonb-as-text serialisation) when none of the deterministic
-- terms are present. Without the ocv/ocf branches, numeric/float leaves
-- (which carry no b3) would hash through `c` and two equal numeric
-- plaintexts would compare unequal.
SELECT (
  CASE
    WHEN a ? 'hm' THEN a
    ELSE a || jsonb_build_object(
      'hm',
      jsonb_build_array(
        a->'s',
        COALESCE(a->'b3', a->'ocv', a->'ocf', a->'c', to_jsonb(a::text))
      )::text
    )
  END
)::encrypted_jsonb
$$;

-- encrypted_jsonb operators

-- =, <> (HMAC equality)

--! @brief Equality wrapper for encrypted_jsonb. Threads through path_value so = comparisons compose with -> / ->> path access.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_eq(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(a::jsonb))::jsonb) = eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(b::jsonb))::jsonb) $$;

--! @brief Equality wrapper for encrypted_jsonb. Threads through path_value so = comparisons compose with -> / ->> path access.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_eq(a encrypted_jsonb, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(a::jsonb))::jsonb) = eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(b))::jsonb) $$;

--! @brief Equality wrapper for encrypted_jsonb. Threads through path_value so = comparisons compose with -> / ->> path access.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_eq(a jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(a))::jsonb) = eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(b::jsonb))::jsonb) $$;

--! @brief Inequality wrapper for encrypted_jsonb. Threads through path_value.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_neq(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(a::jsonb))::jsonb) <> eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(b::jsonb))::jsonb) $$;

--! @brief Inequality wrapper for encrypted_jsonb. Threads through path_value.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_neq(a encrypted_jsonb, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(a::jsonb))::jsonb) <> eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(b))::jsonb) $$;

--! @brief Inequality wrapper for encrypted_jsonb. Threads through path_value.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_neq(a jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(a))::jsonb) <> eql_v2.hmac_256((eql_v2.encrypted_jsonb_path_value(b::jsonb))::jsonb) $$;

-- @>, <@ (STE-vec array containment)

--! @brief STE-vec array extractor for encrypted_jsonb. Returns a normalised jsonb[] (random ciphertext stripped, deterministic terms retained) so @> / <@ are exact across re-encryptions and the GIN functional index engages.
--! @param a encrypted_jsonb
--! @return jsonb[] (normalised STE-vec selector array)
CREATE FUNCTION eql_v2.encrypted_jsonb_array(a encrypted_jsonb)
RETURNS jsonb[] LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.jsonb_array(a::jsonb) $$;

--! @brief STE-vec array extractor for encrypted_jsonb. Returns a normalised jsonb[] (random ciphertext stripped, deterministic terms retained) so @> / <@ are exact across re-encryptions and the GIN functional index engages.
--! @param a jsonb
--! @return jsonb[] (normalised STE-vec selector array)
CREATE FUNCTION eql_v2.encrypted_jsonb_array(a jsonb)
RETURNS jsonb[] LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.jsonb_array(a) $$;

--! @brief Containment wrapper @> for encrypted_jsonb. Inlines to encrypted_jsonb_array @> encrypted_jsonb_array; engages GIN on the array extractor.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_contains(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_array(a) @> eql_v2.encrypted_jsonb_array(b) $$;

--! @brief Containment wrapper @> for encrypted_jsonb. Inlines to encrypted_jsonb_array @> encrypted_jsonb_array; engages GIN on the array extractor.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_contains(a encrypted_jsonb, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_array(a) @> eql_v2.encrypted_jsonb_array(b) $$;

--! @brief Containment wrapper @> for encrypted_jsonb. Inlines to encrypted_jsonb_array @> encrypted_jsonb_array; engages GIN on the array extractor.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_contains(a jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_array(a) @> eql_v2.encrypted_jsonb_array(b) $$;

--! @brief Contained-by wrapper <@ for encrypted_jsonb. Inlines to encrypted_jsonb_array <@ encrypted_jsonb_array.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_contained_by(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_array(a) <@ eql_v2.encrypted_jsonb_array(b) $$;

--! @brief Contained-by wrapper <@ for encrypted_jsonb. Inlines to encrypted_jsonb_array <@ encrypted_jsonb_array.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_contained_by(a encrypted_jsonb, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_array(a) <@ eql_v2.encrypted_jsonb_array(b) $$;

--! @brief Contained-by wrapper <@ for encrypted_jsonb. Inlines to encrypted_jsonb_array <@ encrypted_jsonb_array.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean
CREATE FUNCTION eql_v2.encrypted_jsonb_contained_by(a jsonb, b encrypted_jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_array(a) <@ eql_v2.encrypted_jsonb_array(b) $$;

-- Range blockers (<, <=, >, >=) and LIKE blockers (~~, ~~*)

--! @brief Blocker for < on encrypted_jsonb. Raises 'operator < is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator < is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_lt(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on encrypted_jsonb. Raises 'operator < is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator < is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_lt(a encrypted_jsonb, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on encrypted_jsonb. Raises 'operator < is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator < is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_lt(a jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on encrypted_jsonb. Raises 'operator <= is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator <= is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_lte(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on encrypted_jsonb. Raises 'operator <= is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator <= is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_lte(a encrypted_jsonb, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on encrypted_jsonb. Raises 'operator <= is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator <= is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_lte(a jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on encrypted_jsonb. Raises 'operator > is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator > is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_gt(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on encrypted_jsonb. Raises 'operator > is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator > is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_gt(a encrypted_jsonb, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on encrypted_jsonb. Raises 'operator > is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator > is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_gt(a jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on encrypted_jsonb. Raises 'operator >= is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator >= is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_gte(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on encrypted_jsonb. Raises 'operator >= is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator >= is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_gte(a encrypted_jsonb, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on encrypted_jsonb. Raises 'operator >= is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator >= is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_gte(a jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on encrypted_jsonb. Raises 'operator ~~ is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator ~~ is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_like(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on encrypted_jsonb. Raises 'operator ~~ is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator ~~ is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_like(a encrypted_jsonb, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on encrypted_jsonb. Raises 'operator ~~ is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator ~~ is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_like(a jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on encrypted_jsonb. Raises 'operator ~~* is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator ~~* is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_ilike(a encrypted_jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on encrypted_jsonb. Raises 'operator ~~* is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a encrypted_jsonb
--! @param b jsonb
--! @return boolean (never returns; always raises 'operator ~~* is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_ilike(a encrypted_jsonb, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on encrypted_jsonb. Raises 'operator ~~* is not supported for encrypted_jsonb' so the operator cannot fall through to native jsonb behaviour.
--! @param a jsonb
--! @param b encrypted_jsonb
--! @return boolean (never returns; always raises 'operator ~~* is not supported')
CREATE FUNCTION eql_v2.encrypted_jsonb_ilike(a jsonb, b encrypted_jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('encrypted_jsonb', '~~*'); END; $$
LANGUAGE plpgsql;

-- Path operators (->, ->>) — encrypted document on LHS only. Inlineable SQL
-- wrappers that delegate to eql_v2."->" / eql_v2."->>" on eql_v2_encrypted.
--
-- Contract:
--   -> (encrypted_jsonb, text)    → encrypted_jsonb : the encrypted child at the named
--                                                     selector, with a path-local `hm` token
--                                                     synthesized from the child selector/value
--                                                     so `=` / `<>` compose on path results
--   -> (encrypted_jsonb, integer) → encrypted_jsonb : the encrypted child at the array index,
--                                                     with the same synthesized path-local
--                                                     `hm` token for equality composition
--   ->> (encrypted_jsonb, text)    → text          : JSONB-as-text representation of
--                                                     (encrypted_jsonb, text) result. Both ->>
--                                                     wrappers cast the encrypted child via
--                                                     ::jsonb::text rather than delegating to
--                                                     eql_v2."->>", which would inherit the
--                                                     legacy composite-to-text cast and produce
--                                                     row-syntax (not valid JSON).
--   ->> (encrypted_jsonb, integer) → text          : JSONB-as-text representation of
--                                                     (encrypted_jsonb, integer) result. The
--                                                     returned text is parseable as a JSONB
--                                                     object whose `c` field is the leaf
--                                                     ciphertext.

--! @brief Path operator -> wrapper (text selector). Returns the encrypted child at the named selector via eql_v2."->".
--! @param a encrypted_jsonb
--! @param selector text
--! @return jsonb (encrypted child value)
CREATE FUNCTION eql_v2.encrypted_jsonb_arrow(a encrypted_jsonb, selector text)
RETURNS encrypted_jsonb LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_path_value((eql_v2."->"(eql_v2.to_encrypted(a::jsonb), selector))::jsonb) $$;

--! @brief Path operator -> wrapper (integer selector). Returns the encrypted array element at the given index via eql_v2."->".
--! @param a encrypted_jsonb
--! @param idx integer
--! @return jsonb (encrypted child value)
CREATE FUNCTION eql_v2.encrypted_jsonb_arrow_int(a encrypted_jsonb, idx integer)
RETURNS encrypted_jsonb LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.encrypted_jsonb_path_value((eql_v2."->"(eql_v2.to_encrypted(a::jsonb), idx))::jsonb) $$;

--! @brief Path operator ->> wrapper (text selector). Returns JSONB-as-text representation of the encrypted child.
--! @param a encrypted_jsonb
--! @param selector text
--! @return text (JSONB-as-text of encrypted child)
CREATE FUNCTION eql_v2.encrypted_jsonb_arrow_text(a encrypted_jsonb, selector text)
RETURNS text LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT (eql_v2."->"(eql_v2.to_encrypted(a::jsonb), selector))::jsonb::text $$;

--! @brief Path operator ->> wrapper (integer selector). Returns JSONB-as-text of the encrypted array element.
--! @param a encrypted_jsonb
--! @param idx integer
--! @return text (JSONB-as-text of encrypted child)
CREATE FUNCTION eql_v2.encrypted_jsonb_arrow_text_int(a encrypted_jsonb, idx integer)
RETURNS text LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT (eql_v2."->"(eql_v2.to_encrypted(a::jsonb), idx))::jsonb::text $$;
