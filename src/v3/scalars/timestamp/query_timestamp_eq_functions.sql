-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/query_timestamp_types.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_eq_functions.sql

--! @file encrypted_domain/timestamp/query_timestamp_eq_functions.sql
--! @brief Functions for public.query_timestamp_eq.

--! @brief Index extractor for public.query_timestamp_eq.
--! @param a public.query_timestamp_eq
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.query_timestamp_eq)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.query_timestamp_eq.
--! @param a public.timestamp_eq
--! @param b public.query_timestamp_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.timestamp_eq, b public.query_timestamp_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_timestamp_eq.
--! @param a public.query_timestamp_eq
--! @param b public.timestamp_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.query_timestamp_eq, b public.timestamp_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_timestamp_eq.
--! @param a public.timestamp_eq
--! @param b public.query_timestamp_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.timestamp_eq, b public.query_timestamp_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.query_timestamp_eq.
--! @param a public.query_timestamp_eq
--! @param b public.timestamp_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.query_timestamp_eq, b public.timestamp_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;
