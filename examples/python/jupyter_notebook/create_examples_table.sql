create table examples (
  id serial primary key,
  encrypted_boolean examples__encrypted_boolean,
  encrypted_date examples__encrypted_date,
  encrypted_float examples__encrypted_float,
  encrypted_int examples__encrypted_int,
  encrypted_utf8_str examples__encrypted_utf8_str,
  encrypted_jsonb examples__encrypted_jsonb
);

-- Add CipherStash indexes to Encrypt config
SELECT cs_add_index_v1('examples', 'encrypted_boolean', 'ore', 'boolean');
SELECT cs_add_index_v1('examples', 'encrypted_date', 'ore', 'date');
SELECT cs_add_index_v1('examples', 'encrypted_float', 'ore', 'double');
SELECT cs_add_index_v1('examples', 'encrypted_int', 'ore', 'int');
SELECT cs_add_index_v1('examples', 'encrypted_utf8_str', 'unique', 'text', '{"token_filters": [{"kind": "downcase"}]}');
SELECT cs_add_index_v1('examples', 'encrypted_utf8_str', 'match', 'text');
SELECT cs_add_index_v1('examples', 'encrypted_utf8_str', 'ore', 'text');
SELECT cs_add_index_v1('examples', 'encrypted_jsonb', 'ste_vec', 'jsonb', '{"prefix": "examples/encrypted_jsonb"}');

-- Add corresponding PG indexes for each CipherStash index
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_boolean));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_date));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_float));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_int));
CREATE UNIQUE INDEX ON examples(cs_unique_v1(encrypted_utf8_str));
CREATE INDEX ON examples USING GIN (cs_match_v1(encrypted_utf8_str));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_utf8_str));
-- CREATE INDEX ON examples USING GIN (cs_ste_vec_v1(encrypted_jsonb));

-- Transition the Encrypt config state from "pending", to "encrypting", and then "active".
-- The Encrypt config must be "active" for Proxy to use it.
SELECT cs_encrypt_v1(true);
SELECT cs_activate_v1();
