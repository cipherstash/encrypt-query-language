# CipherStash Encrypt Query Language (EQL)


Encrypt Query Language (EQL) is a set of abstractions for transmitting, storing & interacting with encrypted data and indexes in PostgreSQL.

EQL provides:

- a data format for transmitting and storing encrypted data & indexes
- database types & functions to interact with the encrypted material

EQL relies on [Cipherstash Encrypt](https://cipherstash.com/docs/getting-started/cipherstash-encrypt) and [Cipherstash Proxy](https://cipherstash.com/docs/getting-started/cipherstash-proxy) for low-latency encryption & decryption.

As well as basic encryption of data, Cipherstash Proxy supports a variety of encrypted indexes that enable:

- matching (`a == b` or `a LIKE b`)
- comparison using order revealing encryption (`a < b`)
- enforcing unique constraints (`there is only a`)


Example SQL statements using EQL:
```SQL
-- select using an encrypted match comparison
SELECT cs_ciphertext_v1(name)
FROM users
WHERE cs_match_v1(name) @> $2;

-- insert using jsonb payload
INSERT INTO users (name) VALUES ({"p": "plaintext"});
```


## How EQL works with CipherStash Proxy

EQL uses **CipherStash Proxy** to mediate access to your PostgreSQL database and provide low-latency encryption & decryption.

At a high level:

- encrypted data is stored as `jsonb`
- references to the column in sql statements are wrapped in a helper function
- Cipherstash Proxy transparently encrypts and indexes data



### Writes

1. Database client sends `plaintext` data
2. CipherStash Proxy encrypts the `plaintext` and encodes the value and associated indexes into the `ciphertext` jsonb payload
3. The data is written to the encrypted column


![Insert](/diagrams/overview-insert.drawio.svg)




### Reads

1. Wrap references to the encrypted column in the appropriate EQL function
3. CipherStash Proxy encrypts `plaintext`
4. SQL statement is executed
5. CipherStash Proxy decrypts any returned `ciphertext` data and returns to client


![Select](/diagrams/overview-select.drawio.svg)




## Components


### Data format

Encrypted data and index values are stored as `jsonb`.

Format is defined by [JSON Schema](https://github.com/cipherstash/cipherstash-suite/blob/main/packages/cipherstash-migrator/sql/payload.schema.json).

Encrypted columns should be defined as the `cs_encrypted_v1` Domain Type.

Integrity is ensured via `check constraint`.

```sql

# Plaintext
# Sent by client when using DSL
{
  "v": 1,
  "k": "pt",
  "p": "a plaintext string for encryption",
  "e": {
    "t": "users",
    "c": "name_encrypted"
  }
}

# Ciphertext
# Encoded for storage by proxy
{
  "v": 1,
	"k": "ct",
  "c": "XvfWQUrSxKNhkOxiMXvgvkwxIYFfnYTb",
  "e": {
    "t": "users",
    "c": "name_encrypted"
  }
}

// encrypting/migrating schema
{
  "v": 1,
	"k": "mt",
	"p": "a plaintext string for encryption",
  "c": "XvfWQUrSxKNhkOxiMXvgvkwxIYFfnYTb",
  "e": {
    "t": "users",
    "c": "name_encrypted"
  }
}
```


