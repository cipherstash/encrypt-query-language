-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/functions.sql
-- REQUIRE: src/v3/sem/ope_cllw/functions.sql

--! @file encrypted_domain/bigint/bigint_ord_functions.sql
--! @brief Functions for public.eql_v3_bigint_ord.

--! @brief Index extractor for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @return eql_v3_internal.ope_cllw
CREATE FUNCTION eql_v3.ord_term(a public.eql_v3_bigint_ord)
RETURNS eql_v3_internal.ope_cllw
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3_internal.ope_cllw(a::jsonb) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b::public.eql_v3_bigint_ord) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b::public.eql_v3_bigint_ord) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b::public.eql_v3_bigint_ord) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b::public.eql_v3_bigint_ord) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b::public.eql_v3_bigint_ord) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b::public.eql_v3_bigint_ord) $$;

--! @brief Operator wrapper for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a::public.eql_v3_bigint_ord) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param selector text
--! @return public.eql_v3_bigint_ord
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_bigint_ord, selector text)
RETURNS public.eql_v3_bigint_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param selector integer
--! @return public.eql_v3_bigint_ord
CREATE FUNCTION eql_v3_internal."->"(a public.eql_v3_bigint_ord, selector integer)
RETURNS public.eql_v3_bigint_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param selector public.eql_v3_bigint_ord
--! @return public.eql_v3_bigint_ord
CREATE FUNCTION eql_v3_internal."->"(a jsonb, selector public.eql_v3_bigint_ord)
RETURNS public.eql_v3_bigint_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param selector text
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_bigint_ord, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param selector integer
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a public.eql_v3_bigint_ord, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param selector public.eql_v3_bigint_ord
--! @return text
CREATE FUNCTION eql_v3_internal."->>"(a jsonb, selector public.eql_v3_bigint_ord)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text
--! @return boolean
CREATE FUNCTION eql_v3_internal."?"(a public.eql_v3_bigint_ord, b text)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?|"(a public.eql_v3_bigint_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?|', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text[]
--! @return boolean
CREATE FUNCTION eql_v3_internal."?&"(a public.eql_v3_bigint_ord, b text[])
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '?&', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@?"(a public.eql_v3_bigint_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@?', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_bigint_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a jsonb, b public.eql_v3_bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonpath
--! @return boolean
CREATE FUNCTION eql_v3_internal."@@"(a public.eql_v3_bigint_ord, b jsonpath)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@@', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#>"(a public.eql_v3_bigint_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text[]
--! @return text
CREATE FUNCTION eql_v3_internal."#>>"(a public.eql_v3_bigint_ord, b text[])
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#>>', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_bigint_ord, b text)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b integer
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_bigint_ord, b integer)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."-"(a public.eql_v3_bigint_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '-', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b text[]
--! @return jsonb
CREATE FUNCTION eql_v3_internal."#-"(a public.eql_v3_bigint_ord, b text[])
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '#-', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b public.eql_v3_bigint_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_bigint_ord, b public.eql_v3_bigint_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a public.eql_v3_bigint_ord
--! @param b jsonb
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.eql_v3_bigint_ord, b jsonb)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.eql_v3_bigint_ord.
--! @param a jsonb
--! @param b public.eql_v3_bigint_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a jsonb, b public.eql_v3_bigint_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.eql_v3_bigint_ord'; END; $$
LANGUAGE plpgsql;
