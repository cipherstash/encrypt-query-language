DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users
(
    id SERIAL,
    name text,
    name_encrypted cs_encrypted_v1,
    PRIMARY KEY(id)
);

INSERT INTO users (name_encrypted) VALUES ('
{
  "v": 1,
  "s": {
	"k": "ct",
  	"c": "ciphertext",
	"e": {
		"t": "table",
		"c": "column"
	},
	"m": [42],
	"u": "unique",
	"o": ["a","b","c"]
  },
  "t": {
	"k": "pt",
    "p": "plaintext",
	"e": {
		"t": "table",
		"c": "column"
	},
	"m": [42],
	"u": "unique"
  }
}'::cs_encrypted_v1);


SELECT id, cs_ciphertext_v1(name_encrypted) FROM users
WHERE
  cs_unique_v1(name_encrypted) = 'unique' AND
  cs_match_v1(name_encrypted) @> '{42}';

