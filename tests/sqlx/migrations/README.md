# SQLx Migrations

These migrations install EQL and test helpers into the test database using a **hybrid approach**.

## Hybrid Migration Approach

**Migration 001 is generated**, not static:
- Built from `src/` using `mise run build`
- Automatically copied to `migrations/001_install_eql.sql` by `mise run test:sqlx`
- In `.gitignore` - never commit this file
- Ensures tests always use current EQL version

**Migrations 002-004 are static fixtures**:
- 002: Test helpers (`test_helpers.sql`)
- 003: ORE test data (`ore.sql`)
- 004: STE Vec test data (`ste_vec.sql`)

## How SQLx Uses These Migrations

When using `#[sqlx::test]`:
- Each test gets a fresh database
- All migrations (001-004) run automatically before each test
- Migration 001 contains the latest built EQL
- No need to manually reset database between tests

## When to Manually Regenerate

**You usually don't need to regenerate** - the `test:sqlx` task handles it automatically.

Only regenerate manually if debugging migration issues:
```bash
mise run build
cp release/cipherstash-encrypt.sql tests/sqlx/migrations/001_install_eql.sql
```

## Adding New Test Fixtures

To add new test data or helpers:
1. Create a new migration: `tests/sqlx/migrations/005_my_fixture.sql`
2. Add your SQL fixtures
3. Commit it (static migrations are version-controlled)
4. SQLx will apply it automatically in test runs
