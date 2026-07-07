-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/query_text_types.sql
-- REQUIRE: src/v3/scalars/text/text_ord_ope_functions.sql

--! @file encrypted_domain/text/query_text_ord_ope_functions.sql
--! @brief Functions for public.query_text_ord_ope.

--! @brief Index extractor for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.query_text_ord_ope)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Index extractor for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @return eql_v3_internal.ope_cllw
CREATE FUNCTION eql_v3.ord_ope_term(a public.query_text_ord_ope)
RETURNS eql_v3_internal.ope_cllw
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ope_cllw(a::jsonb) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.text_ord_ope
--! @param b public.query_text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.text_ord_ope, b public.query_text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @param b public.text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.query_text_ord_ope, b public.text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.text_ord_ope
--! @param b public.query_text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.text_ord_ope, b public.query_text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @param b public.text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.query_text_ord_ope, b public.text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.text_ord_ope
--! @param b public.query_text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.text_ord_ope, b public.query_text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @param b public.text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.query_text_ord_ope, b public.text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.text_ord_ope
--! @param b public.query_text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.text_ord_ope, b public.query_text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @param b public.text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.query_text_ord_ope, b public.text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.text_ord_ope
--! @param b public.query_text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.text_ord_ope, b public.query_text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @param b public.text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.query_text_ord_ope, b public.text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.text_ord_ope
--! @param b public.query_text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.text_ord_ope, b public.query_text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_text_ord_ope.
--! @param a public.query_text_ord_ope
--! @param b public.text_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.query_text_ord_ope, b public.text_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;
