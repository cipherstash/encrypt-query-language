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
