# pgrx Investigation - Executive Summary

**Date:** 2025-10-22
**Status:** Investigation Complete
**Decision:** Do not use pgrx. Continue with custom Rust tooling.

---

## The Question

Can we use pgrx (Rust framework for PostgreSQL extensions) to improve EQL's development experience, given that **EQL must remain a SQL file installer** (not a compiled extension)?

---

## The Answer

**No. pgrx is fundamentally incompatible with SQL-only deployment.**

### Why pgrx Doesn't Work

| What pgrx Does | What EQL Needs |
|----------------|----------------|
| Generates compiled `.so` libraries + SQL | Pure SQL files only |
| Rust is the implementation | SQL is the implementation |
| `CREATE EXTENSION` installation | `psql < install.sql` installation |
| Requires binary deployment | Must work in Supabase (no binaries allowed) |

**Core incompatibility:** pgrx's generated SQL files call functions in compiled Rust code. They cannot run standalone.

### Can We Use Parts of pgrx?

We investigated extracting individual components:

- ❌ **Testing framework** - Requires compiled extension
- ❌ **Schema generation** - Generates SQL that references `.so` files
- ❌ **Build tooling** - Designed for binary output
- ❌ **All other components** - Tightly coupled to extension model

**Verdict:** No meaningful parts can be extracted.

---

## What We Already Have (Better!)

The `feature/rust-sql-tooling` spike provides a **custom framework purpose-built for SQL-first extensions**.

### What It Achieves

✅ **Type-safe dependencies** - Compile-time validation via Rust's type system
✅ **SQL-only output** - Generates pure `.sql` files
✅ **Transaction-isolated testing** - `TestDb` with automatic rollback
✅ **Automatic dependency resolution** - No more brittle `-- REQUIRE:` comments
✅ **Rustdoc-compatible** - Can document EQL API in standard Rust docs
✅ **Supabase compatible** - No compiled binaries required

### Architecture Comparison

```
┌──────────────────────────────────────────────────┐
│ pgrx: Rust → .so + SQL → CREATE EXTENSION        │
│                                                  │
│ EQL:  SQL → Rust tooling → .sql → psql install  │
└──────────────────────────────────────────────────┘
```

**Our spike is architecturally aligned. pgrx solves a different problem.**

---

## What Needs Work

The spike is solid but has gaps compared to a mature framework:

| Gap | Impact | Priority |
|-----|--------|----------|
| **Multi-version PostgreSQL testing** | High - testing pg14-17 is manual | 🔴 High |
| **Documentation extraction** | Medium - SQL functions not in rustdoc | 🟡 Medium |
| **Test discovery** | Medium - manual test registration | 🟡 Medium |
| **Dependency visualization** | Low - hard to see dep graph | 🟢 Low |
| **Release automation** | Low - versioning is manual | 🟢 Low |

---

## Recommendations

### 1. ✅ Commit to Custom Rust Tooling

Continue developing `feature/rust-sql-tooling` as EQL's build/test infrastructure.

**Why:**
- Already solves core problems
- pgrx offers no viable alternative
- Investment validates the approach

### 2. 🔴 Priority: Multi-Version PostgreSQL Testing

Add ergonomic testing across PostgreSQL 14-17, inspired by pgrx's approach:

```rust
// From: test_all_versions!(test_name, |db| async move { ... })
// To: Automatically runs against all PostgreSQL versions

#[eql_test(all_versions)]
async fn test_add_column_works() {
    // Runs against pg14, pg15, pg16, pg17
}
```

**Benefit:** Match pgrx's developer experience without the architectural mismatch.

### 3. 🟡 Next: Expand Component Coverage

Map all EQL SQL files to Rust `Component` implementations:
- [ ] `src/blake3/*.sql`
- [ ] `src/encrypted/*.sql`
- [ ] `src/operators/*.sql`
- [ ] `src/ore*/*.sql`
- [ ] `src/config/*.sql` (partially done)

**Goal:** Replace current `mise` + `tsort` build system entirely.

### 4. 🟡 Then: Documentation Extraction

Extract SQL function signatures/docs for rustdoc generation:

```rust
impl Component for AddColumn {
    fn documentation() -> Option<SqlDocs> {
        Some(SqlDocs {
            summary: "Add encrypted column configuration",
            functions: vec![/* ... */],
        })
    }
}
```

**Benefit:** Auto-generated reference docs that stay in sync with code.

---

## Migration Path

### Phase 1: Validate (✅ Complete)
- Spike proves approach works
- Config subsystem as proof-of-concept
- Tests demonstrate transaction isolation

### Phase 2: Expand (Next)
- Map all SQL files to Components
- Add multi-version test support
- Build full `cipherstash-encrypt.sql`

### Phase 3: Replace (Future)
- Migrate CI to `cargo test`
- Update `mise` tasks to call Rust tooling
- Deprecate `tsort` dependency system

### Phase 4: Enhance (Future)
- Documentation generation
- Dependency visualization
- Release automation

---

## What We Learned from pgrx

While we can't use pgrx's code, we stole good ideas:

### Multi-Version Testing Patterns
```rust
// pgrx: cargo pgrx test pg14 pg15 pg16 pg17
// EQL:  Rust macro that runs test across Docker containers
```

### Schema Introspection
```rust
// Extract SQL function metadata for documentation
trait Component {
    fn public_functions() -> Vec<FunctionSignature>;
}
```

### Dependency Automation
```rust
// Automatic topological sorting via type system
AddColumn::collect_dependencies() // Returns ordered list
```

---

## Key Metrics for Success

**Developer Experience:**
- [ ] Test execution < 5 min for all PostgreSQL versions
- [ ] Compile-time dependency validation
- [ ] Zero manual `-- REQUIRE:` maintenance

**Build Quality:**
- [ ] 100% test coverage
- [ ] CI validates pg14-17
- [ ] No Supabase regressions

**Maintainability:**
- [ ] Dependency graph visible via types
- [ ] Documentation stays in sync
- [ ] Breaking changes caught at compile time

---

## Conclusion

### The Decision

**Do not use pgrx.** It's a excellent framework for Rust-based PostgreSQL extensions, but EQL is a SQL-based extension with Rust tooling.

**Continue with `feature/rust-sql-tooling`.** It already provides superior solutions for EQL's specific constraints.

### Why This Is The Right Call

1. **pgrx fundamentally requires compiled extensions** - EQL cannot ship binaries
2. **Custom spike is purpose-built for SQL-first** - Architecturally aligned
3. **Already provides core value** - Type-safe deps, testing, build automation
4. **Clear path forward** - Enhance multi-version testing, expand coverage

### Next Steps

1. 🔴 **Implement multi-version PostgreSQL testing** (high priority)
2. 🟡 **Map remaining SQL files to Components** (expand coverage)
3. 🟡 **Add documentation extraction** (improve DX)
4. 🟢 **Enhance with viz tools** (nice to have)

### Questions?

See full investigation report: `docs/plans/2025-10-22-pgrx-investigation-report.md`

---

**Report Author:** Claude (claude-sonnet-4-5)
**Full Report:** `2025-10-22-pgrx-investigation-report.md`
**Branch:** feature/rust-sql-tooling
