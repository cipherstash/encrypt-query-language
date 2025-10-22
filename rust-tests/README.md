# EQL SQLx Testing Demo

This demonstrates a simpler approach to testing EQL using SQLx instead of the complex Rust component system.

## Approach

1. **Build SQL first** - Use existing bash build system to generate `release/cipherstash-encrypt.sql`
2. **Load in tests** - Each test loads the built SQL file into a fresh PostgreSQL database
3. **Test with SQLx** - Write Rust tests using SQLx's ergonomic API

## Key Benefits

- ✅ **Simple** - No complex type system, no component traits, no macros
- ✅ **Single source of truth** - Dependencies stay in SQL with `-- REQUIRE:` comments
- ✅ **Existing build works** - Bash script with tsort already resolves dependencies
- ✅ **Better test ergonomics** - SQLx provides type-safe queries and better error messages
- ✅ **Easy isolation** - Each test gets a fresh database

## Comparison

### Old Approach (Component System)
```rust
// 200+ lines of trait/macro machinery to get this:
let deps = AddColumn::collect_dependencies();
for file in deps {
    db.load(file).await;
}
```

### New Approach (SQLx + Bash Build)
```rust
// Just load the built release file:
let pool = setup_test_db().await;  // Loads release/cipherstash-encrypt.sql
```

## Setup

1. **Start PostgreSQL** (if not already running):
   ```bash
   mise run postgres:up
   ```

2. **Build the SQL extension**:
   ```bash
   mise run build
   ```
   This creates `release/cipherstash-encrypt.sql` with all dependencies resolved.

3. **Run tests**:
   ```bash
   cd rust-tests
   cargo test
   ```

## How It Works

### Build Time (Bash)
```bash
# tasks/build.sh already does this:
# 1. Parse -- REQUIRE: from SQL files
# 2. Build dependency graph
# 3. Topological sort with tsort
# 4. Concatenate in order -> release/cipherstash-encrypt.sql
```

### Test Time (Rust + SQLx)
```rust
// Load the pre-built SQL
let pool = setup_test_db().await;

// Test specific functionality
let result = sqlx::query_scalar("SELECT eql_v2.add_column(...)")
    .fetch_one(&pool)
    .await?;

assert!(result.get("tables").is_some());
```

## What This Demonstrates

1. **No need for Rust dependency resolution** - Bash + tsort already works
2. **Tests focus on functionality** - Not on component plumbing
3. **Simpler codebase** - Delete 200+ lines of trait/macro code
4. **Better DX** - SQLx error messages, type inference, connection pooling

## Next Steps

If this approach works:
- Keep SQL files with `-- REQUIRE:` comments
- Keep bash build system (`tasks/build.sh`)
- Delete the Rust component system
- Write more tests using this SQLx pattern
- Generate docs from SQL comments (not rustdoc)
