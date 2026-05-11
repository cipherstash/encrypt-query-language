-- Fixture: bench_json_data.sql
--
-- Builds the bench_json table by overlaying the existing `bench` rows
-- (loaded by the bench_data.sql fixture, which must run first) and adding
-- `hm` to the $.hello sv element of each row. This mirrors what
-- `@cipherstash/protect` would produce for a JSONB column where the
-- $.hello path is configured with a `unique` index — without that, the
-- field-level sv element carries only OPE terms (`ocv`) and field-level
-- GROUP BY / DISTINCT / hash joins on the extracted value raise:
--
--     ERROR:  Cannot hash eql_v2_encrypted value: no hmac_256 index term
--             found. Configure a `unique` index on the column for hash
--             operations (GROUP BY, DISTINCT, hash joins).
--
-- The synthesised `hm` is the field's existing `ocv` hex string (already
-- deterministic over the plaintext at that selector) so it serves as a
-- valid equality token without us inventing a separate one. The shape
-- matches production: `c`, `s`, `ocv`, `hm` at the sv element level.
--
-- Selector cheatsheet (matches Selectors:: in tests/sqlx/src/selectors.rs):
--   bca213de9ccce676fa849ff9c4807963 → $       (root, has b3 here today)
--   a7cea93975ed8c01f861ccb6bd082784 → $.hello (we add `hm` here)
--   2517068c0d1f9d4d41d2c666211f785e → $.n     (left alone)

CREATE TABLE IF NOT EXISTS bench_json (
    id bigserial PRIMARY KEY,
    e eql_v2_encrypted
);

INSERT INTO bench_json (e)
SELECT (jsonb_build_object(
    'c',  (encrypted_text).data ->> 'c',
    'i',  (encrypted_text).data -> 'i',
    'v',  2,
    'hm', (encrypted_text).data ->> 'hm',
    'sv', (
        SELECT jsonb_agg(
            CASE
                WHEN elem ->> 's' = 'a7cea93975ed8c01f861ccb6bd082784'
                THEN elem || jsonb_build_object('hm', elem ->> 'ocv')
                ELSE elem
            END
        )
        FROM jsonb_array_elements((encrypted_text).data -> 'sv') elem
    )
)) :: eql_v2_encrypted
FROM bench;

ANALYZE bench_json;
