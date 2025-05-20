# EQL payload data format

Encrypted data is stored as `jsonb` with a specific schema:

## Plaintext payload (client side)

The plaintext json payload that is sent from the client to CipherStash Proxy in order to store and search encrypted data.

```json
{
  "v": 1,
  "k": "pt",
  "p": "plaintext value",
  "i": {
    "t": "table_name",
    "c": "column_name"
  }
}
```

## Encrypted payload (database side)

The encrypted json payload that is stored in the database.
CipherStash Proxy will handle the plaintext payload and create the encrypted payload.

```json
{
  "v": 1,
  "k": "ct",
  "c": "ciphertext value",
  "i": {
    "t": "table_name",
    "c": "column_name"
  }
}
```

## Data format

The format is defined as a [JSON Schema](../../sql/schemas/cs_encrypted_v1.schema.json).

It should never be necessary to directly interact with the stored `jsonb`.
CipherStash Proxy handles the encoding, and EQL provides the functions.

| Field | Name              | Description                                                                                                                                                                                                                                       |
| ----- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| s     | Schema version    | JSON Schema version of this json document.                                                                                                                                                                                                        |
| v     | Version           | The configuration version that generated this stored value.                                                                                                                                                                                       |
| k     | Kind              | The kind of the data (plaintext/pt, ciphertext/ct, encrypting/et).                                                                                                                                                                                |
| i.t   | Table identifier  | Name of the table containing encrypted column.                                                                                                                                                                                                    |
| i.c   | Column identifier | Name of the encrypted column.                                                                                                                                                                                                                     |
| p     | Plaintext         | Plaintext value sent by database client. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                       |
| q     | For query         | Specifies that the plaintext should be encrypted for a specific query operation. If `null`, source encryption and encryption for all indexes will be performed. Valid values are `"match"`, `"ore"`, `"unique"`, `"ste_vec"`, and `"ejson_path"`. |
| c     | Ciphertext        | Ciphertext value. Encrypted by Proxy. Required if kind is plaintext/pt or encrypting/et.                                                                                                                                                          |
| m     | Match index       | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |
| o     | ORE index         | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |
| u     | Unique index      | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |
| sv    | STE vector index  | Ciphertext index value. Encrypted by Proxy.                                                                                                                                                                                                       |

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20PAYLOAD.md)
