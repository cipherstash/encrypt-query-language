# pgrx Investigation Report

**Date:** 2025-10-22
**Investigator:** Toby Hede
**Status:** Complete - pgrx Not Feasible

## Executive Summary

**Question:** Can pgrx be used for EQL, given the constraint that EQL must remain a SQL file installer (not a compiled extension)?

**Answer:** No. pgrx is fundamentally incompatible with EQL's SQL-only deployment model.

**Recommendation:** Continue developing the custom Rust tooling framework in `feature/rust-sql-tooling`. The existing spike already provides superior solutions for EQL's specific needs.

---

## Investigation Context

### EQL's Current Pain Points

1. **No test framework** - Manual Docker setup, no transaction isolation
2. **Brittle dependencies** - String parsing of `-- REQUIRE:` comments, `tsort` for ordering
3. **No documentation tooling** - Cannot embed docs with source
4. **Poor dev experience** - No type safety, no compile-time validation
5. **Minimal release support** - Basic build script with limited automation

### Why pgrx Seemed Promising

pgrx is a mature Rust framework for PostgreSQL extensions offering:
- Built-in testing framework (`#[pg_test]`)
- Automatic dependency management
- Multi-version PostgreSQL support (pg14, pg15, pg16, pg17)
- SQL schema generation
- Documentation via rustdoc
- Sophisticated build tooling

### The Critical Constraint

**EQL must ship as pure SQL files**, not compiled binary extensions. This is non-negotiable for:
- Compatibility with restrictive environments (Supabase, managed PostgreSQL)
- Simple installation via SQL script execution
- No platform-specific binaries to maintain
- Transparent, auditable source code

---

## pgrx Analysis

### How pgrx Works

```
┌─────────────────────────────────────────────────────────────┐
│                         pgrx Model                          │
├─────────────────────────────────────────────────────────────┤
│  Rust Code → Compile → .so Binary + SQL Schema → Install   │
│                                                             │
│  SQL = Interface (calls into Rust)                          │
│  Rust = Implementation (compiled functions)                 │
└─────────────────────────────────────────────────────────────┘
```

**Key characteristics:**
- Generates compiled `.so` shared libraries
- SQL schemas reference functions implemented in the binary
- `cargo pgrx package` creates extension bundles
- Testing requires compiled extension to run
- All features assume Rust is the implementation language

### SQL Generation Capability

**Research finding:** pgrx does generate SQL files, but these are **not standalone**.

From documentation:
> "The generated SQL files describe the extension's SQL interface (functions, types, etc.) but cannot function independently—they require the compiled binary component that pgrx produces from your Rust code."

Example generated SQL:
```sql
CREATE FUNCTION my_function(arg text) RETURNS text
AS 'MODULE_PATHNAME', 'my_function_wrapper'
LANGUAGE C STRICT;
```

The `MODULE_PATHNAME` references the compiled `.so` file. **The SQL cannot run without the binary.**

### Testing Framework (`#[pg_test]`)

**Research finding:** Cannot be used standalone.

- `#[pg_test]` requires a compiled extension
- Tests run "in-process inside Postgres during `cargo pgrx test`"
- The test macro depends on pgrx's extension loading mechanism
- No documented way to use testing infrastructure independently

**Workaround suggested in docs:** Use standard `#[test]` instead of `#[pg_test]` - but this loses PostgreSQL integration.

### Component Extraction Feasibility

| pgrx Component | Can Use Standalone? | Reason |
|----------------|---------------------|--------|
| Testing (`#[pg_test]`) | ❌ No | Requires compiled extension |
| Schema generation | ❌ No | Generates SQL that calls compiled code |
| Build tooling | ❌ No | Designed for `.so` output, not SQL concatenation |
| Multi-version support | ⚠️ Conceptually only | Implementation tied to extension compilation |
| Type mappings | ❌ No | For Rust↔PostgreSQL FFI, not applicable to SQL |
| SQL macros | ❌ No | For embedding SQL in Rust, not managing SQL files |
| Dependency management | ❌ No | Uses Cargo, assumes Rust modules |

**Conclusion:** No meaningful components can be extracted for SQL-only workflow.

---

## Custom Spike Analysis

### What `feature/rust-sql-tooling` Achieves

The existing spike provides a **purpose-built Rust framework for SQL-first extensions**.

#### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         EQL Model                           │
├─────────────────────────────────────────────────────────────┤
│  SQL Files → Resolve Deps → Concatenate → Install          │
│                                                             │
│  SQL = Implementation (the actual extension)                │
│  Rust = Tooling (dependency mgmt, testing, docs)            │
└─────────────────────────────────────────────────────────────┘
```

#### Crates

**`eql-core`** - Core abstractions
- `Component` trait for SQL file dependencies
- `Dependencies` trait for type-level dependency tracking
- Compile-time dependency resolution via Rust's type system

**`eql-postgres`** - PostgreSQL-specific components
- Concrete `Component` implementations for EQL SQL files
- Type-safe dependency declarations (e.g., `type Dependencies = (A, B, C)`)
- API trait (`Config`) describing EQL capabilities

**`eql-test`** - Testing infrastructure
- `TestDb` with automatic transaction isolation
- Async PostgreSQL client via tokio-postgres
- Helper assertions (e.g., `assert_jsonb_has_key`)
- Automatic rollback on test completion

**`eql-build`** - Build tooling
- SQL file concatenation in dependency order
- Removal of `-- REQUIRE:` metadata comments
- Single `.sql` file output to `release/`

#### Example: Type-Safe Dependencies

```rust
// Base component
pub struct ConfigTypes;
impl Component for ConfigTypes {
    type Dependencies = ();  // No dependencies
    fn sql_file() -> &'static str {
        "src/sql/config/types.sql"
    }
}

// Component depending on ConfigTypes
pub struct ConfigTables;
impl Component for ConfigTables {
    type Dependencies = ConfigTypes;  // Type-safe dependency
    fn sql_file() -> &'static str {
        "src/sql/config/tables.sql"
    }
}

// Component with multiple dependencies
pub struct AddColumn;
impl Component for AddColumn {
    type Dependencies = (
        ConfigPrivateFunctions,
        MigrateActivate,
        AddEncryptedConstraint,
        ConfigTypes,
    );
    fn sql_file() -> &'static str {
        "src/sql/config/add_column.sql"
    }
}
```

**Key benefit:** Dependencies are validated at compile time. Missing or circular dependencies cause compiler errors.

#### Example: Testing

```rust
#[tokio::test]
async fn test_add_column_creates_config() {
    let db = TestDb::new().await.expect("Failed to create TestDb");

    // Load dependencies automatically
    let deps = AddColumn::collect_dependencies();
    for sql_file in deps {
        let sql = std::fs::read_to_string(sql_file).unwrap();
        db.batch_execute(&sql).await.unwrap();
    }

    // Setup test data
    db.execute("CREATE TABLE users (id int, email eql_v2_encrypted)")
        .await.expect("Failed to create table");

    // Execute function under test
    let result = db.query_one(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    ).await.expect("Failed to call add_column");

    // Assert results
    db.assert_jsonb_has_key(&result, 0, "tables")
        .expect("Expected 'tables' key in config");

    // Transaction auto-rolls back on drop
}
```

**Key benefits:**
- Transaction isolation (no test pollution)
- Automatic dependency loading
- Type-safe database interactions
- Standard Rust testing tools (`cargo test`)

#### Example: Build Process

```rust
fn build_postgres() -> Result<()> {
    use eql_postgres::config::AddColumn;
    use eql_core::Component;

    let mut builder = Builder::new("CipherStash EQL for PostgreSQL");

    // Automatic dependency resolution
    let deps = AddColumn::collect_dependencies();
    println!("Resolved {} dependencies", deps.len());

    for sql_file in deps {
        builder.add_sql_file(sql_file)?;
    }

    // Write single SQL file
    let output = builder.build();
    fs::write("release/cipherstash-encrypt-postgres-poc.sql", output)?;

    Ok(())
}
```

**Output:** Single `release/cipherstash-encrypt-postgres-poc.sql` file with correct dependency ordering.

---

## Comparison Matrix

### Capabilities

| Capability | EQL Needs | Custom Spike | pgrx | Winner |
|------------|-----------|--------------|------|--------|
| **SQL-only output** | ✅ Required | ✅ Yes | ❌ Requires `.so` | **Spike** |
| **Type-safe dependencies** | ✅ Required | ✅ `Component` trait | ✅ Cargo modules | **Tie** |
| **Auto dependency resolution** | ✅ Required | ✅ `collect_dependencies()` | ✅ Cargo | **Tie** |
| **Testing framework** | ✅ Required | ✅ `TestDb` + tokio | ✅ `#[pg_test]` | **Spike** (SQL-compatible) |
| **Transaction isolation** | ✅ Nice to have | ✅ Built-in | ✅ Built-in | **Tie** |
| **Multi-version PostgreSQL** | ✅ Required | ⚠️ Manual Docker | ✅ `cargo pgrx test pg14 pg15...` | **pgrx** |
| **Documentation** | ✅ Required | ✅ Can use rustdoc | ✅ rustdoc | **Tie** |
| **Build tool** | ✅ Required | ✅ `eql-build` | ✅ `cargo pgrx package` | **Spike** (for SQL) |
| **SQL preservation** | ✅ **BLOCKER** | ✅ SQL stays SQL | ❌ Rust replaces SQL | **Spike** |

### Architecture Alignment

| Aspect | Custom Spike | pgrx |
|--------|--------------|------|
| **Philosophy** | SQL-first, Rust as tooling | Rust-first, SQL as interface |
| **Output artifact** | `.sql` file | `.so` + `.sql` bundle |
| **Installation** | `psql < install.sql` | `CREATE EXTENSION` |
| **Implementation language** | SQL | Rust |
| **Deployment complexity** | Low (single SQL file) | Medium (platform-specific binaries) |
| **Supabase compatibility** | ✅ Yes | ❌ No (no binary extensions) |

**Verdict:** Custom spike is architecturally aligned with EQL's needs. pgrx solves a different problem.

---

## What We Learned from pgrx (Conceptual Inspiration)

While pgrx's code is incompatible, we can steal ideas:

### 1. Multi-Version Testing Ergonomics

**pgrx approach:** `cargo pgrx test pg14 pg15 pg16 pg17`

**Adaptation for EQL:**
```rust
// eql-test/src/lib.rs
pub enum PostgresVersion {
    Pg14, Pg15, Pg16, Pg17
}

impl TestDb {
    pub async fn new_with_version(version: PostgresVersion) -> Result<Self> {
        let port = match version {
            PostgresVersion::Pg14 => 7414,
            PostgresVersion::Pg15 => 7415,
            PostgresVersion::Pg16 => 7416,
            PostgresVersion::Pg17 => 7417,
        };
        // Connect to Docker container for that version
    }
}

// Test macro could expand to run across all versions
#[eql_test(all_versions)]
async fn test_add_column_works() {
    // Automatically runs against pg14, pg15, pg16, pg17
}
```

### 2. Schema Introspection

**pgrx approach:** Extract function signatures from Rust code for SQL generation

**Adaptation for EQL:**
```rust
trait Component {
    // ... existing methods ...

    /// Extract documentation from SQL file
    fn documentation() -> Option<&'static str> {
        None
    }

    /// List public API functions this component provides
    fn public_functions() -> Vec<FunctionSignature> {
        vec![]
    }
}

// Could generate reference docs from this metadata
```

### 3. Dependency Visualization

**Possible addition:**
```bash
$ cargo run --bin eql-deps -- --graph AddColumn
digraph {
  AddColumn -> ConfigPrivateFunctions
  AddColumn -> MigrateActivate
  AddColumn -> AddEncryptedConstraint
  ConfigPrivateFunctions -> ConfigTypes
  MigrateActivate -> ConfigIndexes
  ConfigIndexes -> ConfigTables
  ConfigTables -> ConfigTypes
}
```

---

## Identified Gaps in Custom Spike

| Gap | Current State | Impact | Priority |
|-----|---------------|--------|----------|
| **Multi-version PostgreSQL** | Manual Docker in `tests/docker-compose.yml` | High - testing across versions is tedious | High |
| **Test discovery** | Manual `#[tokio::test]` per file | Medium - no auto-discovery of SQL test files | Medium |
| **Documentation extraction** | Rustdoc for Rust types only | Medium - SQL functions not documented | Medium |
| **Release automation** | Basic `eql-build` | Low - versioning/changelog manual | Low |
| **Dependency visualization** | Implicit in type graph | Low - hard to understand dependency tree | Low |
| **Partial component loading** | All-or-nothing via `collect_dependencies()` | Low - can't test subsets easily | Low |

---

## Alternative Tools Considered

Since pgrx doesn't fit, these tools could address specific gaps:

### pgTAP
**What:** PostgreSQL testing framework with TAP protocol
**How it could help:** SQL-native test assertions callable from Rust
**Integration idea:**
```rust
#[tokio::test]
async fn test_with_pgtap() {
    let db = TestDb::new().await?;
    db.batch_execute(include_str!("pgtap.sql")).await?;

    db.execute("SELECT plan(3);").await?;
    db.execute("SELECT has_function('eql_v2', 'add_column');").await?;
    db.execute("SELECT function_returns('eql_v2', 'add_column', 'jsonb');").await?;
    db.execute("SELECT finish();").await?;
}
```

### sqitch
**What:** Database change management with dependency tracking
**How it could help:** Inspiration for migration/versioning metadata
**Not recommended:** Adds complexity for minimal benefit given existing `Component` approach

### dbmate
**What:** Simple schema migration tool
**How it could help:** SQL file ordering patterns
**Not recommended:** Less powerful than custom `Component` system

### pgx_scripts (Supabase dbdev)
**What:** Supabase's extension packaging for SQL-only extensions
**How it could help:** Learn from their SQL packaging approach
**Worth exploring:** Could inform release/distribution strategy

---

## Recommendations

### 1. ✅ Commit to Custom Rust Tooling

**Decision:** Continue developing `feature/rust-sql-tooling` as the foundation for EQL development.

**Rationale:**
- Already solves core problems (type-safe deps, testing, build)
- Architecturally aligned with SQL-first approach
- pgrx offers no viable path forward
- Investment already made in spike validates approach

### 2. Address High-Priority Gaps

**Immediate improvements:**

#### Multi-Version PostgreSQL Testing

Create `eql-test/src/postgres_version.rs`:
```rust
pub enum PostgresVersion {
    Pg14, Pg15, Pg16, Pg17
}

impl PostgresVersion {
    pub fn all() -> Vec<Self> {
        vec![Self::Pg14, Self::Pg15, Self::Pg16, Self::Pg17]
    }

    pub fn container_name(&self) -> &'static str {
        match self {
            Self::Pg14 => "postgres-14",
            Self::Pg15 => "postgres-15",
            Self::Pg16 => "postgres-16",
            Self::Pg17 => "postgres-17",
        }
    }

    pub async fn ensure_running(&self) -> Result<()> {
        // Docker container management
    }
}
```

Add `eql-test/src/macros.rs`:
```rust
#[macro_export]
macro_rules! test_all_versions {
    ($name:ident, $body:expr) => {
        #[tokio::test]
        async fn $name() {
            for version in PostgresVersion::all() {
                version.ensure_running().await.unwrap();
                let db = TestDb::new_with_version(version).await.unwrap();
                $body(db).await;
            }
        }
    };
}
```

Usage:
```rust
test_all_versions!(test_add_column, |db| async move {
    // Test runs against all PostgreSQL versions
});
```

#### Documentation Extraction

Add to `Component` trait:
```rust
/// SQL documentation metadata
pub struct SqlDocs {
    pub summary: &'static str,
    pub functions: Vec<FunctionDoc>,
}

pub struct FunctionDoc {
    pub name: &'static str,
    pub signature: &'static str,
    pub description: &'static str,
    pub examples: Vec<&'static str>,
}

trait Component {
    // ... existing methods ...

    fn documentation() -> Option<SqlDocs> {
        None
    }
}
```

Generate docs with `cargo doc`:
```rust
impl Component for AddColumn {
    fn documentation() -> Option<SqlDocs> {
        Some(SqlDocs {
            summary: "Add encrypted column configuration",
            functions: vec![FunctionDoc {
                name: "add_column",
                signature: "add_column(table_name text, column_name text, source_type text) RETURNS jsonb",
                description: "Configures an encrypted column...",
                examples: vec![
                    "SELECT eql_v2.add_column('users', 'email', 'text');"
                ],
            }],
        })
    }
}
```

### 3. Medium-Priority Enhancements

- **Test discovery:** Auto-discover `*_test.rs` files
- **Dependency visualization:** Add `eql-deps` binary with `--graph` flag
- **Error messages:** Better compile errors for circular dependencies

### 4. Do NOT Pursue

- ❌ pgrx integration (not feasible)
- ❌ Rewriting EQL in Rust (defeats purpose of SQL-first approach)
- ❌ Compiled UDFs (breaks Supabase compatibility)

---

## Migration Plan

### Phase 1: Validate Spike (Current State)

**Goal:** Prove the approach works for a subset of EQL

**Status:** ✅ Complete
- `eql-core` with `Component` trait
- `eql-postgres` with config components
- `eql-test` with transaction isolation
- `eql-build` generating SQL files
- Working tests demonstrating approach

**Evidence:** `tests/config_test.rs` validates end-to-end workflow

### Phase 2: Expand Component Coverage

**Goal:** Map all EQL SQL files to Rust components

**Tasks:**
- [ ] Create components for all `src/blake3/*.sql` files
- [ ] Create components for all `src/encrypted/*.sql` files
- [ ] Create components for all `src/operators/*.sql` files
- [ ] Create components for all `src/ore*/*.sql` files
- [ ] Create components for all `src/config/*.sql` files

**Acceptance:** Can build full `cipherstash-encrypt.sql` via `eql-build`

### Phase 3: Replace Build System

**Goal:** Replace `mise` + `tsort` with `cargo`

**Tasks:**
- [ ] Add multi-version test support
- [ ] Migrate all `*_test.sql` files to Rust tests
- [ ] Update CI to use `cargo test` instead of `mise run test`
- [ ] Update `mise run build` to call `cargo run --bin eql-build`

**Acceptance:** CI passes using new build system

### Phase 4: Enhance Developer Experience

**Goal:** Make Rust tooling better than old system

**Tasks:**
- [ ] Add dependency visualization
- [ ] Extract SQL documentation for rustdoc
- [ ] Add release automation
- [ ] Create developer documentation

**Acceptance:** Team prefers new workflow over old

---

## Success Metrics

### Developer Experience
- [ ] Test execution time < 5 minutes for all PostgreSQL versions
- [ ] Compile-time dependency validation prevents build errors
- [ ] Zero manual `-- REQUIRE:` comment maintenance
- [ ] Rustdoc generates comprehensive API reference

### Build Quality
- [ ] 100% test coverage (all SQL files have Rust tests)
- [ ] CI validates against PostgreSQL 14, 15, 16, 17
- [ ] Generated SQL identical to current `release/cipherstash-encrypt.sql`
- [ ] No regressions in Supabase compatibility

### Long-Term Maintainability
- [ ] New contributors can understand dependency graph via types
- [ ] Adding new SQL file requires single `Component` impl
- [ ] Breaking changes caught at compile time
- [ ] Documentation stays in sync with code

---

## Conclusion

**pgrx is not suitable for EQL** due to fundamental architectural incompatibility. pgrx assumes Rust is the implementation language with SQL as an interface layer. EQL requires SQL as the implementation with Rust providing development tooling.

**The custom spike in `feature/rust-sql-tooling` is the correct path forward.** It already provides:
- ✅ Type-safe SQL dependency management
- ✅ Transaction-isolated testing
- ✅ SQL-only build output
- ✅ Foundation for documentation generation
- ✅ Better developer experience than current `tsort` approach

**Next steps:**
1. Enhance multi-version PostgreSQL testing
2. Expand component coverage to all EQL SQL files
3. Migrate build system from `mise` to `cargo`
4. Add documentation extraction and dependency visualization

This investigation successfully ruled out pgrx while validating the custom approach. The spike should be developed into EQL's production build/test infrastructure.

---

## Appendix: Key Learnings

### What pgrx Does Well
- Multi-version PostgreSQL testing ergonomics
- Automatic SQL schema generation from code
- In-process testing with transaction isolation
- Mature tooling ecosystem

### Why pgrx Doesn't Fit EQL
- Requires compiled binary extensions
- SQL is interface, not implementation
- Cannot generate standalone SQL files
- Testing framework depends on compiled code
- Incompatible with Supabase/restricted environments

### What Makes Custom Spike Superior
- Purpose-built for SQL-first extensions
- Type-safe dependencies at compile time
- Pure SQL output (no binaries)
- Supabase compatible
- Simpler mental model for SQL developers

### Inspiration from pgrx
- Multi-version testing patterns
- Schema introspection concepts
- Documentation generation ideas
- Dependency resolution approaches

---

**Report Author:** Claude (claude-sonnet-4-5)
**Date:** 2025-10-22
**Branch:** feature/rust-sql-tooling
