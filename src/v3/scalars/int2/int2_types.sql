-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/int2/int2_types.sql
--! @brief Encrypted-domain types for int2.

DO $$
BEGIN
  --! @brief Encrypted domain eql_v3.int2.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int2' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int2 AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '3'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.int2_eq.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int2_eq' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int2_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '3'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.int2_ord_ore.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int2_ord_ore' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int2_ord_ore AS jsonb
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

  --! @brief Encrypted domain eql_v3.int2_ord.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int2_ord' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int2_ord AS jsonb
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

  --! @brief Encrypted domain eql_v3.int2_ord_ope.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int2_ord_ope' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int2_ord_ope AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'op'
        AND VALUE->>'v' = '3'
      );
  END IF;
END
$$;
