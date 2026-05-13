-- Bench schema for Tier 2 benchmarks.
-- Applied against the bench-postgres container AFTER EQL has been explicitly
-- installed by generate.sh (see Task 4 — generate.sh installs
-- release/cipherstash-encrypt.sql directly, not relying on Proxy's async install).

DROP TABLE IF EXISTS bench;

CREATE TABLE bench (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encrypted_text eql_v2_encrypted,
    encrypted_int eql_v2_encrypted,
    encrypted_bigint eql_v2_encrypted
);

-- Idempotency: clear any prior bench search-config rows so re-running the
-- generator against the same container doesn't error with "... index exists
-- for column". EQL uninstall drops the schema but not public config rows.
SELECT eql_v2.remove_search_config('bench', 'encrypted_text', 'unique')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench,encrypted_text,indexes,unique}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench', 'encrypted_text', 'match')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench,encrypted_text,indexes,match}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench', 'encrypted_text', 'ore')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench,encrypted_text,indexes,ore}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench', 'encrypted_int', 'unique')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench,encrypted_int,indexes,unique}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench', 'encrypted_int', 'ore')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench,encrypted_int,indexes,ore}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench', 'encrypted_bigint', 'unique')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench,encrypted_bigint,indexes,unique}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench', 'encrypted_bigint', 'ore')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench,encrypted_bigint,indexes,ore}' IS NOT NULL
  );

-- Proxy search configuration: tells Proxy which index terms to generate
-- for each column when plaintext is inserted.
--
-- Signature: eql_v2.add_search_config(table, column, index, cast_as)
-- (see src/config/functions.sql). add_search_config calls activate_config
-- internally when migrating=false, so no explicit activate_config call.

-- text column: equality (hmac), pattern match (bloom), ordering (ore)
SELECT eql_v2.add_search_config('bench', 'encrypted_text', 'unique', 'text');
SELECT eql_v2.add_search_config('bench', 'encrypted_text', 'match',  'text');
SELECT eql_v2.add_search_config('bench', 'encrypted_text', 'ore',    'text');

-- integer column: equality + ORE range/ordering
SELECT eql_v2.add_search_config('bench', 'encrypted_int', 'unique', 'int');
SELECT eql_v2.add_search_config('bench', 'encrypted_int', 'ore',    'int');

-- bigint column: equality + ORE range/ordering
SELECT eql_v2.add_search_config('bench', 'encrypted_bigint', 'unique', 'big_int');
SELECT eql_v2.add_search_config('bench', 'encrypted_bigint', 'ore',    'big_int');

-- Indexes (created after data load in generate.sh, after ANALYZE)
