-- Schema for the encrypted_int4 plaintext-paired fixture.
-- Applied by tasks/fixtures/generate_encrypted_int4.sh; the generator
-- restarts Proxy afterwards so it reloads the new encrypt config.

DROP TABLE IF EXISTS bench_int4;

CREATE TABLE bench_int4 (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plaintext INTEGER NOT NULL,
    encrypted_int4 eql_v2_encrypted
);

-- Idempotency: drop any prior bench_int4 search-config rows so re-running
-- the generator doesn't error with "unique index exists for column".
SELECT eql_v2.remove_search_config('bench_int4', 'encrypted_int4', 'unique')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench_int4,encrypted_int4,indexes,unique}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench_int4', 'encrypted_int4', 'ore')
  WHERE EXISTS (
    SELECT 1
    FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench_int4,encrypted_int4,indexes,ore}' IS NOT NULL
  );

-- unique → HMAC (drives =, <>); ore → OPE bytes (drives <, <=, >, >=).
SELECT eql_v2.add_search_config('bench_int4', 'encrypted_int4', 'unique', 'int');
SELECT eql_v2.add_search_config('bench_int4', 'encrypted_int4', 'ore',    'int');
