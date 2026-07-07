-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/real/real_types.sql
--! @brief Encrypted-domain types for real.

DO $$
BEGIN
  --! @brief Encrypted domain public.real.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.real IS 'EQL v3 encrypted real column (storage only, not searchable). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.real_eq.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.real_eq IS 'EQL v3 encrypted real column (searchable via = <>). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.real_ord_ore.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_ord_ore AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'ob'
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.real_ord_ore IS 'EQL v3 encrypted real column (searchable via = <> < <= > >=). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.real_ord.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_ord' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_ord AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'ob'
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.real_ord IS 'EQL v3 encrypted real column (searchable via = <> < <= > >=). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.real_ord_ope.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_ord_ope' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_ord_ope AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'op'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.real_ord_ope IS 'EQL v3 encrypted real column (searchable via = <> < <= > >=). jsonb-backed CipherStash searchable-encryption domain.';
END
$$;
