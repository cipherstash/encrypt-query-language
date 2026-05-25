# SQLx Test Fixtures Schema Documentation

This document defines the structure and dependencies of test fixtures used in the SQLx test suite.

## Fixture Dependencies

```
EQL Extension (via migrations)
  ├── encrypted_json.sql
  │   └── array_data.sql (extends `encrypted` table from encrypted_json)
  ├── match_data.sql
  ├── aggregate_minmax_data.sql
  ├── config_tables.sql
  ├── constraint_tables.sql
  ├── encryptindex_tables.sql
  ├── drop_operator_classes.sql (Supabase-simulation; drops opclasses + ORE operators)
  ├── order_by_null_data.sql (depends on ore migration)
  ├── ore table (migration 002 — not a fixture)
  └── bench_data.sql + bench_setup.sql (depend on migration 007)

eql_v2_int4.sql (no EQL dependency — generated, plain jsonb, not committed)
```

All fixtures except the generated `eql_v2_int4.sql` depend on the EQL extension being installed via SQLx migrations.

---

## encrypted_json.sql

**Purpose:** Creates `encrypted` table with HMAC-indexed encrypted values for equality/JSONB tests.

**Schema:**
```sql
CREATE TABLE encrypted (
  id INTEGER PRIMARY KEY,
  e eql_v2_encrypted
);
```

**Data:**
- 3 records (ids 1, 2, 3)
- Each record has encrypted JSONB with HMAC index
- Values include nested objects for JSONB path tests

**Used By:**
- equality_tests.rs
- jsonb_tests.rs
- inequality_tests.rs
- jsonb_path_operators_tests.rs
- containment_tests.rs
- like_operator_tests.rs
- aggregate_tests.rs

**Create Function:**
- Uses `create_encrypted_json(id, 'hm')` for HMAC-indexed values
- Creates consistent test data across test runs

---

## array_data.sql

**Purpose:** Creates test data with arrays for JSONB array function tests.

**Dependencies:**
- Requires `encrypted_json.sql` (extends encrypted table or creates new table)

**Data:**
- Records with JSONB arrays
- Used for testing `jsonb_array_elements()` and array path queries

**Used By:**
- jsonb_tests.rs (array-specific tests)

---

## order_by_null_data.sql

**Purpose:** Creates `encrypted` table with NULL and ORE-encrypted values for ORDER BY NULL ordering tests.

**Dependencies:**
- Requires `ore` table from migrations (selects encrypted values for ids 42 and 3)

**Schema:**
```sql
CREATE TABLE encrypted (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  e eql_v2_encrypted
);
```

**Data:**
- 4 records:
  - id=1: NULL
  - id=2: ORE value for 42 (from ore table)
  - id=3: ORE value for 3 (from ore table)
  - id=4: NULL

**Used By:**
- order_by_tests.rs (NULLS FIRST / NULLS LAST tests)

---

## ore table (from migrations - NOT a fixture)

**Source:** `tests/sqlx/migrations/002_install_ore_data.sql`

**Purpose:** Provides ORE-encrypted values 1-99 for comparison/ORDER BY tests.

**Schema:**
```sql
CREATE TABLE ore (
  id bigint PRIMARY KEY,
  e eql_v2_encrypted
);
```

**Data:**
- 99 records (ids 1-99)
- Each record has ONLY `ob` key (ORE block), NOT ore64 index
- Pre-seeded by migration, available to all tests automatically
- No fixture needed - table exists from migrations

**Used By:**
- comparison_tests.rs (< > <= >=)
- order_by_tests.rs
- ore_equality_tests.rs (ORE variants)
- aggregate_tests.rs (MAX/MIN)

**Helper Functions:**
- `get_ore_encrypted(pool, id)` - Selects encrypted value from ore table
- `create_encrypted_json(id)` - Looks up ore table at `id * 10` (valid ids: 1-9 → ore lookups: 10-90)

**Key Property:**
- Sequential numeric values enable deterministic comparison tests
- e.g., `WHERE e < get_ore_encrypted(42)` should return 41 records

**IMPORTANT:**
- ❌ DO NOT create `ore_data.sql` fixture - table already exists from migrations
- ❌ DO NOT use `scripts("ore_data")` in test attributes
- ✅ Use `#[sqlx::test]` without fixtures for ORE tests

---

## bench_data.sql

**Purpose:** Seeds 10K rows into the `bench` table for performance benchmarking. Opt-in fixture — only loaded when a test explicitly includes `scripts("bench_data")`, so other tests don't pay the cost.

**Dependencies:**
- Requires `bench` table from migration `007_install_bench_data.sql`
- Uses `create_encrypted_json()` from migration `004_install_test_helpers.sql`

**Schema:** Uses `bench` table (DDL in migration 007):
```sql
CREATE TABLE bench (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  encrypted_text    eql_v2_encrypted,
  encrypted_int     eql_v2_encrypted,
  encrypted_bigint  eql_v2_encrypted
);
```

**Data:**
- 10,000 rows drawn from 99 distinct encrypted values via `create_encrypted_json()` helper ids 1-99 (which map to ORE rows 10, 20, ..., 990)
- Zipf-like skew via `setseed(0.42)` + `random()^2` — deterministic and byte-identical across runs
- Top id gets ~5% of rows; tail ids ~0.5% each (top:bottom ratio ~10x)
- Each column draws independently, so column values are decorrelated within a row
- Each row has HMAC, bloom filter, and ORE index terms

**Used By:**
- bench_data_tests.rs (all tests)

---

## bench_setup.sql

**Purpose:** Creates the 5 benchmark indexes and refreshes planner statistics. Always loaded after `bench_data.sql` in tests that verify index usage.

**Dependencies:**
- Requires `bench` table with data from `bench_data.sql`

**Indexes created:**
- `bench_text_hmac_idx` — hash on `eql_v2.hmac_256(encrypted_text)` for equality
- `bench_text_ore_idx` — btree on `encrypted_text` via operator class for text ordering
- `bench_int_ore_idx` — btree on `encrypted_int` via operator class for range/ORDER BY
- `bench_bigint_ore_idx` — btree on `encrypted_bigint` via operator class
- `bench_text_bloom_idx` — GIN on `eql_v2.bloom_filter(encrypted_text)` for containment

**Used By:**
- bench_data_tests.rs (index-usage tests: `scripts("bench_data", "bench_setup")`)

---

## eql_v2_int4.sql

**Purpose:** 14 encrypted integers for verifying encrypted-integer fixture
structure. Unlike its neighbours, this is a **generated** fixture — produced by
`mise run fixture:generate eql_v2_int4` (the Rust fixture framework in
`tests/sqlx/src/fixtures/`) and **not committed** (see `.gitignore`). It is
plain SQL with **no EQL dependency**: `payload` is `jsonb`, so the script
applies standalone.

**Regenerated every test run.** `mise run test:sqlx` invokes the generator
before `cargo test`, so a stale committed fixture cannot mask a payload-shape
regression. The generator encrypts in-process via `cipherstash-client`; it
needs a live Postgres plus CipherStash workspace credentials
(`CS_CLIENT_ACCESS_KEY` + `CS_WORKSPACE_CRN`, or the legacy
`CS_CLIENT_ID`/`CS_CLIENT_KEY` pair) in the shell environment. Do not
hand-edit the generated file; it is overwritten in place on every run.

**Schema:** Table lives in the dedicated `fixtures` SQL schema (kept out of the
`public` type/domain namespace so a downstream `public.eql_v2_int4` domain can
coexist):
```sql
CREATE SCHEMA IF NOT EXISTS fixtures;
CREATE TABLE fixtures.eql_v2_int4 (
  id BIGINT PRIMARY KEY,
  plaintext integer NOT NULL,
  payload jsonb NOT NULL
);
```

**Data:**
- 14 rows, ids 1-14; `id = N` is the Nth generated value.
- `plaintext` values: `-100, -1, 1, 2, 5, 10, 17, 25, 42, 50, 100, 250, 1000, 9999`
  — a negative boundary plus small/medium/large/extreme magnitudes.
- `plaintext` is the **in-table oracle**: consuming tests filter
  `WHERE plaintext = N` directly, so no Rust value constant is shared.
- Each `payload` is a cipherstash-client-encrypted JSONB object carrying
  `c` (ciphertext), `hm` (HMAC equality term), `ob` (ORE block ordering
  term), an inert `i` metadata object, and the EQL v2 root discriminator
  (`k = "ct"`, `v = 2`).

**Used By:**
- eql_v2_int4_fixture_tests.rs (structural verification)
- (#225) the `eql_v2_int4` domain operator tests, via per-query `payload` casts

**Opt-in:** Not a migration — a SQLx fixture script. Each consuming test opts
in explicitly:
```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("eql_v2_int4")))]
```

---

## Validation Tests

Each fixture should have a validation test to ensure correct structure:

### encrypted_json Validation
```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("encrypted_json")))]
async fn fixture_encrypted_json_has_three_records(pool: PgPool) {
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM encrypted")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(count, 3, "encrypted_json fixture should create 3 records");
}
```

### ore Migration Validation
```rust
#[sqlx::test]
async fn fixture_ore_data_has_99_records(pool: PgPool) {
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM ore")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(count, 99, "ore migration should provide 99 records");
}
```

---

## Fixture Naming Conventions

- Use snake_case for fixture file names
- Name should describe the data, not the test using it
- Examples: `encrypted_json.sql`, `array_data.sql`, `bench_data.sql`

## Adding New Fixtures

1. Create fixture file in `tests/sqlx/fixtures/`
2. Add header comment explaining purpose and dependencies
3. Document schema in this file
4. Add validation test
5. Update dependency graph above

## Troubleshooting

**Fixture fails to load:**
- Check EQL extension is installed (migrations run first)
- Verify `create_encrypted_json()` function exists
- Check for SQL syntax errors in fixture file

**Inconsistent test results:**
- Fixtures are loaded per-test (isolated)
- Check fixture dependencies are correct
- Verify no cross-fixture table name conflicts
