-- REFERENCE: hand-written parity baseline for tasks/codegen/ — see ../README.md
-- REQUIRE: src/schema.sql

--! @file encrypted_domain/int4/int4_types.sql
--! @brief Encrypted-domain type family for int4.

DO $$
BEGIN
  --! @brief Storage-only encrypted int4 domain.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4 AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Equality-only encrypted int4 domain.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Ordered encrypted int4 domain. Scheme-explicit twin pinning the ore scheme; prefer the converged int4_ord name.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord_ore AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'ob'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Ordered encrypted int4 domain. Recommended converged name for this role.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'eql_v2_int4_ord' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.eql_v2_int4_ord AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'ob'
        AND VALUE->>'v' = '2'
      );
  END IF;
END
$$;
