-- REQUIRE: src/schema.sql

--! @file encrypted_domain/types.sql
--! @brief High-level encrypted domain types: encrypted_text, encrypted_jsonb,
--!        and the eql_v2_int4 variant family.
--!
--! Defines durable, user-facing jsonb-backed domain types used to surface
--! static operator surfaces for common encrypted plaintext shapes. The
--! int4 family encodes its operator capability in the type name:
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
--!
--! uninstall.sql drops eql_v2 but leaves public types in place; the
--! migration block above DROPs the legacy public.encrypted_int4 so
--! re-installs against existing databases succeed (see docs/upgrading/v2.4.md U-001).

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'encrypted_text'
      AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.encrypted_text AS jsonb;
  END IF;

  -- Migration: drop the legacy single-variant int4 domain. tasks/uninstall.sql
  -- only drops the eql_v2 schema, so public.encrypted_int4 survives uninstall.
  -- An explicit DROP here ensures re-installs against an existing database
  -- succeed. The DROP will fail loudly if any user table still depends on
  -- it; that's the intended migration signal (see U-001).
  DROP DOMAIN IF EXISTS public.encrypted_int4;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4 AS jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ct' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ct AS jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_eq AS jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord_ore AS jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord_ope' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord_ope AS jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'encrypted_jsonb'
      AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.encrypted_jsonb AS jsonb;
  END IF;
END
$$;


