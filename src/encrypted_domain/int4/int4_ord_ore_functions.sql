-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/operators.sql

--! @file encrypted_domain/int4/int4_ord_ore_functions.sql
--! @brief Concrete ordered int4 variant — comparison/path functions
--!        (equality + ORE-block ordering).
--!
--! eql_v2_int4_ord_ore carries `c`, `ob`. It is the scheme-explicit
--! ordered domain: it carries the eql_v2.ord_term() extractor, the six
--! comparison wrappers, the operator declarations, and the blockers.
--! eql_v2_int4_ord — the recommended ordered name — is a separate
--! concrete domain (int4_ord.sql) carrying its own copy of this
--! operator surface; the §8 spike showed a domain-over-domain alias
--! does not transparently inherit the operator surface (D-E fallback).
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
--! @param a eql_v2_int4_ord_ore Ordered encrypted int4 value
--! @return eql_v2.ore_block_u64_8_256 ORE-block index term
--! @throws Exception if the `ob` field is missing from the payload
--! @see eql_v2.ore_block_u64_8_256
--! @example
--! -- functional index for range + equality
--! CREATE INDEX t_col_idx ON t USING btree (eql_v2.ord_term(col));
--! -- ordering
--! SELECT ... FROM t ORDER BY eql_v2.ord_term(col);
CREATE FUNCTION eql_v2.ord_term(a eql_v2_int4_ord_ore)
RETURNS eql_v2.ore_block_u64_8_256
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ore_block_u64_8_256(a::jsonb) $$;

-- = <> < <= > >= comparison wrappers, 3 arg-shapes each (18 functions).
-- All LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE, no SET clause, so they
-- inline: `col < $1` becomes `eql_v2.ord_term(col) < eql_v2.ord_term($1)`.

--! @brief Less-than wrapper for eql_v2_int4_ord_ore. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.lt(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) < eql_v2.ord_term(b::eql_v2_int4_ord_ore) $$;

--! @brief Less-than wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.lt(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord_ore) < eql_v2.ord_term(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ore. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <= eql_v2.ord_term(b) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.lte(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <= eql_v2.ord_term(b::eql_v2_int4_ord_ore) $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.lte(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord_ore) <= eql_v2.ord_term(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ore. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) > eql_v2.ord_term(b) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.gt(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) > eql_v2.ord_term(b::eql_v2_int4_ord_ore) $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.gt(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord_ore) > eql_v2.ord_term(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ore. Inlines to ORE-block compare.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) >= eql_v2.ord_term(b) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.gte(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) >= eql_v2.ord_term(b::eql_v2_int4_ord_ore) $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.gte(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord_ore) >= eql_v2.ord_term(b) $$;

--! @brief Equality wrapper for eql_v2_int4_ord_ore. Routes through ord — ORE on
--!        full-domain int4 is lossless, so this is exact equality.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) = eql_v2.ord_term(b) $$;

--! @brief Equality wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eq(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) = eql_v2.ord_term(b::eql_v2_int4_ord_ore) $$;

--! @brief Equality wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eq(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord_ore) = eql_v2.ord_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ore. Routes through ord.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <> eql_v2.ord_term(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.neq(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a) <> eql_v2.ord_term(b::eql_v2_int4_ord_ore) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.neq(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.ord_term(a::eql_v2_int4_ord_ore) <> eql_v2.ord_term(b) $$;

-- ~~, ~~*, @>, <@ (blockers, 3 shapes each)

--! @brief Blocker for ~~ on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_like(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_like(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_like(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_ilike(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_ilike(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_ilike(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contains(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.contained_by(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

--! @brief Blocker for -> on eql_v2_int4_ord_ore (domain, text).
--! @param a eql_v2_int4_ord_ore
--! @param selector text
--! @return eql_v2_int4_ord_ore (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_ord_ore, selector text)
RETURNS eql_v2_int4_ord_ore IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord_ore (domain, integer).
--! @param a eql_v2_int4_ord_ore
--! @param selector integer
--! @return eql_v2_int4_ord_ore (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a eql_v2_int4_ord_ore, selector integer)
RETURNS eql_v2_int4_ord_ore IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord_ore
--! @return eql_v2_int4_ord_ore (never returns; always raises)
CREATE FUNCTION eql_v2."->"(a jsonb, selector eql_v2_int4_ord_ore)
RETURNS eql_v2_int4_ord_ore IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ore (domain, text).
--! @param a eql_v2_int4_ord_ore
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_ord_ore, selector text)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ore (domain, integer).
--! @param a eql_v2_int4_ord_ore
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a eql_v2_int4_ord_ore, selector integer)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord_ore
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2."->>"(a jsonb, selector eql_v2_int4_ord_ore)
RETURNS text IMMUTABLE PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;
