-- Text fixture schema for encrypted_text domain test coverage.
-- Applied against the bench-postgres container by generate_text_fixture.sh
-- AFTER EQL is installed.
--
-- Mirrors the bench schema's encrypted_text column shape (hmac + bloom + ORE)
-- but pairs each encrypted row with its source plaintext so SQLx tests can
-- assert correctness against literal ground truth.

DROP TABLE IF EXISTS bench_text;

CREATE TABLE bench_text (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plaintext TEXT NOT NULL,
    encrypted_text eql_v2_encrypted
);

-- Idempotency: clear any prior bench_text search-config rows so re-running
-- the generator doesn't error with "unique index exists for column".
-- add_search_config refuses to add an index that's already registered, but
-- gives no native upsert/replace path.
SELECT eql_v2.remove_search_config('bench_text', 'encrypted_text', 'unique')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench_text,encrypted_text,indexes,unique}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench_text', 'encrypted_text', 'match')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench_text,encrypted_text,indexes,match}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench_text', 'encrypted_text', 'ore')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench_text,encrypted_text,indexes,ore}' IS NOT NULL
  );

-- Proxy search configuration: tells Proxy which index terms to generate
-- for the encrypted column when plaintext is inserted. The plaintext
-- column is not registered, so Proxy passes it through unencrypted.
--
-- Signature: eql_v2.add_search_config(table, column, index, cast_as)
-- (see src/config/functions.sql). add_search_config calls activate_config
-- internally when migrating=false.

SELECT eql_v2.add_search_config('bench_text', 'encrypted_text', 'unique', 'text');
SELECT eql_v2.add_search_config('bench_text', 'encrypted_text', 'match',  'text');
SELECT eql_v2.add_search_config('bench_text', 'encrypted_text', 'ore',    'text');
