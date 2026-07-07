-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_query_types.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_eq_functions.sql

--! @file encrypted_domain/bigint/bigint_eq_query_functions.sql
--! @brief Functions for public.bigint_eq_query.

--! @brief Index extractor for public.bigint_eq_query.
--! @param a public.bigint_eq_query
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.bigint_eq_query)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.bigint_eq_query.
--! @param a public.bigint_eq
--! @param b public.bigint_eq_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_eq, b public.bigint_eq_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.bigint_eq_query.
--! @param a public.bigint_eq_query
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_eq_query, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.bigint_eq_query.
--! @param a public.bigint_eq
--! @param b public.bigint_eq_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_eq, b public.bigint_eq_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.bigint_eq_query.
--! @param a public.bigint_eq_query
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_eq_query, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;
