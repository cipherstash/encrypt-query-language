# Accept Canonical Type Names in EQL — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use cipherpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update EQL's SQL validation to accept the new canonical type names (`"json"` alongside `"jsonb"`, `"plaintext_type"` alongside `"cast_as"`) so that configs produced by the canonical schema are accepted by EQL.

**Architecture:** EQL stores encryption config as JSONB in `eql_v2_configuration.data`. Two SQL functions validate the config: `config_check_cast()` (CHECK constraint) and `add_search_config()` (runtime validation). Both hard-code the valid type list. We update these to accept new names while maintaining backwards compatibility.

**Tech Stack:** PostgreSQL, SQL, Rust (SQLx tests)

**Prerequisite:** None — this can be done independently. EQL just needs to accept new names; it doesn't depend on the Rust canonical config crate.

**Design doc:** `~/cipherstash/cipherstash-suite/docs/plans/2026-04-01-canonical-encryption-config-design.md`

---

### Task 1: Update `config_check_cast()` to accept `"json"` as a valid type

**Files:**
- Modify: `src/config/constraints.sql:74-89`

**Step 1: Write the failing test**

Add a new test to `tests/sqlx/tests/config_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("config_tables")))]
async fn configuration_accepts_json_type_name(pool: PgPool) -> Result<()> {
    let config = serde_json::json!({
        "v": 1,
        "tables": {
            "events": {
                "data": {
                    "cast_as": "json",
                    "indexes": {
                        "ste_vec": {
                            "prefix": "event-data"
                        }
                    }
                }
            }
        }
    });

    let result = sqlx::query("INSERT INTO eql_v2_configuration (data) VALUES ($1::jsonb)")
        .bind(&config)
        .execute(&pool)
        .await;

    assert!(result.is_ok(), "Should accept 'json' as a valid type: {:?}", result.err());
    Ok(())
}
```

**Step 2: Run the test to verify it fails**

Run: `mise run test:sqlx`
Expected: FAIL — `"json"` is not in the valid type list

**Step 3: Update the constraint function**

In `src/config/constraints.sql`, update `eql_v2.config_check_cast()` (around line 80):

```sql
-- Before
'{text, int, small_int, big_int, real, double, boolean, date, jsonb}'

-- After
'{text, int, small_int, big_int, real, double, boolean, date, jsonb, json, float, decimal, timestamp}'
```

This adds:
- `json` — canonical name for `jsonb`
- `float` — canonical name (proxy previously used `real`/`double`)
- `decimal` — new type
- `timestamp` — new type

Also update the error message on the same function to include the new types.

**Step 4: Run the test to verify it passes**

Run: `mise run test:sqlx`
Expected: PASS

**Step 5: Commit**

```bash
git add src/config/constraints.sql tests/sqlx/tests/config_tests.rs
git commit --no-gpg-sign -m "feat: accept 'json', 'float', 'decimal', 'timestamp' as valid cast types in config constraints"
```

---

### Task 2: Update `add_search_config()` validation to accept new type names

**Files:**
- Modify: `src/config/functions.sql:49-51`

**Step 1: Write the failing test**

Add a test to `tests/sqlx/tests/config_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("config_tables")))]
async fn add_search_config_accepts_json_type(pool: PgPool) -> Result<()> {
    // First add a column with json type
    let add_col = sqlx::query("SELECT eql_v2.add_column($1, $2, $3)")
        .bind("events")
        .bind("data")
        .bind("json")
        .execute(&pool)
        .await;

    assert!(add_col.is_ok(), "add_column should accept 'json': {:?}", add_col.err());
    Ok(())
}
```

Note: Check the exact signature of `add_column` and `add_search_config` and adjust the test to match the actual function signatures.

**Step 2: Run the test to verify it fails**

Run: `mise run test:sqlx`
Expected: FAIL — `"json"` not accepted

**Step 3: Update the validation**

In `src/config/functions.sql` (around line 49):

```sql
-- Before
IF NOT cast_as = ANY('{text, int, small_int, big_int, real, double, boolean, date, jsonb}') THEN

-- After
IF NOT cast_as = ANY('{text, int, small_int, big_int, real, double, boolean, date, jsonb, json, float, decimal, timestamp}') THEN
```

**Step 4: Run the test to verify it passes**

Run: `mise run test:sqlx`
Expected: PASS

**Step 5: Commit**

```bash
git add src/config/functions.sql tests/sqlx/tests/config_tests.rs
git commit --no-gpg-sign -m "feat: accept canonical type names in add_search_config validation"
```

---

### Task 3: Accept `plaintext_type` field alongside `cast_as`

**Files:**
- Modify: `src/config/constraints.sql`
- Modify: `src/config/functions.sql`
- Modify: `src/config/functions_private.sql` (if it extracts `cast_as` from JSON)

**Step 1: Write the failing test**

Add to `tests/sqlx/tests/config_tests.rs`:

```rust
#[sqlx::test(fixtures(path = "../fixtures", scripts("config_tables")))]
async fn configuration_accepts_plaintext_type_field(pool: PgPool) -> Result<()> {
    let config = serde_json::json!({
        "v": 1,
        "tables": {
            "users": {
                "email": {
                    "plaintext_type": "text",
                    "indexes": {
                        "unique": {}
                    }
                }
            }
        }
    });

    let result = sqlx::query("INSERT INTO eql_v2_configuration (data) VALUES ($1::jsonb)")
        .bind(&config)
        .execute(&pool)
        .await;

    assert!(result.is_ok(), "Should accept 'plaintext_type' field: {:?}", result.err());
    Ok(())
}
```

**Step 2: Run the test to verify it fails**

Run: `mise run test:sqlx`
Expected: FAIL — constraint expects `cast_as` field

**Step 3: Update constraint and function code**

This is the most involved change. You need to find everywhere in the SQL that extracts or validates the `cast_as` key from JSONB and make it also check for `plaintext_type`.

In `config_check_cast()`, the validation likely does something like:

```sql
-- pseudocode of current logic
SELECT jsonb_object_keys(column_config) -> 'cast_as' ...
```

Update to check for either key:

```sql
-- Accept either 'cast_as' or 'plaintext_type'
COALESCE(column_config->>'plaintext_type', column_config->>'cast_as')
```

Similarly in `add_search_config()` and any private helper functions that extract the cast type from the JSONB config.

**Important:** Read through `functions_private.sql` carefully — there may be helper functions that extract `cast_as` from the JSONB data that also need updating.

**Step 4: Run the test to verify it passes**

Run: `mise run test:sqlx`
Expected: PASS

**Step 5: Run full test suite**

Run: `mise run test:sqlx`
Expected: All existing tests still pass (backwards compat with `cast_as`)

**Step 6: Commit**

```bash
git add src/config/constraints.sql src/config/functions.sql src/config/functions_private.sql tests/sqlx/tests/config_tests.rs
git commit --no-gpg-sign -m "feat: accept 'plaintext_type' field as alias for 'cast_as' in EQL config"
```

---

### Task 4: Update documentation

**Files:**
- Modify: `docs/reference/index-config.md`
- Modify: `docs/reference/eql-functions.md` (if it lists valid types)

**Step 1: Update the type list in index-config.md**

Around lines 37-48, update the supported types list to include canonical names:

```markdown
Supported types:
- `text` (default)
- `int`
- `small_int`
- `big_int`
- `float` (also accepts `real`, `double`)
- `boolean`
- `date`
- `json` (also accepts `jsonb`)
- `decimal`
- `timestamp`
```

**Step 2: Document `plaintext_type` field**

Add a note that `plaintext_type` is accepted as an alias for `cast_as`:

```markdown
The type field can be specified as either `plaintext_type` (preferred) or `cast_as` (legacy).
```

**Step 3: Commit**

```bash
git add docs/
git commit --no-gpg-sign -m "docs: update type reference to include canonical type names"
```

---

### Task 5: Full test verification

**Files:** None (verification only)

**Step 1: Build EQL**

Run: `mise run build`
Expected: All three build variants succeed (main, supabase, protect)

**Step 2: Run full test suite**

Run: `mise run test:sqlx`
Expected: All tests pass

**Step 3: If any failures, fix and commit**

```bash
git add -u
git commit --no-gpg-sign -m "fix: resolve issues from canonical type name changes"
```
