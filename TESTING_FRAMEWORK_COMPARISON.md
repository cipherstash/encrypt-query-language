# Testing Framework Comparison for PostgreSQL Extensions

## Context

We're testing **EQL** - a PostgreSQL extension for searchable encryption. The question: what's the best testing framework?

Current prototype uses Rust + SQLx. But is Rust the right tool for testing SQL?

## What Rust/SQLx Actually Provides

### Supposed Benefits
- ✅ Type safety - But SQL is still strings, JSON responses are dynamic
- ✅ Memory safety - Tests don't have memory issues anyway
- ✅ Performance - Tests are I/O bound (database calls), not CPU bound
- ✅ Async/await - Doesn't matter for sequential test execution
- ❌ Compile times - Slow feedback loop (30s+ for simple test changes)

### Actual Benefits
- Connection pooling (nice but not critical for tests)
- Familiar if you're already writing Rust (marginal)
- Good IDE support (LSP, autocomplete)

### Downsides
- Slow compile times kill feedback loop
- Type system doesn't help much (SQL is dynamic)
- Overkill for testing database functions
- Small ecosystem for PostgreSQL testing

## Alternative Testing Frameworks

### Option 1: pgTAP (PostgreSQL-Native Testing)

**What is it:** PostgreSQL extension for writing tests in SQL, inspired by Perl's TAP protocol.

**Example:**
```sql
-- tests/add_column_test.sql
BEGIN;
SELECT plan(5);

-- Load extension
\i release/cipherstash-encrypt.sql

-- Setup
CREATE TABLE users (id int, email eql_v2_encrypted);

-- Test: add_column succeeds
SELECT lives_ok(
    'SELECT eql_v2.add_column(''users'', ''email'', ''text'')',
    'add_column should succeed'
);

-- Test: Configuration has expected structure
SELECT results_eq(
    'SELECT (data->>''tables'') IS NOT NULL FROM eql_v2_configuration WHERE state = ''active''',
    ARRAY[true],
    'Config should have tables key'
);

SELECT results_eq(
    'SELECT (data->>''v'') IS NOT NULL FROM eql_v2_configuration WHERE state = ''active''',
    ARRAY[true],
    'Config should have version key'
);

-- Test: Constraint was added
SELECT has_constraint(
    'users',
    'eql_v2_encrypted_check_email',
    'Should have encrypted constraint on email column'
);

-- Test: Duplicate fails
SELECT throws_ok(
    'SELECT eql_v2.add_column(''users'', ''email'', ''text'')',
    'Column already configured',
    'Duplicate add_column should fail'
);

SELECT * FROM finish();
ROLLBACK;
```

**Running tests:**
```bash
# Install pgTAP
psql -c "CREATE EXTENSION pgtap;"

# Run all tests
pg_prove -d testdb tests/*.sql

# Run with verbose output
pg_prove -v -d testdb tests/add_column_test.sql
```

**Pros:**
- ✅ SQL-native - No language impedance mismatch
- ✅ Tests run IN the database - Can test internal state
- ✅ Designed for PostgreSQL extensions - Used by pg core
- ✅ Fast feedback - No compilation
- ✅ TAP output - CI-friendly
- ✅ Rich assertion library - `has_table`, `has_constraint`, `results_eq`, etc.
- ✅ Automatic rollback - Clean test isolation

**Cons:**
- ❌ Less flexible than general-purpose languages
- ❌ Limited for complex test orchestration
- ❌ Less familiar to non-SQL developers

**Best for:**
- Testing PostgreSQL functions, triggers, constraints
- Validating database schema changes
- Extension development (exactly our use case)

---

### Option 2: Python + pytest

**What is it:** Python's premier testing framework with excellent PostgreSQL support.

**Example:**
```python
# tests/test_add_column.py
import pytest
import psycopg

@pytest.fixture(scope="session")
def eql_sql():
    """Load EQL SQL once per session"""
    with open("release/cipherstash-encrypt.sql") as f:
        return f.read()

@pytest.fixture
def db(eql_sql):
    """Fresh database with EQL loaded for each test"""
    conn = psycopg.connect(
        "host=localhost port=7432 user=cipherstash password=password dbname=postgres"
    )
    conn.autocommit = True

    # Create test database
    test_db = f"eql_test_{uuid.uuid4().hex[:8]}"
    conn.execute(f"CREATE DATABASE {test_db}")

    # Connect to test database
    test_conn = psycopg.connect(f".../{test_db}")
    test_conn.execute(eql_sql)

    yield test_conn

    # Cleanup
    test_conn.close()
    conn.execute(f"DROP DATABASE {test_db}")
    conn.close()

def test_add_column_creates_config(db):
    """Test that add_column creates configuration"""
    db.execute("CREATE TABLE users (id int, email eql_v2_encrypted)")

    result = db.execute(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    ).fetchone()[0]

    assert "tables" in result, "Config should have 'tables' key"
    assert "v" in result, "Config should have version key"

    # Verify persisted config
    config = db.execute(
        "SELECT data FROM eql_v2_configuration WHERE state = 'active'"
    ).fetchone()[0]

    assert config["tables"]["users"]["columns"]["email"] is not None

def test_add_column_rejects_duplicate(db):
    """Test that duplicate add_column fails"""
    db.execute("CREATE TABLE users (id int, email eql_v2_encrypted)")
    db.execute("SELECT eql_v2.add_column('users', 'email', 'text')")

    with pytest.raises(psycopg.Error) as exc:
        db.execute("SELECT eql_v2.add_column('users', 'email', 'text')")

    assert "already configured" in str(exc.value)

def test_multiple_encrypted_columns(db):
    """Test configuring multiple encrypted columns"""
    db.execute("""
        CREATE TABLE users (
            id int,
            email eql_v2_encrypted,
            phone eql_v2_encrypted,
            ssn eql_v2_encrypted
        )
    """)

    columns = ["email", "phone", "ssn"]
    for col in columns:
        db.execute(f"SELECT eql_v2.add_column('users', '{col}', 'text')")

    # Verify all constraints exist
    constraints = db.execute("""
        SELECT conname
        FROM pg_constraint
        WHERE conname LIKE 'eql_v2_encrypted_check_%'
    """).fetchall()

    constraint_names = [row[0] for row in constraints]
    for col in columns:
        expected = f"eql_v2_encrypted_check_{col}"
        assert expected in constraint_names, f"Missing constraint for {col}"
```

**Running tests:**
```bash
# Install dependencies
pip install pytest psycopg[binary]

# Run all tests
pytest tests/

# Run with verbose output
pytest -v tests/test_add_column.py

# Run specific test
pytest tests/test_add_column.py::test_add_column_creates_config

# Run with coverage
pytest --cov=. tests/
```

**Pros:**
- ✅ Excellent fixture system - Setup/teardown is elegant
- ✅ Fast feedback - No compilation step
- ✅ Huge ecosystem - pytest plugins for everything
- ✅ Great for data validation - Python is good at JSON/dict manipulation
- ✅ Familiar to most developers - Low learning curve
- ✅ Parametrized tests - Easy to test multiple scenarios
- ✅ Rich assertions - Many assertion helpers available

**Cons:**
- ❌ Not SQL-native - Extra layer of abstraction
- ❌ Runtime errors - No compile-time type checking
- ❌ Dependency management - pip/venv overhead

**Best for:**
- Complex test orchestration
- Data validation and transformation
- Integration testing across multiple systems
- Teams familiar with Python

---

### Option 3: TypeScript + Deno/Bun

**What is it:** Modern JavaScript runtime with built-in testing and PostgreSQL support.

**Example:**
```typescript
// tests/add_column.test.ts
import { assertEquals, assertRejects } from "@std/assert";
import postgres from "postgres";

// Setup database connection
const sql = postgres("postgres://cipherstash:password@localhost:7432/postgres");

// Load EQL once
let eqlLoaded = false;
async function setupEQL() {
    if (!eqlLoaded) {
        const eql = await Deno.readTextFile("../release/cipherstash-encrypt.sql");
        await sql.unsafe(eql);
        eqlLoaded = true;
    }
}

Deno.test("add_column creates configuration", async () => {
    await setupEQL();

    await sql`CREATE TABLE users (id int, email eql_v2_encrypted)`;

    const [result] = await sql`
        SELECT eql_v2.add_column('users', 'email', 'text') as config
    `;

    assertEquals(typeof result.config.tables, "object", "Config should have tables");
    assertEquals(typeof result.config.v, "string", "Config should have version");

    // Verify persisted config
    const [config] = await sql`
        SELECT data FROM eql_v2_configuration WHERE state = 'active'
    `;

    assertEquals(config.data.tables.users.columns.email !== undefined, true);

    // Cleanup
    await sql`DROP TABLE users`;
});

Deno.test("add_column rejects duplicate", async () => {
    await setupEQL();

    await sql`CREATE TABLE users (id int, email eql_v2_encrypted)`;
    await sql`SELECT eql_v2.add_column('users', 'email', 'text')`;

    await assertRejects(
        async () => {
            await sql`SELECT eql_v2.add_column('users', 'email', 'text')`;
        },
        Error,
        "already configured"
    );

    // Cleanup
    await sql`DROP TABLE users`;
});

Deno.test("multiple encrypted columns", async () => {
    await setupEQL();

    await sql`
        CREATE TABLE users (
            id int,
            email eql_v2_encrypted,
            phone eql_v2_encrypted,
            ssn eql_v2_encrypted
        )
    `;

    const columns = ["email", "phone", "ssn"];
    for (const col of columns) {
        await sql`SELECT eql_v2.add_column('users', ${col}, 'text')`;
    }

    // Verify constraints
    const constraints = await sql`
        SELECT conname
        FROM pg_constraint
        WHERE conname LIKE 'eql_v2_encrypted_check_%'
    `;

    for (const col of columns) {
        const expected = `eql_v2_encrypted_check_${col}`;
        const found = constraints.some(c => c.conname === expected);
        assertEquals(found, true, `Missing constraint for ${col}`);
    }

    // Cleanup
    await sql`DROP TABLE users`;
});
```

**Running tests:**
```bash
# Using Deno (no install needed beyond deno itself)
deno test --allow-read --allow-net tests/

# Using Bun
bun test tests/

# Watch mode
deno test --watch tests/
```

**Pros:**
- ✅ Fast startup - Instant feedback (Deno/Bun)
- ✅ Good type inference - TypeScript catches errors
- ✅ Modern syntax - Async/await, template strings
- ✅ No build step - Direct execution
- ✅ Built-in test runner - No extra dependencies
- ✅ Great DX - Fast iteration

**Cons:**
- ❌ Smaller ecosystem than Python
- ❌ Not SQL-native
- ❌ TypeScript complexity for simple tests

**Best for:**
- Teams already using TypeScript
- Fast iteration cycles
- Modern development workflow

---

### Option 4: Rust + SQLx (Current Prototype)

**Example:**
```rust
use sqlx::PgPool;

#[sqlx::test]
async fn test_add_column_creates_config(pool: PgPool) {
    // Load EQL
    let eql = std::fs::read_to_string("../release/cipherstash-encrypt.sql").unwrap();
    sqlx::raw_sql(&eql).execute(&pool).await.unwrap();

    sqlx::query("CREATE TABLE users (id int, email eql_v2_encrypted)")
        .execute(&pool)
        .await
        .unwrap();

    let result = sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT eql_v2.add_column('users', 'email', 'text')"
    )
    .fetch_one(&pool)
    .await
    .unwrap();

    assert!(result.get("tables").is_some());
    assert!(result.get("v").is_some());
}
```

**Pros:**
- ✅ Type safety - Compile-time checks (limited for SQL strings)
- ✅ Memory safety - Guaranteed at compile time
- ✅ Performance - Fastest runtime (doesn't matter for tests)
- ✅ Familiar for Rust devs

**Cons:**
- ❌ Slow compile times - 30s+ for simple changes
- ❌ Complex toolchain - cargo, rustc, etc.
- ❌ Overkill for SQL testing - Type system doesn't help much
- ❌ Verbose error handling - .unwrap() everywhere
- ❌ Small testing ecosystem - Fewer tools than Python/JS

**Best for:**
- Projects already in Rust
- When compile-time guarantees matter (not really for SQL tests)

---

## Comparison Matrix

| Feature | pgTAP | Python + pytest | TypeScript + Deno | Rust + SQLx |
|---------|-------|-----------------|-------------------|-------------|
| **SQL-native** | ✅✅✅ | ❌ | ❌ | ❌ |
| **Compile time** | None | None | None | **Slow (30s+)** |
| **Type safety** | N/A | Runtime | Good | Excellent (limited benefit) |
| **Test framework** | Excellent | Excellent | Good | Basic |
| **Learning curve** | Medium | Low | Low | High |
| **Feedback loop** | **Fast** | **Fast** | **Fast** | Slow |
| **For PG extensions** | ✅✅✅ | ✅✅ | ✅ | ❌ |
| **Ecosystem** | PostgreSQL-focused | Huge (pytest plugins) | Growing | Small |
| **Fixture system** | Built-in (BEGIN/ROLLBACK) | Excellent (@pytest.fixture) | Good | Basic |
| **CI integration** | Excellent (TAP) | Excellent | Good | Good |
| **Data assertions** | SQL-based | Excellent (Python dicts) | Good (JS objects) | Verbose (JSON) |
| **Team familiarity** | Low (unless SQL-heavy) | High | Medium | Low |
| **Development speed** | Fast | Fast | Fast | Slow |

## Recommendations

### Primary Recommendation: **pgTAP**

**Rationale:**
- Designed specifically for testing PostgreSQL extensions
- Used by PostgreSQL core and major extensions (PostGIS, TimescaleDB)
- SQL-native - No impedance mismatch
- Fast feedback loop
- Can test database internals directly
- Automatic transaction rollback for isolation
- TAP output integrates with standard CI tools

**When to use:**
- Testing PostgreSQL functions, types, operators
- Validating schema migrations
- Extension development (**exactly this use case**)
- When tests are primarily SQL-focused

**Example workflow:**
```bash
# Write test
vim tests/add_column_test.sql

# Run test (instant feedback)
pg_prove -v tests/add_column_test.sql

# Run all tests in CI
pg_prove -r tests/
```

---

### Secondary Recommendation: **Python + pytest**

**Rationale:**
- Excellent when you need complex test orchestration
- Better for data validation/transformation
- Huge ecosystem (coverage, mocking, fixtures)
- Most developers know Python
- Great for integration tests across multiple systems

**When to use:**
- Need to test interactions with external systems
- Complex data validation required
- Team is Python-heavy
- Want to combine SQL tests with API/service tests

**Example workflow:**
```bash
# Write test
vim tests/test_add_column.py

# Run test with auto-reload
pytest-watch tests/

# Run all tests with coverage
pytest --cov=. tests/
```

---

### Not Recommended: **Rust + SQLx**

**Rationale:**
- Compile times kill the feedback loop (30s+ for simple changes)
- Type system provides minimal benefit (SQL is dynamic)
- Overkill for testing database functions
- Verbose error handling
- Small ecosystem for PostgreSQL testing

**Only use Rust if:**
- Already committed to Rust for other parts of the system
- Need to share test utilities with Rust application code
- Team is 100% Rust and nothing else

---

## Decision Framework

Ask yourself:

1. **What are you primarily testing?**
   - SQL functions/types → **pgTAP**
   - Complex workflows → **Python**
   - Mixed → **Python** or **TypeScript**

2. **What does your team know?**
   - SQL experts → **pgTAP**
   - General purpose → **Python**
   - JavaScript/TypeScript → **Deno/Bun**
   - Rust → Stick with **Rust** (but recognize trade-offs)

3. **What's your priority?**
   - Fast feedback → **pgTAP** or **Python**
   - Type safety → **Rust** or **TypeScript** (limited benefit)
   - Simplicity → **pgTAP**
   - Flexibility → **Python**

4. **What's your test complexity?**
   - Mostly SQL validation → **pgTAP**
   - Multi-system integration → **Python**
   - Somewhere in between → **Python** or **TypeScript**

## Conclusion

**For testing EQL (PostgreSQL extension):**

**Best choice: pgTAP**
- SQL-native testing for SQL extensions
- Fast feedback loop
- Industry standard for PostgreSQL extensions
- Can test internal database state

**Solid alternative: Python + pytest**
- When you need more flexibility
- Complex test orchestration
- Better data validation tools

**Avoid: Rust + SQLx**
- Slow compile times
- Overkill for the task
- Type system doesn't help much
- Wrong tool for the job

---

## Next Steps

To prototype pgTAP:
```bash
# Install pgTAP extension
psql -c "CREATE EXTENSION pgtap;"

# Create first test
cat > tests/add_column_test.sql << 'EOF'
BEGIN;
SELECT plan(3);
\i release/cipherstash-encrypt.sql
-- ... tests here
SELECT * FROM finish();
ROLLBACK;
EOF

# Run it
pg_prove -v tests/add_column_test.sql
```

The question isn't "which language is best" - it's "which tool fits the job." For testing SQL, use SQL.
