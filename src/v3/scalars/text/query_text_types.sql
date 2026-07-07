-- AUTOMATICALLY GENERATED FILE.
-- REQUIRE: src/v3/schema.sql

--! @file v3/scalars/text/query_text_types.sql
--! @brief Query-operand domains for text (index-terms-only, no ciphertext).
--! @note Cast a query operand explicitly to its `query_` domain in a predicate
--!       (e.g. `WHERE col = $1::public.query_text_eq`). A bare,
--!       uncast literal RHS is ambiguous between the `query_` and `jsonb`
--!       operator overloads and will not resolve.

DO $$
BEGIN
  --! @brief Query-operand domain public.query_text_eq (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_text_eq' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_text_eq AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_text_eq IS 'EQL text query operand (equality)';

  --! @brief Query-operand domain public.query_text_match (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_text_match' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_text_match AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'bf'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_text_match IS 'EQL text query operand (containment)';

  --! @brief Query-operand domain public.query_text_ord_ore (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_text_ord_ore' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_text_ord_ore AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND VALUE ? 'ob'
        AND NOT (VALUE ? 'c')
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_text_ord_ore IS 'EQL text query operand (equality, ordering)';

  --! @brief Query-operand domain public.query_text_ord (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_text_ord' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_text_ord AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND VALUE ? 'ob'
        AND NOT (VALUE ? 'c')
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_text_ord IS 'EQL text query operand (equality, ordering)';

  --! @brief Query-operand domain public.query_text_ord_ope (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_text_ord_ope' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_text_ord_ope AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND VALUE ? 'op'
        AND NOT (VALUE ? 'c')
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_text_ord_ope IS 'EQL text query operand (equality, ordering)';

  --! @brief Query-operand domain public.query_text_search (term-only; no `c`).
  IF NOT EXISTS (
    SELECT 1 FROM pg_type
    WHERE typname = 'query_text_search' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE DOMAIN public.query_text_search AS jsonb
      CHECK (
        jsonb_typeof(VALUE) = 'object'
        AND VALUE ? 'v'
        AND VALUE ? 'i'
        AND VALUE ? 'hm'
        AND VALUE ? 'ob'
        AND VALUE ? 'bf'
        AND NOT (VALUE ? 'c')
        AND jsonb_typeof(VALUE -> 'ob') = 'array'
        AND jsonb_array_length(VALUE -> 'ob') > 0
        AND VALUE->>'v' = '3'
      );
  END IF;

  COMMENT ON DOMAIN public.query_text_search IS 'EQL text query operand (equality, ordering, containment)';
END
$$;
