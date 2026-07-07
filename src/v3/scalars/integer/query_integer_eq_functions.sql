-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/query_integer_types.sql
-- REQUIRE: src/v3/scalars/integer/integer_eq_functions.sql

--! @file encrypted_domain/integer/query_integer_eq_functions.sql
--! @brief Functions for public.query_integer_eq.

--! @brief Index extractor for public.query_integer_eq.
--! @param a public.query_integer_eq
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.query_integer_eq)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.query_integer_eq.
--! @param a public.integer_eq
--! @param b public.query_integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_eq, b public.query_integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_integer_eq.
--! @param a public.query_integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.query_integer_eq, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_integer_eq.
--! @param a public.integer_eq
--! @param b public.query_integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_eq, b public.query_integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_integer_eq.
--! @param a public.query_integer_eq
--! @param b public.integer_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.query_integer_eq, b public.integer_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;
