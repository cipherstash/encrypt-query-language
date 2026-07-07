-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_query_types.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_ord_functions.sql

--! @file encrypted_domain/smallint/smallint_ord_query_functions.sql
--! @brief Functions for public.smallint_ord_query.

--! @brief Index extractor for public.smallint_ord_query.
--! @param a public.smallint_ord_query
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.smallint_ord_query)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord
--! @param b public.smallint_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_ord, b public.smallint_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord_query
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_ord_query, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord
--! @param b public.smallint_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_ord, b public.smallint_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord_query
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_ord_query, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord
--! @param b public.smallint_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.smallint_ord, b public.smallint_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord_query
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.smallint_ord_query, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord
--! @param b public.smallint_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.smallint_ord, b public.smallint_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord_query
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.smallint_ord_query, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord
--! @param b public.smallint_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.smallint_ord, b public.smallint_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord_query
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.smallint_ord_query, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord
--! @param b public.smallint_ord_query
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.smallint_ord, b public.smallint_ord_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.smallint_ord_query.
--! @param a public.smallint_ord_query
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.smallint_ord_query, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;
