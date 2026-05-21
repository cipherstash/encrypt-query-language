-- REQUIRE: src/schema.sql

--! @file encrypted_domain/types.sql
--! @brief High-level encrypted domain types: the eql_v2_int4 variant family.
--!
--! Four jsonb-backed domains in public, one per operator/index-term
--! capability:
--!   eql_v2_int4         — storage only (all operators blocked); carries `c`
--!   eql_v2_int4_eq      — HMAC equality (=, <>); carries `c`, `hm`
--!   eql_v2_int4_ord_ore — equality + ORE-block ordering (= <> < <= > >=);
--!                         carries `c`, `ob`; the scheme-explicit ordered
--!                         domain
--!   eql_v2_int4_ord     — equality + ORE-block ordering; the recommended
--!                         ordered name. A full concrete domain with its own
--!                         operators/wrappers/blockers (int4_ord.sql) —
--!                         identical operator surface to eql_v2_int4_ord_ore.
--!
--! These domains intentionally live in the public schema, matching the
--! existing lifecycle used by public.eql_v2_encrypted in
--! encrypted/types.sql: user table columns depend on stable public type
--! names, while implementation functions and operators live in eql_v2.
--! tasks/uninstall.sql drops eql_v2 but leaves public types in place.
--!
--! eql_v2_int4_ord is a concrete domain over jsonb (not a domain over
--! eql_v2_int4_ord_ore): the §8 verification spike showed that a
--! domain-over-domain does not transparently inherit the base domain's
--! operator surface — PostgreSQL resolves operators against the ultimate
--! base type (jsonb), so the ordered operators fall through to native
--! jsonb comparison and the blockers do not engage. eql_v2_int4_ord
--! therefore carries its own operator surface (int4_ord.sql).
--!
--! Ordered range and equality both engage a functional btree
--! USING btree (eql_v2.ord_term(col)) — eql_v2.ord_term returns
--! eql_v2.ore_block_u64_8_256, which carries main's DEFAULT btree
--! operator class. No operator class is defined on these domains.

DO $$
BEGIN
  --! @brief Storage-only encrypted int4 domain (jsonb-backed). Every
  --!        operator is a blocker; carries ciphertext (`c`) only.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4 AS jsonb;
  END IF;

  --! @brief Equality-only encrypted int4 domain (jsonb-backed).
  --!        Supports = and <> via HMAC-256; carries `c`, `hm`.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_eq AS jsonb;
  END IF;

  --! @brief Scheme-explicit ordered encrypted int4 domain (jsonb-backed).
  --!        Supports = <> < <= > >= via the ORE-block term; carries
  --!        `c`, `ob`. Carries the eql_v2.ord_term extractor, the comparison
  --!        wrappers, the operator declarations, and the blockers.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord_ore AS jsonb;
  END IF;

  --! @brief Ordered encrypted int4 domain — the recommended ordered
  --!        name. A full concrete domain (its own operators/wrappers/
  --!        blockers in int4_ord.sql) because the pure-alias form does
  --!        not transparently inherit the operator surface (spike §8).
  --!        Supports = <> < <= > >= via the ORE-block term; carries
  --!        `c`, `ob`.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord AS jsonb;
  END IF;
END
$$;
