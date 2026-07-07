-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/smallint/smallint_query_types.sql
--! @brief Query-operand domains for smallint (index-terms-only, no ciphertext).

DO $$
BEGIN
  --! @brief Query-operand domain public.smallint_eq_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_eq_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_eq_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  --! @brief Query-operand domain public.smallint_ord_ore_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_ord_ore_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_ord_ore_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'ob'
        AND NOT (VALUE ? 'c')
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '3'
      );
  END IF;

  --! @brief Query-operand domain public.smallint_ord_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_ord_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_ord_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'ob'
        AND NOT (VALUE ? 'c')
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '3'
      );
  END IF;

  --! @brief Query-operand domain public.smallint_ord_ope_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'smallint_ord_ope_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.smallint_ord_ope_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'op'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;
END
$$;
