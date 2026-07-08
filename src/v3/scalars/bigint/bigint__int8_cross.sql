-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_types.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_functions.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_eq_functions.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_functions.sql
-- REQUIRE: src/v3/scalars/bigint/bigint_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/int8/int8_types.sql
-- REQUIRE: src/v3/scalars/int8/int8_functions.sql
-- REQUIRE: src/v3/scalars/int8/int8_eq_functions.sql
-- REQUIRE: src/v3/scalars/int8/int8_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/int8/int8_ord_functions.sql
-- REQUIRE: src/v3/scalars/int8/int8_ord_ope_functions.sql

--! @file encrypted_domain/bigint/bigint__int8_cross.sql
--! @brief Cross-name operators between bigint and int8.

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint, b public.int8)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint.
--! @param a public.bigint
--! @param b public.int8
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint, b public.int8)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_eq, b public.int8_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_eq, b public.int8_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.bigint_eq, b public.int8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.bigint_eq, b public.int8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.bigint_eq, b public.int8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.bigint_eq, b public.int8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint_eq, b public.int8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint_eq, b public.int8_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_eq.
--! @param a public.bigint_eq
--! @param b public.int8_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint_eq, b public.int8_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_ord_ore.
--! @param a public.bigint_ord_ore
--! @param b public.int8_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint_ord_ore, b public.int8_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_ord, b public.int8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_ord, b public.int8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.bigint_ord, b public.int8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.bigint_ord, b public.int8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.bigint_ord, b public.int8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.bigint_ord, b public.int8_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint_ord, b public.int8_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint_ord, b public.int8_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_ord.
--! @param a public.bigint_ord
--! @param b public.int8_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint_ord, b public.int8_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.bigint_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.bigint_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.bigint_ord_ope.
--! @param a public.bigint_ord_ope
--! @param b public.int8_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.bigint_ord_ope, b public.int8_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.bigint_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int8, b public.bigint)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8.
--! @param a public.int8
--! @param b public.bigint
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int8, b public.bigint)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int8_eq, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int8_eq, b public.bigint_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.int8_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.int8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.int8_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.int8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.int8_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.int8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.int8_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.int8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int8_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int8_eq, b public.bigint_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_eq.
--! @param a public.int8_eq
--! @param b public.bigint_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int8_eq, b public.bigint_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_ord_ore.
--! @param a public.int8_ord_ore
--! @param b public.bigint_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int8_ord_ore, b public.bigint_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int8_ord, b public.bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int8_ord, b public.bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int8_ord, b public.bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int8_ord, b public.bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int8_ord, b public.bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int8_ord, b public.bigint_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int8_ord, b public.bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int8_ord, b public.bigint_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_ord.
--! @param a public.int8_ord
--! @param b public.bigint_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int8_ord, b public.bigint_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.int8_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.int8_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.int8_ord_ope.
--! @param a public.int8_ord_ope
--! @param b public.bigint_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.int8_ord_ope, b public.bigint_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.int8_ord_ope'; END; $$
LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.bigint, RIGHTARG = public.int8
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.bigint_eq, RIGHTARG = public.int8_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.bigint_ord_ore, RIGHTARG = public.int8_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.bigint_ord, RIGHTARG = public.int8_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.bigint_ord_ope, RIGHTARG = public.int8_ord_ope
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int8, RIGHTARG = public.bigint
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int8_eq, RIGHTARG = public.bigint_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int8_ord_ore, RIGHTARG = public.bigint_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int8_ord, RIGHTARG = public.bigint_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.int8_ord_ope, RIGHTARG = public.bigint_ord_ope
);
