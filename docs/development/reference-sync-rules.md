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
