-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/boolean/boolean_types.sql
--! @brief Encrypted-domain types for boolean.

DO $$
BEGIN
  --! @brief Encrypted domain eql_v3.boolean.
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'boolean' AND typnamespace = 'eql_v3'::regnamespace
  ) THEN
    CREATE DOMAIN eql_v3.boolean AS jsonb
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
