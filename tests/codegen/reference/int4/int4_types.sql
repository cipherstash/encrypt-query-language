-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/schema-v3.sql

--! @file encrypted_domain/int4/int4_types.sql
--! @brief Encrypted-domain types for int4.

DO $$
BEGIN
  --! @brief Encrypted domain eql_v3.int4.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int4' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int4 AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.int4_eq.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int4_eq' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int4_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.int4_ord_ore.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int4_ord_ore' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int4_ord_ore AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'ob'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.int4_ord.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'int4_ord' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.int4_ord AS jsonb
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
