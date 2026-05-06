# PostgreSQL Indexing in EQL: Complete Walkthrough

## 1. Architecture Overview

EQL implements searchable encryption by embedding **index terms** inside encrypted JSONB payloads. PostgreSQL never sees the plaintext — instead, custom operator classes teach PostgreSQL how to compare, hash, and order encrypted values using these embedded terms.

```
┌─────────────────────────────────────────────────────────────────┐
│                    eql_v2_encrypted Column                      │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    JSONB Payload                          │  │
│  │                                                           │  │
│  │  "c":  <ciphertext>          ← actual encrypted data      │  │
│  │  "k":  <key-id>              ← encryption key reference   │  │
│  │  "v":  2                     ← version                    │  │
│  │  "i":  { ... }               ← index configuration        │  │
│  │  "sv": [ ... ]               ← STE vector (sub-elements)  │  │
│  │  "a":  true/false            ← array flag                 │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │          Embedded Index Terms                       │  │  │
│  │  │                                                     │  │  │
│  │  │  "b3":  <blake3 hash>      ← equality (match)      │  │  │
│  │  │  "hm":  <hmac-256>         ← equality (unique)     │  │  │
│  │  │  "bf":  [int, int, ...]    ← LIKE (bloom filter)   │  │  │
│  │  │  "ob":  [hex, hex, ...]    ← ORDER BY (ORE block)  │  │  │
│  │  │  "ocf": <hex>              ← ORDER BY (ORE CLLW)   │  │  │
│  │  │  "ocv": <hex>              ← ORDER BY (ORE var)    │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Note**: For STE vector payloads (containing `sv`), the index terms are nested inside each `sv[]` element rather than at the top level of the JSONB. The diagram above shows a simplified structural overview.

## 2. Supported Index Types

EQL supports three PostgreSQL index types on `eql_v2_encrypted` columns:

### B-tree Index (equality, range, ORDER BY)

```sql
CREATE INDEX idx_users_email
ON users (encrypted_email eql_v2.encrypted_operator_class);
ANALYZE users;
```

Uses the custom `eql_v2.encrypted_operator_class` (default for `eql_v2_encrypted`). Supports `=`, `<>`, `<`, `<=`, `>`, `>=` operators. Requires index terms in the encrypted data:
- **Equality** (`=`, `<>`) — requires `hm` (HMAC-256) or `b3` (Blake3) terms
- **Range** (`<`, `>`, `<=`, `>=`, `ORDER BY`) — requires ORE terms (`ob`, `ocf`, or `ocv`)

### Hash Index (GROUP BY, DISTINCT, hash joins)

```sql
-- Hash index is used implicitly via the default hash operator class.
-- PostgreSQL uses it automatically for:
GROUP BY encrypted_column;
SELECT DISTINCT encrypted_column;
```

Uses `eql_v2.encrypted_hash_operator_class` (default for hash access method). Requires `b3` (Blake3) or `hm` (HMAC-256) terms.

### GIN Index (JSONB containment)

```sql
CREATE INDEX idx_encrypted_gin
ON users USING GIN (eql_v2.jsonb_array(encrypted_column));
ANALYZE users;
```

An expression index using PostgreSQL's built-in `array_ops` GIN operator class (not a custom operator class). Supports `@>` and `<@` containment queries:

```sql
-- Query using helper function
SELECT * FROM users
WHERE eql_v2.jsonb_contains(encrypted_column, $1::eql_v2_encrypted);

-- Or using jsonb_array() directly
SELECT * FROM users
WHERE eql_v2.jsonb_array(encrypted_column) @>
      eql_v2.jsonb_array($1::eql_v2_encrypted);
```

### Index Type Summary

| Index Type | Operator Class | Operators | Required Terms | Use Case |
|------------|---------------|-----------|----------------|----------|
| B-tree | `eql_v2.encrypted_operator_class` | `=`, `<>`, `<`, `<=`, `>`, `>=` | `hm`/`b3` (equality), `ob`/`ocf`/`ocv` (range) | Equality, range, ORDER BY |
| Hash | `eql_v2.encrypted_hash_operator_class` | `=` | `b3`/`hm` | GROUP BY, DISTINCT, hash joins |
| GIN | Built-in `array_ops` via `jsonb_array()` | `@>`, `<@` | `s`, `b3`, `hm`, `ocf`, `ocv` | JSONB containment |

**Not supported**: GiST, BRIN, SP-GiST — no operator classes are defined for these access methods.

## 3. The Core Type

Defined in `src/encrypted/types.sql`:

```sql
CREATE TYPE public.eql_v2_encrypted AS (
  data jsonb
);
```

A composite type wrapping a single JSONB field. This is what PostgreSQL stores in table columns. The JSONB payload carries both the ciphertext (`c`) and the index terms used for searching.

## 4. How PostgreSQL Uses Operator Classes

PostgreSQL requires **operator classes** to know how to build and search indexes for a given type. Each access method (btree, hash, GIN) needs a specific set of operators and support functions.

**Reference**: [PostgreSQL Operator Classes and Operator Families](https://www.postgresql.org/docs/current/indexes-opclass.html)

### 4.1 B-tree Operator Class

Defined in `src/operators/operator_class.sql`:

```sql
CREATE OPERATOR FAMILY eql_v2.encrypted_operator_family USING btree;

CREATE OPERATOR CLASS eql_v2.encrypted_operator_class
  DEFAULT FOR TYPE eql_v2_encrypted USING btree
  FAMILY eql_v2.encrypted_operator_family AS
    OPERATOR 1 <,        -- less than
    OPERATOR 2 <=,       -- less than or equal
    OPERATOR 3 =,        -- equal
    OPERATOR 4 >=,       -- greater than or equal
    OPERATOR 5 >,        -- greater than
    FUNCTION 1 eql_v2.compare(a eql_v2_encrypted, b eql_v2_encrypted);
```

The five **strategy numbers** (1-5) are defined by the btree access method specification. `FUNCTION 1` is the btree **support function** — a three-way comparator returning `-1`, `0`, or `1`.

**Reference**: [PostgreSQL B-Tree Support Functions](https://www.postgresql.org/docs/current/btree-support-funcs.html) — Strategy numbers and support function numbers are fixed by the btree AM specification.

Because this is `DEFAULT FOR TYPE`, PostgreSQL uses this operator class automatically for any `CREATE INDEX ... ON col` where `col` is `eql_v2_encrypted`.

### 4.2 Hash Operator Class

Defined in `src/operators/hash_operator_class.sql`:

```sql
CREATE OPERATOR FAMILY eql_v2.encrypted_hash_operator_family USING hash;

CREATE OPERATOR CLASS eql_v2.encrypted_hash_operator_class
  DEFAULT FOR TYPE eql_v2_encrypted USING hash
  FAMILY eql_v2.encrypted_hash_operator_family AS
    OPERATOR 1 = (eql_v2_encrypted, eql_v2_encrypted),
    FUNCTION 1 eql_v2.hash_encrypted(eql_v2_encrypted);
```

Hash operator classes require only the equality operator (strategy 1) and a hash support function (support function 1) that returns `integer`.

**Reference**: [PostgreSQL Hash Index](https://www.postgresql.org/docs/current/hash-intro.html)

This enables `GROUP BY`, `DISTINCT`, hash joins, and `UNION` on encrypted columns.

## 5. Operator Definitions

Each operator maps a symbol (`=`, `<`, etc.) to a function. EQL defines three overloads per operator:

```
  ┌─────────────────────┐     ┌─────────────────────┐     ┌──────────────────────┐
  │ (encrypted, encryp) │     │ (encrypted, jsonb)  │     │ (jsonb, encrypted)   │
  │                     │     │                     │     │                      │
  │  HASHES, MERGES     │     │  MERGES             │     │  MERGES              │
  │  ↓                  │     │  ↓                  │     │  ↓                   │
  │  eql_v2."="(a, b)   │     │  eql_v2."="(a, b)   │     │  eql_v2."="(a, b)    │
  │  → eql_v2.eq(a, b)  │     │  → eql_v2.eq(a, b') │     │  → eql_v2.eq(a', b)  │
  │  → compare(a,b) = 0 │     │  (b cast to encryp) │     │  (a cast to encryp)  │
  └─────────────────────┘     └─────────────────────┘     └──────────────────────┘
```

Only the `(encrypted, encrypted)` overload of `=` includes `HASHES` — this is required for the hash operator class to work. Cross-type operators can't participate in hash operations because each side must be independently hashable.

**Reference**: [PostgreSQL CREATE OPERATOR](https://www.postgresql.org/docs/current/sql-createoperator.html) — HASHES tells the planner this operator can use hash joins; MERGES enables merge joins.

The operators and their key properties:

| Operator | Function | Negator | Commutator | Selectivity | File |
|----------|----------|---------|------------|-------------|------|
| `=`  | `eql_v2."="` → `compare() = 0` | `<>` | — | `eqsel` / `eqjoinsel` | `src/operators/=.sql` |
| `<>` | `eql_v2."<>"` → `compare() != 0` | `=` | — | `eqsel` / `eqjoinsel` | `src/operators/<>.sql` |
| `<`  | `eql_v2."<"` → `compare() = -1` | `>=` | `>` | `scalarltsel` / `scalarltjoinsel` | `src/operators/<.sql` |
| `<=` | `eql_v2."<="` → `compare() <= 0` | `>` | `>=` | `scalarltsel` / `scalarltjoinsel` | `src/operators/<=.sql` |
| `>`  | `eql_v2.">"` → `compare() = 1` | `<=` | `<` | `scalarltsel` / `scalarltjoinsel` | `src/operators/>.sql` |
| `>=` | `eql_v2.">="` → `compare() >= 0` | `<` | `<=` | `scalarltsel` / `scalarltjoinsel` | `src/operators/>=.sql` |
| `~~` | `eql_v2."~~"` → `bloom_filter(@>)` | — | — | `eqsel` / `eqjoinsel` | `src/operators/~~.sql` |
| `@>` | `eql_v2."@>"` → `ste_vec_contains(a, b)` | — | `<@` | — | `src/operators/@>.sql` |
| `<@` | `eql_v2."<@"` → `ste_vec_contains(b, a)` | — | `@>` | — | `src/operators/<@.sql` |

**Note on MERGES**: All comparison operators (`=`, `<>`, `<`, `<=`, `>`, `>=`) and `~~` have `MERGES` on all overloads. Only the `(encrypted, encrypted)` overload of `=` has `HASHES`. The containment operators (`@>`, `<@`) have neither.

**Reference**: [PostgreSQL Operator Optimization](https://www.postgresql.org/docs/current/xoper-optimization.html) — `NEGATOR`, `COMMUTATOR`, `RESTRICT`, `JOIN` hints help the query planner.

## 6. The Compare Function — Heart of B-tree Indexing

This is the single most important function. Defined in `src/operators/compare.sql`:

```
  eql_v2.compare(a, b) → integer (-1, 0, 1)
       │
       ├── Unwrap STE vectors (to_ste_vec_value)
       │
       ├── Has ob + ob? ──→ compare_ore_block_u64_8_256(a, b)
       │                          │
       │                          ├── ore_block_u64_8_256(a) → extract ore_block type
       │                          ├── ore_block_u64_8_256(b) → extract ore_block type
       │                          ├── compare_ore_block_u64_8_256_terms(a.terms, b.terms)
       │                          │     ├── compare_ore_block_u64_8_256_term(a[1], b[1])
       │                          │     │     └── AES-ECB cryptographic comparison
       │                          │     └── recurse on remaining terms
       │                          └── return -1 / 0 / 1
       │
       ├── Has ocf + ocf? ──→ compare_ore_cllw_u64_8(a, b)
       │                          ├── ore_cllw_u64_8(a) → extract term
       │                          ├── ore_cllw_u64_8(b) → extract term
       │                          └── compare_ore_cllw_term_bytes(a_term.bytes, b_term.bytes)
       │                                └── CLLW cryptographic comparison (modular arithmetic)
       │
       ├── Has ocv + ocv? ──→ compare_ore_cllw_var_8(a, b)
       │                          └── compare_ore_cllw_var_8_term(a, b)
       │                                ├── compare common prefix length
       │                                └── fallback to length comparison
       │
       ├── Has hm + hm?  ──→ compare_hmac_256(a, b)
       │                          └── text comparison of HMAC values
       │
       ├── Has b3 + b3?  ──→ compare_blake3(a, b)
       │                          └── text comparison of blake3 hashes
       │
       └── Fallback      ──→ compare_literal(a, b)
                                  └── raw JSONB comparison (a.data vs b.data)
```

**Critical design decision**: The compare function checks both operands for matching index terms and uses the **first match** in priority order. This means:

- **ORE terms** (ob, ocf, ocv) provide true ordering — they support `<`, `<=`, `>`, `>=` with meaningful semantics
- **Hash terms** (hm, b3) only provide equality — but return a consistent text-based ordering for btree correctness (btree requires total ordering even if the ordering isn't semantically meaningful)
- **Literal fallback** prevents PostgreSQL internal errors ("lock BufferContent is not held") that occur when compare returns inconsistent results

**Reference**: [PostgreSQL B-Tree Behavior](https://www.postgresql.org/docs/current/btree-behavior.html) — B-tree support functions must provide a total order; inconsistent results corrupt the index.

## 7. The Hash Function — Hash/Equality Contract

Defined in `src/encrypted/hash.sql`:

```
  eql_v2.hash_encrypted(val) → integer
       │
       ├── Unwrap STE vector (to_ste_vec_value)
       │
       ├── Has b3? ──→ hashtext(blake3(val)::text)     ← CHECKED FIRST
       │
       ├── Has hm? ──→ hashtext(hmac_256(val)::text)
       │
       └── Neither ──→ RAISE EXCEPTION
```

**The hash/equality contract**: PostgreSQL requires that `a = b → hash(a) = hash(b)`. The inverse need not hold (hash collisions are fine).

The subtle insight is why **Blake3 is checked first** in hash, while it's **last** in compare:

```
  Scenario: Value A has {hm, b3}, Value B has {b3} only

  compare(A, B):
    - A has hm? yes.  B has hm? NO.  → skip
    - A has b3? yes.  B has b3? yes. → compare_blake3 → uses b3
    - Result: A = B if blake3 hashes match

  hash(A):
    - Must also use b3 (not hm) so that hash(A) matches hash(B)
    - Therefore: check b3 FIRST
```

If hash used HMAC-256 first for value A, then `hash(A)` would be based on HMAC while `A = B` is based on Blake3 — violating the contract.

**Reference**: [PostgreSQL Hash Index Implementation](https://www.postgresql.org/docs/current/hash-implementation.html)

## 8. Index Term Types and Their Capabilities

```
┌──────────────────────────────────────────────────────────────────┐
│                    Index Term Capabilities                       │
├──────────────┬────────┬──────────┬──────────┬──────────┬────────┤
│ Term Type    │ JSONB  │ Equality │ Ordering │ LIKE     │ GIN    │
│              │ Key    │ (=, <>)  │ (<, >)   │ (~~)     │ (@>)   │
├──────────────┼────────┼──────────┼──────────┼──────────┼────────┤
│ blake3       │ "b3"   │    ✓     │    ✗¹    │    ✗     │   ✓²   │
│ hmac_256     │ "hm"   │    ✓     │    ✗¹    │    ✗     │   ✓²   │
│ bloom_filter │ "bf"   │    ✗     │    ✗     │    ✓     │   ✗    │
│ ore_block    │ "ob"   │    ✓     │    ✓     │    ✗     │   ✗    │
│ ore_cllw_u64 │ "ocf"  │    ✓     │    ✓     │    ✗     │   ✓²   │
│ ore_cllw_var │ "ocv"  │    ✓     │    ✓     │    ✗     │   ✓²   │
├──────────────┴────────┴──────────┴──────────┴──────────┴────────┤
│ ¹ Text ordering for btree consistency, not semantic ordering    │
│ ² Included in jsonb_array() deterministic field extraction      │
└─────────────────────────────────────────────────────────────────┘
```

### 8.1 Blake3 (`b3`) — `src/blake3/`

```sql
CREATE DOMAIN eql_v2.blake3 AS text;  -- types.sql
```

A deterministic hash. Two identical plaintexts produce identical Blake3 hashes. Used for `match` index (equality searches). Extracted via `val.data->>'b3'`.

### 8.2 HMAC-256 (`hm`) — `src/hmac_256/`

```sql
CREATE DOMAIN eql_v2.hmac_256 AS text;  -- types.sql
```

A keyed hash for `unique` index (uniqueness enforcement + equality). Extracted via `val.data->>'hm'`.

### 8.3 Bloom Filter (`bf`) — `src/bloom_filter/`

```sql
CREATE DOMAIN eql_v2.bloom_filter AS smallint[];  -- types.sql
```

A probabilistic data structure for substring matching. The `~~` (LIKE) operator checks containment: `bloom_filter(haystack) @> bloom_filter(needle)`. This uses PostgreSQL's native `smallint[]` array containment — no custom operator class needed.

### 8.4 ORE Block (`ob`) — `src/ore_block_u64_8_256/`

```sql
CREATE TYPE eql_v2.ore_block_u64_8_256_term AS (bytes bytea);
CREATE TYPE eql_v2.ore_block_u64_8_256 AS (terms eql_v2.ore_block_u64_8_256_term[]);
```

**Order-Revealing Encryption** — ciphertexts that reveal the ordering of their plaintexts without revealing the actual values. The type name encodes the ORE parameters: `u64` = 64-bit input values, `8` = 8 blocks, `256` = 256-bucket encryption. The comparison uses a cryptographic protocol involving AES-ECB block encryption (`public.encrypt()` from pgcrypto).

The ORE block comparison algorithm at `src/ore_block_u64_8_256/functions.sql:136`:

```
For each of 8 blocks:
  1. Compare PRP bytes (first 8 bytes, one per block)
  2. Compare PRF blocks (16-byte chunks)
  3. If unequal, record the first differing block

For the first unequal block:
  1. Extract hash_key (IV) from right ciphertext of b
  2. Extract target_block from right side of b
  3. Extract data_block from left side of a
  4. AES-ECB encrypt data_block with hash_key
  5. Compute indicator via modular addition of specific bits
  6. indicator = (get_bit(encrypt_block, 0) + get_bit(target_block, get_byte(a.bytes, unequal_block))) % 2
  7. Return 1 if indicator=1, else -1
```

**Reference**: [Order-Revealing Encryption](https://eprint.iacr.org/2016/612.pdf) — The underlying cryptographic construction.

### 8.5 ORE CLLW (`ocf`, `ocv`) — `src/ore_cllw_u64_8/`, `src/ore_cllw_var_8/`

```sql
CREATE TYPE eql_v2.ore_cllw_u64_8 AS (bytes bytea);   -- fixed-length
CREATE TYPE eql_v2.ore_cllw_var_8 AS (bytes bytea);    -- variable-length
```

Alternative ORE schemes. `ocf` (fixed-width, 8-byte) uses byte-by-byte CLLW cryptographic comparison with modular arithmetic. `ocv` (variable-width) compares the common prefix then falls back to length comparison.

## 9. GIN Indexing for Containment Queries

GIN indexes enable efficient `@>` and `<@` containment queries on encrypted columns. EQL does **not** define a custom GIN operator class — instead, it uses an expression index with PostgreSQL's built-in `array_ops`:

```sql
CREATE INDEX idx ON mytable USING GIN (eql_v2.jsonb_array(encrypted_col));
ANALYZE mytable;
```

Query using the helper function (recommended):

```sql
SELECT * FROM mytable
WHERE eql_v2.jsonb_contains(encrypted_col, $1::eql_v2_encrypted);
```

Or using `jsonb_array()` directly:

```sql
SELECT * FROM mytable
WHERE eql_v2.jsonb_array(encrypted_col) @> eql_v2.jsonb_array($1::eql_v2_encrypted);
```

### 9.1 How `jsonb_array()` Works

The `eql_v2.jsonb_array()` function (`src/ste_vec/functions.sql`) converts an encrypted value into a `jsonb[]` array containing only **deterministic** fields — fields where the same plaintext always produces the same ciphertext. This is required because GIN containment (`@>`) compares entries by exact value.

**Included fields**: `s` (selector), `b3` (Blake3), `hm` (HMAC-256), `ocv` (ORE CLLW var), `ocf` (ORE CLLW u64)

**Excluded fields**: `c` (ciphertext), `k` (key ID), `v` (version), `ob` (ORE block — contains randomized components, unlike the deterministic CLLW variants)

For STE vector payloads (containing `sv`), each `sv[]` element is processed independently. For simple encrypted values, the single value is wrapped in a one-element array.

### 9.2 Helper Functions

- `eql_v2.jsonb_contains(a, b)` → `jsonb_array(a) @> jsonb_array(b)` (GIN-indexable)
- `eql_v2.jsonb_contained_by(a, b)` → `jsonb_array(a) <@ jsonb_array(b)`

**Reference**: [PostgreSQL GIN Indexes](https://www.postgresql.org/docs/current/gin-intro.html) and [GIN Built-in Operator Classes](https://www.postgresql.org/docs/current/gin-builtin-opclasses.html)

## 10. STE Vector Containment (`@>`, `<@`)

The `@>` and `<@` operators use a **separate** containment mechanism that does NOT use GIN. Defined in `src/ste_vec/functions.sql`:

```
  a @> b (Does a contain all elements of b?)
       │
       ├── eql_v2.ste_vec(a) → eql_v2_encrypted[]  (extract STE vector array)
       ├── eql_v2.ste_vec(b) → eql_v2_encrypted[]
       │
       └── For each element _b in sv_b:
             For each element _a in sv_a:
               Check: selector(_a) = selector(_b) AND _a = _b
             All _b elements must match some _a element
```

This performs element-by-element matching on both **selector** (the `s` field, which identifies the JSON path) and **value equality** (using the standard `=` operator, which itself delegates to `compare()`).

The `<@` operator reverses the arguments:

```
  a <@ b (Is a contained by b? Equivalent to: b @> a)
       │
       └── eql_v2.ste_vec_contains(b, a)   ← note reversed arguments
```

## 11. Query Execution Flow — End to End

### 12.1 Equality Query (`WHERE col = ?`)

```
  SQL: SELECT * FROM users WHERE encrypted_email = $1::eql_v2_encrypted

  1. Planner sees: = operator on eql_v2_encrypted
  2. Looks up default btree operator class → encrypted_operator_class
  3. If btree index exists on col:
     a. Uses FUNCTION 1 (compare) as the btree support function
     b. Descends B-tree using compare(indexed_val, search_val)
     c. compare() checks index terms in priority order
     d. First matching term type in both values is used
  4. If hash index exists on col:
     a. Computes hash_encrypted($1) → integer
     b. Looks up hash bucket
     c. Rechecks with = operator

  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐
  │  = op    │───→│  eql_v2."="  │───→│  eql_v2.eq(a,b)  │
  └──────────┘    └──────────────┘    └──────────────────┘
                                              │
                                      ┌───────▼───────────┐
                                      │ compare(a,b) = 0  │
                                      └───────────────────┘
                                              │
                  ┌─────────┼─────────┬──────────┬──────────┐
               has ob?  has ocf? has ocv?  has hm?    has b3?
                  │        │        │         │           │
          compare_ore  compare   compare  compare    compare
          _block       _ore_cllw _ore_cllw _hmac_256  _blake3
          (true order) (true)    (true)    (text)     (text)
```

### 12.2 Range Query (`WHERE col > ? AND col < ?`)

```
  SQL: SELECT * FROM users WHERE encrypted_age > $1 AND encrypted_age < $2

  1. Planner sees: > and < operators on eql_v2_encrypted
  2. With btree index, performs range scan
  3. compare() must use ORE terms (ob/ocf/ocv) for meaningful ordering
  4. If only hash terms present, ordering is deterministic but not semantic

  Note: Only ORE-indexed columns produce meaningful range query results.
  Blake3/HMAC ordering is arbitrary (consistent for btree but not meaningful).
```

### 12.3 LIKE Query (`WHERE col ~~ ?`)

```
  SQL: SELECT * FROM users WHERE encrypted_name ~~ $1::eql_v2_encrypted

  1. Operator ~~ resolved to eql_v2."~~"
  2. Delegates to eql_v2.like(a, b)
  3. Extracts bloom filters: bloom_filter(a), bloom_filter(b)
  4. Uses PostgreSQL native: smallint[] @> smallint[]

  ┌──────────┐    ┌──────────────┐    ┌──────────────────────────────┐
  │  ~~ op   │───→│ eql_v2."~~"  │───→│ bloom_filter(a) @> bloom(b)  │
  └──────────┘    └──────────────┘    └──────────────────────────────┘
                                              │
                                      Uses native smallint[]
                                      containment operator
```

### 11.4 GIN Containment Query

```
  SQL: SELECT * FROM t
       WHERE eql_v2.jsonb_contains(encrypted_col, $1::eql_v2_encrypted)

  1. Expression index: GIN(eql_v2.jsonb_array(encrypted_col))
  2. jsonb_contains → jsonb_array(a) @> jsonb_array(b)
  3. PostgreSQL uses GIN index on jsonb_array(col) for the @> check
  4. GIN extracts individual jsonb elements as keys
  5. Lookup matches on deterministic fields (s, b3, hm, ocv, ocf)
```

## 12. The Consistency Invariants

### 12.1 B-tree Total Order Requirement

PostgreSQL B-tree indexes require a **strict total order**: for any values a, b, c:
- `compare(a, a) = 0` (reflexive)
- `compare(a, b) = -compare(b, a)` (antisymmetric)
- If `compare(a, b) <= 0` and `compare(b, c) <= 0` then `compare(a, c) <= 0` (transitive)

EQL satisfies this by:
1. Using the same comparison function for all operator strategies
2. Falling back to literal JSONB comparison when no index terms match
3. Never returning inconsistent results (which would corrupt the btree)

**Reference**: [PostgreSQL B-Tree Behavior](https://www.postgresql.org/docs/current/btree-behavior.html)

### 12.2 Hash/Equality Contract

`a = b → hash(a) = hash(b)` is maintained by:
1. `hash_encrypted` uses Blake3 first, because blake3 is the broadest common denominator — `compare()` will fall through to blake3 when no higher-priority terms match in both operands, so hash must also use blake3 to maintain the contract
2. If A has `{hm, b3}` and B has `{b3}`, compare uses `b3`, hash uses `b3`
3. If both have only `hm`, compare uses `hm`, hash uses `hm` (since no b3 exists)

**Reference**: [PostgreSQL Hash Index Support](https://www.postgresql.org/docs/current/hash-intro.html)

### 12.3 IMMUTABLE and PARALLEL SAFE

The core index support functions are declared `IMMUTABLE STRICT PARALLEL SAFE`:
- `eql_v2.compare()` — the btree support function
- `eql_v2.hash_encrypted()` — the hash support function
- `eql_v2.eq()`, `eql_v2.neq()` — equality/inequality helpers
- All `compare_*` sub-functions (`compare_blake3`, `compare_hmac_256`, `compare_ore_block_u64_8_256`, etc.)

The operator wrapper functions (`eql_v2."<"`, `eql_v2.">"`, etc.) and ordering helpers (`eql_v2.lt`, `eql_v2.gt`, `eql_v2.lte`, `eql_v2.gte`) do **not** currently declare these attributes, relying on PostgreSQL defaults. Since they only call IMMUTABLE functions, they could be declared IMMUTABLE as well.

**Reference**: [PostgreSQL Function Volatility](https://www.postgresql.org/docs/current/xfunc-volatility.html) — Index support functions **must** be IMMUTABLE.

## 13. Summary Diagram — The Full Stack

```
                        ┌─────────────────────┐
                        │    SQL Query         │
                        │  WHERE col = $1      │
                        │  ORDER BY col        │
                        │  GROUP BY col        │
                        └─────────┬───────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    PostgreSQL Planner      │
                    │                            │
                    │  Looks up operator class   │
                    │  for eql_v2_encrypted      │
                    └─────────────┬──────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌───────▼───────┐  ┌───────▼────────┐
     │  btree opclass  │ │ hash opclass  │  │  GIN (expr)    │
     │  FUNCTION 1     │ │ FUNCTION 1    │  │  jsonb_array() │
     │  compare()      │ │ hash_encryp() │  │  → jsonb[] @>  │
     └────────┬────────┘ └───────┬───────┘  └────────────────┘
              │                  │
     ┌────────▼────────┐ ┌──────▼────────┐
     │ Index Term      │ │ Index Term    │
     │ Detection       │ │ Detection     │
     │ (has_* checks)  │ │ (has_* checks)│
     └────────┬────────┘ └──────┬────────┘
              │                 │
   ┌──────────┼──────────┐     │
   │    ORE   │  Hash    │     │
   │  ob/ocf  │  hm/b3   │     │
   │  ocv     │          │     │
   │          │          │     │
   ▼          ▼          │     ▼
  Crypto    Text       hashtext()
  Compare   Compare    of term
  (-1/0/1)  (-1/0/1)   → int32
```

## 14. Key PostgreSQL Documentation References

| Topic | URL |
|-------|-----|
| Operator Classes & Families | https://www.postgresql.org/docs/current/indexes-opclass.html |
| B-Tree Support Functions | https://www.postgresql.org/docs/current/btree-support-funcs.html |
| B-Tree Behavior | https://www.postgresql.org/docs/current/btree-behavior.html |
| Hash Index | https://www.postgresql.org/docs/current/hash-intro.html |
| GIN Indexes | https://www.postgresql.org/docs/current/gin-intro.html |
| GIN Built-in Operator Classes | https://www.postgresql.org/docs/current/gin-builtin-opclasses.html |
| CREATE OPERATOR | https://www.postgresql.org/docs/current/sql-createoperator.html |
| CREATE OPERATOR CLASS | https://www.postgresql.org/docs/current/sql-createopclass.html |
| CREATE OPERATOR FAMILY | https://www.postgresql.org/docs/current/sql-createopfamily.html |
| Operator Optimization | https://www.postgresql.org/docs/current/xoper-optimization.html |
| Function Volatility | https://www.postgresql.org/docs/current/xfunc-volatility.html |
| Interfacing Extensions to Indexes | https://www.postgresql.org/docs/current/xindex.html |
