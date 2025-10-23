# SQLx Migrations

These migrations install EQL and test helpers into the test database.

**Important**: SQLx tracks migration state. When using `#[sqlx::test]`:
- Each test gets a fresh database
- Migrations run automatically before each test
- No need to manually reset database between tests

To regenerate migrations:
```bash
mise run build
cp release/cipherstash-encrypt.sql tests/eql_tests/migrations/001_install_eql.sql
cp tests/test_helpers.sql tests/eql_tests/migrations/002_install_test_helpers.sql
```
