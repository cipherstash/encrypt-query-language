# Database Indexes for Encrypted Columns

EQL supports PostgreSQL B-tree indexes on `eql_v2_encrypted` columns to improve query performance. This guide explains how to create and use indexes effectively.

## Table of Contents

- [Creating Indexes](#creating-indexes)
- [Index Usage Requirements](#index-usage-requirements)
- [Query Patterns That Use Indexes](#query-patterns-that-use-indexes)
- [Query Patterns That Don't Use Indexes](#query-patterns-that-dont-use-indexes)
- [Index Limitations](#index-limitations)
- [Best Practices](#best-practices)

---

## Creating Indexes

### Basic Index Creation

Create a B-tree index on an encrypted column using the `eql_v2.encrypted_operator_class`:

```sql
CREATE INDEX ON table_name (encrypted_column eql_v2.encrypted_operator_class);
```

**Named index:**

```sql
CREATE INDEX idx_users_email ON users (encrypted_email eql_v2.encrypted_operator_class);
```

### When to Create Indexes

Create indexes on encrypted columns when:
- The table has a significant number of rows (typically > 1000)
- You frequently query by equality on that column
- Query performance is important
- The column contains searchable index terms (hmac_256, blake3, or ore)

---

## Index Usage Requirements

For PostgreSQL to use an index on encrypted columns, **all** of these conditions must be met:

### 1. Column Must Have Appropriate Search Terms

The encrypted data must contain the index term types that support the operation:

- **Equality queries** - Require `unique` index config (adds `hm` hmac_256 or `b3` blake3 terms)
- **Range queries** - Require `ore` index config (adds `ob` ore_block_u64_8_256 terms)
- **Pattern matching** - Typically scans (bloom filters don't use B-tree indexes)

**Example:**
```sql
-- This data HAS hmac_256 term - index will be used
'{"i":{"t":"users","c":"email"},"v":2,"hm":"abc123..."}'

-- This data has ONLY bloom filter - index WON'T be used for equality
'{"i":{"t":"users","c":"email"},"v":2,"bf":[1,2,3]}'
```

### 2. Index Must Be Created AFTER Data Contains Required Terms

If you:
1. Insert data without a search term (e.g., only `bf`)
2. Add the search term later (e.g., add `hm`)
3. Create an index

**The index will NOT work** until you:
- Recreate the index, OR
- Truncate and repopulate the table

**Correct order:**
```sql
-- 1. Configure the index type FIRST
SELECT eql_v2.add_search_config('users', 'encrypted_email', 'unique', 'text');

-- 2. Insert/update data through CipherStash Proxy (adds index terms)
INSERT INTO users (encrypted_email) VALUES (...);

-- 3. Create the PostgreSQL index
CREATE INDEX ON users (encrypted_email eql_v2.encrypted_operator_class);
ANALYZE users;
```

### 3. Query Must Use Correct Type Casting

The query value must be cast to `eql_v2_encrypted`:

**✓ Index will be used:**
```sql
-- Literal row type
WHERE e = '("{\"hm\": \"abc\"}")';

-- Cast to eql_v2_encrypted
WHERE e = '{"hm": "abc"}'::eql_v2_encrypted;
WHERE e = '{"hm": "abc"}'::text::eql_v2_encrypted;
WHERE e = '{"hm": "abc"}'::jsonb::eql_v2_encrypted;

-- Using helper function
WHERE e = eql_v2.to_encrypted('{"hm": "abc"}'::jsonb);
WHERE e = eql_v2.to_encrypted('{"hm": "abc"}');

-- Using parameterized query with encrypted value
WHERE e = $1::eql_v2_encrypted;
```

**✗ Index will NOT be used:**
```sql
-- Missing type cast
WHERE e = '{"hm": "abc"}'::jsonb;
```

---

## Query Patterns That Use Indexes

### Equality Queries

When encrypted column has `hm` (hmac_256) or `b3` (blake3) index terms:

```sql
-- These will use the index
SELECT * FROM users
WHERE encrypted_email = $1::eql_v2_encrypted;

SELECT * FROM users
WHERE encrypted_email = '{"hm": "abc123..."}'::eql_v2_encrypted;

SELECT * FROM users
WHERE encrypted_email = eql_v2.to_encrypted('{"hm": "abc123..."}'::jsonb);
```

**Expected EXPLAIN output:**
```
Index Only Scan using idx_users_email on users
  Index Cond: (encrypted_email = '...'::eql_v2_encrypted)
```

Or:
```
Bitmap Heap Scan on users
  Recheck Cond: (encrypted_email = '...'::eql_v2_encrypted)
  -> Bitmap Index Scan on idx_users_email
       Index Cond: (encrypted_email = '...'::eql_v2_encrypted)
```

### Range Queries

When encrypted column has `ob` (ore_block_u64_8_256) index terms:

```sql
SELECT * FROM events
WHERE encrypted_date < $1::eql_v2_encrypted
ORDER BY encrypted_date DESC;
```

### GROUP BY

Encrypted columns can be used in GROUP BY with indexes:

```sql
SELECT encrypted_status, COUNT(*)
FROM orders
GROUP BY encrypted_status;
```

---

## Query Patterns That Don't Use Indexes

### 1. Missing Type Cast

```sql
-- ✗ No index usage - missing ::eql_v2_encrypted cast
SELECT * FROM users WHERE encrypted_email = '{"hm": "abc"}'::jsonb;
```

### 2. Data Without Required Index Terms

```sql
-- ✗ Data only has bloom filter, not hmac_256
-- Index won't be used even if query is correct
SELECT * FROM users
WHERE encrypted_email = $1::eql_v2_encrypted;
-- If column only has: '{"bf":[1,2,3]}'
```

### 3. Pattern Matching (LIKE)

```sql
-- ✗ Bloom filter queries typically don't use B-tree indexes
SELECT * FROM users
WHERE encrypted_name ~~ $1::eql_v2_encrypted;
```

### 4. Index Created Before Data Population

```sql
-- ✗ Wrong order
CREATE INDEX ON users (encrypted_email eql_v2.encrypted_operator_class);
-- Then add data with hm terms
-- Index won't work until recreated
```

---

## Index Limitations

### 1. Index Term Requirement

B-tree indexes **only work** with:
- `hm` (hmac_256) - for equality
- `b3` (blake3) - for equality
- `ob` (ore_block_u64_8_256) - for range queries

They **do not work** with:
- `bf` (bloom_filter) - pattern matching
- `sv` (ste_vec) - JSONB containment
- Data without any index terms

### 2. Index Creation Timing

The index must be created **after** the data contains the required index terms. If you:

1. Add `unique` config to existing column
2. Re-encrypt data to add `hm` terms
3. Create index

You must create the index **after step 2**, not before.

### 3. Index Doesn't Auto-Update

If you modify the search configuration (e.g., change from `unique` to different config), you should:

```sql
-- Drop and recreate the index
DROP INDEX idx_users_email;
CREATE INDEX idx_users_email ON users (encrypted_email eql_v2.encrypted_operator_class);
ANALYZE users;
```

---

## Best Practices

### 1. Configure Search Indexes First

Always configure EQL search indexes before creating PostgreSQL indexes:

```sql
-- Step 1: Configure searchable encryption
SELECT eql_v2.add_column('users', 'encrypted_email', 'text');
SELECT eql_v2.add_search_config('users', 'encrypted_email', 'unique', 'text');

-- Step 2: Populate data (through CipherStash Proxy)
INSERT INTO users (encrypted_email) VALUES (...);

-- Step 3: Create PostgreSQL index
CREATE INDEX ON users (encrypted_email eql_v2.encrypted_operator_class);
ANALYZE users;
```

### 2. Run ANALYZE After Index Creation

Always run `ANALYZE` after creating an index to update query planner statistics:

```sql
CREATE INDEX idx_users_email ON users (encrypted_email eql_v2.encrypted_operator_class);
ANALYZE users;
```

### 3. Verify Index Usage

Use `EXPLAIN ANALYZE` to verify the index is being used:

```sql
EXPLAIN ANALYZE
SELECT * FROM users
WHERE encrypted_email = $1::eql_v2_encrypted;
```

Look for:
- `Index Only Scan using idx_name`
- `Bitmap Index Scan on idx_name`
- `Bitmap Heap Scan` with `Bitmap Index Scan`

If you see `Seq Scan`, the index is not being used.

### 4. Name Your Indexes

Use descriptive names for easier management:

```sql
CREATE INDEX idx_users_encrypted_email
ON users (encrypted_email eql_v2.encrypted_operator_class);

CREATE INDEX idx_events_encrypted_date
ON events (encrypted_date eql_v2.encrypted_operator_class);
```

### 5. Consider Index Size

Indexes on encrypted columns can be large. Monitor index size:

```sql
SELECT
  indexname,
  pg_size_pretty(pg_relation_size(schemaname||'.'||indexname)) AS index_size
FROM pg_indexes
WHERE tablename = 'users';
```

### 6. Drop Unused Indexes

If you remove a search configuration, drop the corresponding PostgreSQL index:

```sql
-- After removing search config
SELECT eql_v2.remove_search_config('users', 'encrypted_email', 'unique');

-- Drop the PostgreSQL index
DROP INDEX IF EXISTS idx_users_encrypted_email;
```

---

## Troubleshooting

### Index Not Being Used

**Check 1: Verify data has index terms**

```sql
-- Check if data contains hm (hmac_256) or b3 (blake3) for equality
SELECT encrypted_email::jsonb ? 'hm' AS has_hmac,
       encrypted_email::jsonb ? 'b3' AS has_blake3,
       encrypted_email::jsonb ? 'ob' AS has_ore
FROM users LIMIT 1;
```

**Check 2: Verify query uses correct cast**

```sql
-- ✓ Correct - will use index
WHERE encrypted_email = $1::eql_v2_encrypted

-- ✗ Wrong - won't use index
WHERE encrypted_email = $1::jsonb
```

**Check 3: Recreate index if needed**

```sql
DROP INDEX IF EXISTS idx_users_encrypted_email;
CREATE INDEX idx_users_encrypted_email
ON users (encrypted_email eql_v2.encrypted_operator_class);
ANALYZE users;
```

**Check 4: Verify index exists**

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'users'
  AND indexname LIKE '%encrypted%';
```

### Poor Query Performance

1. **Ensure index exists and is being used** - Use `EXPLAIN ANALYZE`
2. **Check table has been ANALYZEd** - Run `ANALYZE table_name`
3. **Consider index selectivity** - Very small tables might not use indexes
4. **Check for appropriate search config** - Equality needs `unique`, ranges need `ore`

---

## See Also

- [EQL Functions Reference](./eql-functions.md) - Complete function API
- [Index Configuration](./index-config.md) - Searchable encryption index types
- [Configuration Tutorial](../tutorials/proxy-configuration.md) - Setting up encrypted columns

---

### Didn't find what you wanted?

[Click here to let us know what was missing from our docs.](https://github.com/cipherstash/encrypt-query-language/issues/new?template=docs-feedback.yml&title=[Docs:]%20Feedback%20on%20database-indexes.md)
