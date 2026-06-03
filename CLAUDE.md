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
- `mise run docs:generate:markdown` - Convert XML to Markdown API reference
  - Generates single-file API reference: `docs/api/markdown/API.md`
  - Includes 84 documented functions with parameters, return values, and source links
- `mise run docs:validate` - Validate documentation coverage and tags
- `mise run docs:package` - Package XML docs for distribution (~230KB archive)

### Testing
- Run all tests: `mise run test`
- Run SQLx tests directly: `mise run test:sqlx`
- Run SQLx tests in watch mode: `mise run test:sqlx:watch`
- Tests are located in `tests/sqlx/` using Rust and SQLx framework
- Regenerate the scalar matrix coverage snapshots: `mise run test:matrix:inventory` (no database required). These committed `tests/sqlx/snapshots/<T>_matrix_tests.txt` baselines pin the set of `scalars::<T>::*` test names so a silently dropped/renamed/`#[cfg]`-gated test fails CI's `matrix-coverage` job. When you add or remove matrix tests (or add a scalar type), regenerate and commit the affected snapshot in the same change. See `tests/sqlx/snapshots/README.md`.

### Build System
- Dependencies are resolved using `-- REQUIRE:` comments in SQL files
- Build outputs to `release/` directory:
  - `cipherstash-encrypt.sql` - Main installer
  - `cipherstash-encrypt-supabase.sql` - Supabase-compatible (excludes operator classes)
  - `cipherstash-encrypt-protect.sql` - ProtectJS variant (excludes config management)
  - Corresponding uninstallers for each variant

#### Build Variants
| Variant | Excludes | Use Case |
|---------|----------|----------|
| Main | Nothing | Full EQL with all features |
| Supabase | Operator classes | Supabase compatibility |
| Protect | `src/config/*`, `src/encryptindex/*` | ProtectJS (no database-side config) |

## Project Architecture

This is the **Encrypt Query Language (EQL)** - a PostgreSQL extension for searchable encryption. Key architectural components:

### Core Structure
- **Schema**: Core EQL functions/types are in the `eql_v2` PostgreSQL schema. The encrypted-domain type families (`int4` and future scalar domains) live in a separate `eql_v3` schema (see below); they reuse the core `eql_v2` index-term types cross-schema. `eql_v2` is unchanged and remains the documented public API.
- **Main Type**: `eql_v2_encrypted` - composite type for encrypted columns (stored as JSONB)
- **Configuration**: `eql_v2_configuration` table tracks encryption configs
- **Index Types**: Various encrypted index types (blake3, hmac_256, bloom_filter, ore variants)

### Directory Structure
- `src/` - Modular SQL components with dependency management
- `src/encrypted/` - Core encrypted column type implementation
- `src/operators/` - SQL operators for encrypted data comparisons
- `src/config/` - Configuration management functions
- `src/blake3/`, `src/hmac_256/`, `src/bloom_filter/`, `src/ore_*` - Index implementations
- `src/encrypted_domain/` - Encrypted-domain type families (jsonb-backed PostgreSQL domains, one per operator/index capability)
- `tasks/` - mise task scripts
- `tests/sqlx/` - Rust/SQLx test framework (PostgreSQL 14-17 support)
- `release/` - Generated SQL installation files

### Key Concepts
- **Dependency System**: SQL files declare dependencies via `-- REQUIRE:` comments
- **Encrypted Data**: Stored as JSONB payloads with metadata
- **Index Terms**: Transient types for search operations (blake3, hmac_256, etc.)
- **Operators**: Support comparisons between encrypted and plain JSONB data
- **CipherStash Proxy**: Required for encryption/decryption operations

### Encrypted-Domain Types

`src/encrypted_domain/` holds **encrypted-domain type families** — jsonb-backed PostgreSQL domains in the **`eql_v3` schema**, one domain per operator/index capability (`eql_v3.<T>` storage-only, `eql_v3.<T>_eq`, `eql_v3.<T>_ord`). The schema qualifier replaces the old version-prefixed name, so the domains are `eql_v3.int4`, `eql_v3.int4_eq`, `eql_v3.int4_ord`, `eql_v3.int4_ord_ore` — created in `eql_v3`, not `public`. Their extractors/wrappers/aggregates (`eql_v3.eq_term`, `eql_v3.ord_term`, `eql_v3.eq`/`lt`/…, `eql_v3.min`/`max`) also live in `eql_v3`, but the index-term types they return and construct (`eql_v2.hmac_256`, `eql_v2.ore_block_u64_8_256`) stay in `eql_v2` and are referenced cross-schema. `eql_v3.int4` (PR #239, supersedes #225) is the reference scalar implementation; future scalar types such as `int8`, `bool`, `date`, `float`, `numeric`, `timestamp`, `text`, and `jsonb` follow this materializer pattern. `text`, `numeric`, and `jsonb` are planned but have no generated SQL surface yet — `jsonb` in particular needs a separate SQL design beyond the ordered-scalar materializer. The `eql-scalars` fixture catalog (`crates/eql-scalars`) already models their fixture values ahead of the SQL surface.

Adding a scalar encrypted-domain type is generated from a minimal manifest at `tasks/codegen/types/<T>.toml`: the filename supplies `<T>`, and the `[domain]` table maps each generated domain name to the fixed index terms it carries. Example: `int4_eq = ["hm"]`, `int4_ord = ["ore"]`. Term capabilities are fixed in `tasks/codegen/terms.py`: `hm` provides equality, and `ore` provides equality plus ordering. `mise run build` regenerates the scalar SQL surface into `src/encrypted_domain/<T>/` from every manifest at the start of every build; that surface includes supported comparison wrappers plus blockers for native `jsonb` operators that would otherwise be reachable through domain fallback. Use `mise run codegen:domain <T>` to refresh a single type manually while iterating on its manifest, or `mise run codegen:domain:all` to regenerate every type at once (the same enumeration `mise run build` uses). The generated `*_types.sql` / `*_functions.sql` / `*_operators.sql` files are gitignored and never committed — the TOML manifest plus `tasks/codegen/terms.py` are the source of truth. Generated files carry an `AUTOMATICALLY GENERATED FILE — DO NOT EDIT` header (the project-wide marker that `docs:validate` greps on to skip generated SQL); change the manifest or term catalog and rebuild, never hand-edit. Hand-written SQL beyond the fixed surface goes in `src/encrypted_domain/<T>/<T>_extensions.sql` with no auto-generated header and explicit `-- REQUIRE:` edges — that file IS committed. `text` and `jsonb` have no generated SQL surface yet (they are planned, not out of scope); `jsonb` needs a separate SQL design beyond this ordered-scalar materializer.

**Adding a new encrypted-domain type: follow `docs/reference/encrypted-domain-implementation-spec.md`.** The mechanics are fixed for ordered scalar domains; the manifest only declares domain names and terms. New term behavior belongs in `tasks/codegen/terms.py` with tests, not in free-form TOML fields.

Regeneration is deterministic: identical manifest + term catalog produce byte-identical SQL. If `mise run build` produces unexpected output, the change is in the manifest, `tasks/codegen/terms.py`, or `tasks/codegen/templates.py` — not in random run-to-run variation.

Footguns the spec exists to prevent:

- **Blockers must never be `STRICT`.** A `STRICT` blocker lets PostgreSQL skip the body and return `NULL` on a `NULL` argument, silently bypassing the "operator not supported" exception.
- **No domain-over-domain** (`CREATE DOMAIN a AS b`). Operators resolve against the ultimate base type (`jsonb`), so a derived domain does not inherit the base domain's operator surface — blockers stop engaging.
- **No operator class on a domain.** Index through a functional index on the extractor (`eq_term` / `ord_term`), whose return type already carries a default opclass.
- **Inlinable functions** (extractors, comparison wrappers) need `LANGUAGE sql`, a single-statement `SELECT`, `IMMUTABLE`, and **no `SET` clause** — a pinned `search_path` disables inlining. No per-type allowlist edit: the `pin_search_path.sql` structural rule recognises encrypted-domain functions intrinsically and `tasks/test/splinter.sh` covers the converged extractor/wrapper names.
- **Blockers must be `LANGUAGE plpgsql`, not `LANGUAGE sql`.** The inverse of the rule above. A blocker exists to always raise, but a `LANGUAGE sql` body is inlinable and the planner can elide the call when the result is provably unused (dead `CASE` branch, folded predicate). `LANGUAGE plpgsql` is opaque to the planner, so the call — and its `RAISE` — survives. The generator in `tasks/codegen/templates.py` enforces this; don't "simplify" the rendered blockers to `LANGUAGE sql` even though the body is a single expression.
- **Build with `mise run clean && mise run build`** — a bare build can leave stale `release/*.sql`.

### Testing Infrastructure
- Tests are written in Rust using SQLx, located in `tests/sqlx/`
- Tests run against PostgreSQL 14, 15, 16, 17 using Docker containers
- Use `mise run test --postgres 14|15|16|17` to test against a specific version
- Container configuration in `tests/docker-compose.yml`
- SQL test fixtures and helpers in `tests/test_helpers.sql`
- Database connection: `localhost:7432` (cipherstash/password)

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
- Build system uses `tsort` to resolve dependency order
- Supabase build excludes operator classes (not supported)
- **Documentation**: All functions/types must have Doxygen comments (see Documentation Standards above)

### Function Language Choice (SQL vs PL/pgSQL)

Prefer `LANGUAGE SQL` over `LANGUAGE plpgsql` unless you need procedural features.

| Aspect            | LANGUAGE SQL                      | LANGUAGE plpgsql        |
|-------------------|-----------------------------------|-------------------------|
| Inlining          | ✅ Can be inlined by planner       | ❌ Never inlined         |
| Call overhead     | Lower (can be optimized away)     | Higher (context switch) |
| Index performance | Better for GIN index expressions  | Worse                   |
| Control flow      | CASE expression                   | IF/THEN/ELSE            |

**Why SQL wins for simple functions:**

1. **Inlining** - PostgreSQL can inline simple SQL functions into the calling query, eliminating function call overhead entirely. PL/pgSQL functions are never inlined.
2. **Index context** - Functions used in index expressions (e.g., `CREATE INDEX ... USING GIN (eql_v2.jsonb_array(col))`) are called on every row insertion/update. Inlining matters.
3. **Simple logic** - A CASE expression is a single statement. PL/pgSQL's procedural features aren't needed.

**When PL/pgSQL is appropriate:**

- Multiple statements with intermediate variables
- Exception handling (`BEGIN...EXCEPTION...END`)
- Complex control flow (loops, early returns)
- Dynamic SQL (`EXECUTE`)
- Functions that must remain opaque to the planner — typically blockers whose only job is to `RAISE`. `LANGUAGE sql` would be inlined and may be elided when the result is provably unused; `LANGUAGE plpgsql` is never inlined, so the body always runs. See the encrypted-domain footgun list above and the blocker renderers in `tasks/codegen/templates.py`.

## Release & changelog discipline

EQL maintains a [Keep-a-Changelog](https://keepachangelog.com/en/1.1.0/)-style `CHANGELOG.md` and per-version upgrade guides under `docs/upgrading/`. The conventions are documented at the top of `CHANGELOG.md`; what follows is what to do when working in this repo.

### When you make a user-facing change

If your PR adds, changes, removes, deprecates, or fixes anything observable to a caller — new function, new operator, behaviour change, error message change, performance characteristic that callers might notice (e.g. an index now engages), changed default — **add an entry under `## [Unreleased]` in `CHANGELOG.md` as part of the same PR.**

User-facing means: someone outside EQL would care. If in doubt, add the entry; it's cheap.

What does *not* need an entry:

- Internal refactors that don't change observable behaviour
- Test-only changes
- CI / tooling-only changes
- Documentation typo fixes
- Doxygen comments

### How to write the entry

Pick the right section (`Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security`). Lead with the user-visible fact, then a short "Why." explanation, then a PR link in parentheses. Match the tone and density of existing entries — a single dense paragraph per entry, not a bullet list.

Example entry (real entry from `2.3.0`):

> **`=`, `<>`, `~~` (`LIKE`), `~~*` (`ILIKE`) on `eql_v2_encrypted` are now inlinable SQL functions.** The planner can structurally match these operators against the documented functional indexes (`eql_v2.hmac_256(col)` for equality, `eql_v2.bloom_filter(col)` for `LIKE`/`ILIKE`), so bare-form queries (`WHERE col = $1`) engage the index without per-query rewriting. Previously these operators wrapped multi-branch PL/pgSQL bodies that the planner could not inline, forcing seq scans on Supabase / managed Postgres installations that lack operator-class indexes. ([#193](...), [#196](...))

### When a change warrants an upgrade note

If the change has *behaviour callers should be aware of* — even when no API breaks — add a numbered upgrade note (`U-NNN`) to the active `docs/upgrading/v<version>.md` file. Examples of what warrants an upgrade note:

- Recommended recipe shifts (e.g. opclass → functional indexes)
- Tightened error semantics (e.g. "raises now where it used to silently NULL")
- Required payload terms changing (e.g. equality requires `hm`)
- Anything where a caller might need to audit their schema or queries

The entry under `Changed` / `Deprecated` should cross-link to the `U-NNN`. See `docs/upgrading/v2.3.md` for the format — TL;DR, compatibility table, numbered notes, verification checklist, rollback.

### Versioning

The `eql_v2` PostgreSQL schema name is part of the public API and is **independent of the EQL release version**. Major-version bumps to EQL do not rename the schema. The `eql_v3` schema is **not** a rename of `eql_v2`: it is a separate, additional schema introduced to namespace the encrypted-domain type families. Both schemas coexist; `eql_v2` keeps the core types/operators and is unchanged. Adding a new schema for a new surface is additive, not a public-API break. When deciding on a version bump:

- **Patch (`2.3.x`)** — bug fixes, no behaviour changes
- **Minor (`2.x.0`)** — additive changes, behaviour changes that don't break the public API (signatures, schema name, payload format, operator names)
- **Major (`3.0.0`)** — only for changes that break the public API. Do not reach for a major bump just because a behaviour change has wide blast radius — that's what upgrade notes are for.

### Cutting a release

When a release is being prepared:

1. Confirm `[Unreleased]` is non-empty and entries are coherent.
2. Rename `## [Unreleased]` to `## [<version>] — YYYY-MM-DD` and add a fresh empty `[Unreleased]` above it.
3. Update the link references at the bottom of `CHANGELOG.md` (new `[Unreleased]` compare URL, new `[<version>]` tag URL).
4. Commit, then create the GitHub release. The release workflow (`.github/workflows/release-eql.yml`) takes the tag and builds artefacts.
5. The `[<version>]` section is the GitHub release body — paste it verbatim.
