-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_query_types.sql
-- REQUIRE: src/v3/scalars/numeric/numeric_ord_ore_functions.sql

--! @file encrypted_domain/numeric/numeric_ord_ore_query_functions.sql
--! @brief Functions for public.numeric_ord_ore_query.

--! @brief Index extractor for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore_query
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.numeric_ord_ore_query)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore
--! @param b public.numeric_ord_ore_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_ord_ore, b public.numeric_ord_ore_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore_query
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.numeric_ord_ore_query, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore
--! @param b public.numeric_ord_ore_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_ord_ore, b public.numeric_ord_ore_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore_query
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.numeric_ord_ore_query, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore
--! @param b public.numeric_ord_ore_query
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.numeric_ord_ore, b public.numeric_ord_ore_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore_query
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.numeric_ord_ore_query, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore
--! @param b public.numeric_ord_ore_query
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.numeric_ord_ore, b public.numeric_ord_ore_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore_query
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.numeric_ord_ore_query, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore
--! @param b public.numeric_ord_ore_query
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.numeric_ord_ore, b public.numeric_ord_ore_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore_query
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.numeric_ord_ore_query, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore
--! @param b public.numeric_ord_ore_query
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.numeric_ord_ore, b public.numeric_ord_ore_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.numeric_ord_ore_query.
--! @param a public.numeric_ord_ore_query
--! @param b public.numeric_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.numeric_ord_ore_query, b public.numeric_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;
