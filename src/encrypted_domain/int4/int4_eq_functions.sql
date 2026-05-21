-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/hmac_256/functions.sql

--! @file encrypted_domain/int4/int4_eq_functions.sql
--! @brief Equality-only int4 variant — comparison/path functions. Supports = and <> via HMAC-256.
--!
--! eql_v2_int4_eq carries `c`, `hm` and supports HMAC equality. The
--! functional btree on ((eql_v2.hmac_256(col::jsonb))) engages for `=`.
--! `<>` is supported but is a seq-scan (btree supports only equality).
--! All other operators raise. Payload-term assumption: `c`, `hm`.

-- = / <> (HMAC equality wrappers, 3 shapes each)

--! @brief Equality wrapper for eql_v2_int4_eq. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq_eq(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Equality wrapper for eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq_eq(a eql_v2_int4_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b) $$;

--! @brief Equality wrapper for eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq_eq(a jsonb, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4_eq. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq_neq(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq_neq(a eql_v2_int4_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_eq_neq(a jsonb, b eql_v2_int4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) <> eql_v2.hmac_256(b::jsonb) $$;

-- <, <=, >, >=, ~~, ~~*, @>, <@ (blockers, 3 shapes each — 8 ops × 3 = 24 functions)

--! @brief Blocker for < on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_lt(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_lt(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for < on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_lt(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_lte(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_lte(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <= on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_lte(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_gt(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_gt(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for > on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_gt(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_gte(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_gte(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for >= on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_gte(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '>='); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_like(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_like(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_like(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_ilike(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_ilike(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_ilike(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_contains(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_contains(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_contains(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_eq.
--! @param a eql_v2_int4_eq
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_contained_by(a eql_v2_int4_eq, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_eq (domain, jsonb).
--! @param a eql_v2_int4_eq
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_contained_by(a eql_v2_int4_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_eq
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_contained_by(a jsonb, b eql_v2_int4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_eq', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

--! @brief Blocker for -> on eql_v2_int4_eq (domain, text).
--! @param a eql_v2_int4_eq
--! @param selector text
--! @return eql_v2_int4_eq (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_arrow(a eql_v2_int4_eq, selector text)
RETURNS eql_v2_int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_eq (domain, integer).
--! @param a eql_v2_int4_eq
--! @param selector integer
--! @return eql_v2_int4_eq (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_arrow(a eql_v2_int4_eq, selector integer)
RETURNS eql_v2_int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_eq
--! @return eql_v2_int4_eq (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_arrow(a jsonb, selector eql_v2_int4_eq)
RETURNS eql_v2_int4_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_eq (domain, text).
--! @param a eql_v2_int4_eq
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_arrow_text(a eql_v2_int4_eq, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_eq (domain, integer).
--! @param a eql_v2_int4_eq
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_arrow_text(a eql_v2_int4_eq, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_eq (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_eq
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_eq_arrow_text(a jsonb, selector eql_v2_int4_eq)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_eq'; END; $$
LANGUAGE plpgsql;
