-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/real/real_query_types.sql
--! @brief Query-operand domains for real (index-terms-only, no ciphertext).
--! @note Cast a query operand explicitly to its `_query` domain in a predicate
--!       (e.g. `WHERE col = $1::public.real_eq_query`). A bare,
--!       uncast literal RHS is ambiguous between the `_query` and `jsonb`
--!       operator overloads and will not resolve.

DO $$
BEGIN
  --! @brief Query-operand domain public.real_eq_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_eq_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_eq_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.real_eq_query IS 'EQL real query operand (equality)';

  --! @brief Query-operand domain public.real_ord_ore_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_ord_ore_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_ord_ore_query AS jsonb
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

  COMMENT ON DOMAIN public.real_ord_ore_query IS 'EQL real query operand (equality, ordering)';

  --! @brief Query-operand domain public.real_ord_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_ord_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_ord_query AS jsonb
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

  COMMENT ON DOMAIN public.real_ord_query IS 'EQL real query operand (equality, ordering)';

  --! @brief Query-operand domain public.real_ord_ope_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'real_ord_ope_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.real_ord_ope_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'op'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.real_ord_ope_query IS 'EQL real query operand (equality, ordering)';
END
$$;
