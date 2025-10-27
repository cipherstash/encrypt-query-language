# Test Coverage Improvement Opportunities

> **Status:** Like-for-like migration complete (100%). This document identifies areas for enhanced coverage.

## Current Coverage (Like-for-Like)

✅ **Equality Operators**: 16/16 assertions (100%)
- HMAC equality (operator + function + JSONB)
- Blake3 equality (operator + function + JSONB)

✅ **JSONB Functions**: 24/24 assertions (100%)
- Array functions (elements, elements_text, length)
- Path queries (query, query_first, exists)
- Structure validation
- Encrypted selectors

## Improvement Opportunities

### 1. Parameterized Testing (Reduce Code Duplication)

**Current State:** Separate tests for HMAC vs Blake3 with duplicated logic

**Improvement:** Use test parameterization

```rust
#[rstest]
#[case("hm", "HMAC")]
#[case("b3", "Blake3")]
fn equality_operator_finds_matching_record(
    #[case] index_type: &str,
    #[case] index_name: &str,
) {
    // Single test covers both index types
}
```

**Benefits:**
- Reduces code duplication
- Easier to add new index types
- Consistent test patterns

**Dependencies:** Add `rstest = "0.18"` to Cargo.toml

---

### 2. Property-Based Testing for Loops

**Current State:** SQL tests loop 1..3, Rust tests single iteration

**SQL Pattern:**
```sql
for i in 1..3 loop
  e := create_encrypted_json(i, 'hm');
  PERFORM assert_result(...);
end loop;
```

**Improvement:** Use proptest for multiple iterations

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn equality_works_for_multiple_records(id in 1..=10i32) {
        // Test holds for any id in range
    }
}
```

**Benefits:**
- Tests edge cases automatically
- Discovers unexpected failures
- More thorough than fixed iterations

**Dependencies:** Add `proptest = "1.0"` to Cargo.toml

---

### 3. Additional Operator Coverage

**Missing from SQL tests:**
- `<>` (not equals) operator
- `<`, `>`, `<=`, `>=` (comparison operators with ORE)
- `@>`, `<@` (containment operators)
- `~~` (LIKE operator)

**Recommendation:** Add comprehensive operator test suite

**Files to reference:**
- `src/operators/<>.sql`
- `src/operators/<.sql`, `src/operators/>.sql`
- `src/operators/@>.sql`, `src/operators/<@.sql`
- `src/operators/~~.sql`

---

### 4. Error Handling & Edge Cases

**Current Coverage:** Basic exception tests (non-array to array functions)

**Additional Tests:**
- NULL handling
- Empty arrays
- Invalid selector formats
- Type mismatches
- Concurrent updates

---

### 5. Performance & Load Testing

**Not covered in SQL or Rust tests:**

- Query performance with large datasets
- Index effectiveness validation
- Concurrent query behavior
- Memory usage patterns

**Recommendation:** Separate benchmark suite using criterion.rs

---

## Priority Ranking

1. **High:** Additional operator coverage (inequality, comparisons, containment)
2. **Medium:** Parameterized tests (reduce duplication)
3. **Medium:** Error handling edge cases
4. **Low:** Property-based testing (nice-to-have)
5. **Low:** Performance benchmarks (separate concern)

---

## Next Steps

1. Complete like-for-like migration ✅
2. Review this document with team
3. Prioritize improvements based on risk/value
4. Create separate tasks for each improvement
5. Implement incrementally
