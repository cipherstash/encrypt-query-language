-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/date/date_query_types.sql
-- REQUIRE: src/v3/scalars/date/date_ord_functions.sql

--! @file encrypted_domain/date/date_ord_query_functions.sql
--! @brief Functions for public.date_ord_query.

--! @brief Index extractor for public.date_ord_query.
--! @param a public.date_ord_query
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.date_ord_query)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord
--! @param b public.date_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.date_ord, b public.date_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord_query
--! @param b public.date_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.date_ord_query, b public.date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord
--! @param b public.date_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.date_ord, b public.date_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord_query
--! @param b public.date_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.date_ord_query, b public.date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord
--! @param b public.date_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.date_ord, b public.date_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord_query
--! @param b public.date_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.date_ord_query, b public.date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord
--! @param b public.date_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.date_ord, b public.date_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord_query
--! @param b public.date_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.date_ord_query, b public.date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord
--! @param b public.date_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.date_ord, b public.date_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord_query
--! @param b public.date_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.date_ord_query, b public.date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord
--! @param b public.date_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.date_ord, b public.date_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.date_ord_query.
--! @param a public.date_ord_query
--! @param b public.date_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.date_ord_query, b public.date_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;
