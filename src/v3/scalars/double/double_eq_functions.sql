-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/hmac_256/functions.sql

--! @file encrypted_domain/double/double_eq_functions.sql
--! @brief Functions for public.double_eq.

--! @brief Index extractor for public.double_eq.
--! @param a public.double_eq
--! @return eql_v3_internal.hmac_256
CREATE FUNCTION eql_v3.eq_term(a public.double_eq)
RETURNS eql_v3_internal.hmac_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.hmac_256(a::jsonb) $$;

--! @brief Operator wrapper for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_eq, b public.double_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b::public.double_eq) $$;

--! @brief Operator wrapper for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.double_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::public.double_eq) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_eq, b public.double_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_eq, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b::public.double_eq) $$;

--! @brief Operator wrapper for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.double_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a::public.double_eq) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.double_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.double_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a jsonb, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.double_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.double_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a jsonb, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.double_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.double_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a jsonb, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.double_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.double_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a jsonb, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_eq, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param selector text
--! @return public.double_eq
CREATE FUNCTION eql_v3_internal."->"(a public.double_eq, selector text)
RETURNS public.double_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param selector integer
--! @return public.double_eq
CREATE FUNCTION eql_v3_internal."->"(a public.double_eq, selector integer)
RETURNS public.double_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param selector public.double_eq
--! @return public.double_eq
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.double_eq)
RETURNS public.double_eq IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.double_eq, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.double_eq, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param selector public.double_eq
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.double_eq)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.double_eq, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.double_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.double_eq, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.double_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.double_eq, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.double_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.double_eq, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double_eq, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double_eq, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.double_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.double_eq, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.double_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_eq, b public.double_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_eq, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a jsonb
--! @param b public.double_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.double_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_eq'; END; $$
LANGUAGE plpgsql;
