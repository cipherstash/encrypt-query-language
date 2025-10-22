# SQLx Testing Approach

## Problem Statement

The Rust component system (branch: `feature/rust-sql-tooling`) was built to:
1. Manage SQL file dependencies
2. Generate documentation
3. Enable Rust-based testing

However, it introduced significant complexity:
- 200+ lines of trait/macro machinery
- Associated types, dependency traits, 9 macro patterns
- Documentation still needs transformation to be useful for customers
- No compile-time safety (SQL files can still be missing/broken)

## Key Insight

**We already have working dependency resolution** - the bash build system:

```bash
# tasks/build.sh
find src -name "*.sql" | while read sql_file; do
    # Parse -- REQUIRE: comments
    # Build dependency graph
done

cat src/deps.txt | tsort | tac > src/deps-ordered.txt
cat src/deps-ordered.txt | xargs cat > release/cipherstash-encrypt.sql
```

This works perfectly for:
- ✅ Building release files
- ✅ Resolving dependencies
- ✅ Development workflow

## Proposed Solution

**Use SQLx for testing, keep bash for builds:**

1. **Dependencies** - Stay in SQL where they belong (`-- REQUIRE:`)
2. **Build** - Keep existing bash + tsort system
3. **Tests** - Use SQLx to load built SQL and test functionality
4. **Docs** - Generate from SQL comments (not rustdoc)

## Architecture Comparison

### Current (Bash + SQL)
```
SQL files with -- REQUIRE:
    ↓
tasks/build.sh (parse + tsort)
    ↓
release/cipherstash-encrypt.sql
    ↓
psql < release/...
```

### Attempted (Rust Component System)
```
SQL files with -- REQUIRE:
    ↓
Duplicate in Rust (sql_component! macro)
    ↓
Component::collect_dependencies()
    ↓
Load files in Rust tests
```

**Problem:** Duplication! Dependencies defined twice (SQL + Rust).

### Proposed (Bash + SQLx)
```
SQL files with -- REQUIRE:
    ↓
tasks/build.sh (existing)
    ↓
release/cipherstash-encrypt.sql
    ↓
SQLx tests load pre-built SQL
```

**Benefit:** Single source of truth in SQL.

## Test Example

### Before (Component System)
```rust
// Need component machinery
let deps = AddColumn::collect_dependencies();
for file in deps {
    let sql = std::fs::read_to_string(file)?;
    db.batch_execute(&sql).await?;
}

let result = db.query_one("SELECT eql_v2.add_column(...)").await?;
db.assert_jsonb_has_key(&result, 0, "tables")?;
```

### After (SQLx)
```rust
// Just load built SQL
let pool = setup_test_db().await?;  // Loads release/cipherstash-encrypt.sql

// Type-safe queries
let result = sqlx::query_scalar::<_, serde_json::Value>(
    "SELECT eql_v2.add_column($1, $2, $3)"
)
.bind("users")
.bind("email")
.bind("text")
.fetch_one(&pool)
.await?;

assert!(result.get("tables").is_some());
```

## Benefits

1. **Simpler** - No 200-line type system
2. **DRY** - Dependencies defined once (in SQL)
3. **Better ergonomics** - SQLx type inference, error messages
4. **Existing build works** - No changes to deployment
5. **Test isolation** - Each test gets fresh database

## Trade-offs

### What We Lose
- ❌ Rust type system for dependency graph
- ❌ rustdoc generation

### What We Keep
- ✅ Working dependency resolution (bash + tsort)
- ✅ Tests in Rust (better than psql scripts)
- ✅ Single source of truth (SQL)

### What We Gain
- ✅ Simpler codebase (delete complex machinery)
- ✅ Better test ergonomics (SQLx)
- ✅ Can generate docs from SQL comments directly

## Implementation

See `rust-tests/` directory for working prototype:
- `src/lib.rs` - Test setup helpers
- `tests/add_column_test.rs` - Example tests using SQLx
- `run-tests.sh` - Simple test runner

## Decision

The Rust component system solves a problem we don't have:
- We already have dependency resolution (bash + tsort)
- We don't get compile-time safety anyway (SQL not validated)
- Documentation needs transformation regardless

**Recommendation:** Use SQLx for testing, keep bash for builds, delete component system.
