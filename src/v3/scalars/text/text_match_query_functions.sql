-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_query_types.sql
-- REQUIRE: src/v3/scalars/text/text_match_functions.sql

--! @file encrypted_domain/text/text_match_query_functions.sql
--! @brief Functions for public.text_match_query.

--! @brief Index extractor for public.text_match_query.
--! @param a public.text_match_query
--! @return eql_v3_internal.bloom_filter
CREATE FUNCTION eql_v3.match_term(a public.text_match_query)
RETURNS eql_v3_internal.bloom_filter
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.bloom_filter(a::jsonb) $$;

--! @brief Operator wrapper for public.text_match_query.
--! @param a public.text_match
--! @param b public.text_match_query
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.text_match, b public.text_match_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.text_match_query.
--! @param a public.text_match_query
--! @param b public.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.text_match_query, b public.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.text_match_query.
--! @param a public.text_match
--! @param b public.text_match_query
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.text_match, b public.text_match_query)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.text_match_query.
--! @param a public.text_match_query
--! @param b public.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.text_match_query, b public.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;
