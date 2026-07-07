-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/integer/integer_types.sql
--! @brief Encrypted-domain types for integer.

DO $$
BEGIN
  --! @brief Encrypted domain public.integer.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'integer' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.integer AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.integer IS 'EQL encrypted integer (storage only)';

  --! @brief Encrypted domain public.integer_eq.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'integer_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.integer_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.integer_eq IS 'EQL encrypted integer (equality)';

  --! @brief Encrypted domain public.integer_ord_ore.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'integer_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.integer_ord_ore AS jsonb
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

  COMMENT ON DOMAIN public.integer_ord_ore IS 'EQL encrypted integer (equality, ordering)';

  --! @brief Encrypted domain public.integer_ord.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'integer_ord' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.integer_ord AS jsonb
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

  COMMENT ON DOMAIN public.integer_ord IS 'EQL encrypted integer (equality, ordering)';

  --! @brief Encrypted domain public.integer_ord_ope.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'integer_ord_ope' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.integer_ord_ope AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'op'
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.integer_ord_ope IS 'EQL encrypted integer (equality, ordering)';
END
$$;
