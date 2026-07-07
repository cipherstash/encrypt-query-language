-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/smallint/smallint_types.sql
--! @brief Encrypted-domain types for smallint.

DO $$
BEGIN
  --! @brief Encrypted domain public.smallint.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.smallint IS 'EQL v3 encrypted smallint column (storage only, not searchable). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.smallint_eq.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.smallint_eq IS 'EQL v3 encrypted smallint column (searchable via = <>). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.smallint_ord_ore.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_ord_ore AS jsonb
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

  COMMENT ON DOMAIN public.smallint_ord_ore IS 'EQL v3 encrypted smallint column (searchable via = <> < <= > >=). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.smallint_ord.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_ord' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_ord AS jsonb
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

  COMMENT ON DOMAIN public.smallint_ord IS 'EQL v3 encrypted smallint column (searchable via = <> < <= > >=). jsonb-backed CipherStash searchable-encryption domain.';

  --! @brief Encrypted domain public.smallint_ord_ope.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_ord_ope' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_ord_ope AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'op'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.smallint_ord_ope IS 'EQL v3 encrypted smallint column (searchable via = <> < <= > >=). jsonb-backed CipherStash searchable-encryption domain.';
END
$$;
