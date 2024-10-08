create table examples (
  id serial primary key,
  encrypted_big_int examples__encrypted_big_int,
  encrypted_boolean examples__encrypted_boolean,
  encrypted_date examples__encrypted_date,
  encrypted_float examples__encrypted_float,
  encrypted_int examples__encrypted_int,
  encrypted_small_int examples__encrypted_small_int,
  encrypted_utf8_str examples__encrypted_utf8_str
);

CREATE UNIQUE INDEX encrypted_utf8_str_unique_index
	ON examples( (encrypted_utf8_str->>'u') );
