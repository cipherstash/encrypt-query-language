-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/double/double_types.sql
-- REQUIRE: src/v3/scalars/double/double_functions.sql
-- REQUIRE: src/v3/scalars/double/double_eq_functions.sql
-- REQUIRE: src/v3/scalars/double/double_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/double/double_ord_functions.sql
-- REQUIRE: src/v3/scalars/double/double_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/float8/float8_types.sql
-- REQUIRE: src/v3/scalars/float8/float8_functions.sql
-- REQUIRE: src/v3/scalars/float8/float8_eq_functions.sql
-- REQUIRE: src/v3/scalars/float8/float8_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/float8/float8_ord_functions.sql
-- REQUIRE: src/v3/scalars/float8/float8_ord_ope_functions.sql

--! @file encrypted_domain/double/double__float8_cross.sql
--! @brief Cross-name operators between double and float8.

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double, b public.float8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double.
--! @param a public.double
--! @param b public.float8
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double, b public.float8)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_eq, b public.float8_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_eq, b public.float8_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.double_eq, b public.float8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.double_eq, b public.float8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.double_eq, b public.float8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.double_eq, b public.float8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_eq, b public.float8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_eq, b public.float8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_eq.
--! @param a public.double_eq
--! @param b public.float8_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_eq, b public.float8_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord_ore.
--! @param a public.double_ord_ore
--! @param b public.float8_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_ord_ore, b public.float8_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_ord, b public.float8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_ord, b public.float8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.double_ord, b public.float8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.double_ord, b public.float8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.double_ord, b public.float8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.double_ord, b public.float8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_ord, b public.float8_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_ord, b public.float8_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord.
--! @param a public.double_ord
--! @param b public.float8_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_ord, b public.float8_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.double_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.double_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.double_ord_ope.
--! @param a public.double_ord_ope
--! @param b public.float8_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.double_ord_ope, b public.float8_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.double_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float8, b public.double)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8.
--! @param a public.float8
--! @param b public.double
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float8, b public.double)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float8_eq, b public.double_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float8_eq, b public.double_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.float8_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.float8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.float8_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.float8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.float8_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.float8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.float8_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.float8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float8_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float8_eq, b public.double_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_eq.
--! @param a public.float8_eq
--! @param b public.double_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float8_eq, b public.double_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_ord_ore.
--! @param a public.float8_ord_ore
--! @param b public.double_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float8_ord_ore, b public.double_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float8_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float8_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.float8_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.float8_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.float8_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.float8_ord, b public.double_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float8_ord, b public.double_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float8_ord, b public.double_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_ord.
--! @param a public.float8_ord
--! @param b public.double_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float8_ord, b public.double_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float8_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float8_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float8_ord_ope.
--! @param a public.float8_ord_ope
--! @param b public.double_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float8_ord_ope, b public.double_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float8_ord_ope'; END; $$
LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double, RIGHTARG = public.float8
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double_eq, RIGHTARG = public.float8_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double_ord_ore, RIGHTARG = public.float8_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double_ord, RIGHTARG = public.float8_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.double_ord_ope, RIGHTARG = public.float8_ord_ope
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float8, RIGHTARG = public.double
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float8_eq, RIGHTARG = public.double_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float8_ord_ore, RIGHTARG = public.double_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float8_ord, RIGHTARG = public.double_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float8_ord_ope, RIGHTARG = public.double_ord_ope
);
