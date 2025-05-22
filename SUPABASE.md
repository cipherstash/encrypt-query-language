# Supabase

## No operators, no problems

Supabase [does not currently support](https://github.com/supabase/supautils/issues/72) custom operators.
The EQL operator functions can be used in this situation.

In EQL, PostgreSQL operators are an alias for a function, so the implementation and behaviour remains the same across operators and functions.

| Operator | Function                                                      | Example                                                                      |
| -------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `=`      | `eql_v2.eq(eql_v2_encrypted, eql_v2_encrypted)`               | `SELECT * FROM users WHERE eql_v2.eq(encrypted_email, $1)`<br>               |
| `<>`     | `eql_v2.neq(eql_v2_encrypted, eql_v2_encrypted)`              | `SELECT * FROM users WHERE eql_v2.neq(encrypted_email, $1)`<br>              |
| `<`      | `eql_v2.lt(eql_v2_encrypted, eql_v2_encrypted)`               | `SELECT * FROM users WHERE eql_v2.lt(encrypted_email, $1)`<br>               |
| `<=`     | `eql_v2.lte(eql_v2_encrypted, eql_v2_encrypted)`              | `SELECT * FROM users WHERE eql_v2.lte(encrypted_email, $1)`<br>              |
| `>`      | `eql_v2.gt(eql_v2_encrypted, eql_v2_encrypted)`               | `SELECT * FROM users WHERE eql_v2.gt(encrypted_email, $1)`<br>               |
| `>=`     | `eql_v2.gte(eql_v2_encrypted, eql_v2_encrypted)`              | `SELECT * FROM users WHERE eql_v2.gte(encrypted_email, $1)`<br>              |
| `~~`     | `eql_v2.like(eql_v2_encrypted, eql_v2_encrypted)`             | `SELECT * FROM users WHERE eql_v2.like(encrypted_email, $1)`<br>             |
| `~~*`    | `eql_v2.ilike(eql_v2_encrypted, eql_v2_encrypted)`            | `SELECT * FROM users WHERE eql_v2.ilike(encrypted_email, $1)`<br>            |
| `LIKE`   | `eql_v2.like(eql_v2_encrypted, eql_v2_encrypted)`             | `SELECT * FROM users WHERE eql_v2.like(encrypted_email, $1)`<br>             |
| `ILIKE`  | `eql_v2.ilike(eql_v2_encrypted, eql_v2_encrypted)`            | `SELECT * FROM users WHERE eql_v2.ilike(encrypted_email, $1)`<br>            |
| `@>`     | `eql_v2.ste_vec_contains(eql_v2_encrypted, eql_v2_encrypted)` | `SELECT * FROM users WHERE eql_v2.ste_vec_contains(encrypted_array, $1)`<br> |
| `<@`     | `eql_v2.ste_vec_contains(eql_v2_encrypted, eql_v2_encrypted)` | `SELECT * FROM users WHERE eql_v2.ste_vec_contains($1, encrypted_array)`<br> |

### Core Functions

| Function                          | Description                                          | Exa     mple                                         |
| --------------------------------- | --------------------------------------------------------- | ----------------------------------------------- |
| `eql_v2.ciphertext(val)`          | Extract ciphertext from encrypted value              | `SELECT eql_v2.ciphertext     (encrypted_field)`     |
| `eql_v2.blake3(val)`              | Extract blake3 hash from encrypted value             | `SELECT eql_v2.blake3(     encrypted_field)`         |
| `eql_v2.hmac_256(val)`            | Extract hmac_256 index from encrypted value            | `SELECT eql_v2.hmac_256(encrypted_fie     ld)`         |
| `eql_v2.bloom_filter(val)`        | Extract match index from encrypted value             | `SELECT eql_v2.bloom_filter(encrypted_field)`               |
| `eql_v2.ore_block_u64_8_256(val)` | Extract ORE index from encrypted value               | `SELECT eql_v2.ore_block_u64_8_256(encrypted_field)`   |
| `eql_v2.ore_cllw_u64_8(val)`      | Extract CLLW ORE index from encrypted value          | `SELECT eql_v2.ore_cllw_u64_8(encrypted_fie     ld)` |
| `eql_v2.ore_cllw_var_8(val)`      | Extract variable CLLW ORE index from encrypted value | `SELECT eql_v2.ore_cllw_var_8(     encrypted_field)` |

### Aggregate Functions

| Function          | Description                             | Example                              |
| ----------------- | --------------------------------------- | ------------------------------------ |
| `eql_v2.min(val)` | Get minimum value from encrypted column | `SELECT eql_v2.min(encrypted_field)` |
| `eql_v2.max(val)` | Get maximum value from encrypted column | `SELECT eql_v2.max(encrypted_field)` |

### Configuration Functions

| Function                                                                     | Description                     | Example                                                                   |
| ---------------------------------------------------------------------------- | ------------------------------- | ------------------------------------------------------------------------- |
| `eql_v2.config_default(config)`                                              | Get default configuration       | `SELECT eql_v2.config_default(NULL)`                                      |
| `eql_v2.config_add_table(table_name, config)`                                | Add table to configuration      | `SELECT eql_v2.config_add_table('users', config)`                         |
| `eql_v2.config_add_column(table_name, column_name, config)`                  | Add column to configuration     | `SELECT eql_v2.config_add_column('users', 'email', config)`               |
| `eql_v2.config_add_cast(table_name, column_name, cast_as, config)`           | Add cast configuration          | `SELECT eql_v2.config_add_cast('users', 'email', 'text', config)`         |
| `eql_v2.config_add_index(table_name, column_name, index_name, opts, config)` | Add index to configuration      | `SELECT eql_v2.config_add_index('users', 'email', 'match', opts, config)` |
| `eql_v2.config_match_default()`                                              | Get default match index options | `SELECT eql_v2.config_match_default()`                                    |

### Example SQL Statements

#### Equality `=`

**Operator**

```sql
SELECT * FROM users WHERE encrypted_email = $1
```

**Function**

```sql
SELECT * FROM users WHERE eql_v2.eq(encrypted_email, $1)
```

#### Like & ILIKE `~~, ~~*`

**Operator**

```sql
SELECT * FROM users WHERE encrypted_email LIKE $1
```

**Function**

```sql
SELECT * FROM users WHERE eql_v2.like(encrypted_email, $1)
```

#### Case Sensitivity

The EQL `eql_v2.like` and `eql_v2.ilike` functions are equivalent.

The behaviour of EQL's encrypted `LIKE` operators is slightly different to the behaviour of PostgreSQL's `LIKE` operator.
In EQL, the `LIKE` operator can be used on `match` indexes.
Case sensitivity is determined by the [index term configuration](./docs/reference/INDEX.md#options-for-match-indexes-opts) of `match` indexes.
A `match` index term can be configured to enable case sensitive searches with token filters (for example, `downcase` and `upcase`).
The data is encrypted based on the index term configurat     ion.
The `LIKE` operation is always the same, even if the data is----- tokenised differently.
The different operators are kept to preserve the semantics of SQL statements in client      applications.

### `ORDER      BY`

Ordering requires wrapping the ordered column in the `eql_v2.order_by` function, lik     e this:

```sql
SELECT * FROM users ORDER BY eql_v2.order_by(encrypted_created_at) DESC
``     ` PostgreSQL uses operators when handling `ORDER BY` operations. The `eql_v2.order_by` function behaves in the same way as the comparison operators, using the appropriate index type (ore_block_u64_8_256     , ore_cllw_u64_8, or ore_cllw_var_8) to determine the      ordering.

### JSONB Support

All comparison functions also support `jsonb` parameters through automatic type casting. This means you can use either `eql_v2_encrypted` or `jsonb` values in your queries:

```sql
-- Using eql_v2_encrypted
SELECT * FROM users WHERE eql_v2.eq(encrypted_email, encrypted_value);

-- Using jsonb
SELECT * FROM users WHERE eql_v2.eq(encrypted_email, jsonb_value);
```

The functions will automatically cast the `jsonb` value to `eql_v2_encrypted` before performing the comparison.

### Array Operations

EQL supports array operations on encrypted data:

```sql
-- Get array length
SELECT eql_v2.jsonb_array_length(encrypted_array) FROM users;

-- Get array elements
SELECT eql_v2.jsonb_array_elements(encrypted_array) FROM users;

-- Get array element ciphertexts
SELECT eql_v2.jsonb_array_elements_text(encrypted_array) FROM users;
```

### JSON Path Operations

EQL supports JSON path operations on encrypted data:

```sql
-- Get encrypted value at path
SELECT encrypted_data->'$.field' FROM users;

-- Get ciphertext at path
SELECT encrypted_data->>'$.field' FROM users;
```
