-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/text/text_types.sql
--! @brief Encrypted-domain types for text.

DO $$
BEGIN
  --! @brief Encrypted domain eql_v3.text.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'text' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.text AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.text_eq.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'text_eq' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.text_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.text_match.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'text_match' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.text_match AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'bf'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.text_ord_ore.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'text_ord_ore' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.text_ord_ore AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE ? 'ob'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.text_ord.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'text_ord' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.text_ord AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE ? 'ob'
        AND VALUE->>'v' = '2'
      );
  END IF;

  --! @brief Encrypted domain eql_v3.text_search.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'text_search' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.text_search AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE ? 'hm'
        AND VALUE ? 'ob'
        AND VALUE ? 'bf'
        AND VALUE->>'v' = '2'
      );
  END IF;
END
$$;
