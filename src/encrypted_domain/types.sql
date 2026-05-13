-- REQUIRE: src/schema.sql

--! @file encrypted_domain/types.sql
--! @brief Prototype high-level encrypted domain types
--!
--! Defines durable, user-facing jsonb-backed domain types used to
--! prototype static operator surfaces for common encrypted plaintext
--! shapes.
--!
--! These domains intentionally live in the public schema, matching the
--! existing lifecycle used by public.eql_v2_encrypted in
--! encrypted/types.sql: user table columns depend on stable public type
--! names, while implementation functions and operators live in eql_v2.
--!
--! uninstall.sql drops eql_v2 but leaves public types in place; test
--! reset clears public when fixtures need a clean slate.

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

  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'encrypted_int4'
      AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.encrypted_int4 AS jsonb;
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


