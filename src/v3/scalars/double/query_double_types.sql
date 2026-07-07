-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/double/query_double_types.sql
--! @brief Query-operand domains for double (index-terms-only, no ciphertext).
--! @note Cast a query operand explicitly to its `query_` domain in a predicate
--!       (e.g. `WHERE col = $1::public.query_double_eq`). A bare,
--!       uncast literal RHS is ambiguous between the `query_` and `jsonb`
--!       operator overloads and will not resolve.

DO $$
BEGIN
  --! @brief Query-operand domain public.query_double_eq (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_double_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_double_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_double_eq IS 'EQL double query operand (equality)';

  --! @brief Query-operand domain public.query_double_ord_ore (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_double_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_double_ord_ore AS jsonb
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

  COMMENT ON DOMAIN public.query_double_ord_ore IS 'EQL double query operand (equality, ordering)';

  --! @brief Query-operand domain public.query_double_ord (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_double_ord' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_double_ord AS jsonb
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

  COMMENT ON DOMAIN public.query_double_ord IS 'EQL double query operand (equality, ordering)';

  --! @brief Query-operand domain public.query_double_ord_ope (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_double_ord_ope' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_double_ord_ope AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'op'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_double_ord_ope IS 'EQL double query operand (equality, ordering)';
END
$$;
