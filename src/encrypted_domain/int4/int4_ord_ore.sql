-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted_domain/types.sql
-- REQUIRE: src/encrypted_domain/functions.sql
-- REQUIRE: src/hmac_256/functions.sql
-- REQUIRE: src/ore_block_u64_8_256/compare.sql
-- REQUIRE: src/encrypted/casts.sql

--! @file encrypted_domain/int4/int4_ord_ore.sql
--! @brief Equality + ORE-block ordering int4 variant.
--!
--! eql_v2_int4_ord_ore carries `hm` and `ob`. Equality uses HMAC
--! (functional btree engages). Range operators reduce to
--! eql_v2.compare_ore_block_u64_8_256(eql_v2_encrypted, eql_v2_encrypted)
--! and **are seq-scan**: compare_ore_block_u64_8_256 is PL/pgSQL and
--! does not inline, so no functional btree on the extractor engages.
--! See docs/upgrading/v2.4.md U-001 (Range-index limitation) — choose
--! eql_v2_int4_ord_ope if range performance matters.
--! Payload-term assumption: `hm`, `ob`.

-- = / <> (HMAC equality wrappers, 3 shapes each)

--! @brief Equality wrapper for eql_v2_int4_ord_ore. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_eq(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Equality wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_eq(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) = eql_v2.hmac_256(b) $$;

--! @brief Equality wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_eq(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) = eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ore. Inlines to hmac_256 comparison.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_neq(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b::jsonb) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_neq(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a::jsonb) <> eql_v2.hmac_256(b) $$;

--! @brief Inequality wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_neq(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.hmac_256(a) <> eql_v2.hmac_256(b::jsonb) $$;

-- <, <=, >, >= (ORE-block range wrappers, 3 shapes each)
-- compare_ore_block_u64_8_256 only accepts (eql_v2_encrypted, eql_v2_encrypted),
-- so every jsonb arg requires an explicit ::eql_v2_encrypted cast (via
-- src/encrypted/casts.sql). Range is seq-scan: see file-level @brief and U-001.

--! @brief Less-than wrapper for eql_v2_int4_ord_ore. Reduces to compare_ore_block_u64_8_256 < 0.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_lt(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) < 0 $$;

--! @brief Less-than wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_lt(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) < 0 $$;

--! @brief Less-than wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_lt(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) < 0 $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_lte(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) <= 0 $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_lte(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) <= 0 $$;

--! @brief Less-than-or-equal wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_lte(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) <= 0 $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_gt(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) > 0 $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_gt(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) > 0 $$;

--! @brief Greater-than wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_gt(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) > 0 $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_gte(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) >= 0 $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_gte(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::jsonb::eql_v2_encrypted, b::eql_v2_encrypted) >= 0 $$;

--! @brief Greater-than-or-equal wrapper for eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_gte(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT eql_v2.compare_ore_block_u64_8_256(a::eql_v2_encrypted, b::jsonb::eql_v2_encrypted) >= 0 $$;

-- ~~, ~~*, @>, <@ (blockers, 3 shapes each)

--! @brief Blocker for ~~ on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_like(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_like(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~ on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_like(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_ilike(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_ilike(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ~~* on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_ilike(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '~~*'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_contains(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_contains(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for @> on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_contains(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '@>'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ore.
--! @param a eql_v2_int4_ord_ore
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_contained_by(a eql_v2_int4_ord_ore, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ore (domain, jsonb).
--! @param a eql_v2_int4_ord_ore
--! @param b jsonb
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_contained_by(a eql_v2_int4_ord_ore, b jsonb)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '<@'); END; $$
LANGUAGE plpgsql;

--! @brief Blocker for <@ on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param b eql_v2_int4_ord_ore
--! @return boolean (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_contained_by(a jsonb, b eql_v2_int4_ord_ore)
RETURNS boolean IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RETURN eql_v2.encrypted_domain_unsupported_bool('eql_v2_int4_ord_ore', '<@'); END; $$
LANGUAGE plpgsql;

-- -> and ->> (blockers, 3 asymmetric shapes each)

--! @brief Blocker for -> on eql_v2_int4_ord_ore (domain, text).
--! @param a eql_v2_int4_ord_ore
--! @param selector text
--! @return eql_v2_int4_ord_ore (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_arrow(a eql_v2_int4_ord_ore, selector text)
RETURNS eql_v2_int4_ord_ore IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord_ore (domain, integer).
--! @param a eql_v2_int4_ord_ore
--! @param selector integer
--! @return eql_v2_int4_ord_ore (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_arrow(a eql_v2_int4_ord_ore, selector integer)
RETURNS eql_v2_int4_ord_ore IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for -> on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord_ore
--! @return eql_v2_int4_ord_ore (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_arrow(a jsonb, selector eql_v2_int4_ord_ore)
RETURNS eql_v2_int4_ord_ore IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ore (domain, text).
--! @param a eql_v2_int4_ord_ore
--! @param selector text
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_arrow_text(a eql_v2_int4_ord_ore, selector text)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ore (domain, integer).
--! @param a eql_v2_int4_ord_ore
--! @param selector integer
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_arrow_text(a eql_v2_int4_ord_ore, selector integer)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

--! @brief Blocker for ->> on eql_v2_int4_ord_ore (jsonb, domain).
--! @param a jsonb
--! @param selector eql_v2_int4_ord_ore
--! @return text (never returns; always raises)
CREATE FUNCTION eql_v2.eql_v2_int4_ord_ore_arrow_text(a jsonb, selector eql_v2_int4_ord_ore)
RETURNS text IMMUTABLE STRICT PARALLEL SAFE
AS $$ BEGIN RAISE EXCEPTION 'operator % is not supported for %', '->>', 'eql_v2_int4_ord_ore'; END; $$
LANGUAGE plpgsql;

-- Operator declarations

CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_eq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_eq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);
CREATE OPERATOR = (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_eq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = <>, RESTRICT = eqsel, JOIN = eqjoinsel
);

CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_neq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_neq,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);
CREATE OPERATOR <> (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_neq,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore,
  NEGATOR = =, RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR < (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_lt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR < (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR <= (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_lte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalarltsel, JOIN = scalarltjoinsel
);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR <= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_lte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR > (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_gt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gt,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR > (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gt,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR >= (
  FUNCTION = eql_v2.eql_v2_int4_ord_ore_gte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore,
  RESTRICT = scalargtsel, JOIN = scalargtjoinsel
);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gte,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR >= (FUNCTION = eql_v2.eql_v2_int4_ord_ore_gte,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_like,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_like,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR ~~ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_like,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ore_ilike,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ore_ilike,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR ~~* (FUNCTION = eql_v2.eql_v2_int4_ord_ore_ilike,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contains,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contains,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR @> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contains,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contained_by,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = eql_v2_int4_ord_ore);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contained_by,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = jsonb);
CREATE OPERATOR <@ (FUNCTION = eql_v2.eql_v2_int4_ord_ore_contained_by,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = text);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = integer);
CREATE OPERATOR -> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);

CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow_text,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = text);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow_text,
  LEFTARG = eql_v2_int4_ord_ore, RIGHTARG = integer);
CREATE OPERATOR ->> (FUNCTION = eql_v2.eql_v2_int4_ord_ore_arrow_text,
  LEFTARG = jsonb, RIGHTARG = eql_v2_int4_ord_ore);
