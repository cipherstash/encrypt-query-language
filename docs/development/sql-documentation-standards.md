# SQL Documentation Standards

## Required Doxygen Tags

### Mandatory
- `@brief` - One sentence description
- `@param` - For each parameter (with type and description)
- `@return` - Return value description (include structure for JSONB)

### Encouraged
- `@example` - Usage examples (SQL code blocks)
- `@throws` - Exception conditions (when RAISE is used)
- `@internal` - Mark private functions (prefix with `_`)

### Optional
- `@see` - Cross-references
- `@note` - Additional warnings/notes
- `@deprecated` - Migration path for deprecated functions

## Format Examples

### Public Function
```sql
--! @brief Extract the equality (hm) index term from an encrypted value
--!
--! Returns the HMAC equality term used by `=` / `<>` and by a functional
--! hash index. Inlinable, so a functional index on this extractor engages
--! bare-form queries.
--!
--! @param a eql_v3.int4_eq Encrypted value carrying an `hm` term
--! @return eql_v3.hmac_256 The equality index term
--!
--! @example
--! CREATE INDEX ON users USING hash (eql_v3.eq_term(salary_eq));
--!
--! @see eql_v3.ord_term
CREATE FUNCTION eql_v3.eq_term(a eql_v3.int4_eq)
  RETURNS eql_v3.hmac_256
AS $$ ... $$;
```

### Private Function
```sql
--! @brief Internal helper for encrypted-payload validation
--! @internal
--! @param val JSONB Encrypted payload to validate
--! @return Boolean True if the payload is well-formed
CREATE FUNCTION eql_v3._validate_payload(val jsonb)
  RETURNS boolean
AS $$ ... $$;
```

### Operator
```sql
--! @brief Equality comparison for an encrypted-domain value
--!
--! Implements the `=` operator for an `eql_v3` domain variant. Reduces to a
--! comparison on the extracted equality term — no decryption.
--!
--! @param a eql_v3.int4_eq Left operand
--! @param b eql_v3.int4_eq Right operand
--! @return Boolean True if the equality terms match
--!
--! @example
--! -- Using operator syntax:
--! SELECT * FROM users WHERE encrypted_email = $1;
--!
--! @see eql_v3.eq_term
CREATE FUNCTION eql_v3.eq(a eql_v3.int4_eq, b eql_v3.int4_eq)
  RETURNS boolean
AS $$ ... $$;

CREATE OPERATOR = (
  FUNCTION=eql_v3.eq,
  LEFTARG=eql_v3.int4_eq,
  RIGHTARG=eql_v3.int4_eq
);
```

### Type
```sql
--! @brief Encrypted-domain type for an equality-searchable int4 column
--!
--! A `jsonb`-backed domain in the `eql_v3` schema. The `CHECK` requires the
--! envelope keys (`v`, `i`, `c`), the equality term (`hm`), and pins the
--! payload version (`VALUE->>'v' = '2'`).
--!
--! @see eql_v3.eq_term
CREATE DOMAIN eql_v3.int4_eq AS jsonb
  CHECK ( ... );
```

### Aggregate
```sql
--! @brief State transition function for the MIN aggregate
--! @internal
--! @param $1 eql_v3.int4_ord Accumulated state
--! @param $2 eql_v3.int4_ord New value
--! @return eql_v3.int4_ord Updated state
CREATE FUNCTION eql_v3.min_sfunc(eql_v3.int4_ord, eql_v3.int4_ord)
  RETURNS eql_v3.int4_ord
AS $$ ... $$;

--! @brief Minimum encrypted value in a group
--!
--! Aggregate over an ordered encrypted-domain column. Comparison routes
--! through the variant's `<` operator (the ORE block term) — no decryption.
--!
--! @param input eql_v3.int4_ord Encrypted values to aggregate
--! @return eql_v3.int4_ord The minimum value
--!
--! @example
--! SELECT eql_v3.min(price_encrypted) FROM products;
--!
--! @see eql_v3.min_sfunc
CREATE AGGREGATE eql_v3.min(eql_v3.int4_ord) (
  SFUNC = eql_v3.min_sfunc,
  STYPE = eql_v3.int4_ord
);
```
