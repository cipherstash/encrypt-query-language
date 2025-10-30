# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

This project uses `mise` for task management. Common commands:

- `mise run build` (alias: `mise r b`) - Build SQL into single release file
- `mise run test` (alias: `mise r test`) - Build, reset and run tests
- `mise run postgres:up` - Start PostgreSQL container
- `mise run postgres:down` - Stop PostgreSQL containers
- `mise run reset` - Reset database state
- `mise run clean` (alias: `mise r k`) - Clean release files

### Documentation
- `mise run docs:generate` - Generate API documentation (requires doxygen)
  - Outputs XML (primary) and HTML (preview) formats
  - XML suitable for downstream processing/website integration
  - See `docs/api/README.md` for XML format details
- `mise run docs:markdown` - Convert XML to Markdown API reference
  - Generates single-file API reference: `docs/api/markdown/API.md`
  - Includes 84 documented functions with parameters, return values, and source links
- `mise run docs:validate` - Validate documentation coverage and tags
- `mise run docs:package` - Package XML docs for distribution (~230KB archive)

### Testing
- Run all tests: `mise run test`
- Run specific test: `mise run test --test <test_name>`
- Run tests against specific PostgreSQL version: `mise run test --postgres 14|15|16|17`
- Tests are located in `*_test.sql` files alongside source code

### Build System
- Dependencies are resolved using `-- REQUIRE:` comments in SQL files
- Build outputs to `release/` directory:
  - `cipherstash-encrypt.sql` - Main installer
  - `cipherstash-encrypt-supabase.sql` - Supabase-compatible installer
  - `cipherstash-encrypt-uninstall.sql` - Uninstaller

## Project Architecture

This is the **Encrypt Query Language (EQL)** - a PostgreSQL extension for searchable encryption. Key architectural components:

### Core Structure
- **Schema**: All EQL functions/types are in `eql_v2` PostgreSQL schema
- **Main Type**: `eql_v2_encrypted` - composite type for encrypted columns (stored as JSONB)
- **Configuration**: `eql_v2_configuration` table tracks encryption configs
- **Index Types**: Various encrypted index types (blake3, hmac_256, bloom_filter, ore variants)

### Directory Structure
- `src/` - Modular SQL components with dependency management
- `src/encrypted/` - Core encrypted column type implementation
- `src/operators/` - SQL operators for encrypted data comparisons
- `src/config/` - Configuration management functions
- `src/blake3/`, `src/hmac_256/`, `src/bloom_filter/`, `src/ore_*` - Index implementations
- `tasks/` - mise task scripts
- `tests/` - Test files (PostgreSQL 14-17 support)
- `release/` - Generated SQL installation files

### Key Concepts
- **Dependency System**: SQL files declare dependencies via `-- REQUIRE:` comments
- **Encrypted Data**: Stored as JSONB payloads with metadata
- **Index Terms**: Transient types for search operations (blake3, hmac_256, etc.)
- **Operators**: Support comparisons between encrypted and plain JSONB data
- **CipherStash Proxy**: Required for encryption/decryption operations

### Testing Infrastructure
- Tests run against PostgreSQL 14, 15, 16, 17 using Docker containers
- Container configuration in `tests/docker-compose.yml`
- Test helpers in `tests/test_helpers.sql`
- Database connection: `localhost:7432` (cipherstash/password)
- **Rust/SQLx Tests**: Modern test framework in `tests/sqlx/` (see README there)

## Project Learning & Retrospectives

Valuable lessons and insights from completed work:

- **SQLx Test Migration (2025-10-24)**: See `docs/retrospectives/2025-10-24-sqlx-migration-retrospective.md`
  - Migrated 40 SQL assertions to Rust/SQLx (100% coverage)
  - Key insights: Blake3 vs HMAC differences, batch-review pattern effectiveness, coverage metric definitions
  - Lessons: TDD catches setup issues, infrastructure investment pays off, code review after each batch prevents compound errors

## Documentation Standards

### Doxygen Comments

All SQL functions and types must be documented using Doxygen-style comments:

- **Comment Style**: Use `--!` prefix for Doxygen comments (not `--`)
- **Required Tags**:
  - `@brief` - Short description (required for all functions/files)
  - `@param` - Parameter description (required for functions with parameters)
  - `@return` - Return value description (required for functions with non-void returns)
- **Optional Tags**:
  - `@throws` - Exception conditions
  - `@note` - Important notes or caveats
  - `@warning` - Warning messages (e.g., for DDL-executing functions)
  - `@see` - Cross-references to related functions
  - `@example` - Usage examples
  - `@internal` - Mark internal/private functions
  - `@file` - File-level documentation

### Documentation Example

```sql
--! @brief Create encrypted index configuration
--!
--! Initializes a new encrypted index configuration for a table column.
--! The configuration tracks encryption settings and index types.
--!
--! @param p_table_name text Table name (schema-qualified)
--! @param p_column_name text Column name to encrypt
--! @param p_index_type text Type of encrypted index (blake3, hmac_256, etc.)
--!
--! @return uuid Configuration ID for the created index
--!
--! @throws unique_violation If configuration already exists for this column
--!
--! @note This function executes DDL and modifies database schema
--! @see eql_v2.activate_encrypted_index
--!
--! @example
--! -- Create blake3 index configuration
--! SELECT eql_v2.create_encrypted_index(
--!   'public.users',
--!   'email',
--!   'blake3'
--! );
CREATE FUNCTION eql_v2.create_encrypted_index(...)
```

### Validation Tools

Verify documentation quality:

```bash
# Using mise (recommended - validates coverage and tags)
mise run docs:validate

# Or run individual scripts directly
mise run docs:validate:coverage       # Check 100% coverage
mise run docs:validate:required-tags  # Verify @brief, @param, @return tags
mise run docs:validate:documented-sql # Validate SQL syntax (requires database)
```

### Template Files

Template files (e.g., `version.template`) must be documented. The Doxygen comments are automatically included in generated files during build.

### Generated Documentation Format

The documentation is generated in **XML format** as the primary output:

- **Location**: `docs/api/xml/`
- **Format**: Doxygen XML (v1.15.0) with XSD schemas
- **Usage**: Machine-readable, suitable for downstream processing
- **Publishing**: Package with `mise run docs:package` → creates `eql-docs-xml-2.x.tar.gz`
- **Integration**: See `docs/api/README.md` for XML structure and transformation examples

HTML output is also generated in `docs/api/html/` for local preview only.

## Development Notes

- SQL files are modular - put operator wrappers in `operators.sql`, implementation in `functions.sql`
- All SQL files must have `-- REQUIRE:` dependency declarations
- Test files end with `_test.sql` and live alongside source files
- Build system uses `tsort` to resolve dependency order
- Supabase build excludes operator classes (not supported)
- **Documentation**: All functions/types must have Doxygen comments (see Documentation Standards above)