-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/bloom_filter/functions.sql

--! @file encrypted_domain/text/text_match_functions.sql
--! @brief Functions for eql_v3.text_match.

--! @brief Index extractor for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @return eql_v3_internal.bloom_filter
CREATE FUNCTION eql_v3.match_term(a eql_v3.text_match)
RETURNS eql_v3_internal.bloom_filter
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.bloom_filter(a::jsonb) $$;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.text_match, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.text_match)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contains(a eql_v3.text_match, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) @> eql_v3.match_term(b::eql_v3.text_match) $$;

--! @brief Operator wrapper for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contains(a jsonb, b eql_v3.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a::eql_v3.text_match) @> eql_v3.match_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.text_match, b eql_v3.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b) $$;

--! @brief Operator wrapper for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a eql_v3.text_match, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a) <@ eql_v3.match_term(b::eql_v3.text_match) $$;

--! @brief Operator wrapper for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return boolean
CREATE FUNCTION eql_v3.contained_by(a jsonb, b eql_v3.text_match)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.match_term(a::eql_v3.text_match) <@ eql_v3.match_term(b) $$;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param selector text
--! @return eql_v3.text_match
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.text_match, selector text)
RETURNS eql_v3.text_match IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param selector integer
--! @return eql_v3.text_match
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.text_match, selector integer)
RETURNS eql_v3.text_match IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param selector eql_v3.text_match
--! @return eql_v3.text_match
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.text_match)
RETURNS eql_v3.text_match IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.text_match, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.text_match, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param selector eql_v3.text_match
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.text_match)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.text_match, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.text_match, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.text_match, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.text_match, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.text_match, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.text_match, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.text_match, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.text_match, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.text_match, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.text_match, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.text_match, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b eql_v3.text_match
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.text_match, b eql_v3.text_match)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a eql_v3.text_match
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.text_match, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text_match.
--! @param a jsonb
--! @param b eql_v3.text_match
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.text_match)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text_match'; END; $$
LANGUAGE plpgsql;
