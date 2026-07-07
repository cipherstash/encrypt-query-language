-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/smallint/query_smallint_types.sql
-- REQUIRE: src/v3/scalars/smallint/smallint_ord_ope_functions.sql

--! @file encrypted_domain/smallint/query_smallint_ord_ope_functions.sql
--! @brief Functions for public.query_smallint_ord_ope.

--! @brief Index extractor for public.query_smallint_ord_ope.
--! @param a public.query_smallint_ord_ope
--! @return eql_v3_internal.ope_cllw
CREATE FUNCTION eql_v3.ord_ope_term(a public.query_smallint_ord_ope)
RETURNS eql_v3_internal.ope_cllw
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ope_cllw(a::jsonb) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.query_smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.smallint_ord_ope, b public.query_smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.query_smallint_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.query_smallint_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.query_smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.smallint_ord_ope, b public.query_smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.query_smallint_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.query_smallint_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.query_smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.smallint_ord_ope, b public.query_smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.query_smallint_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.query_smallint_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.query_smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.smallint_ord_ope, b public.query_smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.query_smallint_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.query_smallint_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.query_smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.smallint_ord_ope, b public.query_smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.query_smallint_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.query_smallint_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.smallint_ord_ope
--! @param b public.query_smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.smallint_ord_ope, b public.query_smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.query_smallint_ord_ope.
--! @param a public.query_smallint_ord_ope
--! @param b public.smallint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.query_smallint_ord_ope, b public.smallint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;
