-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/timestamp/timestamp_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/ope_cllw/functions.sql

--! @file encrypted_domain/timestamp/timestamp_ord_ope_functions.sql
--! @brief Functions for public.eql_v3_timestamp_ord_ope.

--! @brief Index extractor for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @return eql_v3_internal.ope_cllw
CREATE FUNCTION eql_v3.ord_term(a public.eql_v3_timestamp_ord_ope)
RETURNS eql_v3_internal.ope_cllw
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ope_cllw(a::jsonb) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b::public.eql_v3_timestamp_ord_ope) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_timestamp_ord_ope) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b::public.eql_v3_timestamp_ord_ope) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_timestamp_ord_ope) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::public.eql_v3_timestamp_ord_ope) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_timestamp_ord_ope) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b::public.eql_v3_timestamp_ord_ope) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_timestamp_ord_ope) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b::public.eql_v3_timestamp_ord_ope) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_timestamp_ord_ope) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b::public.eql_v3_timestamp_ord_ope) $$;

--! @brief Operator wrapper for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_timestamp_ord_ope) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param selector text
--! @return public.eql_v3_timestamp_ord_ope
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_timestamp_ord_ope, selector text)
RETURNS public.eql_v3_timestamp_ord_ope IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param selector integer
--! @return public.eql_v3_timestamp_ord_ope
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_timestamp_ord_ope, selector integer)
RETURNS public.eql_v3_timestamp_ord_ope IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param selector public.eql_v3_timestamp_ord_ope
--! @return public.eql_v3_timestamp_ord_ope
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.eql_v3_timestamp_ord_ope)
RETURNS public.eql_v3_timestamp_ord_ope IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_timestamp_ord_ope, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_timestamp_ord_ope, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param selector public.eql_v3_timestamp_ord_ope
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.eql_v3_timestamp_ord_ope)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.eql_v3_timestamp_ord_ope, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.eql_v3_timestamp_ord_ope, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.eql_v3_timestamp_ord_ope, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.eql_v3_timestamp_ord_ope, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_timestamp_ord_ope, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.eql_v3_timestamp_ord_ope, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.eql_v3_timestamp_ord_ope, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_timestamp_ord_ope, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_timestamp_ord_ope, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_timestamp_ord_ope, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.eql_v3_timestamp_ord_ope, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b public.eql_v3_timestamp_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_timestamp_ord_ope, b public.eql_v3_timestamp_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a public.eql_v3_timestamp_ord_ope
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_timestamp_ord_ope, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_timestamp_ord_ope.
--! @param a jsonb
--! @param b public.eql_v3_timestamp_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.eql_v3_timestamp_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_timestamp_ord_ope'; END; $$
LANGUAGE plpgsql;
