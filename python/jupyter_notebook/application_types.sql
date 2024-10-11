--
-- Application-specific types
--

CREATE DOMAIN examples__encrypted_big_int AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_big_int'
);

CREATE DOMAIN examples__encrypted_boolean AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_boolean'
);

CREATE DOMAIN examples__encrypted_date AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_date'
);

CREATE DOMAIN examples__encrypted_float AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_float'
);

CREATE DOMAIN examples__encrypted_int AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_int'
);

CREATE DOMAIN examples__encrypted_small_int AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_small_int'
);

CREATE DOMAIN examples__encrypted_utf8_str AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_utf8_str'
);

CREATE DOMAIN examples__encrypted_jsonb AS cs_encrypted_v1
CHECK(
    VALUE#>>'{i,t}' = 'examples' AND
    VALUE#>>'{i,c}' = 'encrypted_jsonb'
);
