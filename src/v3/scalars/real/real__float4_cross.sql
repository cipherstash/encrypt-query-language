-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql
-- REQUIRE: src/v3/scalars/real/real_types.sql
-- REQUIRE: src/v3/scalars/real/real_functions.sql
-- REQUIRE: src/v3/scalars/real/real_eq_functions.sql
-- REQUIRE: src/v3/scalars/real/real_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/real/real_ord_functions.sql
-- REQUIRE: src/v3/scalars/real/real_ord_ope_functions.sql
-- REQUIRE: src/v3/scalars/float4/float4_types.sql
-- REQUIRE: src/v3/scalars/float4/float4_functions.sql
-- REQUIRE: src/v3/scalars/float4/float4_eq_functions.sql
-- REQUIRE: src/v3/scalars/float4/float4_ord_ore_functions.sql
-- REQUIRE: src/v3/scalars/float4/float4_ord_functions.sql
-- REQUIRE: src/v3/scalars/float4/float4_ord_ope_functions.sql

--! @file encrypted_domain/real/real__float4_cross.sql
--! @brief Cross-name operators between real and float4.

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.real, b public.float4)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real.
--! @param a public.real
--! @param b public.float4
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.real, b public.float4)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.real_eq, b public.float4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.real_eq, b public.float4_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.real_eq, b public.float4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.real_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.real_eq, b public.float4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.real_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.real_eq, b public.float4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.real_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.real_eq, b public.float4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.real_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.real_eq, b public.float4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.real_eq, b public.float4_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_eq.
--! @param a public.real_eq
--! @param b public.float4_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.real_eq, b public.float4_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_ord_ore.
--! @param a public.real_ord_ore
--! @param b public.float4_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.real_ord_ore, b public.float4_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.real_ord, b public.float4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.real_ord, b public.float4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.real_ord, b public.float4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.real_ord, b public.float4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.real_ord, b public.float4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.real_ord, b public.float4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.real_ord, b public.float4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.real_ord, b public.float4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_ord.
--! @param a public.real_ord
--! @param b public.float4_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.real_ord, b public.float4_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.real_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.real_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.real_ord_ope.
--! @param a public.real_ord_ope
--! @param b public.float4_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.real_ord_ope, b public.float4_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.real_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.eq(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '=', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.neq(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<>', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float4, b public.real)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4.
--! @param a public.float4
--! @param b public.real
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float4, b public.real)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float4'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float4_eq, b public.real_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) = eql_v3.eq_term(b) $$;

--! @brief Operator wrapper for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float4_eq, b public.real_eq)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.eq_term(a) <> eql_v3.eq_term(b) $$;

--! @brief Unsupported operator blocker for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lt(a public.float4_eq, b public.real_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<', 'public.float4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.lte(a public.float4_eq, b public.real_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<=', 'public.float4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gt(a public.float4_eq, b public.real_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>', 'public.float4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.gte(a public.float4_eq, b public.real_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '>=', 'public.float4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float4_eq, b public.real_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float4_eq, b public.real_eq)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_eq.
--! @param a public.float4_eq
--! @param b public.real_eq
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float4_eq, b public.real_eq)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float4_eq'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_ord_ore.
--! @param a public.float4_ord_ore
--! @param b public.real_ord_ore
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float4_ord_ore, b public.real_ord_ore)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float4_ord, b public.real_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) = eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float4_ord, b public.real_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <> eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.float4_ord, b public.real_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) < eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.float4_ord, b public.real_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) <= eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.float4_ord, b public.real_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) > eql_v3.ord_term(b) $$;

--! @brief Operator wrapper for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.float4_ord, b public.real_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_term(a) >= eql_v3.ord_term(b) $$;

--! @brief Unsupported operator blocker for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float4_ord, b public.real_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float4_ord, b public.real_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_ord.
--! @param a public.float4_ord
--! @param b public.real_ord
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float4_ord, b public.real_ord)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Operator wrapper for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.eq(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) = eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.neq(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <> eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lt(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) < eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.lte(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) <= eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gt(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) > eql_v3.ord_ope_term(b) $$;

--! @brief Operator wrapper for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3.gte(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v3.ord_ope_term(a) >= eql_v3.ord_ope_term(b) $$;

--! @brief Unsupported operator blocker for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contains(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '@>', 'public.float4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return boolean
CREATE FUNCTION eql_v3_internal.contained_by(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '<@', 'public.float4_ord_ope'; END; $$
LANGUAGE plpgsql;

--! @brief Unsupported operator blocker for public.float4_ord_ope.
--! @param a public.float4_ord_ope
--! @param b public.real_ord_ope
--! @return jsonb
CREATE FUNCTION eql_v3_internal."||"(a public.float4_ord_ope, b public.real_ord_ope)
RETURNS jsonb IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '||', 'public.float4_ord_ope'; END; $$
LANGUAGE plpgsql;


CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.real, RIGHTARG = public.float4
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.real_eq, RIGHTARG = public.float4_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.real_ord_ore, RIGHTARG = public.float4_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.real_ord, RIGHTARG = public.float4_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.real_ord_ope, RIGHTARG = public.float4_ord_ope
);

CREATE OPERATOR = (
  FUNCTION = eql_v3_internal.eq,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3_internal.neq,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float4, RIGHTARG = public.real
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3_internal.lt,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3_internal.lte,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq
);

CREATE OPERATOR > (
  FUNCTION = eql_v3_internal.gt,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3_internal.gte,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float4_eq, RIGHTARG = public.real_eq
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float4_ord_ore, RIGHTARG = public.real_ord_ore
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float4_ord, RIGHTARG = public.real_ord
);

CREATE OPERATOR = (
  FUNCTION = eql_v3.eq,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope,
  COMMUTATOR = =, NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v3.neq,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope,
  COMMUTATOR = <>, NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v3.lt,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope,
  COMMUTATOR = >, NEGATOR = >=, RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  FUNCTION = eql_v3.lte,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope,
  COMMUTATOR = >=, NEGATOR = >, RESTRICT = scalarlesel, JOIN = scalarlejoinsel
);

CREATE OPERATOR > (
  FUNCTION = eql_v3.gt,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope,
  COMMUTATOR = <, NEGATOR = <=, RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  FUNCTION = eql_v3.gte,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope,
  COMMUTATOR = <=, NEGATOR = <, RESTRICT = scalargesel, JOIN = scalargejoinsel
);

CREATE OPERATOR @> (
  FUNCTION = eql_v3_internal.contains,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope
);

CREATE OPERATOR <@ (
  FUNCTION = eql_v3_internal.contained_by,
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope
);

CREATE OPERATOR || (
  FUNCTION = eql_v3_internal."||",
  LEFTARG = public.float4_ord_ope, RIGHTARG = public.real_ord_ope
);
