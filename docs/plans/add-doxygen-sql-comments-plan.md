# Implementation Plan: Add Doxygen-Style Comments to All SQL Implementation Files

**Status:** Ready for Execution
**Created:** 2025-10-24
**Branch:** `add-doxygen-sql-comments`
**Worktree:** `/Users/tobyhede/src/encrypt-query-language/.worktrees/sql-documentation`

## Context & Objectives

**Goal:** Add comprehensive Doxygen-style comments to all SQL implementation files in the EQL codebase to enable automated documentation generation.

**Scope:**
- 53 SQL implementation files across 13 modules
- Excludes test files (*_test.sql)
- Aligns with docs/reference/ content (SQL source is source of truth)
- Uses Doxygen annotations per RFC: `sql-documentation-generation-rfc.md`

**Success Criteria:**
1. Every database object (function, type, operator, aggregate, constraint) has Doxygen comments
2. Comments include mandatory tags: `@brief`, `@param`, `@return`
3. Comments include encouraged tags where applicable: `@example`, `@throws`, `@internal`
4. Reference documentation can be verified against source comments
5. All annotations follow Doxygen syntax (`--!` prefix)

**Related Documents:**
- [SQL Documentation Generation RFC](./sql-documentation-generation-rfc.md)
- [EQL Functions Reference](../reference/eql-functions.md)

---

## Estimation Summary

| Phase | Tasks | Estimated Hours |
|-------|-------|----------------|
| Phase 0: Pre-flight Checks | 1 | 0.25 |
| Phase 1: Setup & Validation | 5 | 1-2 |
| Phase 2: Core Modules | 7 | 10-15 |
| Phase 3: Index Modules (PARALLEL) | 6 | 6-8 |
| Phase 4: Supporting Modules (PARALLEL) | 6 | 4-5 |
| Phase 5: Quality Assurance | 5 | 3-4 |
| Phase 6: Documentation & Handoff | 6 | 2-3 |
| **TOTAL** | **36** | **26-39 hours** |

**Note:** Phases 3 and 4 can be executed in parallel using subagent-driven-development. See execution strategy below.

---

## Execution Strategy

### PR Strategy
Create small, reviewable PRs:
- **PR 1:** Phase 0 + Phase 1 (Setup & validation tooling)
- **PR 2:** Phase 2.1-2.2 (config module)
- **PR 3:** Phase 2.3-2.4 (encrypted module)
- **PR 4:** Phase 2.5-2.6 (operators module)
- **PR 5:** Phase 3 (all index modules - can use subagents)
- **PR 6:** Phase 4 (all supporting modules - can use subagents)
- **PR 7:** Phase 5 + Phase 6 (QA, documentation, CI integration)

### Subagent Usage
**When to use subagent-driven-development skill:**
- Phase 3: Dispatch 6 parallel subagents (one per index module)
- Phase 4: Dispatch 6 parallel subagents (one per supporting module group)

**Subagent task template:**
```
Task: Document [module_name] with Doxygen comments

Context:
- Working in: /Users/tobyhede/src/encrypt-query-language/.worktrees/sql-documentation
- Branch: add-doxygen-sql-comments
- Templates: docs/development/sql-documentation-templates.md
- Standards: docs/development/sql-documentation-standards.md

Files to document: [list files]

CRITICAL: DO NOT modify SQL code implementation. Only add Doxygen comments.
SQL code is source of truth - document what the code does, not what you think it should do.

Deliverables:
1. Add @brief, @param, @return tags to all database objects
2. Validate syntax: psql -f [file] --set ON_ERROR_STOP=1
3. Verify required tags: grep -c "@brief" [file]
4. Report completion with file list and object count
```

---

## Phase 0: Pre-flight Checks (0.25 hours)

### Task 0.1: Verify Environment and Create Backup

**CRITICAL PRINCIPLE: DO NOT MODIFY SQL CODE**
This plan only adds documentation comments. The SQL implementation is the source of truth.
If you find bugs, unclear behavior, or discrepancies with reference docs:
- Document what the code ACTUALLY does (not what it should do)
- Note issues separately for later review
- DO NOT fix bugs or change behavior

**Pre-flight checklist:**
```bash
# 1. Verify location and branch
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/sql-documentation
pwd  # Must be in sql-documentation worktree
git branch --show-current  # Must be: add-doxygen-sql-comments

# 2. Verify clean state
git status  # Should show no uncommitted changes

# 3. Create backup branch
git branch backup/pre-documentation-$(date +%Y%m%d)
echo "Backup branch created: backup/pre-documentation-$(date +%Y%m%d)"

# 4. Verify database is running
mise run postgres:up
psql postgres://cipherstash:password@localhost:7432 -c "SELECT version();"

# 5. Check disk space (need ~500KB for comment additions)
df -h . | tail -1

# 6. Verify all SQL files are accessible
echo "Counting SQL implementation files (excluding tests):"
find src -name "*.sql" -not -name "*_test.sql" | wc -l  # Should be 53

# 7. Test one file syntax validation
psql postgres://cipherstash:password@localhost:7432 \
  -f src/version.sql --set ON_ERROR_STOP=1 -q

echo "✅ Pre-flight checks complete"
```

**Verification:**
```bash
# All commands above should succeed
# Database should be running on localhost:7432
# Backup branch should exist: git branch --list 'backup/*'
```

**If any check fails:**
- Database not running → `mise run postgres:up`
- Wrong directory → Navigate to correct worktree
- Wrong branch → `git checkout add-doxygen-sql-comments`
- Uncommitted changes → Commit or stash first
- Syntax errors in existing SQL → Note as blocker, investigate before proceeding

---

## Phase 1: Setup & Validation (1-2 hours)

### Task 1.1: Create Documentation Standards Document
**File:** `docs/development/sql-documentation-standards.md`

**Content:**
```markdown
# SQL Documentation Standards

## Required Doxygen Tags

### Mandatory
- `@brief` - One sentence description
- `@param` - For each parameter (with type and description)
- `@return` - Return value description (include structure for JSONB)

### Encouraged
- `@example` - Usage examples (SQL code blocks)
- `@throws` - Exception conditions (when RAISE is used)
- `@internal` - Mark private functions (prefix with `_`)

### Optional
- `@see` - Cross-references
- `@note` - Additional warnings/notes
- `@deprecated` - Migration path for deprecated functions

## Format Examples

### Public Function
\`\`\`sql
--! @brief Initialize a column for encryption/decryption
--!
--! This function configures the CipherStash Proxy to encrypt/decrypt
--! data in the specified column. Must be called before adding search indexes.
--!
--! @param table_name Text name of table containing the column
--! @param column_name Text name of column to encrypt
--! @param cast_as Text PostgreSQL type to cast decrypted value (default: 'text')
--! @param migrating Boolean whether this is migration operation (default: false)
--! @return JSONB Configuration object with encryption settings
--! @throws Exception if table or column does not exist
--!
--! @example
--! SELECT eql_v2.add_column('users', 'encrypted_email', 'text');
--!
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.add_column(
  table_name text,
  column_name text,
  cast_as text DEFAULT 'text',
  migrating boolean DEFAULT false
) RETURNS jsonb
AS $$ ... $$;
\`\`\`

### Private Function
\`\`\`sql
--! @brief Internal helper for encryption validation
--! @internal
--! @param config JSONB Configuration object to validate
--! @return Boolean True if configuration is valid
CREATE FUNCTION eql_v2._validate_config(config jsonb)
  RETURNS boolean
AS $$ ... $$;
\`\`\`

### Operator
\`\`\`sql
--! @brief Equality comparison for encrypted values
--!
--! Implements the = operator for encrypted column comparisons.
--! Uses encrypted index terms for comparison without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if values are equal via encrypted comparison
--!
--! @example
--! -- Using operator syntax:
--! SELECT * FROM users WHERE encrypted_email = encrypted_value;
--!
--! @see eql_v2.compare
CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$ ... $$;

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted
);
\`\`\`

### Type
\`\`\`sql
--! @brief Composite type for encrypted column data
--!
--! This is the core type used for all encrypted columns. Data is stored
--! as JSONB with the following structure:
--! - `c`: ciphertext (encrypted value)
--! - `i`: index terms (searchable metadata)
--! - `k`: key ID
--! - `m`: metadata
--!
--! @see eql_v2.ciphertext
--! @see eql_v2.meta_data
CREATE TYPE eql_v2_encrypted AS (
  data jsonb
);
\`\`\`

### Aggregate
\`\`\`sql
--! @brief State transition function for grouped_value aggregate
--! @internal
--! @param $1 JSONB Accumulated state
--! @param $2 JSONB New value
--! @return JSONB Updated state
CREATE FUNCTION eql_v2._first_grouped_value(jsonb, jsonb)
  RETURNS jsonb
AS $$ ... $$;

--! @brief Return first non-null value in a group
--!
--! Aggregate function that returns the first non-null encrypted value
--! encountered in a GROUP BY clause.
--!
--! @param input JSONB Encrypted values to aggregate
--! @return JSONB First non-null value in group
--!
--! @example
--! -- Get first email per user group
--! SELECT user_id, eql_v2.grouped_value(encrypted_email)
--! FROM user_emails
--! GROUP BY user_id;
--!
--! @see eql_v2._first_grouped_value
CREATE AGGREGATE eql_v2.grouped_value(jsonb) (
  SFUNC = eql_v2._first_grouped_value,
  STYPE = jsonb
);
\`\`\`
```

**Verification:**
```bash
cat docs/development/sql-documentation-standards.md | grep -E "@brief|@param|@return"
```

---

### Task 1.2: Create Template Files for Each Object Type
**File:** `docs/development/sql-documentation-templates.md`

**Content:**
```markdown
# SQL Documentation Templates

## Template: Public Function

\`\`\`sql
--! @brief [One sentence description]
--!
--! [Detailed description paragraph explaining purpose,
--! behavior, and any important context]
--!
--! @param param_name [Type] [Description]
--! @param param_name [Type] [Description with default: DEFAULT value]
--! @return [Return type] [Description of return value structure]
--! @throws [Condition that triggers exception]
--!
--! @example
--! -- [Example description]
--! SELECT eql_v2.function_name('value1', 'value2');
--!
--! @see eql_v2.related_function
CREATE FUNCTION eql_v2.function_name(...)
\`\`\`

## Template: Private/Internal Function

\`\`\`sql
--! @brief [One sentence description]
--! @internal
--! @param param_name [Type] [Description]
--! @return [Return type] [Description]
CREATE FUNCTION eql_v2._internal_function(...)
\`\`\`

## Template: Operator Implementation

\`\`\`sql
--! @brief [Operator symbol] operator for encrypted values
--!
--! Implements the [operator] operator using [index type] for
--! [operation description] without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean [Result description]
--!
--! @example
--! -- [Specific example showing operator usage]
--! SELECT * FROM table WHERE encrypted_col [operator] value;
--!
--! @see eql_v2.[related_function]
CREATE FUNCTION eql_v2."[operator]"(...)
\`\`\`

## Template: Domain Type

\`\`\`sql
--! @brief [Type name] index term type
--!
--! Domain type representing [description of what this type represents].
--! Used for [use case] via the '[index_name]' index type.
--!
--! @see eql_v2.add_search_config
--! @note This is a transient type used only during query execution
CREATE DOMAIN eql_v2.[type_name] AS [base_type];
\`\`\`

## Template: Composite Type

\`\`\`sql
--! @brief [Brief description of composite type]
--!
--! [Detailed description including structure/fields]
--!
--! @see [related functions]
CREATE TYPE eql_v2.[type_name] AS (
  field_name field_type
);
\`\`\`

## Template: Aggregate Function

\`\`\`sql
--! @brief [State function description]
--! @internal
--! @param $1 [State type] [State description]
--! @param $2 [Input type] [Input description]
--! @return [State type] [Updated state description]
CREATE FUNCTION eql_v2._state_function(...)

--! @brief [Aggregate behavior description]
--!
--! [Detailed description of what aggregate computes]
--!
--! @param input [Input type] [Input description]
--! @return [Return type] [Return description]
--!
--! @example
--! -- [Example query using aggregate]
--!
--! @see eql_v2._state_function
CREATE AGGREGATE eql_v2.aggregate_name(...) (...)
\`\`\`

## Template: Operator Class

\`\`\`sql
--! @brief [Operator class purpose description]
--!
--! Defines the operator class required for creating [index type] indexes
--! on encrypted columns. Enables [capabilities description].
--!
--! @example
--! -- Create index using this operator class:
--! CREATE INDEX ON table USING [index_method] (column [opclass_name]);
--!
--! @see CREATE OPERATOR CLASS in PostgreSQL documentation
CREATE OPERATOR CLASS [opclass_name] ...
\`\`\`

## Template: Constraint Function

\`\`\`sql
--! @brief [Constraint check description]
--!
--! [What the constraint validates]
--!
--! @param value [Type] [Value being checked]
--! @return Boolean True if constraint satisfied
--! @throws Exception if [constraint violation condition]
CREATE FUNCTION eql_v2.[constraint_function](...)
\`\`\`
```

**Verification:**
```bash
grep -A 20 "Template: Public Function" docs/development/sql-documentation-templates.md
```

---

### Task 1.3: Inventory All Database Objects
**File:** `docs/development/documentation-inventory.md`

**Generate inventory with:**
```bash
cd /Users/tobyhede/src/encrypt-query-language/.worktrees/sql-documentation

# Count objects by type
echo "# SQL Documentation Inventory" > docs/development/documentation-inventory.md
echo "" >> docs/development/documentation-inventory.md
echo "Generated: $(date)" >> docs/development/documentation-inventory.md
echo "" >> docs/development/documentation-inventory.md

for file in $(find src -name "*.sql" -not -name "*_test.sql" | sort); do
  echo "## $file" >> docs/development/documentation-inventory.md
  echo "" >> docs/development/documentation-inventory.md
  grep -E "^CREATE (FUNCTION|OPERATOR|TYPE|DOMAIN|AGGREGATE|OPERATOR CLASS)" "$file" | \
    sed 's/^/- /' >> docs/development/documentation-inventory.md
  echo "" >> docs/development/documentation-inventory.md
done

# Add summary
echo "## Summary" >> docs/development/documentation-inventory.md
echo "" >> docs/development/documentation-inventory.md
echo "- Total files: $(find src -name "*.sql" -not -name "*_test.sql" | wc -l)" >> docs/development/documentation-inventory.md
echo "- Total CREATE statements: $(find src -name "*.sql" -not -name "*_test.sql" -exec grep -h "^CREATE" {} \; | wc -l)" >> docs/development/documentation-inventory.md
```

**Verification:**
```bash
wc -l docs/development/documentation-inventory.md
file_count=$(find src -name "*.sql" -not -name "*_test.sql" | wc -l | xargs)
echo "Found $file_count SQL implementation files"
```

---

### Task 1.4: Create Cross-Reference Sync Rules
**File:** `docs/development/reference-sync-rules.md`

**Content:**
```markdown
# Reference Documentation Sync Rules

## CRITICAL PRINCIPLE
**SQL code implementation is the source of truth.**

During documentation, you will encounter discrepancies between:
- SQL code behavior
- Existing SQL comments (if any)
- Reference documentation in `docs/reference/`

**NEVER modify SQL code to match documentation.**
**ALWAYS document what the code actually does.**

## Decision Tree for Discrepancies

### Scenario 1: SQL code is more detailed/accurate than reference docs
**Action:**
- Document the SQL code behavior accurately
- Mark reference doc for update in tracking file
- Continue with documentation

**Add to:** `docs/development/reference-sync-notes.md`
**Format:**
```
- [ ] docs/reference/eql-functions.md:add_column
      SQL implementation has additional parameter validation not documented
      SQL shows: validates table exists before adding config
      Docs show: minimal description
```

### Scenario 2: Reference docs describe different behavior than SQL implements
**Action:**
- Document what the SQL code ACTUALLY does
- Flag discrepancy for principal engineer review
- DO NOT change SQL code
- DO NOT invent behavior to match docs

**Add to:** `docs/development/documentation-questions.md`
**Format:**
```
- [ ] DISCREPANCY: eql_v2.add_column behavior
      SQL code: raises exception if column already encrypted
      Reference docs: suggest idempotent behavior
      Question: Is SQL correct or does it need fixing?
      For review by: Principal Engineer
```

### Scenario 3: SQL code appears to have a bug
**Action:**
- Document the actual behavior (including the bug)
- Create GitHub issue for bug investigation
- Add `@note` tag mentioning the issue number
- DO NOT fix the bug in this plan

**Example:**
```sql
--! @brief Extract ciphertext from encrypted value
--! @param encrypted JSONB Raw encrypted value
--! @return Text Extracted ciphertext
--! @note Issue #XXX: Returns null for malformed input instead of raising error
CREATE FUNCTION eql_v2.ciphertext(encrypted jsonb) ...
```

**Add to:** `docs/development/documentation-blockers.md`
**Format:**
```
- [ ] BUG FOUND: eql_v2.ciphertext
      Issue: Returns null for malformed input instead of raising error
      GitHub Issue: #XXX
      Action: Documented actual behavior, flagged for fix
      Blocking documentation: No (documented as-is)
```

### Scenario 4: Unclear what code does (complex logic)
**Action:**
- Study the test files in `src/**/*_test.sql`
- Examine test cases to understand intended behavior
- Document based on test coverage
- If still unclear, read the code carefully and document what you observe
- Flag for principal engineer review if high-impact function

**Add to:** `docs/development/documentation-questions.md`

### Scenario 5: Reference docs conflict with each other
**Action:**
- SQL code is tiebreaker
- Document what code does
- Note conflicting docs in sync notes

## Review Process

**Principal Engineer + Team Code Review** will handle:
- Discrepancies flagged in `documentation-questions.md`
- Bugs flagged in `documentation-blockers.md`
- Reference doc updates listed in `reference-sync-notes.md`

**Timeline:**
- Flag issues during documentation (Phases 1-4)
- Review session after Phase 5 (QA)
- Address critical issues before final PR
- Schedule reference doc updates as follow-up work

## Tracking Files

Create these files in `docs/development/`:

**reference-sync-notes.md** - Reference docs needing updates
**documentation-questions.md** - Discrepancies needing review
**documentation-blockers.md** - Bugs found during documentation

Initialize with:
```bash
cat > docs/development/reference-sync-notes.md <<'EOF'
# Reference Documentation Sync Notes

Items to update in docs/reference/ after documentation complete:

## Format
- [ ] docs/reference/file.md:section
      Issue: [what needs updating]
      SQL shows: [actual behavior]
      Docs show: [current docs content]

---

EOF

cat > docs/development/documentation-questions.md <<'EOF'
# Documentation Questions for Review

Discrepancies requiring principal engineer + team review:

## Format
- [ ] DISCREPANCY: function_name
      SQL code: [what code does]
      Reference docs: [what docs say]
      Question: [specific question]
      For review by: Principal Engineer

---

EOF

cat > docs/development/documentation-blockers.md <<'EOF'
# Documentation Blockers

Bugs found during documentation process:

## Format
- [ ] BUG FOUND: function_name
      Issue: [description]
      GitHub Issue: #XXX (if created)
      Action: [what was done]
      Blocking documentation: Yes/No

---

EOF
```

**Verification:**
```bash
ls -la docs/development/reference-sync-rules.md
ls -la docs/development/reference-sync-notes.md
ls -la docs/development/documentation-questions.md
ls -la docs/development/documentation-blockers.md
```

---

### Task 1.5: Commit Phase 1 Setup
**Action:**
```bash
# Verify setup complete
ls -la docs/development/sql-documentation-standards.md
ls -la docs/development/sql-documentation-templates.md
ls -la docs/development/documentation-inventory.md
ls -la docs/development/reference-sync-rules.md

# Add all setup files
git add docs/development/

# Commit
git commit -m "docs(sql): add documentation standards, templates, and tooling (Phase 1)

Setup for SQL Doxygen documentation project:
- Documentation standards with required tags
- Templates for all SQL object types
- Inventory of 53 SQL files to document
- Cross-reference sync rules (SQL is source of truth)
- Tracking files for discrepancies and issues

Part of: add-doxygen-sql-comments plan
PR: Phase 0 + Phase 1 (Setup)
"

# Verify commit
git log -1 --stat
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(sql)"
git status  # Should be clean
```

---

## Phase 2: Core Module Documentation (10-15 hours)

Document high-value, customer-facing modules first.

### Task 2.1: Document `src/config/functions.sql`
**Objects:** `add_column`, `add_search_config`, `remove_column`, `remove_search_config`, `modify_search_config`

**Source file:** `src/config/functions.sql`

**Reference docs:** `docs/reference/eql-functions.md` (Configuration Functions section)

**Approach:**
1. Read current reference documentation for each function
2. Read test files (`src/config/*_test.sql`) for usage examples
3. Add Doxygen comments to each function using template
4. Verify SQL syntax still valid: `psql -f src/config/functions.sql --set ON_ERROR_STOP=1`

**For each function:**
```sql
--! @brief [Extract from docs/reference/eql-functions.md]
--!
--! [Detailed explanation from reference docs]
--!
--! @param table_name Text name of the table containing the column
--! @param column_name Text name of the column to configure
--! @param cast_as Text PostgreSQL type for decrypted value (default: 'text')
--! @param migrating Boolean migration operation flag (default: false)
--! @return JSONB Configuration object with encryption settings
--! @throws Exception if table or column does not exist
--!
--! @example
--! -- [Extract example from reference docs or tests]
--! SELECT eql_v2.add_column('users', 'encrypted_email', 'text');
--!
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.add_column(...)
```

**Verification:**
```bash
# Syntax check
psql postgres://cipherstash:password@localhost:7432 \
  -f src/config/functions.sql \
  --set ON_ERROR_STOP=1

# Comment coverage check
grep -c "^--! @brief" src/config/functions.sql  # Should match function count
```

---

### Task 2.2: Document `src/config/functions_private.sql`
**Objects:** Private/internal configuration functions (prefix with `_`)

**Approach:**
- Mark all functions with `@internal` tag
- Brief descriptions only (internal use)
- No examples required (internal API)

**Template:**
```sql
--! @brief [Brief internal description]
--! @internal
--! @param ...
--! @return ...
CREATE FUNCTION eql_v2._internal_function(...)
```

**Verification:**
```bash
grep -c "@internal" src/config/functions_private.sql  # Should match function count
```

---

### Task 2.3: Document `src/encrypted/functions.sql`
**Objects:** Core encrypted column functions (`ciphertext`, `meta_data`, `grouped_value`, `add_encrypted_constraint`, etc.)

**Reference:** `docs/reference/eql-functions.md` (Helper Functions section)

**Special considerations:**
- `grouped_value` is an AGGREGATE (document both state function and aggregate)
- Functions with multiple overloads (e.g., `ciphertext(jsonb)` vs `ciphertext(eql_v2_encrypted)`)

**For aggregates:**
```sql
--! @brief State transition function for grouped_value aggregate
--! @internal
--! @param $1 JSONB Accumulated state
--! @param $2 JSONB New value
--! @return JSONB Updated state
CREATE FUNCTION eql_v2._first_grouped_value(jsonb, jsonb) ...

--! @brief Return first non-null value in a group
--!
--! Aggregate function that returns the first non-null encrypted value
--! encountered in a GROUP BY clause.
--!
--! @param input JSONB Encrypted values to aggregate
--! @return JSONB First non-null value in group
--!
--! @example
--! -- Get first email per user group
--! SELECT user_id, eql_v2.grouped_value(encrypted_email)
--! FROM user_emails
--! GROUP BY user_id;
--!
--! @see eql_v2._first_grouped_value
CREATE AGGREGATE eql_v2.grouped_value(jsonb) (...)
```

**Verification:**
```bash
grep -c "^--! @brief" src/encrypted/functions.sql
psql -f src/encrypted/functions.sql --set ON_ERROR_STOP=1
```

---

### Task 2.4: Document `src/encrypted/types.sql`
**Objects:** `eql_v2_encrypted` composite type

**Type documentation format:**
```sql
--! @brief Composite type for encrypted column data
--!
--! This is the core type used for all encrypted columns. Data is stored
--! as JSONB with the following structure:
--! - `c`: ciphertext (encrypted value)
--! - `i`: index terms (searchable metadata)
--! - `k`: key ID
--! - `m`: metadata
--!
--! @see eql_v2.ciphertext
--! @see eql_v2.meta_data
CREATE TYPE eql_v2_encrypted AS (
  data jsonb
);
```

**Verification:**
```bash
grep "@brief" src/encrypted/types.sql
```

---

### Task 2.5: Document `src/operators/=.sql`
**Objects:** Equality operator and supporting functions

**Reference:** `docs/reference/eql-functions.md` (Operators section)

**Operator documentation approach:**
Document the implementation function with operator usage in @example:

```sql
--! @brief Equality comparison for encrypted values
--!
--! Implements the = operator for encrypted column comparisons.
--! Uses encrypted index terms for comparison without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean True if values are equal via encrypted comparison
--!
--! @example
--! -- Using operator syntax:
--! SELECT * FROM users WHERE encrypted_email = encrypted_value;
--!
--! -- Comparing encrypted column to JSONB literal:
--! SELECT * FROM users WHERE encrypted_email = '{"c":"...","i":{"unique":"..."}}'::jsonb;
--!
--! @see eql_v2.compare
CREATE FUNCTION eql_v2."="(a eql_v2_encrypted, b eql_v2_encrypted) ...

CREATE OPERATOR = (
  FUNCTION=eql_v2."=",
  ...
);
```

**Verification:**
```bash
grep -c "@example.*operator" src/operators/=.sql  # Should be present
```

---

### Task 2.6: Document All Remaining Operators
**Files:** `~~.sql`, `<.sql`, `<=.sql`, `>.sql`, `>=.sql`, `<>.sql`, `@>.sql`, `<@.sql`, `->.sql`, `->>.sql`

**Reference:** `docs/reference/eql-functions.md` (Operators section)

**For each operator:**
1. Read reference docs for operator behavior
2. Check test files for examples
3. Document implementation function with operator example
4. Include index type used (bloom_filter for `~~`, ore for range operators, etc.)

**Pattern:**
```sql
--! @brief [Operator name] operator for encrypted values
--!
--! Implements the [operator] operator using [index type] for
--! [operation description] without decryption.
--!
--! @param a eql_v2_encrypted Left operand
--! @param b eql_v2_encrypted Right operand
--! @return Boolean [Result description]
--!
--! @example
--! -- [Specific example from reference docs]
--!
--! @see eql_v2.[related_function]
CREATE FUNCTION eql_v2."[operator]"(...) ...
```

**Verification:**
```bash
for op in '~~' '<' '<=' '>' '>=' '<>' '@>' '<@' '->' '->>'; do
  file="src/operators/${op}.sql"
  if [ -f "$file" ]; then
    grep -q "@brief" "$file" && echo "$file: OK" || echo "$file: MISSING"
  fi
done
```

---

### Task 2.7: Commit Phase 2 Progress
**Action:**
```bash
# Run validation on completed modules
./tasks/validate-required-tags.sh 2>&1 | grep -E "(src/config|src/encrypted|src/operators)"

# Count completed files
completed=$(find src/config src/encrypted src/operators -name "*.sql" -not -name "*_test.sql" | wc -l | xargs)
echo "Phase 2 complete: $completed files documented"

# Add and commit
git add src/config/ src/encrypted/ src/operators/

git commit -m "docs(sql): add Doxygen comments to core modules (Phase 2)

Documented core customer-facing modules:
- src/config/functions.sql: add_column, add_search_config, remove_column, etc.
- src/config/functions_private.sql: internal config helpers
- src/encrypted/functions.sql: ciphertext, meta_data, grouped_value, etc.
- src/encrypted/types.sql: eql_v2_encrypted composite type
- src/operators/=.sql: equality operator
- src/operators/~~.sql: LIKE/pattern match operator
- src/operators/<.sql, <=.sql, >.sql, >=.sql: range operators
- src/operators/<>.sql: not equal operator
- src/operators/@>.sql, <@.sql: containment operators
- src/operators/->.sql, ->>.sql: JSONB access operators

All functions include @brief, @param, @return tags.
Customer-facing functions include @example tags.

Coverage: $completed/53 files completed
Part of: add-doxygen-sql-comments plan
PR: Phase 2 (Core modules)
"

# Verify commit
git log -1 --stat
```

**Verification:**
```bash
git log -1 --oneline | grep "Phase 2"
git diff main --stat | grep -E "(config|encrypted|operators)"
```

**Create PR for Phase 2:**
```bash
# Push branch
git push origin add-doxygen-sql-comments

# Create PR (adjust based on actual PR structure - may split into 3 PRs)
gh pr create --title "docs(sql): Add Doxygen comments to core modules" \
  --body "## Summary
Documents core EQL modules with Doxygen-style comments:
- Configuration functions (add_column, add_search_config)
- Encrypted type and helper functions
- All operators (=, ~~, <, >, @>, <@, ->, etc.)

## Coverage
- Files: $completed/53
- All objects have @brief, @param, @return tags
- Customer-facing functions include @example tags

## Testing
- [x] SQL syntax validated
- [x] Required tags present
- [x] No SQL code modified (comments only)

## Related
- Plan: docs/plans/add-doxygen-sql-comments-plan.md
- RFC: docs/plans/sql-documentation-generation-rfc.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" \
  --base main

# Or split into smaller PRs:
# PR 2: config module only
# PR 3: encrypted module only
# PR 4: operators module only
```

---

## Phase 3: Index Implementation Modules (6-8 hours)

**⚡ PARALLEL EXECUTION RECOMMENDED**

This phase documents 6 independent index modules. Each module can be documented in parallel using the `superpowers:subagent-driven-development` skill.

**Execution approach:**
```markdown
Use subagent-driven-development skill to dispatch 6 parallel subagents:
1. blake3 module → Subagent 1
2. hmac_256 module → Subagent 2
3. bloom_filter module → Subagent 3
4. ore_block_u64_8_256 module → Subagent 4
5. ore_cllw_u64_8 module → Subagent 5
6. ore_cllw_var_8 + ste_vec modules → Subagent 6

Each subagent receives:
- Task description (document module with Doxygen comments)
- Template reference (docs/development/sql-documentation-templates.md)
- Standards reference (docs/development/sql-documentation-standards.md)
- Files to document
- CRITICAL: Do not modify SQL code, only add comments
```

### Task 3.1: Document `src/blake3/`
**Files:** `types.sql`, `functions.sql`, `compare.sql`

**Objects:**
- `eql_v2.blake3` domain type
- Blake3 hash extraction functions
- Comparison functions

**Reference:** `docs/reference/index-config.md`, `docs/reference/eql-functions.md` (Index Term Extraction)

**For domain types:**
```sql
--! @brief Blake3 hash index term type
--!
--! Domain type representing Blake3 cryptographic hash values.
--! Used for exact-match encrypted searches via the 'unique' index type.
--!
--! @see eql_v2.add_search_config
--! @note This is a transient type used only during query execution
CREATE DOMAIN eql_v2.blake3 AS text;
```

**Verification:**
```bash
find src/blake3 -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \;
```

---

### Task 3.2: Document `src/hmac_256/`
**Files:** `types.sql`, `functions.sql`, `compare.sql`

**Objects:**
- `eql_v2.hmac_256` domain type
- HMAC-SHA256 extraction functions
- Comparison functions

**Similar approach to blake3 documentation**

**Verification:**
```bash
find src/hmac_256 -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \;
```

---

### Task 3.3: Document `src/bloom_filter/`
**Files:** `types.sql`, `functions.sql`

**Objects:**
- `eql_v2.bloom_filter` type
- Bloom filter term extraction
- Pattern matching functions

**Reference:** `docs/reference/eql-functions.md` (match index, ~~ operator)

**Verification:**
```bash
find src/bloom_filter -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \;
```

---

### Task 3.4: Document `src/ore_block_u64_8_256/`
**Files:** `types.sql`, `functions.sql`, `compare.sql`, `casts.sql`, `operators.sql`, `operator_class.sql`

**Objects:**
- ORE (Order-Revealing Encryption) types
- Range comparison functions
- Operator class for B-tree indexes

**Reference:** `docs/reference/eql-functions.md` (ore index, range operators)

**For operator classes:**
```sql
--! @brief B-tree operator class for ORE encrypted values
--!
--! Defines the operator class required for creating B-tree indexes
--! on encrypted columns using Order-Revealing Encryption (ORE).
--! Enables range queries (<, <=, =, >=, >) and ORDER BY on encrypted data.
--!
--! @example
--! -- Create index using this operator class:
--! CREATE INDEX ON events USING btree (encrypted_timestamp eql_v2_encrypted_ops);
--!
--! @see CREATE OPERATOR CLASS in PostgreSQL documentation
CREATE OPERATOR CLASS eql_v2_encrypted_ops ...
```

**Verification:**
```bash
find src/ore_block_u64_8_256 -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \;
```

---

### Task 3.5: Document `src/ore_cllw_u64_8/` and `src/ore_cllw_var_8/`
**Files:** `types.sql`, `functions.sql`, `compare.sql`

**Objects:** Alternative ORE implementations

**Note:** These are variants of ORE scheme - ensure documentation explains differences

**Verification:**
```bash
find src/ore_cllw_* -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \;
```

---

### Task 3.6: Document `src/ste_vec/`
**Files:** `functions.sql`

**Objects:** Structured Encryption for vectors (JSONB containment)

**Reference:** `docs/reference/eql-functions.md` (ste_vec index, @> and <@ operators)

**Verification:**
```bash
grep -c "@brief" src/ste_vec/functions.sql
```

---

### Task 3.7: Commit Phase 3 Progress
**Action:**
```bash
# Validate all index modules
find src/blake3 src/hmac_256 src/bloom_filter src/ore_* src/ste_vec \
  -name "*.sql" -not -name "*_test.sql" \
  -exec ./tasks/validate-required-tags.sh {} \;

# Count completed files
completed=$(find src/blake3 src/hmac_256 src/bloom_filter src/ore_* src/ste_vec \
  -name "*.sql" -not -name "*_test.sql" | wc -l | xargs)
echo "Phase 3 complete: $completed index module files documented"

# Add and commit
git add src/blake3/ src/hmac_256/ src/bloom_filter/ src/ore_*/ src/ste_vec/

git commit -m "docs(sql): add Doxygen comments to index modules (Phase 3)

Documented all index implementation modules:
- src/blake3/: Blake3 hash index terms (unique index)
- src/hmac_256/: HMAC-SHA256 index terms
- src/bloom_filter/: Bloom filter for pattern matching (match index)
- src/ore_block_u64_8_256/: Order-Revealing Encryption (ore index)
- src/ore_cllw_u64_8/: ORE CLLW variant
- src/ore_cllw_var_8/: ORE CLLW variable-length variant
- src/ste_vec/: Structured encryption for vectors (ste_vec index)

All domain types, functions, and operators documented.
Includes operator class documentation for B-tree indexes.

Coverage: [X]/53 files completed
Part of: add-doxygen-sql-comments plan
PR: Phase 3 (Index modules)
"

# Verify commit
git log -1 --stat
```

**Verification:**
```bash
git log -1 --oneline | grep "Phase 3"
git diff main --stat | grep -E "(blake3|hmac|bloom|ore|ste_vec)"
```

---

## Phase 4: Supporting Modules (4-5 hours)

**⚡ PARALLEL EXECUTION RECOMMENDED**

This phase documents supporting infrastructure modules. Can be parallelized using `superpowers:subagent-driven-development` skill.

**Execution approach:**
```markdown
Use subagent-driven-development skill to dispatch 6 parallel subagents:
1. operators/compare.sql, order_by.sql, operator_class.sql → Subagent 1
2. encrypted/aggregates.sql, casts.sql, compare.sql, constraints.sql → Subagent 2
3. jsonb/functions.sql → Subagent 3
4. config/types.sql, tables.sql, indexes.sql, constraints.sql → Subagent 4
5. encryptindex/functions.sql → Subagent 5
6. common.sql, crypto.sql, schema.sql, version.sql → Subagent 6
```

### Task 4.1: Document `src/operators/compare.sql`, `src/operators/order_by.sql`, `src/operators/operator_class.sql`
**Objects:** Core comparison and ordering infrastructure

**These are foundational - reference from other operator docs**

**Verification:**
```bash
grep -l "@brief" src/operators/{compare,order_by,operator_class}.sql
```

---

### Task 4.2: Document `src/encrypted/aggregates.sql`, `src/encrypted/casts.sql`, `src/encrypted/compare.sql`, `src/encrypted/constraints.sql`
**Objects:** Supporting functions for encrypted type

**Verification:**
```bash
find src/encrypted -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \;
```

---

### Task 4.3: Document `src/jsonb/functions.sql`
**Objects:** JSONB path extraction functions

**Reference:** `docs/reference/json-support.md`

**Verification:**
```bash
grep -c "@brief" src/jsonb/functions.sql
```

---

### Task 4.4: Document `src/config/types.sql`, `src/config/tables.sql`, `src/config/indexes.sql`, `src/config/constraints.sql`
**Objects:** Configuration schema components

**Verification:**
```bash
find src/config -name "*.sql" -not -name "*_test.sql" -not -name "functions*.sql" -exec grep -l "@brief" {} \;
```

---

### Task 4.5: Document `src/encryptindex/functions.sql`
**Objects:** Index management functions

**Verification:**
```bash
grep -c "@brief" src/encryptindex/functions.sql
```

---

### Task 4.6: Document `src/common.sql`, `src/crypto.sql`, `src/schema.sql`, `src/version.sql`
**Objects:** Utility functions, schema creation, versioning

**Verification:**
```bash
for file in src/common.sql src/crypto.sql src/schema.sql src/version.sql; do
  if grep -q "CREATE" "$file"; then
    if grep -q "@brief" "$file"; then
      echo "$file: OK"
    else
      echo "$file: MISSING"
    fi
  fi
done
```

---

### Task 4.7: Commit Phase 4 Progress
**Action:**
```bash
# Validate all supporting modules
find src/operators src/encrypted src/jsonb src/config src/encryptindex \
  -name "*.sql" -not -name "*_test.sql" -not -name "functions.sql" \
  -exec bash -c 'grep -q "@brief" "$1" 2>/dev/null || echo "Missing: $1"' _ {} \;

# Also validate root-level files
for file in src/common.sql src/crypto.sql src/schema.sql src/version.sql; do
  grep -q "@brief" "$file" 2>/dev/null || echo "Missing: $file"
done

# Count completed files
total_now=$(find src -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \; | wc -l | xargs)
echo "Phase 4 complete: All 53 files should now be documented"
echo "Current documented count: $total_now/53"

# Add and commit
git add src/operators/ src/encrypted/ src/jsonb/ src/config/ src/encryptindex/
git add src/common.sql src/crypto.sql src/schema.sql src/version.sql

git commit -m "docs(sql): add Doxygen comments to supporting modules (Phase 4)

Documented all supporting infrastructure:
- src/operators/: compare, order_by, operator_class (core infrastructure)
- src/encrypted/: aggregates, casts, compare, constraints
- src/jsonb/: JSONB path extraction functions
- src/config/: types, tables, indexes, constraints (schema)
- src/encryptindex/: index management functions
- src/common.sql: utility functions
- src/crypto.sql: cryptographic helpers
- src/schema.sql: schema creation
- src/version.sql: version tracking

All infrastructure components documented.

Coverage: $total_now/53 files completed
Part of: add-doxygen-sql-comments plan
PR: Phase 4 (Supporting modules)
"

# Verify commit
git log -1 --stat
```

**Verification:**
```bash
git log -1 --oneline | grep "Phase 4"
# Verify all files documented
find src -name "*.sql" -not -name "*_test.sql" | wc -l  # Should be 53
find src -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \; | wc -l  # Should be 53
```

---

## Phase 5: Quality Assurance (3-4 hours)

### Task 5.1: Cross-Reference with docs/reference/
**Files to check against:**
- `docs/reference/eql-functions.md`
- `docs/reference/index-config.md`
- `docs/reference/json-support.md`
- `docs/reference/database-indexes.md`
- `docs/reference/PAYLOAD.md`

**Process:**
1. For each section in reference docs, find corresponding SQL source
2. Verify comments match or improve upon reference docs
3. Note discrepancies (SQL is source of truth)
4. Create list of reference doc updates needed

**Output file:** `docs/development/reference-sync-notes.md`

**Verification:**
```bash
# Generate comparison report
echo "# Reference Documentation Sync Notes" > docs/development/reference-sync-notes.md
echo "" >> docs/development/reference-sync-notes.md
echo "Generated: $(date)" >> docs/development/reference-sync-notes.md
echo "" >> docs/development/reference-sync-notes.md
echo "## Functions in docs/reference/eql-functions.md vs SQL source" >> docs/development/reference-sync-notes.md
# ... add comparison logic
```

---

### Task 5.2: Validate All Files Have SQL Syntax
**Run against PostgreSQL:**

**Create script:** `tasks/validate-documented-sql.sh`

```bash
#!/bin/bash
# tasks/validate-documented-sql.sh

set -e

cd "$(dirname "$0")/.."

PGHOST=localhost
PGPORT=7432
PGUSER=cipherstash
PGPASSWORD=password
PGDATABASE=postgres

echo "Validating SQL syntax for all documented files..."
echo ""

errors=0
validated=0

for file in $(find src -name "*.sql" -not -name "*_test.sql" | sort); do
  echo -n "Validating $file... "

  # Capture both stdout and stderr
  error_output=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
          -f "$file" --set ON_ERROR_STOP=1 -q 2>&1)
  exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo "✓"
    validated=$((validated + 1))
  else
    echo "✗ SYNTAX ERROR"
    echo "  Error in: $file"
    echo "  Details:"
    echo "$error_output" | tail -10 | sed 's/^/    /'
    echo ""
    errors=$((errors + 1))
  fi
done

echo ""
echo "Validation complete:"
echo "  Validated: $validated"
echo "  Errors: $errors"

if [ $errors -gt 0 ]; then
  echo ""
  echo "❌ Validation failed with $errors errors"
  exit 1
else
  echo ""
  echo "✅ All SQL files validated successfully"
  exit 0
fi
```

**Verification:**
```bash
chmod +x tasks/validate-documented-sql.sh
./tasks/validate-documented-sql.sh
```

---

### Task 5.3: Generate Coverage Report
**Check all objects have @brief:**

**Create script:** `tasks/check-doc-coverage.sh`

```bash
#!/bin/bash
# tasks/check-doc-coverage.sh

set -e

cd "$(dirname "$0")/.."

output_file="docs/development/coverage-report.md"

echo "# Documentation Coverage Report" > "$output_file"
echo "" >> "$output_file"
echo "Generated: $(date)" >> "$output_file"
echo "" >> "$output_file"

total_objects=0
documented_objects=0
incomplete_files=()

for file in $(find src -name "*.sql" -not -name "*_test.sql" | sort); do
  # Count CREATE statements
  creates=$(grep -c "^CREATE " "$file" 2>/dev/null || echo 0)
  total_objects=$((total_objects + creates))

  # Count @brief annotations
  briefs=$(grep -c "^--! @brief" "$file" 2>/dev/null || echo 0)
  documented_objects=$((documented_objects + briefs))

  if [ "$creates" -gt 0 ]; then
    if [ "$creates" -eq "$briefs" ]; then
      status="✓ Complete"
    else
      status="✗ Incomplete ($briefs/$creates)"
      incomplete_files+=("$file")
    fi
    echo "- $file: $status" >> "$output_file"
  fi
done

echo "" >> "$output_file"
echo "## Summary" >> "$output_file"
echo "" >> "$output_file"
echo "- Total objects: $total_objects" >> "$output_file"
echo "- Documented: $documented_objects" >> "$output_file"

if [ $total_objects -gt 0 ]; then
  coverage=$((documented_objects * 100 / total_objects))
  echo "- Coverage: ${coverage}%" >> "$output_file"
else
  echo "- Coverage: N/A" >> "$output_file"
  coverage=0
fi

if [ ${#incomplete_files[@]} -gt 0 ]; then
  echo "" >> "$output_file"
  echo "## Incomplete Files" >> "$output_file"
  echo "" >> "$output_file"
  for file in "${incomplete_files[@]}"; do
    echo "- $file" >> "$output_file"
  done
fi

echo ""
cat "$output_file"
echo ""

if [ $coverage -eq 100 ]; then
  echo "✅ 100% documentation coverage achieved!"
  exit 0
else
  echo "⚠️  Documentation coverage: ${coverage}%"
  exit 1
fi
```

**Verification:**
```bash
chmod +x tasks/check-doc-coverage.sh
./tasks/check-doc-coverage.sh
# Should show 100% coverage
```

---

### Task 5.4: Validate Required Tags Present
**Check mandatory tags:**

**Create script:** `tasks/validate-required-tags.sh`

```bash
#!/bin/bash
# tasks/validate-required-tags.sh

set -e

cd "$(dirname "$0")/.."

echo "Validating required Doxygen tags..."
echo ""

errors=0
warnings=0

for file in $(find src -name "*.sql" -not -name "*_test.sql"); do
  # For each CREATE FUNCTION, check tags
  functions=$(grep -n "^CREATE FUNCTION" "$file" 2>/dev/null | cut -d: -f1 || echo "")

  for line_no in $functions; do
    # Find comment block above function (search backwards max 50 lines)
    start=$((line_no - 50))
    [ "$start" -lt 1 ] && start=1

    comment_block=$(sed -n "${start},${line_no}p" "$file" | grep "^--!" | tail -20)

    function_sig=$(sed -n "${line_no}p" "$file")
    function_name=$(echo "$function_sig" | grep -oP 'CREATE FUNCTION \K[^\(]+' | xargs)

    # Check for @brief
    if ! echo "$comment_block" | grep -q "@brief"; then
      echo "ERROR: $file:$line_no $function_name - Missing @brief"
      errors=$((errors + 1))
    fi

    # Check for @param (if function has parameters)
    if echo "$function_sig" | grep -q "(" && \
       ! echo "$function_sig" | grep -q "()"; then
      if ! echo "$comment_block" | grep -q "@param"; then
        echo "WARNING: $file:$line_no $function_name - Missing @param"
        warnings=$((warnings + 1))
      fi
    fi

    # Check for @return (if function returns something other than void)
    if ! echo "$function_sig" | grep -qi "RETURNS void"; then
      if ! echo "$comment_block" | grep -q "@return"; then
        echo "ERROR: $file:$line_no $function_name - Missing @return"
        errors=$((errors + 1))
      fi
    fi
  done
done

echo ""
echo "Validation summary:"
echo "  Errors: $errors"
echo "  Warnings: $warnings"
echo ""

if [ "$errors" -gt 0 ]; then
  echo "❌ Validation failed with $errors errors"
  exit 1
else
  echo "✅ All required tags present"
  exit 0
fi
```

**Verification:**
```bash
chmod +x tasks/validate-required-tags.sh
./tasks/validate-required-tags.sh
```

---

### Task 5.5: Test Doxygen Generation (Early Validation)
**Purpose:** Verify Doxygen can parse our comments before claiming completion

**Install Doxygen:**
```bash
# macOS
brew install doxygen

# Verify installation
doxygen --version
```

**Create minimal Doxyfile:**
```bash
cat > Doxyfile.test <<'EOF'
# Minimal Doxygen config for testing SQL documentation

PROJECT_NAME           = "EQL SQL Documentation Test"
OUTPUT_DIRECTORY       = docs/doxygen-test
INPUT                  = src/
FILE_PATTERNS          = *.sql
RECURSIVE              = YES
EXCLUDE_PATTERNS       = *_test.sql

# SQL-specific settings
EXTENSION_MAPPING      = sql=C++
OPTIMIZE_OUTPUT_JAVA   = NO

# Comment parsing
JAVADOC_AUTOBRIEF      = YES
QT_AUTOBRIEF           = NO

# Generate HTML only (for testing)
GENERATE_HTML          = YES
GENERATE_LATEX         = NO
GENERATE_XML           = NO

# Warning settings (strict)
WARNINGS               = YES
WARN_IF_UNDOCUMENTED   = NO
WARN_IF_DOC_ERROR      = YES
WARN_NO_PARAMDOC       = YES

# Quiet mode for cleaner output
QUIET                  = NO
EOF
```

**Run Doxygen:**
```bash
# Generate documentation
doxygen Doxyfile.test 2>&1 | tee doxygen-test.log

# Check for errors
if grep -i "error" doxygen-test.log; then
  echo "❌ Doxygen encountered errors - review doxygen-test.log"
  exit 1
fi

# Check for warnings (excluding undocumented warnings)
if grep -i "warning" doxygen-test.log | grep -v "undocumented"; then
  echo "⚠️  Doxygen has warnings - review doxygen-test.log"
fi

# Verify HTML was generated
if [ -d "docs/doxygen-test/html" ]; then
  echo "✅ Doxygen HTML generated successfully"
  echo "View at: docs/doxygen-test/html/index.html"
else
  echo "❌ Doxygen HTML generation failed"
  exit 1
fi
```

**Manual verification:**
```bash
# Open generated docs in browser
open docs/doxygen-test/html/index.html

# Check a few specific functions are documented:
# - eql_v2.add_column
# - eql_v2.ciphertext
# - eql_v2.= operator
# - eql_v2_encrypted type
```

**Common Doxygen issues to look for:**
- Malformed @param tags (wrong parameter names)
- Missing @return tags for non-void functions
- Unclosed comment blocks
- Incorrect @brief syntax
- Special characters breaking parsing

**If errors found:**
- Fix formatting issues in SQL files
- Re-run validation scripts
- Re-test with Doxygen
- DO NOT proceed to Phase 6 until Doxygen parses cleanly

**Cleanup (after verification):**
```bash
# Keep test config but remove generated output
rm -rf docs/doxygen-test/
# Keep Doxyfile.test for future reference
```

**Verification:**
```bash
# Should complete without errors
doxygen Doxyfile.test 2>&1 | grep -i error
echo "Exit code: $?"  # Should be 1 (no matches found)
```

---

## Phase 6: Documentation & Handoff (2-3 hours)

### Task 6.1: Update DEVELOPMENT.md
**Add section:**

```markdown
## SQL Documentation

All SQL implementation files use Doxygen-style comments for automated documentation generation.

### Required Annotations

- `@brief` - One sentence description (mandatory)
- `@param` - Parameter descriptions (mandatory for all parameters)
- `@return` - Return value description (mandatory)
- `@example` - Usage examples (encouraged)
- `@throws` - Exception conditions (encouraged)
- `@internal` - Mark private functions (for functions prefixed with `_`)

### Templates

See `docs/development/sql-documentation-templates.md` for templates.

### Validation

Check documentation coverage:
```bash
mise run check-doc-coverage
```

Validate required tags:
```bash
mise run validate-required-tags
```

Validate SQL syntax:
```bash
mise run validate-documented-sql
```
```

**Verification:**
```bash
grep -A 10 "## SQL Documentation" DEVELOPMENT.md
```

---

### Task 6.2: Add mise Tasks
**File:** `mise.toml`

Add tasks:
```toml
[tasks."check-doc-coverage"]
description = "Check SQL documentation coverage"
run = "./tasks/check-doc-coverage.sh"

[tasks."validate-required-tags"]
description = "Validate required Doxygen tags present"
run = "./tasks/validate-required-tags.sh"

[tasks."validate-documented-sql"]
description = "Validate SQL syntax of documented files"
run = "./tasks/validate-documented-sql.sh"
```

**Verification:**
```bash
mise tasks | grep doc
mise run check-doc-coverage
```

---

### Task 6.3: Create PR Checklist Template
**File:** `.github/pull_request_template.md` (or update existing)

Add checklist item:
```markdown
## SQL Documentation

- [ ] All new SQL functions have Doxygen comments (`@brief`, `@param`, `@return`)
- [ ] Examples added for customer-facing functions
- [ ] Private functions marked with `@internal`
- [ ] Documentation validated: `mise run validate-required-tags`
```

**Verification:**
```bash
cat .github/pull_request_template.md | grep -A 4 "SQL Documentation"
```

---

### Task 6.4: Create Final Summary Document
**File:** `docs/development/sql-documentation-completion-summary.md`

**Content:**
```markdown
# SQL Documentation Completion Summary

## Overview
All SQL implementation files across 13 modules have been documented with Doxygen-style comments.

## Coverage
- Total database objects: [COUNT from coverage report]
- Documented objects: [COUNT from coverage report]
- Coverage: 100%

## Files Modified
[Insert list from docs/development/documentation-inventory.md]

## Validation Results
- ✅ SQL syntax validated (all files)
- ✅ Required tags present (all functions)
- ✅ Coverage report: 100%

## Next Steps
1. Implement build-time doc generator (per RFC)
2. Configure Doxygen for HTML generation
3. Integrate into CI/CD pipeline
4. Publish generated reference docs

## Reference
- RFC: docs/plans/sql-documentation-generation-rfc.md
- Templates: docs/development/sql-documentation-templates.md
- Standards: docs/development/sql-documentation-standards.md
- Plan: docs/plans/add-doxygen-sql-comments-plan.md
```

**Verification:**
```bash
cat docs/development/sql-documentation-completion-summary.md
```

---

### Task 6.5: Add CI Validation Workflow
**File:** `.github/workflows/validate-sql-docs.yml` (or add to existing workflow)

**Content:**
```yaml
name: Validate SQL Documentation

on:
  pull_request:
    paths:
      - 'src/**/*.sql'
      - 'tasks/validate-*.sh'
      - 'tasks/check-doc-coverage.sh'
  push:
    branches:
      - main
    paths:
      - 'src/**/*.sql'

jobs:
  validate-documentation:
    name: Validate SQL Doxygen Comments
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: cipherstash
          POSTGRES_PASSWORD: password
          POSTGRES_DB: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up environment
        run: |
          chmod +x tasks/validate-documented-sql.sh
          chmod +x tasks/validate-required-tags.sh
          chmod +x tasks/check-doc-coverage.sh

      - name: Validate SQL syntax
        env:
          PGHOST: localhost
          PGPORT: 5432
          PGUSER: cipherstash
          PGPASSWORD: password
          PGDATABASE: postgres
        run: |
          echo "Validating SQL syntax for all documented files..."
          ./tasks/validate-documented-sql.sh

      - name: Validate required Doxygen tags
        run: |
          echo "Checking for required @brief, @param, @return tags..."
          ./tasks/validate-required-tags.sh

      - name: Check documentation coverage
        run: |
          echo "Verifying documentation coverage..."
          ./tasks/check-doc-coverage.sh

      - name: Report results
        if: always()
        run: |
          echo "## SQL Documentation Validation Results" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          if [ -f docs/development/coverage-report.md ]; then
            cat docs/development/coverage-report.md >> $GITHUB_STEP_SUMMARY
          fi

  # Optional: Doxygen build test
  test-doxygen-generation:
    name: Test Doxygen Generation
    runs-on: ubuntu-latest
    needs: validate-documentation

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install Doxygen
        run: |
          sudo apt-get update
          sudo apt-get install -y doxygen

      - name: Test Doxygen generation
        run: |
          # Use test config
          if [ -f Doxyfile.test ]; then
            doxygen Doxyfile.test 2>&1 | tee doxygen-test.log

            # Check for errors
            if grep -i "error" doxygen-test.log; then
              echo "❌ Doxygen generation failed"
              exit 1
            fi

            echo "✅ Doxygen generation successful"
          else
            echo "⚠️  No Doxyfile.test found - skipping Doxygen test"
          fi
```

**Alternative: Add to existing CI workflow**
If you already have a CI workflow, add these jobs to it instead of creating a new file.

**Verification:**
```bash
# Check workflow syntax
cat .github/workflows/validate-sql-docs.yml

# Test locally (if using act)
act pull_request -j validate-documentation

# Or push to test branch and verify on GitHub
git add .github/workflows/validate-sql-docs.yml
git commit -m "ci: add SQL documentation validation workflow"
git push origin add-doxygen-sql-comments
```

**Success criteria:**
- [ ] CI runs on SQL file changes
- [ ] Syntax validation passes
- [ ] Required tags validation passes
- [ ] Coverage check passes (100%)
- [ ] Doxygen generation succeeds (optional)

---

### Task 6.6: Final Commit and Summary
**Action:**
```bash
# Run all QA checks one final time
echo "Running final validation suite..."
./tasks/validate-documented-sql.sh
./tasks/validate-required-tags.sh
./tasks/check-doc-coverage.sh

# Verify 100% coverage
coverage=$(grep "Coverage:" docs/development/coverage-report.md | grep -oP '\d+')
if [ "$coverage" -ne 100 ]; then
  echo "❌ Coverage is $coverage%, not 100%"
  exit 1
fi

echo "✅ All validation checks passed"
echo "✅ 100% documentation coverage achieved"

# Add final documentation and tooling
git add docs/development/
git add DEVELOPMENT.md
git add mise.toml
git add .github/pull_request_template.md
git add .github/workflows/validate-sql-docs.yml
git add Doxyfile.test
git add tasks/

git commit -m "docs(sql): add QA tooling, CI integration, and completion summary (Phase 5+6)

Quality assurance and handoff:
- Cross-reference validation with docs/reference/
- Validation scripts with error reporting
- Coverage reporting (100% achieved)
- CI workflow for automated validation
- mise tasks for local validation
- PR template with SQL documentation checklist
- Doxygen test configuration
- Completion summary and next steps

All 53 SQL implementation files now have comprehensive Doxygen comments.

Coverage: 53/53 files (100%)
Part of: add-doxygen-sql-comments plan
PR: Phase 5 + Phase 6 (QA and handoff)
"

# Verify final state
git log --oneline -10
git status

echo ""
echo "========================================="
echo "SQL Documentation Project Complete!"
echo "========================================="
echo ""
echo "Summary:"
find src -name "*.sql" -not -name "*_test.sql" | wc -l | xargs echo "- Total files:"
find src -name "*.sql" -not -name "*_test.sql" -exec grep -l "@brief" {} \; | wc -l | xargs echo "- Documented:"
echo "- Coverage: 100%"
echo ""
echo "Next steps:"
echo "1. Create PRs for each phase (see PR strategy)"
echo "2. Review tracking files:"
echo "   - docs/development/reference-sync-notes.md"
echo "   - docs/development/documentation-questions.md"
echo "   - docs/development/documentation-blockers.md"
echo "3. Schedule follow-up for reference doc updates"
echo "4. Implement production Doxygen build process (per RFC)"
echo ""
```

**Verification:**
```bash
# All validation should pass
mise run check-doc-coverage
mise run validate-required-tags
mise run validate-documented-sql

# Coverage should be 100%
grep "Coverage: 100%" docs/development/coverage-report.md
```

---

## Complete File Checklist (53 files)

### src/blake3/ (3 files)
- [ ] `compare.sql` - Blake3 comparison functions
- [ ] `functions.sql` - Blake3 extraction functions
- [ ] `types.sql` - Blake3 domain type

### src/bloom_filter/ (2 files)
- [ ] `functions.sql` - Bloom filter extraction
- [ ] `types.sql` - Bloom filter type

### src/config/ (6 files)
- [ ] `constraints.sql` - Configuration constraints
- [ ] `functions.sql` - **HIGH PRIORITY** - Public config functions
- [ ] `functions_private.sql` - Private config functions
- [ ] `indexes.sql` - Configuration indexes
- [ ] `tables.sql` - Configuration tables
- [ ] `types.sql` - Configuration types

### src/encrypted/ (6 files)
- [ ] `aggregates.sql` - Aggregate functions
- [ ] `casts.sql` - Type casts
- [ ] `compare.sql` - Comparison functions
- [ ] `constraints.sql` - Encrypted column constraints
- [ ] `functions.sql` - **HIGH PRIORITY** - Core encrypted functions
- [ ] `types.sql` - **HIGH PRIORITY** - eql_v2_encrypted type

### src/encryptindex/ (1 file)
- [ ] `functions.sql` - Index management

### src/hmac_256/ (3 files)
- [ ] `compare.sql` - HMAC comparison
- [ ] `functions.sql` - HMAC extraction
- [ ] `types.sql` - HMAC domain type

### src/jsonb/ (1 file)
- [ ] `functions.sql` - JSONB path functions

### src/operators/ (13 files)
- [ ] `->.sql` - JSONB field access operator
- [ ] `->>.sql` - JSONB text extraction operator
- [ ] `<.sql` - Less than operator
- [ ] `<=.sql` - Less than or equal operator
- [ ] `<>.sql` - Not equal operator
- [ ] `<@.sql` - Contained by operator
- [ ] `=.sql` - **HIGH PRIORITY** - Equality operator
- [ ] `>.sql` - Greater than operator
- [ ] `>=.sql` - Greater than or equal operator
- [ ] `@>.sql` - Contains operator
- [ ] `compare.sql` - Core comparison logic
- [ ] `operator_class.sql` - Operator class definition
- [ ] `order_by.sql` - Ordering functions
- [ ] `~~.sql` - **HIGH PRIORITY** - LIKE operator

### src/ore_block_u64_8_256/ (6 files)
- [ ] `casts.sql` - ORE type casts
- [ ] `compare.sql` - ORE comparison
- [ ] `functions.sql` - ORE extraction
- [ ] `operator_class.sql` - ORE operator class
- [ ] `operators.sql` - ORE operators
- [ ] `types.sql` - ORE types

### src/ore_cllw_u64_8/ (3 files)
- [ ] `compare.sql` - ORE CLLW comparison
- [ ] `functions.sql` - ORE CLLW extraction
- [ ] `types.sql` - ORE CLLW types

### src/ore_cllw_var_8/ (3 files)
- [ ] `compare.sql` - ORE CLLW VAR comparison
- [ ] `functions.sql` - ORE CLLW VAR extraction
- [ ] `types.sql` - ORE CLLW VAR types

### src/ste_vec/ (1 file)
- [ ] `functions.sql` - Structured encryption vectors

### src/ root (5 files)
- [ ] `common.sql` - Common utilities
- [ ] `crypto.sql` - Cryptographic utilities
- [ ] `schema.sql` - Schema creation
- [ ] `version.sql` - Version tracking

---

## Notes for Engineers

**Context:**
- Working in git worktree at `/Users/tobyhede/src/encrypt-query-language/.worktrees/sql-documentation`
- Branch: `add-doxygen-sql-comments`
- Main repository: `/Users/tobyhede/src/encrypt-query-language/`
- PostgreSQL test database: `localhost:7432` (credentials: cipherstash/password)

**File Paths:**
- All SQL source: `src/`
- Reference docs: `docs/reference/`
- Test files: `tests/` and `src/**/*_test.sql`

**Testing:**
Each documentation task should be followed by syntax validation:
```bash
mise run postgres:up  # Ensure database running
psql postgres://cipherstash:password@localhost:7432 -f src/path/to/file.sql --set ON_ERROR_STOP=1
```

**Reference Priority:**
1. SQL source code (source of truth)
2. Test files (*_test.sql) for usage examples
3. docs/reference/*.md for descriptions
4. RFC (`docs/plans/sql-documentation-generation-rfc.md`) for format

**Common Patterns:**

Private functions (prefix `_`):
```sql
--! @brief [Brief description]
--! @internal
--! @param ...
--! @return ...
CREATE FUNCTION eql_v2._internal_function(...)
```

Functions with RAISE:
```sql
--! @brief [Description]
--! @param ...
--! @return ...
--! @throws Exception if [specific condition that raises]
CREATE FUNCTION eql_v2.some_function(...)
```

Functions with defaults:
```sql
--! @brief [Description]
--! @param table_name Text name of the table
--! @param cast_as Text type for casting (default: 'text')
--! @return ...
CREATE FUNCTION eql_v2.function_name(table_name text, cast_as text DEFAULT 'text')
```

JSONB return structures (be specific about structure):
```sql
--! @brief [Description]
--! @param ...
--! @return JSONB Configuration object with keys: 'table_name', 'column_name', 'cast_as', 'indexes'
CREATE FUNCTION eql_v2.get_config(...)
```

Overloaded functions (multiple signatures):
```sql
--! @brief Extract ciphertext from encrypted value
--! @overload JSONB input variant
--! @param encrypted JSONB Raw encrypted value from database
--! @return Text Extracted ciphertext string
CREATE FUNCTION eql_v2.ciphertext(encrypted jsonb)
  RETURNS text ...

--! @brief Extract ciphertext from encrypted type
--! @overload Typed input variant
--! @param encrypted eql_v2_encrypted Encrypted column value
--! @return Text Extracted ciphertext string
CREATE FUNCTION eql_v2.ciphertext(encrypted eql_v2_encrypted)
  RETURNS text ...
```

Handling existing comments:
```sql
-- WRONG: Don't leave old comments mixed with Doxygen
-- This function does X
--! @brief This function does X
CREATE FUNCTION ...

-- CORRECT: Doxygen only, move old comments inside function body
--! @brief This function does X
--! @param ...
--! @return ...
CREATE FUNCTION eql_v2.some_function(...) AS $$
BEGIN
  -- TODO: Optimize this query (old comment moved here)
  -- Note: This handles edge case Y (implementation note moved here)
  ...
END;
$$;
```

Dynamic SQL and macros:
```sql
--! @brief Create encrypted column index dynamically
--! @param table_name Text Table name for index creation
--! @param column_name Text Column name for index creation
--! @return VOID
--! @note Uses EXECUTE for dynamic SQL - actual DDL constructed at runtime
--! @see eql_v2.add_search_config for index type configuration
CREATE FUNCTION eql_v2._create_index_dynamic(...)
```

**Quality Checklist:**
- [ ] Every CREATE FUNCTION has `@brief`, `@param` (if params), `@return`
- [ ] Every CREATE OPERATOR's implementation function documents operator usage in `@example`
- [ ] Every CREATE TYPE/DOMAIN has `@brief`
- [ ] Every CREATE AGGREGATE has both state function and aggregate documented
- [ ] Private functions marked with `@internal`
- [ ] Functions with RAISE have `@throws`
- [ ] Customer-facing functions have `@example`
- [ ] SQL syntax validated with `psql`

---

## Progress Tracking

Track progress using this plan as a checklist. Update the checkboxes as tasks are completed.

**Current Status:** Ready for Execution (Plan Updated with Recommendations)

**Last Updated:** 2025-10-27

**Execution Notes:**
- Use small PRs strategy (7 PRs total)
- Parallelize Phases 3 and 4 with subagent-driven-development skill
- Run validation after each phase
- Create tracking files for discrepancies/questions/blockers
- SQL code is source of truth - document actual behavior, not intended behavior
- Principal engineer + team review handles flagged issues

**Phase Completion:**
- [ ] Phase 0: Pre-flight checks
- [ ] Phase 1: Setup & validation tooling
- [ ] Phase 2: Core modules (config, encrypted, operators)
- [ ] Phase 3: Index modules (blake3, hmac_256, bloom_filter, ore_*, ste_vec)
- [ ] Phase 4: Supporting modules (compare, aggregates, jsonb, etc.)
- [ ] Phase 5: Quality assurance
- [ ] Phase 6: Documentation & handoff + CI integration
