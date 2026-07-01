-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/timestamp/timestamp_types.sql
--! @brief Encrypted-domain types for timestamp.

DO $$
BEGIN
  --! @brief Encrypted domain eql_v3.timestamp.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'timestamp' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.timestamp AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.timestamp_eq.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'timestamp_eq' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.timestamp_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.timestamp_ord_ore.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'timestamp_ord_ore' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.timestamp_ord_ore AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'ob'
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.timestamp_ord.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'timestamp_ord' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.timestamp_ord AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'ob'
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '2'
      );
  END IF;
END
$$;
