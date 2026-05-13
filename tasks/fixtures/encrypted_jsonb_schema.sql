-- Schema for the encrypted_jsonb plaintext-paired fixture.
-- Applied by tasks/fixtures/generate_encrypted_jsonb.sh; the generator
-- restarts Proxy afterwards so it reloads the new encrypt config.

DROP TABLE IF EXISTS bench_jsonb;

CREATE TABLE bench_jsonb (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plaintext JSONB NOT NULL,
    encrypted_jsonb eql_v2_encrypted
);

-- Idempotency: drop any prior bench_jsonb search-config rows.
SELECT eql_v2.remove_search_config('bench_jsonb', 'encrypted_jsonb', 'unique')
  WHERE EXISTS (
    SELECT 1 FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench_jsonb,encrypted_jsonb,indexes,unique}' IS NOT NULL
  );
SELECT eql_v2.remove_search_config('bench_jsonb', 'encrypted_jsonb', 'ste_vec')
  WHERE EXISTS (
    SELECT 1 FROM public.eql_v2_configuration c
    WHERE c.data #> '{tables,bench_jsonb,encrypted_jsonb,indexes,ste_vec}' IS NOT NULL
  );

-- unique → HMAC on the whole doc (drives =, <>)
-- ste_vec → per-leaf STE-vec elements (drives @>, <@, ->, ->>)
SELECT eql_v2.add_search_config('bench_jsonb', 'encrypted_jsonb', 'unique',  'jsonb');
SELECT eql_v2.add_search_config(
  'bench_jsonb',
  'encrypted_jsonb',
  'ste_vec',
  'jsonb',
  '{"prefix": "bench_jsonb/encrypted_jsonb"}'::jsonb
);
