create table examples (
  id serial primary key,
  encrypted_big_int examples__encrypted_big_int,
  encrypted_boolean examples__encrypted_boolean,
  encrypted_date examples__encrypted_date,
  encrypted_float examples__encrypted_float,
  encrypted_int examples__encrypted_int,
  encrypted_small_int examples__encrypted_small_int,
  encrypted_utf8_str examples__encrypted_utf8_str,
  encrypted_jsonb examples__encrypted_jsonb
);

CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_big_int));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_boolean));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_date));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_float));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_int));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_small_int));
CREATE UNIQUE INDEX ON examples(cs_unique_v1(encrypted_utf8_str));
CREATE INDEX ON examples USING GIN (cs_match_v1(encrypted_utf8_str));
CREATE INDEX ON examples (cs_ore_64_8_v1(encrypted_utf8_str));
CREATE INDEX ON examples USING GIN (cs_ste_vec_v1(encrypted_jsonb));
