-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/bloom_filter/functions.sql

--! @file encrypted_domain/text/text_match_functions.sql
--! @brief Functions for public.eql_v3_text_match.

--! @brief Index extractor for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @return eql_v3_internal.bloom_filter
CREATE FUNCTION eql_v3.match_term(a public.eql_v3_text_match)
RETURNS eql_v3_internal.bloom_filter
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.bloom_filter(a::jsonb) $$;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.eql_v3_text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a public.eql_v3_text_match, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b::public.eql_v3_text_match) $$;

--! @brief Operator wrapper for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b public.eql_v3_text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a::public.eql_v3_text_match) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a public.eql_v3_text_match, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b::public.eql_v3_text_match) $$;

--! @brief Operator wrapper for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b public.eql_v3_text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a::public.eql_v3_text_match) <@ eql_v3.match_term(b) $$;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param selector text
--! @return public.eql_v3_text_match
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_text_match, selector text)
RETURNS public.eql_v3_text_match IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param selector integer
--! @return public.eql_v3_text_match
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_text_match, selector integer)
RETURNS public.eql_v3_text_match IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param selector public.eql_v3_text_match
--! @return public.eql_v3_text_match
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.eql_v3_text_match)
RETURNS public.eql_v3_text_match IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_text_match, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_text_match, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param selector public.eql_v3_text_match
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.eql_v3_text_match)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.eql_v3_text_match, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.eql_v3_text_match, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.eql_v3_text_match, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.eql_v3_text_match, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_text_match, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.eql_v3_text_match, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.eql_v3_text_match, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_text_match, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_text_match, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_text_match, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.eql_v3_text_match, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b public.eql_v3_text_match
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_text_match, b public.eql_v3_text_match)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a public.eql_v3_text_match
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_text_match, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_text_match.
--! @param a jsonb
--! @param b public.eql_v3_text_match
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.eql_v3_text_match)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_text_match'; END; $$
LANGUAGE plpgsql;
