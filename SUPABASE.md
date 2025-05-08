# Supabase


## No operators, no problems

Supabase [does not currently support](https://github.com/supabase/supautils/issues/72) custom operators.
The EQL operator functions can be used in this situation.

In EQL, PostgreSQL operators are an alias for a function, so the implementation and behaviour remains the same across operators and functions.

| Operator | Function                                           | Example                                                           |
| -------- | -------------------------------------------------- | ----------------------------------------------------------------- |
| `=`      | `eql_v1.eq(eql_v1_encrypted, eql_v1_encrypted)`    | `SELECT * FROM users WHERE eql_v1.eq(encrypted_email, $1)`<br>    |
| `<>`     | `eql_v1.neq(eql_v1_encrypted, eql_v1_encrypted)`   | `SELECT * FROM users WHERE eql_v1.neq(encrypted_email, $1)`<br>   |
| `<`      | `eql_v1.lt(eql_v1_encrypted, eql_v1_encrypted)`    | `SELECT * FROM users WHERE eql_v1.lt(encrypted_email, $1)`<br>    |
| `<=`     | `eql_v1.lte(eql_v1_encrypted, eql_v1_encrypted)`   | `SELECT * FROM users WHERE eql_v1.lte(encrypted_email, $1)`<br>   |
| `>`      | `eql_v1.gt(eql_v1_encrypted, eql_v1_encrypted)`    | `SELECT * FROM users WHERE eql_v1.gt(encrypted_email, $1)`<br>    |
| `>=`     | `eql_v1.gte(eql_v1_encrypted, eql_v1_encrypted)`   | `SELECT * FROM users WHERE eql_v1.gte(encrypted_email, $1)`<br>   |
| `~~`     | `eql_v1.like(eql_v1_encrypted, eql_v1_encrypted)`  | `SELECT * FROM users WHERE eql_v1.like(encrypted_email, $1)`<br>  |
| `~~*`    | `eql_v1.ilike(eql_v1_encrypted, eql_v1_encrypted)` | `SELECT * FROM users WHERE eql_v1.ilike(encrypted_email, $1)`<br> |
| `LIKE`   | `eql_v1.like(eql_v1_encrypted, eql_v1_encrypted)`  | `SELECT * FROM users WHERE eql_v1.like(encrypted_email, $1)`<br>  |
| `ILIKE`  | `eql_v1.ilike(eql_v1_encrypted, eql_v1_encrypted)` | `SELECT * FROM users WHERE eql_v1.ilike(encrypted_email, $1)`<br> |

### Example SQL Statements

#### Equality `=`


**Operator**
```sql
SELECT * FROM users WHERE encrypted_email = $1
```

**Function**
```sql
SELECT * FROM users WHERE eql_v1.eq(encrypted_email, $1)
```


#### Like & ILIKE `~~, ~~*`


**Operator**
```sql
SELECT * FROM users WHERE encrypted_email LIKE $1
```

**Function**
```sql
SELECT * FROM users WHERE eql_v1.like(encrypted_email, $1)
```

#### Case Sensitivity

The EQL `eql_v1.like` and `eql_v1.ilike` functions are equivalent.

The behaviour of the "match" index term that is used by the encrypted `LIKE` operators is slightly different to default PostgreSQL.
Case sensitivity is determined by the index term configuration.
A `match` index term can be configured to enable case sensitive searches with token filters (for example, `downcase` and `upcase`).
The data is encrypted based on the configuration.
The `LIKE` operation is always the same, and the data is different.
The different operators are kept to preserve the semantics of SQL statements in client applications.

### `ORDER BY`

Ordering requires wrapping the ordered column in the `eql_v1.order_by` function, like this:

```sql
SELECT * FROM users ORDER BY eql_v1.order_by(encrypted_created_at) DESC
```

PostgreSQL uses operators when handling `ORDER BY` operations. The `eql_v1.order_by` function behaves in

