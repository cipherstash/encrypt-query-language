-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/integer_query_types.sql
-- REQUIRE: src/v3/scalars/integer/integer_ord_ope_functions.sql

--! @file encrypted_domain/integer/integer_ord_ope_query_functions.sql
--! @brief Functions for public.integer_ord_ope_query.

--! @brief Index extractor for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope_query
--! @return eql_v3_internal.ope_cllw
CREATE FUNCTION eql_v3.ord_ope_term(a public.integer_ord_ope_query)
RETURNS eql_v3_internal.ope_cllw
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ope_cllw(a::jsonb) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope
--! @param b public.integer_ord_ope_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_ord_ope, b public.integer_ord_ope_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope_query
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_ord_ope_query, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope
--! @param b public.integer_ord_ope_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_ord_ope, b public.integer_ord_ope_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope_query
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_ord_ope_query, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope
--! @param b public.integer_ord_ope_query
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.integer_ord_ope, b public.integer_ord_ope_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope_query
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.integer_ord_ope_query, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope
--! @param b public.integer_ord_ope_query
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.integer_ord_ope, b public.integer_ord_ope_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope_query
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.integer_ord_ope_query, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope
--! @param b public.integer_ord_ope_query
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.integer_ord_ope, b public.integer_ord_ope_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope_query
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.integer_ord_ope_query, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope
--! @param b public.integer_ord_ope_query
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.integer_ord_ope, b public.integer_ord_ope_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.integer_ord_ope_query.
--! @param a public.integer_ord_ope_query
--! @param b public.integer_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.integer_ord_ope_query, b public.integer_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;
