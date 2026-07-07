-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_query_types.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_eq_functions.sql

--! @file encrypted_domain/smallint/smallint_eq_query_functions.sql
--! @brief Functions for public.smallint_eq_query.

--! @brief Index extractor for public.smallint_eq_query.
--! @param a public.smallint_eq_query
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.smallint_eq_query)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.smallint_eq_query.
--! @param a public.smallint_eq
--! @param b public.smallint_eq_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_eq, b public.smallint_eq_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.smallint_eq_query.
--! @param a public.smallint_eq_query
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_eq_query, b public.smallint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.smallint_eq_query.
--! @param a public.smallint_eq
--! @param b public.smallint_eq_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_eq, b public.smallint_eq_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.smallint_eq_query.
--! @param a public.smallint_eq_query
--! @param b public.smallint_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_eq_query, b public.smallint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;
