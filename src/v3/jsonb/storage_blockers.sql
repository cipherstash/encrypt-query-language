-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/jsonb/types.sql

--! @file v3/jsonb/storage_blockers.sql
--! @brief Native-jsonb firewall for the storage-only public.eql_v3_json domain.
--!
--! public.eql_v3_json is storage-only / encryption-only (a plain {v, i, c}
--! envelope) and supports NO eql operators — unlike the searchable
--! public.eql_v3_json_search document, which supports @> <@ -> ->>. So EVERY
--! native jsonb (and scalar-comparison) operator reachable via domain fallback
--! against the base type jsonb is BLOCKED here, so an encryption-only column can
--! never silently route to plaintext-jsonb semantics. This mirrors the firewall
--! the generated scalar storage domains (e.g. public.eql_v3_boolean) install.
--!
--! Each blocker is LANGUAGE plpgsql (NEVER STRICT — a STRICT blocker would let
--! PostgreSQL skip the body and return NULL on a NULL argument, bypassing the
--! exception) and RAISEs. Each blocker's RETURNS type matches the native
--! operator it shadows so a composed expression resolves and the body raises
--! 'operator not supported', rather than failing earlier with a misleading
--! 'operator does not exist' on an intermediate.

------------------------------------------------------------------------------
-- Blocker functions.
------------------------------------------------------------------------------


--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_json, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_json, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.eql_v3_json)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector text
--! @return public.eql_v3_json
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_json, selector text)
RETURNS public.eql_v3_json IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector integer
--! @return public.eql_v3_json
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_json, selector integer)
RETURNS public.eql_v3_json IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param selector public.eql_v3_json
--! @return public.eql_v3_json
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.eql_v3_json)
RETURNS public.eql_v3_json IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_json, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_json, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param selector public.eql_v3_json
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.eql_v3_json)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.eql_v3_json, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.eql_v3_json, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.eql_v3_json, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.eql_v3_json, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_json, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.eql_v3_json, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.eql_v3_json, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_json, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_json, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_json, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.eql_v3_json, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b public.eql_v3_json
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_json, b public.eql_v3_json)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a public.eql_v3_json
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_json, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_json.
--! @param a jsonb
--! @param b public.eql_v3_json
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.eql_v3_json)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_json'; END; $$
LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- Operators.
------------------------------------------------------------------------------


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.eql_v3_json, RIGHTARG = text
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = public.eql_v3_json, RIGHTARG = integer
);

CREATE OPERATOR -> (
  FUNCTION = eql_v3_internal."->",
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.eql_v3_json, RIGHTARG = text
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = public.eql_v3_json, RIGHTARG = integer
);

CREATE OPERATOR ->> (
  FUNCTION = eql_v3_internal."->>",
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR ? (
  FUNCTION = eql_v3_internal."?",
  LEFTARG = public.eql_v3_json, RIGHTARG = text
);

CREATE OPERATOR ?| (
  FUNCTION = eql_v3_internal."?|",
  LEFTARG = public.eql_v3_json, RIGHTARG = text[]
);

CREATE OPERATOR ?& (
  FUNCTION = eql_v3_internal."?&",
  LEFTARG = public.eql_v3_json, RIGHTARG = text[]
);

CREATE OPERATOR @? (
  FUNCTION = eql_v3_internal."@?",
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonpath
);

CREATE OPERATOR @@ (
  FUNCTION = eql_v3_internal."@@",
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonpath
);

CREATE OPERATOR #> (
  FUNCTION = eql_v3_internal."#>",
  LEFTARG = public.eql_v3_json, RIGHTARG = text[]
);

CREATE OPERATOR #>> (
  FUNCTION = eql_v3_internal."#>>",
  LEFTARG = public.eql_v3_json, RIGHTARG = text[]
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.eql_v3_json, RIGHTARG = text
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.eql_v3_json, RIGHTARG = integer
);

CREATE OPERATOR - (
  FUNCTION = eql_v3_internal."-",
  LEFTARG = public.eql_v3_json, RIGHTARG = text[]
);

CREATE OPERATOR #- (
  FUNCTION = eql_v3_internal."#-",
  LEFTARG = public.eql_v3_json, RIGHTARG = text[]
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.eql_v3_json, RIGHTARG = public.eql_v3_json
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.eql_v3_json, RIGHTARG = jsonb
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = jsonb, RIGHTARG = public.eql_v3_json
);
