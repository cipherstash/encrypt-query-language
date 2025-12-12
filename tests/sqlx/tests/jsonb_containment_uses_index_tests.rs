//! Macro-based containment tests (@> and <@) for encrypted JSONB with GIN index
//!
//! These tests use a declarative macro pattern to systematically generate containment
//! tests for all operator/argument type combinations.
//!
//! Coverage Matrix (Macro-Generated):
//!
//! | Operator           | LHS              | RHS              | Expected Result |
//! |--------------------|------------------|------------------|-----------------|
//! | jsonb_contains     | EncryptedColumn  | EncryptedParam   | Match (self)    |
//! | jsonb_contains     | EncryptedColumn  | SvElementParam   | Match (subset)  |
//! | jsonb_contains     | EncryptedParam   | EncryptedColumn  | Match (self)    |
//! | jsonb_contains     | SvElementParam   | EncryptedColumn  | NO MATCH        |
//! | jsonb_contained_by | EncryptedColumn  | EncryptedParam   | Match (self)    |
//! | jsonb_contained_by | SvElementParam   | EncryptedColumn  | Match (subset)  |
//! | jsonb_contained_by | EncryptedParam   | EncryptedColumn  | Match (self)    |
//! | jsonb_contained_by | EncryptedColumn  | SvElementParam   | NO MATCH        |
//!
//! Uses the ste_vec_vast table (500 rows) from migration 005_install_ste_vec_vast_data.sql

use anyhow::{Context, Result};
use eql_tests::{
    analyze_table, assert_uses_index, create_jsonb_gin_index, get_ste_vec_encrypted,
    get_ste_vec_sv_element,
};
use sqlx::PgPool;

// Constants for ste_vec_vast table testing
const STE_VEC_VAST_TABLE: &str = "ste_vec_vast";
const STE_VEC_VAST_GIN_INDEX: &str = "ste_vec_vast_gin_idx";

// ============================================================================
// GIN Index Helper Functions
// ============================================================================

/// Setup GIN index on ste_vec_vast table for testing
///
/// Creates the GIN index and runs ANALYZE to ensure query planner
/// has accurate statistics.
async fn setup_ste_vec_vast_gin_index(pool: &PgPool) -> Result<()> {
    create_jsonb_gin_index(pool, STE_VEC_VAST_TABLE, STE_VEC_VAST_GIN_INDEX).await?;
    analyze_table(pool, STE_VEC_VAST_TABLE).await?;
    Ok(())
}

// ============================================================================
// Macro-Based Coverage Matrix Tests
// ============================================================================
//
// These tests use a declarative macro pattern to generate containment tests
// for all operator/type combinations systematically.

/// Containment operator under test
#[derive(Debug, Clone, Copy)]
enum ContainmentOp {
    /// jsonb_contains(lhs, rhs) - LHS contains RHS
    Contains,
    /// jsonb_contained_by(lhs, rhs) - LHS is contained by RHS
    ContainedBy,
}

/// Argument type for LHS or RHS position in containment query
#[derive(Debug, Clone, Copy, PartialEq)]
enum ArgumentType {
    /// Table column reference: `e`
    EncryptedColumn,
    /// Full encrypted value as parameter: `$N::jsonb`
    EncryptedParam,
    /// Single sv element as parameter: `$N::jsonb`
    SvElementParam,
}

/// Test case configuration for containment operator tests
struct ContainmentTestCase {
    operator: ContainmentOp,
    lhs: ArgumentType,
    rhs: ArgumentType,
}

/// Generate a containment test from operator and argument types
macro_rules! containment_test {
    ($name:ident, op = $op:ident, lhs = $lhs:ident, rhs = $rhs:ident) => {
        #[sqlx::test]
        async fn $name(pool: PgPool) -> Result<()> {
            let test_case = ContainmentTestCase {
                operator: ContainmentOp::$op,
                lhs: ArgumentType::$lhs,
                rhs: ArgumentType::$rhs,
            };
            test_case
                .run(&pool, STE_VEC_VAST_TABLE, STE_VEC_VAST_GIN_INDEX)
                .await
        }
    };
}

/// Generate a negative containment test that verifies NO match is returned
macro_rules! containment_negative_test {
    ($name:ident, op = $op:ident, lhs = $lhs:ident, rhs = $rhs:ident, $reason:expr) => {
        #[sqlx::test]
        async fn $name(pool: PgPool) -> Result<()> {
            let test_case = ContainmentTestCase {
                operator: ContainmentOp::$op,
                lhs: ArgumentType::$lhs,
                rhs: ArgumentType::$rhs,
            };
            test_case
                .run_negative(&pool, STE_VEC_VAST_TABLE, $reason)
                .await
        }
    };
}

impl ContainmentOp {
    fn sql_function(&self) -> &'static str {
        match self {
            ContainmentOp::Contains => "eql_v2.jsonb_contains",
            ContainmentOp::ContainedBy => "eql_v2.jsonb_contained_by",
        }
    }
}

impl ArgumentType {
    fn is_param(&self) -> bool {
        matches!(
            self,
            ArgumentType::EncryptedParam | ArgumentType::SvElementParam
        )
    }
}

impl ContainmentTestCase {
    /// Build SQL query with proper placeholders based on argument types
    fn build_query(&self, table: &str) -> (String, usize) {
        let mut param_idx = 1usize;

        let lhs_sql = match self.lhs {
            ArgumentType::EncryptedColumn => "e".to_string(),
            ArgumentType::EncryptedParam | ArgumentType::SvElementParam => {
                let s = format!("${}::jsonb", param_idx);
                param_idx += 1;
                s
            }
        };

        let rhs_sql = match self.rhs {
            ArgumentType::EncryptedColumn => "e".to_string(),
            ArgumentType::EncryptedParam | ArgumentType::SvElementParam => {
                let s = format!("${}::jsonb", param_idx);
                param_idx += 1;
                s
            }
        };

        let id_param = format!("${}", param_idx);

        let sql = format!(
            "SELECT id FROM {} WHERE {}({}, {}) AND id = {}",
            table,
            self.operator.sql_function(),
            lhs_sql,
            rhs_sql,
            id_param
        );

        (sql, param_idx)
    }

    /// Get the JSON value for a parameter based on argument type
    fn get_param_value<'a>(
        &self,
        arg_type: ArgumentType,
        encrypted: &'a serde_json::Value,
        sv_element: &'a serde_json::Value,
    ) -> &'a serde_json::Value {
        match arg_type {
            ArgumentType::EncryptedColumn => encrypted,
            ArgumentType::EncryptedParam => encrypted,
            ArgumentType::SvElementParam => sv_element,
        }
    }

    /// Execute query with dynamic bindings based on argument types
    async fn execute_with_bindings(
        &self,
        pool: &PgPool,
        sql: &str,
        encrypted: &serde_json::Value,
        sv_element: &serde_json::Value,
        id: i64,
    ) -> Result<Option<(i64,)>> {
        let lhs_is_param = self.lhs.is_param();
        let rhs_is_param = self.rhs.is_param();

        let result = match (lhs_is_param, rhs_is_param) {
            (false, false) => sqlx::query_as(sql)
                .bind(id)
                .fetch_optional(pool)
                .await
                .with_context(|| {
                    format!(
                        "executing {:?}({:?}, {:?}) with id={}",
                        self.operator, self.lhs, self.rhs, id
                    )
                })?,
            (true, false) => {
                let lhs_val = self.get_param_value(self.lhs, encrypted, sv_element);
                sqlx::query_as(sql)
                    .bind(lhs_val)
                    .bind(id)
                    .fetch_optional(pool)
                    .await
                    .with_context(|| {
                        format!(
                            "executing {:?}({:?}, {:?}) with id={}",
                            self.operator, self.lhs, self.rhs, id
                        )
                    })?
            }
            (false, true) => {
                let rhs_val = self.get_param_value(self.rhs, encrypted, sv_element);
                sqlx::query_as(sql)
                    .bind(rhs_val)
                    .bind(id)
                    .fetch_optional(pool)
                    .await
                    .with_context(|| {
                        format!(
                            "executing {:?}({:?}, {:?}) with id={}",
                            self.operator, self.lhs, self.rhs, id
                        )
                    })?
            }
            (true, true) => {
                let lhs_val = self.get_param_value(self.lhs, encrypted, sv_element);
                let rhs_val = self.get_param_value(self.rhs, encrypted, sv_element);
                sqlx::query_as(sql)
                    .bind(lhs_val)
                    .bind(rhs_val)
                    .bind(id)
                    .fetch_optional(pool)
                    .await
                    .with_context(|| {
                        format!(
                            "executing {:?}({:?}, {:?}) with id={}",
                            self.operator, self.lhs, self.rhs, id
                        )
                    })?
            }
        };

        Ok(result)
    }

    /// Verify that the GIN index is used for this query
    async fn verify_index_usage(
        &self,
        pool: &PgPool,
        table: &str,
        index: &str,
        encrypted: &serde_json::Value,
        sv_element: &serde_json::Value,
    ) -> Result<()> {
        let lhs_sql = match self.lhs {
            ArgumentType::EncryptedColumn => "e".to_string(),
            ArgumentType::EncryptedParam => format!("'{}'::jsonb", encrypted),
            ArgumentType::SvElementParam => format!("'{}'::jsonb", sv_element),
        };

        let rhs_sql = match self.rhs {
            ArgumentType::EncryptedColumn => "e".to_string(),
            ArgumentType::EncryptedParam => format!("'{}'::jsonb", encrypted),
            ArgumentType::SvElementParam => format!("'{}'::jsonb", sv_element),
        };

        let explain_sql = format!(
            "SELECT id FROM {} WHERE {}({}, {}) LIMIT 1",
            table,
            self.operator.sql_function(),
            lhs_sql,
            rhs_sql
        );

        assert_uses_index(pool, &explain_sql, index)
            .await
            .with_context(|| {
                format!(
                    "verifying index usage for {:?}({:?}, {:?})",
                    self.operator, self.lhs, self.rhs
                )
            })?;

        Ok(())
    }

    fn should_verify_index(&self) -> bool {
        match self.operator {
            ContainmentOp::Contains => self.lhs == ArgumentType::EncryptedColumn,
            ContainmentOp::ContainedBy => self.rhs == ArgumentType::EncryptedColumn,
        }
    }

    /// Execute the test case
    async fn run(&self, pool: &PgPool, table: &str, index: &str) -> Result<()> {
        setup_ste_vec_vast_gin_index(pool)
            .await
            .with_context(|| format!("setting up GIN index for {:?} test", self.operator))?;

        let id: i64 = 1;

        let encrypted = get_ste_vec_encrypted(pool, table, id as i32)
            .await
            .with_context(|| {
                format!(
                    "fetching encrypted value for {:?}({:?}, {:?})",
                    self.operator, self.lhs, self.rhs
                )
            })?;
        let sv_element = get_ste_vec_sv_element(pool, table, id as i32, 0)
            .await
            .with_context(|| {
                format!(
                    "fetching sv_element for {:?}({:?}, {:?})",
                    self.operator, self.lhs, self.rhs
                )
            })?;

        let (sql, _param_count) = self.build_query(table);

        let result: Option<(i64,)> = self
            .execute_with_bindings(pool, &sql, &encrypted, &sv_element, id)
            .await?;

        assert!(
            result.is_some(),
            "{:?}({:?}, {:?}) should find match for id={}",
            self.operator,
            self.lhs,
            self.rhs,
            id
        );
        assert_eq!(result.unwrap().0, id);

        if self.should_verify_index() {
            self.verify_index_usage(pool, table, index, &encrypted, &sv_element)
                .await?;
        }

        Ok(())
    }

    /// Execute a negative test case - verifies NO match is returned
    ///
    /// Used for asymmetric containment cases where a partial value (sv_element)
    /// cannot contain a full value, and vice versa.
    async fn run_negative(&self, pool: &PgPool, table: &str, reason: &str) -> Result<()> {
        // 1. Setup GIN index
        setup_ste_vec_vast_gin_index(pool).await.with_context(|| {
            format!("setting up GIN index for negative {:?} test", self.operator)
        })?;

        let id: i64 = 1;

        // 2. Fetch test data
        let encrypted = get_ste_vec_encrypted(pool, table, id as i32)
            .await
            .with_context(|| {
                format!(
                    "fetching encrypted value for negative {:?}({:?}, {:?})",
                    self.operator, self.lhs, self.rhs
                )
            })?;
        let sv_element = get_ste_vec_sv_element(pool, table, id as i32, 0)
            .await
            .with_context(|| {
                format!(
                    "fetching sv_element for negative {:?}({:?}, {:?})",
                    self.operator, self.lhs, self.rhs
                )
            })?;

        // 3. Build query
        let (sql, _param_count) = self.build_query(table);

        // 4. Execute query with appropriate bindings
        let result: Option<(i64,)> = self
            .execute_with_bindings(pool, &sql, &encrypted, &sv_element, id)
            .await?;

        // 5. Assert NO match found (negative test)
        assert!(
            result.is_none(),
            "{:?}({:?}, {:?}) should NOT find match - {}",
            self.operator,
            self.lhs,
            self.rhs,
            reason
        );

        Ok(())
    }
}

// ============================================================================
// Contains Operator Tests via Macro
// ============================================================================

// Encrypted column contains encrypted parameter (self-containment)
containment_test!(
    macro_contains_encrypted_encrypted_param,
    op = Contains,
    lhs = EncryptedColumn,
    rhs = EncryptedParam
);

// Column contains sv element param (element is subset of full value)
containment_test!(
    macro_contains_encrypted_jsonb_param,
    op = Contains,
    lhs = EncryptedColumn,
    rhs = SvElementParam
);

// Encrypted param contains column (self-containment, param position reversed)
containment_test!(
    macro_contains_encrypted_param_encrypted,
    op = Contains,
    lhs = EncryptedParam,
    rhs = EncryptedColumn
);

// ============================================================================
// ContainedBy Operator Tests via Macro
// ============================================================================

// Column contained by encrypted param (self-containment)
containment_test!(
    macro_contained_by_encrypted_encrypted_param,
    op = ContainedBy,
    lhs = EncryptedColumn,
    rhs = EncryptedParam
);

// SV element param contained by column (element is subset of full value)
containment_test!(
    macro_contained_by_jsonb_param_encrypted,
    op = ContainedBy,
    lhs = SvElementParam,
    rhs = EncryptedColumn
);

// Encrypted param contained by column (self-containment, param position reversed)
containment_test!(
    macro_contained_by_encrypted_param_encrypted,
    op = ContainedBy,
    lhs = EncryptedParam,
    rhs = EncryptedColumn
);

// ============================================================================
// Negative Tests: Asymmetric Containment Cases
// ============================================================================
//
// These tests verify that asymmetric containment relationships correctly
// return no match. A single sv_element cannot contain a full encrypted value,
// and a full encrypted value is not contained within a single sv_element.

// SV element param does NOT contain column (element is subset, not superset)
containment_negative_test!(
    macro_contains_jsonb_param_encrypted_no_match,
    op = Contains,
    lhs = SvElementParam,
    rhs = EncryptedColumn,
    "sv_element is a subset of encrypted value, cannot contain the full value"
);

// Column is NOT contained by sv element param (full value not subset of element)
containment_negative_test!(
    macro_contained_by_encrypted_jsonb_param_no_match,
    op = ContainedBy,
    lhs = EncryptedColumn,
    rhs = SvElementParam,
    "encrypted value has more keys than sv_element, cannot be contained in it"
);
