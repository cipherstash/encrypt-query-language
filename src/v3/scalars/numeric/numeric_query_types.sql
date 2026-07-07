-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/numeric/numeric_query_types.sql
--! @brief Query-operand domains for numeric (index-terms-only, no ciphertext).
--! @note Cast a query operand explicitly to its `_query` domain in a predicate
--!       (e.g. `WHERE col = $1::public.numeric_eq_query`). A bare,
--!       uncast literal RHS is ambiguous between the `_query` and `jsonb`
--!       operator overloads and will not resolve.

DO $$
BEGIN
  --! @brief Query-operand domain public.numeric_eq_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'numeric_eq_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.numeric_eq_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.numeric_eq_query IS 'EQL v3 query operand for encrypted numeric (searchable via = <>). Index terms only; carries no ciphertext (c).';

  --! @brief Query-operand domain public.numeric_ord_ore_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'numeric_ord_ore_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.numeric_ord_ore_query AS jsonb
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

  COMMENT ON DOMAIN public.numeric_ord_ore_query IS 'EQL v3 query operand for encrypted numeric (searchable via = <> < <= > >=). Index terms only; carries no ciphertext (c).';

  --! @brief Query-operand domain public.numeric_ord_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'numeric_ord_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.numeric_ord_query AS jsonb
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

  COMMENT ON DOMAIN public.numeric_ord_query IS 'EQL v3 query operand for encrypted numeric (searchable via = <> < <= > >=). Index terms only; carries no ciphertext (c).';

  --! @brief Query-operand domain public.numeric_ord_ope_query (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'numeric_ord_ope_query' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.numeric_ord_ope_query AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'op'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.numeric_ord_ope_query IS 'EQL v3 query operand for encrypted numeric (searchable via = <> < <= > >=). Index terms only; carries no ciphertext (c).';
END
$$;
