-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/query_double_types.sql
-- REQUIRE: src/v3/scalars/double/double_ord_ore_functions.sql

--! @file encrypted_domain/double/query_double_ord_ore_functions.sql
--! @brief Functions for public.query_double_ord_ore.

--! @brief Index extractor for public.query_double_ord_ore.
--! @param a public.query_double_ord_ore
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.query_double_ord_ore)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.query_double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_ord_ore, b public.query_double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.query_double_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.query_double_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.query_double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_ord_ore, b public.query_double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.query_double_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.query_double_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.query_double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.double_ord_ore, b public.query_double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.query_double_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.query_double_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.query_double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.double_ord_ore, b public.query_double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.query_double_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.query_double_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.query_double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.double_ord_ore, b public.query_double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.query_double_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.query_double_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.query_double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.double_ord_ore, b public.query_double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_double_ord_ore.
--! @param a public.query_double_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.query_double_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;
