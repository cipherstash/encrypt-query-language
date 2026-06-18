-- REFERENCE: hand-maintained parity baseline for crates/eql-codegen - see ../README.md
-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/bool/bool_types.sql
--! @brief Encrypted-domain types for bool.

DO $$
BEGIN
  --! @brief Encrypted domain eql_v3.bool.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'bool' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.bool AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'c'
        AND VALUE->>'v' = '2'
      );
  END IF;
END
$$;
