-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_query_types.sql
-- REQUIRE: src/v3/scalars/text/text_search_functions.sql

--! @file encrypted_domain/text/text_search_query_functions.sql
--! @brief Functions for public.text_search_query.

--! @brief Index extractor for public.text_search_query.
--! @param a public.text_search_query
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.text_search_query)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Index extractor for public.text_search_query.
--! @param a public.text_search_query
--! @return eql_v3_internal.ore_block_256
CREATE FUNCTION eql_v3.ord_term(a public.text_search_query)
RETURNS eql_v3_internal.ore_block_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ore_block_256(a::jsonb) $$;

--! @brief Index extractor for public.text_search_query.
--! @param a public.text_search_query
--! @return eql_v3_internal.bloom_filter
CREATE FUNCTION eql_v3.match_term(a public.text_search_query)
RETURNS eql_v3_internal.bloom_filter
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.bloom_filter(a::jsonb) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search
--! @param b public.text_search_query
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.text_search, b public.text_search_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.text_search_query.
--! @param a public.text_search_query
--! @param b public.text_search
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.text_search_query, b public.text_search)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;
