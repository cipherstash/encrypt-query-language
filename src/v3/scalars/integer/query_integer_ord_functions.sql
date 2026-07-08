-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/integer/query_integer_types.sql
-- REQUIRE: src/v3/scalars/integer/integer_ord_functions.sql

--! @file encrypted_domain/integer/query_integer_ord_functions.sql
--! @brief Functions for eql_v3.query_integer_ord.

--! @brief Index extractor for eql_v3.query_integer_ord.
--! @param a eql_v3.query_integer_ord
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a eql_v3.query_integer_ord)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a public.integer_ord
--! @param b eql_v3.query_integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.integer_ord, b eql_v3.query_integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a eql_v3.query_integer_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a eql_v3.query_integer_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a public.integer_ord
--! @param b eql_v3.query_integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.integer_ord, b eql_v3.query_integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a eql_v3.query_integer_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a eql_v3.query_integer_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a public.integer_ord
--! @param b eql_v3.query_integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.integer_ord, b eql_v3.query_integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a eql_v3.query_integer_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a eql_v3.query_integer_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a public.integer_ord
--! @param b eql_v3.query_integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.integer_ord, b eql_v3.query_integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a eql_v3.query_integer_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a eql_v3.query_integer_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a public.integer_ord
--! @param b eql_v3.query_integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.integer_ord, b eql_v3.query_integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a eql_v3.query_integer_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a eql_v3.query_integer_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a public.integer_ord
--! @param b eql_v3.query_integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.integer_ord, b eql_v3.query_integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for eql_v3.query_integer_ord.
--! @param a eql_v3.query_integer_ord
--! @param b public.integer_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a eql_v3.query_integer_ord, b public.integer_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;
