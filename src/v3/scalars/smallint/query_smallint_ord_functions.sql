-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/smallint/query_smallint_types.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_ord_functions.sql

--! @file encrypted_domain/smallint/query_smallint_ord_functions.sql
--! @brief Functions for public.query_smallint_ord.

--! @brief Index extractor for public.query_smallint_ord.
--! @param a public.query_smallint_ord
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.query_smallint_ord)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.smallint_ord
--! @param b public.query_smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_ord, b public.query_smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.query_smallint_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.query_smallint_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.smallint_ord
--! @param b public.query_smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_ord, b public.query_smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.query_smallint_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.query_smallint_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.smallint_ord
--! @param b public.query_smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.smallint_ord, b public.query_smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.query_smallint_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.query_smallint_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.smallint_ord
--! @param b public.query_smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.smallint_ord, b public.query_smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.query_smallint_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.query_smallint_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.smallint_ord
--! @param b public.query_smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.smallint_ord, b public.query_smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.query_smallint_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.query_smallint_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.smallint_ord
--! @param b public.query_smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.smallint_ord, b public.query_smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord.
--! @param a public.query_smallint_ord
--! @param b public.smallint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.query_smallint_ord, b public.smallint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;
