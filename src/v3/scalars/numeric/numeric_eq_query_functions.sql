-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_query_types.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_eq_functions.sql

--! @file encrypted_domain/numeric/numeric_eq_query_functions.sql
--! @brief Functions for public.numeric_eq_query.

--! @brief Index extractor for public.numeric_eq_query.
--! @param a public.numeric_eq_query
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.numeric_eq_query)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.numeric_eq_query.
--! @param a public.numeric_eq
--! @param b public.numeric_eq_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_eq, b public.numeric_eq_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.numeric_eq_query.
--! @param a public.numeric_eq_query
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_eq_query, b public.numeric_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.numeric_eq_query.
--! @param a public.numeric_eq
--! @param b public.numeric_eq_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_eq, b public.numeric_eq_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.numeric_eq_query.
--! @param a public.numeric_eq_query
--! @param b public.numeric_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_eq_query, b public.numeric_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;
