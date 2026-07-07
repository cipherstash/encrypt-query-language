-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/date/date_query_types.sql
--! @brief Query-operand domains for date (index-terms-only, no ciphertext).
--! @note Cast a query operand explicitly to its `_query` domain in a predicate
--!       (e.g. `WHERE col = $1::public.date_eq_query`). A bare,
--!       uncast literal RHS is ambiguous between the `_query` and `jsonb`
--!       operator overloads and will not resolve.

DO $$
BEGIN
  --! @brief Query-operand domain public.date_eq_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'date_eq_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.date_eq_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  --! @brief Query-operand domain public.date_ord_ore_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'date_ord_ore_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.date_ord_ore_query AS jsonb
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

  --! @brief Query-operand domain public.date_ord_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'date_ord_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.date_ord_query AS jsonb
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

  --! @brief Query-operand domain public.date_ord_ope_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'date_ord_ope_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.date_ord_ope_query AS jsonb
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
