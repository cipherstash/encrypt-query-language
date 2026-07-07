-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/query_text_types.sql
-- REQUIRE: src/v3/scalars/text/text_match_functions.sql

--! @file encrypted_domain/text/query_text_match_functions.sql
--! @brief Functions for public.query_text_match.

--! @brief Index extractor for public.query_text_match.
--! @param a public.query_text_match
--! @return eql_v3_internal.bloom_filter
CREATE FUNCTION eql_v3.match_term(a public.query_text_match)
RETURNS eql_v3_internal.bloom_filter
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.bloom_filter(a::jsonb) $$;

--! @brief Operator wrapper for public.query_text_match.
--! @param a public.text_match
--! @param b public.query_text_match
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.text_match, b public.query_text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.query_text_match.
--! @param a public.query_text_match
--! @param b public.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.query_text_match, b public.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.query_text_match.
--! @param a public.text_match
--! @param b public.query_text_match
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.text_match, b public.query_text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.query_text_match.
--! @param a public.query_text_match
--! @param b public.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.query_text_match, b public.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;
