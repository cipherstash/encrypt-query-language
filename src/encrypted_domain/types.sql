-- REQUIRE: src/schema.sql

--! @file encrypted_domain/types.sql
--! @brief High-level encrypted domain types: the eql_v2_int4 variant family.
--!
--! Five jsonb-backed domains in public, one per operator/index-term
--! combination:
--!   eql_v2_int4_ct        — storage only (all blockers)
--!   eql_v2_int4_eq        — HMAC equality only
--!   eql_v2_int4_ord_ore   — HMAC equality + ORE-block ordering (range = seq-scan)
--!   eql_v2_int4_ord_ope   — HMAC equality + OPE-direct ordering (range = functional btree)
--!   eql_v2_int4           — default; behaves as _ord_ore
--!
--! These domains intentionally live in the public schema, matching the
--! existing lifecycle used by public.eql_v2_encrypted in
--! encrypted/types.sql: user table columns depend on stable public type
--! names, while implementation functions and operators live in eql_v2.
--! tasks/uninstall.sql drops eql_v2 but leaves public types in place.

DO $$
BEGIN
  --! @brief Default encrypted int4 domain (jsonb-backed). Operator
  --!        surface identical to eql_v2_int4_ord_ore (HMAC equality +
  --!        ORE-block ordering).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4 AS jsonb;
  END IF;

  --! @brief Storage-only encrypted int4 domain (jsonb-backed). Every
  --!        operator is a blocker; carries ciphertext (`c`) only.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ct' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ct AS jsonb;
  END IF;

  --! @brief Equality-only encrypted int4 domain (jsonb-backed).
  --!        Supports = and <> via HMAC-256.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_eq AS jsonb;
  END IF;

  --! @brief Equality + ORE-block ordering encrypted int4 domain
  --!        (jsonb-backed). Range engages a btree operator class.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord_ore AS jsonb;
  END IF;

  --! @brief Equality + OPE-direct ordering encrypted int4 domain
  --!        (jsonb-backed). Range engages a functional btree.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord_ope' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord_ope AS jsonb;
  END IF;
END
$$;
