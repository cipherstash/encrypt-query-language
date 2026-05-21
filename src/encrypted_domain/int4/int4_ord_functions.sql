-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/operators.sql

--! @file encrypted_domain/int4/int4_ord_functions.sql
--! @brief Concrete ordered int4 variant (D-E fallback) — comparison/path
--!        functions. The recommended ordered name.
--!
--! eql_v2_int4_ord carries `c`, `ob`. It is a full concrete mirror of
--! int4_ord_ore.sql: the §8 verification spike showed the pure-alias
--! form (a domain over eql_v2_int4_ord_ore) does not transparently
--! inherit the operator surface — PostgreSQL resolves operators against
--! the ultimate base type (jsonb), so ordered operators fall through to
--! native jsonb comparison and the blockers do not engage.
--! eql_v2_int4_ord therefore carries its own eql_v2.ord_term() overload,
--! comparison wrappers, operator declarations, and blockers.
--! eql_v2_int4_ord_ore is the scheme-explicit ordered domain with the
--! identical operator surface.
--!
--! Equality and range both route through eql_v2.ord_term:
--! ord_term(a) <op> ord_term(b)
--! is the corresponding operator on eql_v2.ore_block_u64_8_256. ORE on a
--! full-domain int4 is lossless, so the order term is also an exact
--! equality term — there is no separate `hm` term (D#1).
--!
--! All six comparison wrappers are LANGUAGE sql IMMUTABLE STRICT
--! PARALLEL SAFE with no SET clause, so the planner inlines them:
--! `col < $1` becomes `eql_v2.ord_term(col) < eql_v2.ord_term($1)`. The inner `<`
--! is the operator on eql_v2.ore_block_u64_8_256, a member of main's
--! DEFAULT btree operator class. A functional index
--! `USING btree (eql_v2.ord_term(col))` therefore serves all six operators.
--!
--! @note The ORE-block operator class is excluded from the Supabase
--!       build variant, so ordered int4 columns have no indexed range on
--!       Supabase (seq-scan). See docs/upgrading/v2.4.md U-001.

--! @brief Index/ORDER BY extractor for the ordered int4 variants.
--!
--! Returns the ORE-block composite carried in the `ob` field of the
--! jsonb payload. The returned eql_v2.ore_block_u64_8_256 type carries
--! main's DEFAULT btree operator class, so a functional index
--! USING btree (eql_v2.ord_term(col)) binds that opclass automatically.
--! This is the single uniform extractor for index creation and ORDER BY
--! across the ordered variants.
--!
--! @param a eql_v2_int4_ord Ordered encrypted int4 value
--! @return eql_v2.ore_block_u64_8_256 ORE-block index term
--! @throws Exception if the `ob` field is missing from the payload
--! @see eql_v2.ore_block_u64_8_256
--! @example
--! -- functional index for range + equality
--! CREATE INDEX t_col_idx ON t USING btree (eql_v2.ord_term(col));
--! -- ordering
--! SELECT ... FROM t ORDER BY eql_v2.ord_term(col);
CREATE FUNCTION eql_v2.ord_term(a eql_v2_int4_ord)
RETURNS eql_v2.ore_block_u64_8_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ore_block_u64_8_256(a::jsonb) $$;

-- = <> < <= > >= comparison wrappers, 3 arg-shapes each (18 functions).
-- All LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE, no SET clause, so they
-- inline: `col < $1` becomes `eql_v2.ord_term(col) < eql_v2.ord_term($1)`.

--! @brief Less-than wrapper for eql_v2_int4_ord. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lt(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) < eql_v2.ord_term(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <= eql_v2.ord_term(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <= eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.lte(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) <= eql_v2.ord_term(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) > eql_v2.ord_term(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) > eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gt(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) > eql_v2.ord_term(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) >= eql_v2.ord_term(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) >= eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.gte(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) >= eql_v2.ord_term(b) $$;

--! @brief Equality wrapper for eql_v2_int4_ord. Routes through ord — ORE on
--!        full-domain int4 is lossless, so this is exact equality.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) = eql_v2.ord_term(b) $$;

--! @brief Equality wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) = eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Equality wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.eq(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) = eql_v2.ord_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord. Routes through ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <> eql_v2.ord_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_ord, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <> eql_v2.ord_term(b::eql_v2_int4_ord) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean
CREATE FUNCTION eql_v2.neq(a jsonb, b eql_v2_int4_ord)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord) <> eql_v2.ord_term(b) $$;

-- ~~, ~~*, @>, <@ (blockers, 3 shapes each)

--! @brief Blocker for ~~ on eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_like(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_like(a eql_v2_int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_like(a jsonb, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ilike(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ilike(a eql_v2_int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ilike(a jsonb, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a jsonb, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord.
--! @param a eql_v2_int4_ord
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_ord, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord (domain, jsonb).
--! @param a eql_v2_int4_ord
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_ord, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a jsonb, b eql_v2_int4_ord)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

--! @brief Blocker for -> on eql_v2_int4_ord (domain, text).
--! @param a eql_v2_int4_ord
--! @param selector text
--! @return eql_v2_int4_ord (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_ord, selector text)
RETURNS eql_v2_int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord (domain, integer).
--! @param a eql_v2_int4_ord
--! @param selector integer
--! @return eql_v2_int4_ord (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_ord, selector integer)
RETURNS eql_v2_int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord
--! @return eql_v2_int4_ord (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a jsonb, selector eql_v2_int4_ord)
RETURNS eql_v2_int4_ord IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord (domain, text).
--! @param a eql_v2_int4_ord
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_ord, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord (domain, integer).
--! @param a eql_v2_int4_ord
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_ord, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a jsonb, selector eql_v2_int4_ord)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord'; END; $$
LANGUAGE plpgsql;
