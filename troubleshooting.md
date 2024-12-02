
# Troubleshooting Guide for Potential Constraint Failures



## cs_encrypted_v1_check

This guide provides information on potential constraint failures related to the cs_encrypted_v1_check constraint in the 010-core.sql file. It explains what the current errors mean and what you can do to fix them. The constraint relies on the function cs_check_encrypted_v1, which in turn calls several other functions to validate different aspects of the JSONB value.


### Constraint Definition

```sql
ALTER DOMAIN cs_encrypted_v1
  ADD CONSTRAINT cs_encrypted_v1_check CHECK (
   cs_check_encrypted_v1(VALUE)
);
```


### Constraint Functions

```sql
    _cs_encrypted_check_v(jsonb)
    _cs_encrypted_check_i(jsonb)
    _cs_encrypted_check_i_ct(jsonb)
    _cs_encrypted_check_k(jsonb)
    _cs_encrypted_check_k_ct(jsonb)
    _cs_encrypted_check_k_sv(jsonb)
    _cs_encrypted_check_q(jsonb)
    _cs_encrypted_check_p(jsonb)
```


## Potential Errors and Fixes

### Version (_cs_encrypted_check_v)

**Error Message**
```
Encrypted column missing version (v) field
```

This error indicates that the version value in the encrypted data is not valid.

Ensure that the version value in the JSONB data is correct and matches the expected format.
The version should be a valid integer.



### Identity (_cs_encrypted_check_i)

**Error Message**
```
Encrypted column missing identity (i) field
```

This error indicates that the identifier in the encrypted data is not valid.

Verify that the identifier in the JSONB data is correctly defined.
Ensure that the identifier adheres to the expected format and contains valid values.



### Table & Column (_cs_encrypted_check_i_ct)

**Error Message**
```
Encrypted column identity (i) missing table (t) or column (c) fields
```

This error indicates that the identifier in the encrypted data is not valid.

Verify that the identifier in the JSONB data is correctly defined and contains table (t) and column (c) fields.
Ensure that the identifier adheres to the expected format and contains valid values.



### _cs_encrypted_check_k(jsonb)

**Error Message**

```
  Invalid kind (%) in Encrypted column. Kind should be one of {ct, sv, en};
```

This error indicates that the kind in the encrypted data is not valid.

Check the kind in the JSONB data to ensure it is valid.
Ensure that the kind adheres to the expected format and contains valid values.
Kind should be `ct`, `sv` or `en`.


### Ciphertext (_cs_encrypted_check_k_ct)

**Error Message**
```
  Encrypted column kind (k) of "ct" missing data field (c)
```

This error indicates that the ciphertext in the encrypted data is missing.

If the kind (k) is `ct` the JSONB data must include a `ciphertext` (c) field.
Review the key ciphertext in the JSONB data to ensure it is correctly defined.
Ensure that the ciphertext is correctly specified and matches the expected format.




### Ciphertext (_cs_encrypted_check_k_sv)

**Error Message**
```
  Encrypted column kind (k) of "ct" missing data field (c)
```

This error indicates that the ciphertext in the encrypted data is missing.

If the kind (k) is `sv` the JSONB data must include a `structured_vec` (sv) field.
Review the key ciphertext in the JSONB data to ensure it is correctly defined.
Ensure that the ciphertext is correctly specified and matches the expected format.



### Query (_cs_encrypted_check_q)


**Error Message**
```
  Encrypted column includes query (q) field
```

This error indicates that the the encrypted data contains a query (q) field.

The query (q) flag indicates this data is read-only and is not a valid value for `INSERT` or `UPDATE` statements.


### Plaintext (_cs_encrypted_check_q)


**Error Message**
```
  Encrypted column includes plaintext (p) field
```

This error indicates that the the encrypted data contains a plaintext (p) field.

The query (q) flag indicates this data is read-only and is not a valid value for `INSERT` or `UPDATE` statements.


