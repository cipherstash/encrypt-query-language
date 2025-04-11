



### cs_encrypt_v1

Marks the currently `pending` configuration as `encrypting`.

Validates the database schema and returns an error if the configured columns are not of `jsonb` or `cs_encrypted_v1` type.






```
SELECT cs_encrypt_v1(true);
```