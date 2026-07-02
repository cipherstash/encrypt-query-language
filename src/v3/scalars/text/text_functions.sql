-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/text/text_types.sql
-- REQUIRE: src/v3/scalars/functions.sql

--! @file encrypted_domain/text/text_functions.sql
--! @brief Functions for eql_v3.text.

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.text, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a eql_v3.text, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b eql_v3.text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param selector text
--! @return eql_v3.text
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.text, selector text)
RETURNS eql_v3.text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param selector integer
--! @return eql_v3.text
CREATE FUNCTION eql_v3_internal."->"(a eql_v3.text, selector integer)
RETURNS eql_v3.text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param selector eql_v3.text
--! @return eql_v3.text
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector eql_v3.text)
RETURNS eql_v3.text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.text, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a eql_v3.text, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param selector eql_v3.text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector eql_v3.text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a eql_v3.text, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a eql_v3.text, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a eql_v3.text, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a eql_v3.text, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a eql_v3.text, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a eql_v3.text, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a eql_v3.text, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.text, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.text, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a eql_v3.text, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a eql_v3.text, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b eql_v3.text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.text, b eql_v3.text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a eql_v3.text
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a eql_v3.text, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for eql_v3.text.
--! @param a jsonb
--! @param b eql_v3.text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b eql_v3.text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'eql_v3.text'; END; $$
LANGUAGE plpgsql;
