//! Type-generic test matrix for encrypted scalar domains.
//!
//! Two entry points:
//!
//! - **`ordered_numeric_matrix!`** — the recommended wrapper. For an
//!   ordered numeric scalar (i32, i64, f64, date, numeric, timestamp,
//!   ...) all four variants are present, the operator surface is
//!   identical, and the only inputs that change per type are the scalar
//!   itself, the suite token (used to derive domain + test names), the
//!   EQL type name (the fixture `scripts(...)` ref), and the pivot
//!   values. Invocation is ~5 lines.
//!
//! - **`scalar_domain_matrix!`** — the lower-level macro the wrapper
//!   expands to. Use directly only for types with a non-standard surface
//!   (e.g. equality-only scalars like bool).
//!
//! Each invocation emits one `#[sqlx::test]` per (category, domain,
//! operator, pivot) tuple. Categories: sanity, correctness, cross-shape,
//! supported-NULL, blocker raises, index engagement, ORDER BY, ORDER BY
//! USING.
//!
//! Per-domain capability and payload metadata live in `Variant` (see
//! `scalar_domains.rs`); the macro derives the runtime `ScalarDomainSpec`
//! from `<$scalar as ScalarType>::PG_TYPE` + `Variant::<X>` so no
//! per-type constants are needed.

/// Convention wrapper for ordered numeric scalars. Expands to a
/// `scalar_domain_matrix!` invocation with the standard 4 variants, 6
/// supported comparison operators, 2 path operators, and the standard
/// blocker / index partitions.
///
/// `eql_type` is the EQL domain type name (e.g. `"eql_v2_int4"`). It is
/// used as the SQLx fixture `scripts(...)` ref, which sqlx parses as a
/// token-level string literal — so it must be a literal, not derived.
///
/// Pivots — the comparison anchors swept by the correctness / cross-shape
/// arms — are derived from the scalar type: `MIN`, `MAX`, and zero
/// (`Default::default()`). The fixture must contain those three plaintext
/// rows, since each pivot's ciphertext is fetched at test time via
/// `fetch_fixture_payload`.
#[macro_export]
macro_rules! ordered_numeric_matrix {
    (
        suite = $suite:ident,
        scalar = $scalar:ty,
        eql_type = $eql_type:literal $(,)?
    ) => {
        $crate::scalar_domain_matrix! {
            suite = $suite,
            scalar = $scalar,
            eql_type = $eql_type,
            // Relative to the suite source file at
            // tests/sqlx/tests/encrypted_domain/scalars/<T>.rs; sqlx's
            // include_str! resolves it against that file. Every scalar
            // suite lives at this depth, so the path is fixed here rather
            // than repeated per invocation.
            fixture_path = "../../../fixtures",
            all_domains = [(storage, Storage), (eq, Eq), (ord, Ord), (ord_ore, OrdOre)],
            eq_domains = [(eq, Eq), (ord, Ord), (ord_ore, OrdOre)],
            ord_domains = [(ord, Ord), (ord_ore, OrdOre)],
            ord_ore_domains = [(ord_ore, OrdOre)],
            pivots = [
                (min,  <$scalar>::MIN),
                (max,  <$scalar>::MAX),
                (zero, <$scalar as ::core::default::Default>::default()),
            ],
            eq_ops = [(eq, "="), (neq, "<>")],
            ord_ops = [(lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")],
            index_combos = [
                (eq, Eq, "eql_v2.eq_term", "btree", [(eq, "=")]),
                (eq, Eq, "eql_v2.eq_term", "hash", [(eq, "=")]),
                (ord, Ord, "eql_v2.ord_term", "btree",
                    [(eq, "="), (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")]),
                (ord_ore, OrdOre, "eql_v2.ord_term", "btree",
                    [(eq, "="), (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")]),
            ],
            blocker_combos = [
                (storage, Storage, [
                    (eq, "="), (neq, "<>"),
                    (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">="),
                    (contains, "@>"), (contained_by, "<@"),
                ]),
                (eq, Eq, [
                    (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">="),
                    (contains, "@>"), (contained_by, "<@"),
                ]),
                (ord, Ord, [(contains, "@>"), (contained_by, "<@")]),
                (ord_ore, OrdOre, [(contains, "@>"), (contained_by, "<@")]),
            ],
        }
    };
}

/// Convention wrapper for equality-only scalars (no ord variants). Bool
/// is the canonical consumer: `=` / `<>` are meaningful; the four ord
/// operators are deliberate blockers.
///
/// Expands to `scalar_domain_matrix!` with `ord_domains = []`,
/// `ord_ore_domains = []`, no btree-ord index combo, and blocker_combos
/// covering the ord operators on every materialised variant. Order-by /
/// order-by-using arms emit zero tests because they iterate empty
/// ord_domains.
///
/// **Status:** this umbrella has no in-tree consumer yet. It exists so
/// that adding `bool` (or any other equality-only scalar) is one
/// `impl ScalarType` + fixture + one-line macro invocation, with no
/// macro authoring required. Runtime validation lands with bool.
#[macro_export]
macro_rules! eq_only_scalar_matrix {
    (
        suite = $suite:ident,
        scalar = $scalar:ty,
        eql_type = $eql_type:literal,
        pivots = [$($pivot:tt),+ $(,)?] $(,)?
    ) => {
        $crate::scalar_domain_matrix! {
            suite = $suite,
            scalar = $scalar,
            eql_type = $eql_type,
            // Fixed path; see `ordered_numeric_matrix!` for the rationale.
            fixture_path = "../../../fixtures",
            all_domains = [(storage, Storage), (eq, Eq)],
            eq_domains = [(eq, Eq)],
            ord_domains = [],
            ord_ore_domains = [],
            pivots = [$($pivot),+],
            eq_ops = [(eq, "="), (neq, "<>")],
            ord_ops = [(lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")],
            index_combos = [
                (eq, Eq, "eql_v2.eq_term", "btree", [(eq, "=")]),
                (eq, Eq, "eql_v2.eq_term", "hash",  [(eq, "=")]),
            ],
            blocker_combos = [
                (storage, Storage, [
                    (eq, "="), (neq, "<>"),
                    (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">="),
                    (contains, "@>"), (contained_by, "<@"),
                ]),
                (eq, Eq, [
                    (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">="),
                    (contains, "@>"), (contained_by, "<@"),
                ]),
            ],
        }
    };
}

/// Low-level entry point. Use `ordered_numeric_matrix!` instead unless
/// your type's surface deviates from the standard ordered-numeric shape.
#[macro_export]
macro_rules! scalar_domain_matrix {
    (
        suite = $suite:ident,
        scalar = $scalar:ty,
        eql_type = $eql_type:literal,
        fixture_path = $fixture_path:literal,
        all_domains = [$(($all_name:ident, $all_variant:ident)),+ $(,)?],
        eq_domains = [$($eq_dom:tt),+ $(,)?],
        ord_domains = [$($ord_dom:tt),* $(,)?],
        ord_ore_domains = [$($ord_ore_dom:tt),* $(,)?],
        pivots = [$($pivot:tt),+ $(,)?],
        eq_ops = [$($eq_op:tt),+ $(,)?],
        ord_ops = [$($ord_op:tt),+ $(,)?],
        index_combos = [$($index_combo:tt),+ $(,)?],
        blocker_combos = [$($blocker_combo:tt),+ $(,)?] $(,)?
    ) => {
        $crate::__scalar_matrix_sanity! {
            suite = $suite, scalar = $scalar,
            domains = [$(($all_name, $all_variant)),+],
        }
        $crate::__scalar_matrix_dxop_outer! {
            case = __scalar_matrix_correctness_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($eq_dom),+], ops_list = [$($eq_op),+],
            pivots_list = [$($pivot),+],
        }
        $crate::__scalar_matrix_dxop_outer! {
            case = __scalar_matrix_correctness_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*], ops_list = [$($ord_op),+],
            pivots_list = [$($pivot),+],
        }
        $crate::__scalar_matrix_dxop_outer! {
            case = __scalar_matrix_cross_shape_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($eq_dom),+], ops_list = [$($eq_op),+],
            pivots_list = [$($pivot),+],
        }
        $crate::__scalar_matrix_dxop_outer! {
            case = __scalar_matrix_cross_shape_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*], ops_list = [$($ord_op),+],
            pivots_list = [$($pivot),+],
        }
        $crate::__scalar_matrix_dxo_outer! {
            case = __scalar_matrix_supported_null_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($eq_dom),+], ops_list = [$($eq_op),+],
        }
        $crate::__scalar_matrix_dxo_outer! {
            case = __scalar_matrix_supported_null_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*], ops_list = [$($ord_op),+],
        }
        $crate::__scalar_matrix_blocker_outer! {
            suite = $suite, scalar = $scalar,
            combos = [$($blocker_combo),+],
        }
        $crate::__scalar_matrix_payload_check_outer! {
            suite = $suite, scalar = $scalar,
            domains = [$(($all_name, $all_variant)),+],
        }
        $crate::__scalar_matrix_path_op_outer! {
            suite = $suite, scalar = $scalar,
            domains = [$(($all_name, $all_variant)),+],
        }
        $crate::__scalar_matrix_native_absent_outer! {
            suite = $suite, scalar = $scalar,
            domains = [$(($all_name, $all_variant)),+],
        }
        $crate::__scalar_matrix_typed_column_outer! {
            suite = $suite, scalar = $scalar,
            combos = [$($blocker_combo),+],
        }
        $crate::__scalar_matrix_planner_metadata_outer! {
            suite = $suite, scalar = $scalar, group = eq,
            domains = [$($eq_dom),+],
            ops_list = [$($eq_op),+],
        }
        $crate::__scalar_matrix_planner_metadata_outer! {
            suite = $suite, scalar = $scalar, group = ord,
            domains = [$($ord_dom),*],
            ops_list = [$($ord_op),+],
        }
        $crate::__scalar_matrix_index_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            combos = [$($index_combo),+],
        }
        $crate::__scalar_matrix_scale_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            combos = [$($index_combo),+],
        }
        $crate::__scalar_matrix_fixture_shape! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
        }
        $crate::__scalar_matrix_ord_routes_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*],
        }
        $crate::__scalar_matrix_ore_injectivity_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_ore_dom),*],
        }
        $crate::__scalar_matrix_aggregate_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*],
        }
        $crate::__scalar_matrix_aggregate_group_by_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*],
        }
        $crate::__scalar_matrix_aggregate_typecheck_outer! {
            suite = $suite, scalar = $scalar,
            domains = [$(($all_name, $all_variant)),+],
        }
        $crate::__scalar_matrix_count_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$(($all_name, $all_variant)),+],
        }
        $crate::__scalar_matrix_order_by_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*],
        }
        $crate::__scalar_matrix_order_by_nulls_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*],
        }
        $crate::__scalar_matrix_order_by_using_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            domains = [$($ord_dom),*], ops_list = [$($ord_op),+],
        }
    };
}

// ============================================================================
// Helpers: spec construction inside generated test bodies.
// ============================================================================

/// Inside a generated test body, build the runtime `ScalarDomainSpec`
/// from `<$scalar>::PG_TYPE` + `Variant::$variant`. All categories use
/// this — keeps the per-case body short.
#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_spec {
    ($scalar:ty, $variant:ident) => {
        $crate::scalar_domains::ScalarDomainSpec::new::<$scalar>(
            $crate::scalar_domains::Variant::$variant,
        )
    };
}

// ============================================================================
// Sanity category — one test per domain. Cheap thread-through check that
// the macro expanded and the trait wires up.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_sanity {
    (
        suite = $suite:ident,
        scalar = $scalar:ty,
        domains = [$(($name:ident, $variant:ident)),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::paste::paste! {
                #[sqlx::test]
                async fn [<matrix_ $suite _ $name _sanity>](_pool: sqlx::PgPool)
                    -> anyhow::Result<()>
                {
                    let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                    assert!(!spec.sql_domain.is_empty());
                    assert!(<$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name()
                        .starts_with("fixtures."));
                    Ok(())
                }
            }
        )+
    };
}

// ============================================================================
// Shared cartesian-product drivers. `macro_rules!` cannot cross-product
// independent lists in one repetition (`$($($(…)*)*)*` over flat depth-1
// lists does not compile — every metavariable is bound at depth 1), so one
// recursion level fixes one dimension. These generic drivers do that fan-out
// once and dispatch to a per-category leaf macro named by `case`. The
// dimension lists are independent: this is a product, not a zip.
// ============================================================================

// domain × op × pivot.
#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_dxop_outer {
    (
        case = $case:ident,
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$($domain:tt),* $(,)?],
        ops_list = $ops_list:tt, pivots_list = $pivots_list:tt $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_dxop_mid! {
                case = $case,
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                domain = $domain, ops_list = $ops_list, pivots_list = $pivots_list,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_dxop_mid {
    (
        case = $case:ident,
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domain = ($dom_name:ident, $variant:ident),
        ops_list = [$($op:tt),+ $(,)?], pivots_list = $pivots_list:tt $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_dxop_inner! {
                case = $case,
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant,
                op = $op, pivots_list = $pivots_list,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_dxop_inner {
    (
        case = $case:ident,
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op = ($op_name:ident, $op:literal),
        pivots_list = [$($pivot:tt),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::$case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant,
                op_name = $op_name, op = $op, pivot = $pivot,
            }
        )+
    };
}

// domain × op.
#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_dxo_outer {
    (
        case = $case:ident,
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$($domain:tt),* $(,)?], ops_list = $ops_list:tt $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_dxo_inner! {
                case = $case,
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                domain = $domain, ops_list = $ops_list,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_dxo_inner {
    (
        case = $case:ident,
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domain = ($dom_name:ident, $variant:ident),
        ops_list = [$($op:tt),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::$case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant, op = $op,
            }
        )+
    };
}

// ============================================================================
// Correctness category — leaf for the domain × op × pivot driver: assert the
// row set from `WHERE col op pivot` matches `T::expected_forward(op, pivot)`.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_correctness_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op_name = $op_name:ident, op = $op:literal,
        pivot = ($pivot_name:ident, $pivot_val:expr) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _ $op_name _pivot_ $pivot_name _correctness>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let pivot: $scalar = $pivot_val;
                let payload =
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, pivot).await?;
                let lit = $crate::scalar_domains::sql_string_literal(&payload);
                let predicate = format!(
                    "payload::{d} {op} {lit}::jsonb::{d}",
                    d = &spec.sql_domain, op = $op,
                );
                let expected =
                    <$scalar as $crate::scalar_domains::ScalarType>::expected_forward($op, pivot);
                $crate::scalar_domains::assert_scalar_plaintexts::<$scalar>(
                    &pool, &spec.sql_domain, $op, &predicate, &expected,
                )
                .await
            }
        }
    };
}

// ============================================================================
// Cross-shape category — leaf for the domain × op × pivot driver: per
// (domain, op, pivot) sweep the three operator argument shapes (d,d), (d,j),
// (j,d) and assert each returns the right row count. The `j_d` shape uses the
// commuted operator's expected set.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_cross_shape_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op_name = $op_name:ident, op = $op:literal,
        pivot = ($pivot_name:ident, $pivot_val:expr) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _ $op_name _pivot_ $pivot_name _cross_shape>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let pivot: $scalar = $pivot_val;
                let payload =
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, pivot).await?;
                let lit = $crate::scalar_domains::sql_string_literal(&payload);
                let forward_count =
                    <$scalar as $crate::scalar_domains::ScalarType>::expected_forward($op, pivot)
                        .len() as i64;
                let commuted_count = <$scalar as $crate::scalar_domains::ScalarType>::expected_forward(
                    $crate::scalar_domains::commute_op($op), pivot,
                ).len() as i64;
                let d = &spec.sql_domain;
                let shapes = [
                    ("d_d", format!("payload::{d} {op} {lit}::jsonb::{d}", op = $op), forward_count),
                    ("d_j", format!("payload::{d} {op} {lit}::jsonb", op = $op), forward_count),
                    ("j_d", format!("{lit}::jsonb {op} payload::{d}", op = $op), commuted_count),
                ];
                let table = <$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name();
                for (shape_label, predicate, expected_count) in shapes {
                    let count_sql = format!("SELECT count(*) FROM {table} WHERE {predicate}");
                    let count: i64 = sqlx::query_scalar(&count_sql).fetch_one(&pool).await?;
                    assert_eq!(
                        count, expected_count,
                        "domain={} op={} pivot={:?} shape={shape_label} SQL={count_sql} \
                         expected {expected_count} rows, got {count}",
                        d, $op, pivot
                    );
                }
                Ok(())
            }
        }
    };
}

// ============================================================================
// Supported-NULL category — leaf for the domain × op driver: STRICT wrappers
// must propagate NULL on all three NULL positions (left, right, both).
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_supported_null_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op = ($op_name:ident, $op:literal) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _ $op_name _supported_null>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let payload = $crate::helpers::PLACEHOLDER_PAYLOAD;
                let sql = format!(
                    "SELECT $1::jsonb::{d} {op} $2::jsonb::{d}",
                    d = &spec.sql_domain, op = $op,
                );
                $crate::scalar_domains::assert_null(&pool, &sql, &[Some(payload), None]).await?;
                $crate::scalar_domains::assert_null(&pool, &sql, &[None, Some(payload)]).await?;
                $crate::scalar_domains::assert_null(&pool, &sql, &[None, None]).await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Blocker category — per blocked (domain, op), sweep 3 arg shapes (all
// must raise) and 3 NULL positions on the (d, d) shape (non-STRICT proof).
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_blocker_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        combos = [$($combo:tt),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_blocker_combo! {
                suite = $suite, scalar = $scalar, combo = $combo,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_blocker_combo {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        combo = ($dom_name:ident, $variant:ident, [$($op:tt),+ $(,)?]) $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_blocker_case! {
                suite = $suite, scalar = $scalar,
                dom_name = $dom_name, variant = $variant, op = $op,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_blocker_case {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op = ($op_name:ident, $op:literal) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _ $op_name _blocker>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let payload = $crate::helpers::PLACEHOLDER_PAYLOAD;
                let msg = $crate::scalar_domains::blocker_msg(&spec.sql_domain, $op);
                let d = &spec.sql_domain;

                // Sweep 3 arg shapes — every overload must engage.
                let shapes: [(String, String); 3] = [
                    (format!("$1::jsonb::{d}"), format!("$2::jsonb::{d}")),
                    (format!("$1::jsonb::{d}"), "$2::jsonb".into()),
                    ("$1::jsonb".into(), format!("$2::jsonb::{d}")),
                ];
                for (lhs, rhs) in shapes {
                    let sql = format!("SELECT {lhs} {op} {rhs}", op = $op);
                    $crate::scalar_domains::assert_raises(
                        &pool, &sql, &[Some(payload), Some(payload)], &msg,
                    ).await?;
                }

                // Sweep 3 NULL positions on the (d, d) shape — blockers
                // are non-STRICT so they must engage on every NULL config.
                let null_sql = format!(
                    "SELECT $1::jsonb::{d} {op} $2::jsonb::{d}", op = $op,
                );
                $crate::scalar_domains::assert_raises(&pool, &null_sql, &[None, Some(payload)], &msg).await?;
                $crate::scalar_domains::assert_raises(&pool, &null_sql, &[Some(payload), None], &msg).await?;
                $crate::scalar_domains::assert_raises(&pool, &null_sql, &[None, None], &msg).await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Payload-check category — per variant, the domain CHECK rejects payloads
// missing required keys (envelope `v`/`i`/`c` plus `Variant::required_term()`)
// and rejects non-object payloads. Required keys are derived from
// `Variant::payload_required_keys()` so future variants pick up coverage.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_payload_check_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        domains = [$(($dom_name:ident, $variant:ident)),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_payload_check_case! {
                suite = $suite, scalar = $scalar,
                dom_name = $dom_name, variant = $variant,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_payload_check_case {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _payload_check>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let baseline = $crate::helpers::PLACEHOLDER_PAYLOAD;

                // Each required key must trigger CHECK rejection when stripped.
                for key in spec.variant.payload_required_keys() {
                    let sql = format!(
                        "SELECT ('{baseline}'::jsonb - '{key}')::{d}",
                    );
                    let err = sqlx::query(&sql)
                        .fetch_one(&pool)
                        .await
                        .expect_err(&format!(
                            "{d} must reject payload missing `{key}`: {sql}"
                        ))
                        .to_string();
                    anyhow::ensure!(
                        err.contains("violates check constraint"),
                        "expected check-constraint violation for missing `{key}` on {d}, got: {err}",
                    );
                }

                // Non-object payloads are rejected for every variant.
                let sql = format!(r#"SELECT '["v","i","c"]'::jsonb::{d}"#);
                let err = sqlx::query(&sql)
                    .fetch_one(&pool)
                    .await
                    .expect_err(&format!("{d} must reject non-object payload"))
                    .to_string();
                anyhow::ensure!(
                    err.contains("violates check constraint"),
                    "expected check-constraint violation for non-object on {d}, got: {err}",
                );
                Ok(())
            }
        }
    };
}

// ============================================================================
// Path-operator category — `->` and `->>` must raise the blocker on every
// variant (encrypted domains don't expose JSON path access). Three arg
// shapes per op, matching the parameter blocker arm's coverage.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_path_op_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        domains = [$(($dom_name:ident, $variant:ident)),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_path_op_case! {
                suite = $suite, scalar = $scalar,
                dom_name = $dom_name, variant = $variant,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_path_op_case {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _path_op_blockers>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let payload = $crate::helpers::PLACEHOLDER_PAYLOAD;

                for op in ["->", "->>"] {
                    let msg = $crate::scalar_domains::blocker_msg(d, op);
                    for sql in [
                        format!("SELECT $1::jsonb::{d} {op} 'field'::text"),
                        format!("SELECT $1::jsonb::{d} {op} 0::integer"),
                        format!("SELECT $1::jsonb {op} $1::jsonb::{d}"),
                    ] {
                        $crate::scalar_domains::assert_raises(
                            &pool, &sql, &[Some(payload)], &msg,
                        ).await?;
                    }
                }
                Ok(())
            }
        }
    };
}

// ============================================================================
// Native-absent category — `~~` / `~~*` (LIKE / ILIKE) are deliberately
// not declared on encrypted-domain types (no pattern-match capability),
// so resolution falls back to PostgreSQL's "operator does not exist"
// rather than an EQL blocker. Pin that they stay absent on every variant.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_native_absent_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        domains = [$(($dom_name:ident, $variant:ident)),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_native_absent_case! {
                suite = $suite, scalar = $scalar,
                dom_name = $dom_name, variant = $variant,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_native_absent_case {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _native_absent_ops>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let payload = $crate::helpers::PLACEHOLDER_PAYLOAD;

                for op in ["~~", "~~*"] {
                    let sql = format!("SELECT $1::jsonb::{d} {op} $2::jsonb::{d}");
                    $crate::scalar_domains::assert_raises(
                        &pool, &sql,
                        &[Some(payload), Some(payload)],
                        "operator does not exist",
                    ).await?;
                }
                Ok(())
            }
        }
    };
}

// ============================================================================
// Typed-column blocker category — pins the bare `WHERE col op col` form a
// real caller writes. The parameter blocker arm uses $1/$2 binds; this
// form resolves the same overloads through a different planner path
// (column-typed operand vs. cast-expression operand). One test per
// (variant, blocker-ops list), savepoint-isolated to avoid abort.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_typed_column_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        combos = [$($combo:tt),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_typed_column_case! {
                suite = $suite, scalar = $scalar, combo = $combo,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_typed_column_case {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        combo = ($dom_name:ident, $variant:ident, [$(($op_name:ident, $op:literal)),+ $(,)?]) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _typed_column_blocker>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let payload = $crate::helpers::PLACEHOLDER_PAYLOAD;

                let mut tx = pool.begin().await?;
                let create_sql = format!(
                    "CREATE TEMP TABLE typed_col (\
                         id integer GENERATED ALWAYS AS IDENTITY,\
                         value {d}\
                     ) ON COMMIT DROP"
                );
                sqlx::query(&create_sql).execute(&mut *tx).await?;
                let insert_sql = format!(
                    "INSERT INTO typed_col(value) VALUES ($1::jsonb::{d})"
                );
                sqlx::query(&insert_sql).bind(payload).execute(&mut *tx).await?;

                $(
                    sqlx::query("SAVEPOINT op_probe").execute(&mut *tx).await?;
                    let sql = format!("SELECT * FROM typed_col WHERE value {op} value", op = $op);
                    let err = sqlx::query(&sql)
                        .fetch_all(&mut *tx)
                        .await
                        .expect_err(&format!("{d} column {op} must raise", op = $op))
                        .to_string();
                    let expected = $crate::scalar_domains::blocker_msg(d, $op);
                    anyhow::ensure!(
                        err.contains(&expected),
                        "unexpected error for {sql}: got {err}, want {expected}",
                    );
                    sqlx::query("ROLLBACK TO SAVEPOINT op_probe").execute(&mut *tx).await?;
                )+

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Planner-metadata category — for every (variant, supported-op) the
// declared operator must carry COMMUTATOR, NEGATOR, and the RESTRICT /
// JOIN selectivity estimators on all 3 arg-shapes. Without these the
// planner cannot normalise commuted/negated predicates or cost them.
// Called twice from `scalar_domain_matrix!`: once for (eq_domains,
// eq_ops), once for (ord_domains, ord_ops). Storage variants have no
// supported ops and so don't emit a test.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_planner_metadata_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, group = $group:ident,
        domains = [$(($dom_name:ident, $variant:ident)),* $(,)?],
        ops_list = $ops_list:tt $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_planner_metadata_case! {
                suite = $suite, scalar = $scalar, group = $group,
                dom_name = $dom_name, variant = $variant,
                ops_list = $ops_list,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_planner_metadata_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, group = $group:ident,
        dom_name = $dom_name:ident, variant = $variant:ident,
        ops_list = [$(($op_name:ident, $op:literal)),+ $(,)?] $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _planner_metadata_ $group>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let ops: &[&str] = &[$($op),+];
                let op_list = ops.iter()
                    .map(|o| format!("'{o}'"))
                    .collect::<Vec<_>>()
                    .join(", ");
                let sql = format!(
                    r#"
                    SELECT o.oprname,
                           lt.typname AS lhs,
                           rt.typname AS rhs,
                           o.oprcom <> 0       AS has_commutator,
                           o.oprnegate <> 0    AS has_negator,
                           o.oprrest::oid <> 0 AS has_restrict,
                           o.oprjoin::oid <> 0 AS has_join
                    FROM pg_catalog.pg_operator o
                    JOIN pg_catalog.pg_type lt ON lt.oid = o.oprleft
                    JOIN pg_catalog.pg_type rt ON rt.oid = o.oprright
                    WHERE o.oprname IN ({op_list})
                      AND (lt.typname = '{d}' OR rt.typname = '{d}')
                    "#
                );
                let rows: Vec<(String, String, String, bool, bool, bool, bool)> =
                    sqlx::query_as(&sql).fetch_all(&pool).await?;

                let expected = ops.len() * 3;
                anyhow::ensure!(
                    rows.len() == expected,
                    "expected {expected} rows ({n_ops} ops x 3 arg shapes) on {d}, got {got}",
                    n_ops = ops.len(),
                    got = rows.len(),
                );
                for (op, lhs, rhs, has_com, has_neg, has_rest, has_join) in &rows {
                    anyhow::ensure!(*has_com,
                        "operator {op}({lhs},{rhs}) must declare COMMUTATOR");
                    anyhow::ensure!(*has_neg,
                        "operator {op}({lhs},{rhs}) must declare NEGATOR");
                    anyhow::ensure!(*has_rest,
                        "operator {op}({lhs},{rhs}) must declare RESTRICT");
                    anyhow::ensure!(*has_join,
                        "operator {op}({lhs},{rhs}) must declare JOIN");
                }
                Ok(())
            }
        }
    };
}

// ============================================================================
// Scale-preference category — feature-gated. Builds a temp table with
// ~5000 filler rows plus one selective pivot, creates the functional
// index, and asserts the planner *prefers* the index with
// `enable_seqscan` left on. The index_engages arm forces seqscan off and
// only proves the index is *usable*; this proves the planner picks it.
// Off by default (`#[cfg(feature = "scale")]`) so PR CI stays fast.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_scale_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        combos = [$($combo:tt),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_scale_case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path, combo = $combo,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_scale_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        combo = (
            $dom_name:ident, $variant:ident,
            $extractor:literal, $using:literal,
            [$(($op_name:ident, $op:literal)),+ $(,)?] $(,)?
        ) $(,)?
    ) => {
        $crate::paste::paste! {
            #[cfg(feature = "scale")]
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _scale_preference_ $using>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let table = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name),
                    "_scale_", $using,
                );
                let index = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name),
                    "_scale_", $using, "_idx",
                );

                let values: &[$scalar] = <$scalar as ScalarType>::FIXTURE_VALUES;
                anyhow::ensure!(values.len() >= 2,
                    "scale test requires >= 2 fixture rows for distinct filler/pivot");
                let filler = values[0];
                let pivot = values[values.len() / 2];
                let filler_payload =
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, filler).await?;
                let pivot_payload =
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, pivot).await?;

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE {table} (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO {table}(value) \
SELECT $1::jsonb::{d} FROM generate_series(1, 5000)",
                )).bind(&filler_payload).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO {table}(value) VALUES ($1::jsonb::{d})",
                )).bind(&pivot_payload).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "CREATE INDEX {index} ON {table} USING {using} ({extractor}(value))", using = $using, extractor = $extractor,
                )).execute(&mut *tx).await?;
                sqlx::query(&format!("ANALYZE {table}"))
                    .execute(&mut *tx).await?;

                let lit = pivot_payload.replace('\'', "''");
                let plan: Vec<String> = sqlx::query_scalar(&format!(
                    "EXPLAIN SELECT * FROM {table} WHERE value = '{lit}'::jsonb::{d}",
                )).fetch_all(&mut *tx).await?;
                let plan_text = plan.join("\n");
                anyhow::ensure!(plan_text.contains(index),
                    "with seqscan enabled the planner must prefer the {extractor} \
{using} index for a selective = ; plan:\n{plan_text}",
                    extractor = $extractor, using = $using,
                );

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Fixture-shape category — one test per type that pins the fixture's
// structural invariants: row count matches `T::FIXTURE_VALUES.len()`,
// ids are sequential from 1, plaintext column matches FIXTURE_VALUES in
// order, every payload carries the variant terms (`hm`, `ob`, `c`),
// distinct plaintexts produce distinct hm terms, every payload declares
// `v=2`. A single test runs all assertions to keep pool-setup cost
// bounded.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_fixture_shape {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _fixture_shape>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let table = <$scalar as ScalarType>::fixture_table_name();
                let expected: &[$scalar] = <$scalar as ScalarType>::FIXTURE_VALUES;
                let n = expected.len() as i64;

                let count: i64 = sqlx::query_scalar(&format!(
                    "SELECT COUNT(*) FROM {table}",
                )).fetch_one(&pool).await?;
                anyhow::ensure!(count == n,
                    "row count must match FIXTURE_VALUES.len(): want {n}, got {count}");

                let ids: Vec<i64> = sqlx::query_scalar(&format!(
                    "SELECT id FROM {table} ORDER BY id",
                )).fetch_all(&pool).await?;
                anyhow::ensure!(ids == (1..=n).collect::<Vec<i64>>(),
                    "ids must be sequential from 1: got {ids:?}");

                let plaintexts: Vec<$scalar> = sqlx::query_scalar(&format!(
                    "SELECT plaintext FROM {table} ORDER BY id",
                )).fetch_all(&pool).await?;
                anyhow::ensure!(plaintexts == expected,
                    "plaintext column must match FIXTURE_VALUES in order");

                for (label, predicate) in [
                    ("hm string", "payload->'hm' IS NULL OR jsonb_typeof(payload->'hm') <> 'string'"),
                    ("ob array",  "payload->'ob' IS NULL OR jsonb_typeof(payload->'ob') <> 'array'"),
                    ("c string",  "payload->'c'  IS NULL OR jsonb_typeof(payload->'c')  <> 'string'"),
                ] {
                    let missing: i64 = sqlx::query_scalar(&format!(
                        "SELECT COUNT(*) FROM {table} WHERE {predicate}",
                    )).fetch_one(&pool).await?;
                    anyhow::ensure!(missing == 0,
                        "every payload must carry a `{label}` term; missing = {missing}");
                }

                let distinct_hm: i64 = sqlx::query_scalar(&format!(
                    "SELECT COUNT(DISTINCT payload->>'hm') FROM {table}",
                )).fetch_one(&pool).await?;
                anyhow::ensure!(distinct_hm == n,
                    "{n} distinct values -> {n} distinct hm terms; got {distinct_hm}");

                let mismatched_version: i64 = sqlx::query_scalar(&format!(
                    "SELECT COUNT(*) FROM {table} \
                     WHERE payload->'v' IS NULL OR payload->>'v' <> '2'",
                )).fetch_one(&pool).await?;
                anyhow::ensure!(mismatched_version == 0,
                    "every payload must declare v = '2'");

                // Value-filtering oracle: take the midpoint of FIXTURE_VALUES,
                // derive its expected id from position, assert exactly one row.
                if !expected.is_empty() {
                    let probe = expected[expected.len() / 2];
                    let probe_lit = <$scalar as ScalarType>::to_sql_literal(probe);
                    let expected_id = (expected.len() / 2 + 1) as i64;
                    let ids: Vec<i64> = sqlx::query_scalar(&format!(
                        "SELECT id FROM {table} WHERE plaintext = {lit} ORDER BY id", lit = probe_lit,
                    )).fetch_all(&pool).await?;
                    anyhow::ensure!(ids == vec![expected_id],
                        "expected exactly one row with plaintext = {probe:?} at id {expected_id}, got {ids:?}");
                }

                Ok(())
            }
        }
    };
}

// ============================================================================
// Ord-routes-through-ob category — ordered variants carry `c + ob` and
// drop `hm`. Equality on an ord variant must therefore route through
// `eql_v2.ord_term` (the `ob` term), never HMAC. Strip `hm` from every
// fixture payload so an accidental regression to HMAC equality fails
// rather than passing on the hm-carrying fixture.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_ord_routes_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$(($dom_name:ident, $variant:ident)),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_ord_routes_case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_ord_routes_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _ord_routes_through_ob>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let table = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name), "_no_hm",
                );
                let index = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name), "_no_hm_idx",
                );
                let fixture_table =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name();
                let pivot: $scalar =
                    <$scalar as $crate::scalar_domains::ScalarType>::FIXTURE_VALUES[0];
                let pivot_lit =
                    <$scalar as $crate::scalar_domains::ScalarType>::to_sql_literal(pivot);

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE {table} (plaintext {pg}, value {d}) ON COMMIT DROP",
                    pg = <$scalar as $crate::scalar_domains::ScalarType>::PG_TYPE,
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO {table}(plaintext, value) \
                     SELECT plaintext, (payload - 'hm')::{d} FROM {fixture}", fixture = fixture_table,
                )).execute(&mut *tx).await?;
                let with_hm: i64 = sqlx::query_scalar(&format!(
                    "SELECT count(*) FROM {table} WHERE jsonb_exists(value::jsonb, 'hm')",
                )).fetch_one(&mut *tx).await?;
                anyhow::ensure!(with_hm == 0, "test rows must not carry hm");

                sqlx::query(&format!(
                    "CREATE INDEX {index} ON {table} USING btree (eql_v2.ord_term(value))",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!("ANALYZE {table}"))
                    .execute(&mut *tx).await?;
                sqlx::query("SET LOCAL enable_seqscan = off")
                    .execute(&mut *tx).await?;

                let pivot_payload: String = sqlx::query_scalar(&format!(
                    "SELECT (payload - 'hm')::text FROM {fixture} WHERE plaintext = {lit}",
                    fixture = fixture_table, lit = pivot_lit,
                )).fetch_one(&mut *tx).await?;

                let eq_count: i64 = sqlx::query_scalar(&format!(
                    "SELECT count(*) FROM {table} WHERE value = $1::jsonb::{d}",
                )).bind(&pivot_payload).fetch_one(&mut *tx).await?;
                anyhow::ensure!(eq_count >= 1,
                    "= must match the pivot row via ob with no hm present");

                let expected_neq =
                    <$scalar as $crate::scalar_domains::ScalarType>::FIXTURE_VALUES.len() as i64
                    - eq_count;
                let neq_count: i64 = sqlx::query_scalar(&format!(
                    "SELECT count(*) FROM {table} WHERE value <> $1::jsonb::{d}",
                )).bind(&pivot_payload).fetch_one(&mut *tx).await?;
                anyhow::ensure!(neq_count == expected_neq,
                    "<> must match every non-pivot fixture row (want {expected_neq}, got {neq_count})",
                );

                let lit = pivot_payload.replace('\'', "''");
                let plan: Vec<String> = sqlx::query_scalar(&format!(
                    "EXPLAIN SELECT * FROM {table} WHERE value = '{lit}'::jsonb::{d}",
                )).fetch_all(&mut *tx).await?;
                let plan_text = plan.join("\n");
                anyhow::ensure!(plan_text.contains(index),
                    "= must engage the eql_v2.ord_term functional btree with no hm; plan:\n{plan_text}",
                );

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// ORE-injectivity category — for OrdOre variants, distinct plaintexts in
// the fixture must produce distinct ORE blocks. Pairwise self-join over
// the fixture: zero collisions.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_ore_injectivity_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$(($dom_name:ident, $variant:ident)),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_ore_injectivity_case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_ore_injectivity_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _ore_injectivity>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let fixture_table =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name();
                let collisions: i64 = sqlx::query_scalar(&format!(
                    "SELECT count(*) \
FROM {fixture} a \
JOIN {fixture} b ON a.id < b.id \
WHERE a.payload::{d} = b.payload::{d}",
                    fixture = fixture_table,
                )).fetch_one(&pool).await?;
                anyhow::ensure!(collisions == 0,
                    "no two distinct plaintexts may share an ORE term on {d}");
                Ok(())
            }
        }
    };
}

// ============================================================================
// Index-engagement category — per (domain, extractor, using, ops) build a
// typed temp table from the fixture, create the functional index, sweep
// ops × rhs-casts asserting EXPLAIN includes the index name.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_index_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        combos = [$($combo:tt),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_index_case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path, combo = $combo,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_index_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        combo = (
            $dom_name:ident, $variant:ident,
            $extractor:literal, $using:literal,
            [$(($op_name:ident, $op:literal)),+ $(,)?] $(,)?
        ) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _index_engages_ $using>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let table = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name),
                    "_idx_", $using,
                );
                let index = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name),
                    "_idx_", $using, "_idx",
                );
                let fixture_table =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name();
                let mut tx = pool.begin().await?;

                sqlx::query(&format!(
                    "CREATE TEMP TABLE {table} (plaintext {pg}, value {d}) ON COMMIT DROP",
                    pg = <$scalar as $crate::scalar_domains::ScalarType>::PG_TYPE,
                    d = &spec.sql_domain,
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO {table}(plaintext, value) \
                     SELECT plaintext, payload::{d} FROM {fixture}", d = &spec.sql_domain, fixture = fixture_table,
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "CREATE INDEX {index} ON {table} USING {using} ({extractor}(value))", using = $using, extractor = $extractor,
                )).execute(&mut *tx).await?;
                sqlx::query(&format!("ANALYZE {table}"))
                    .execute(&mut *tx).await?;
                sqlx::query("SET LOCAL enable_seqscan = off").execute(&mut *tx).await?;

                let pivot: $scalar = <$scalar as $crate::scalar_domains::ScalarType>::FIXTURE_VALUES[0];
                let payload =
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, pivot).await?;
                let lit = $crate::scalar_domains::sql_string_literal(&payload);

                let rhs_casts = [format!("::{d}", d = &spec.sql_domain), String::new()];
                $(
                    for rhs_cast in &rhs_casts {
                        let sql = format!(
                            "EXPLAIN SELECT * FROM {table} WHERE value {op} {lit}::jsonb{cast}", op = $op, cast = rhs_cast,
                        );
                        let plan: Vec<String> =
                            sqlx::query_scalar(&sql).fetch_all(&mut *tx).await?;
                        let plan_text = plan.join("\n");
                        assert!(
                            plan_text.contains(index),
                            "domain={} op={} rhs_cast={} SQL={} must use index={}; plan:\n{plan_text}",
                            &spec.sql_domain, $op, rhs_cast, sql, index
                        );
                    }
                )+

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// ORDER BY category — per ord domain × {ASC,DESC} × {no-WHERE, WHERE>0}.
// Fixture has no NULL plaintexts so NULLS FIRST/LAST is moot.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$($domain:tt),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_order_by_domain! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path, domain = $domain,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_domain {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domain = ($dom_name:ident, $variant:ident) $(,)?
    ) => {
        $crate::__scalar_matrix_order_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = asc_no_where, direction = "ASC", where_clause = "",
        }
        $crate::__scalar_matrix_order_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = desc_no_where, direction = "DESC", where_clause = "",
        }
        $crate::__scalar_matrix_order_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = asc_with_where, direction = "ASC",
            where_clause = " WHERE plaintext > 0",
        }
        $crate::__scalar_matrix_order_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = desc_with_where, direction = "DESC",
            where_clause = " WHERE plaintext > 0",
        }
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        mode_name = $mode_name:ident, direction = $direction:literal,
        where_clause = $where_clause:literal $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _order_by_ $mode_name>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let fixture_table =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name();
                let sql = format!(
                    "SELECT plaintext FROM {fixture}{where_clause} \
ORDER BY eql_v2.ord_term(payload::{d}) {dir}",
                    fixture = fixture_table, where_clause = $where_clause,
                    d = &spec.sql_domain, dir = $direction,
                );
                let actual: Vec<$scalar> = sqlx::query_scalar(&sql).fetch_all(&pool).await?;

                let zero: $scalar = Default::default();
                let mut expected: Vec<$scalar> =
                    <$scalar as $crate::scalar_domains::ScalarType>::FIXTURE_VALUES.to_vec();
                expected.sort();
                if $where_clause.contains("plaintext > 0") {
                    expected.retain(|v| *v > zero);
                }
                if $direction == "DESC" { expected.reverse(); }

                assert_eq!(actual, expected,
                    "domain={} mode={} SQL={} expected {:?}, got {:?}",
                    &spec.sql_domain, stringify!($mode_name), sql, expected, actual);
                Ok(())
            }
        }
    };
}

// ============================================================================
// ORDER BY NULLS FIRST/LAST category — per ord domain × {ASC,DESC} ×
// {NULLS FIRST, NULLS LAST}. The plain ORDER BY arm above sorts the fixture,
// which has no NULL rows, so NULLS placement goes untested there. This arm
// builds an isolated temp table mixing NULL-valued rows with the fixture rows
// and pins that the NULL sort keys land at the requested end while the
// non-NULL rows stay in plaintext order. `eql_v2.ord_term` is STRICT, so a
// NULL domain value yields a NULL sort key; a regression making it non-STRICT
// would let NULL rows interleave — see the `family::mutations` negative
// control for that dimension.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_nulls_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$($domain:tt),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_order_by_nulls_domain! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path, domain = $domain,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_nulls_domain {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domain = ($dom_name:ident, $variant:ident) $(,)?
    ) => {
        $crate::__scalar_matrix_order_by_nulls_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = asc_nulls_first, direction = "ASC", nulls = "FIRST",
        }
        $crate::__scalar_matrix_order_by_nulls_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = asc_nulls_last, direction = "ASC", nulls = "LAST",
        }
        $crate::__scalar_matrix_order_by_nulls_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = desc_nulls_first, direction = "DESC", nulls = "FIRST",
        }
        $crate::__scalar_matrix_order_by_nulls_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = desc_nulls_last, direction = "DESC", nulls = "LAST",
        }
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_nulls_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        mode_name = $mode_name:ident, direction = $direction:literal, nulls = $nulls:literal $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _order_by_ $mode_name>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                // Number of NULL-valued rows mixed in; >1 proves they cluster.
                const NULL_ROWS: usize = 3;

                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let table = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name),
                    "_order_by_", stringify!($mode_name),
                );
                let fixture_table =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name();
                let pg = <$scalar as $crate::scalar_domains::ScalarType>::PG_TYPE;

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE {table} (plaintext {pg}, value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                // Non-NULL rows: every fixture row, carrying its plaintext.
                sqlx::query(&format!(
                    "INSERT INTO {table}(plaintext, value) \
                     SELECT plaintext, payload::{d} FROM {fixture}", fixture = fixture_table,
                )).execute(&mut *tx).await?;
                // NULL-valued rows: NULL plaintext too, so they surface as None
                // and their position is what the assertion pins.
                sqlx::query(&format!(
                    "INSERT INTO {table}(plaintext, value) \
                     SELECT NULL::{pg}, NULL::{d} FROM generate_series(1, {n})", n = NULL_ROWS,
                )).execute(&mut *tx).await?;

                let sql = format!(
                    "SELECT plaintext FROM {table} \
                     ORDER BY eql_v2.ord_term(value) {dir} NULLS {nulls}",
                    dir = $direction, nulls = $nulls,
                );
                let actual: Vec<Option<$scalar>> =
                    sqlx::query_scalar(&sql).fetch_all(&mut *tx).await?;

                // Ground truth: non-NULL plaintexts sorted (reversed for DESC),
                // with NULL_ROWS Nones at the requested end.
                let mut non_null: Vec<$scalar> =
                    <$scalar as $crate::scalar_domains::ScalarType>::FIXTURE_VALUES.to_vec();
                non_null.sort();
                if $direction == "DESC" { non_null.reverse(); }
                let sorted = non_null.into_iter().map(Some);
                let mut expected: Vec<Option<$scalar>> = Vec::new();
                if $nulls == "FIRST" {
                    expected.extend(std::iter::repeat(None).take(NULL_ROWS));
                    expected.extend(sorted);
                } else {
                    expected.extend(sorted);
                    expected.extend(std::iter::repeat(None).take(NULL_ROWS));
                }

                assert_eq!(actual, expected,
                    "domain={} mode={} SQL={} expected {:?}, got {:?}",
                    d, stringify!($mode_name), sql, expected, actual);

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// ORDER BY USING <op> category — every op × ord domain must reject
// `ORDER BY col USING <op>` because the design forbids opclasses on
// these domains. If a refactor accidentally adds one, this fails.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_using_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$($domain:tt),* $(,)?], ops_list = $ops_list:tt $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_order_by_using_inner! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                domain = $domain, ops_list = $ops_list,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_using_inner {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domain = ($dom_name:ident, $variant:ident),
        ops_list = [$(($op_name:ident, $op:literal)),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_order_by_using_case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant,
                op_name = $op_name, op = $op,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_order_by_using_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op_name = $op_name:ident, op = $op:literal $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _order_by_using_ $op_name _rejects>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let fixture_table =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_table_name();
                let sql = format!(
                    "SELECT plaintext FROM {fixture} ORDER BY payload::{d} USING {op}",
                    fixture = fixture_table, d = &spec.sql_domain, op = $op,
                );
                let err = sqlx::query_scalar::<_, $scalar>(&sql)
                    .fetch_all(&pool)
                    .await
                    .expect_err(&format!(
                        "domain={} op={} SQL={} must reject ORDER BY USING (no opclass on \
domain by design) but succeeded",
                        &spec.sql_domain, $op, sql,
                    ));
                // SQLSTATE 42809 (wrong_object_type) — "operator X is not a
                // valid ordering operator". The boolean operator exists on the
                // domain but lacks a btree opclass entry, so ORDER BY USING
                // refuses to use it. Pinning this catches the regression where
                // a stray opclass would make ORDER BY USING start succeeding
                // for the wrong reason — `is_err()` alone could not.
                $crate::assert_db_error(&err, "42809", None);
                Ok(())
            }
        }
    };
}

// ============================================================================
// Aggregate category — per (ord domain, op ∈ {min, max}), three tests:
// extremum identity (payload of the min/max FIXTURE_VALUES row), all-NULL
// returns NULL, and mixed NULL/non-NULL returns the correct extremum from
// the non-NULL subset. Pins that `eql_v2.min` / `eql_v2.max` aggregates
// route through the domain's `<` / `>` and that the STRICT state function
// correctly seeds + skips NULLs. Emits zero tests when ord_domains is
// empty — eq-only umbrellas pick that up naturally.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$($domain:tt),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_aggregate_mid! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                domain = $domain,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_mid {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domain = ($dom_name:ident, $variant:ident) $(,)?
    ) => {
        $crate::__scalar_matrix_aggregate_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            op_name = min, agg_fn = "min", picker = min,
        }
        $crate::__scalar_matrix_aggregate_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            op_name = max, agg_fn = "max", picker = max,
        }
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op_name = $op_name:ident, agg_fn = $agg_fn:literal, picker = $picker:ident $(,)?
    ) => {
        $crate::paste::paste! {
            // Extremum identity: aggregate returns the exact payload of the
            // smallest (or largest) fixture row. Domain-cast on both sides
            // so the comparator routes through the variant's `<` / `>`.
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _aggregate_ $op_name>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let extremum: $scalar = <$scalar as ScalarType>::FIXTURE_VALUES
                    .iter()
                    .copied()
                    .$picker()
                    .expect("FIXTURE_VALUES must be non-empty");
                let extremum_lit = <$scalar as ScalarType>::to_sql_literal(extremum);

                let expected: String = sqlx::query_scalar(&format!(
                    "SELECT payload::text FROM {fixture} WHERE plaintext = {lit}", lit = extremum_lit,
                )).fetch_one(&pool).await?;

                let actual: String = sqlx::query_scalar(&format!(
                    "SELECT eql_v2.{agg}(payload::{d})::text FROM {fixture}",
                    agg = $agg_fn,
                )).fetch_one(&pool).await?;

                assert_eq!(
                    actual, expected,
                    "eql_v2.{}({}) must return the payload of plaintext={:?} (the fixture {})",
                    $agg_fn, d, extremum, $agg_fn,
                );

                // Secondary diagnostic: when the primary identity holds,
                // the ORE comparator must agree. The check is reached only
                // on success of `assert_eq!`, so it's a self-consistency
                // assertion on the comparator — catches the regression
                // where payload text matches but `ord_term` resolves to a
                // different value (e.g. due to payload-key reordering).
                let ord_terms_match: bool = sqlx::query_scalar(&format!(
                    "SELECT eql_v2.ord_term(eql_v2.{agg}(payload::{d})) \
                          = eql_v2.ord_term($1::jsonb::{d}) \
                     FROM {fixture}",
                    agg = $agg_fn,
                ))
                .bind(&expected)
                .fetch_one(&pool)
                .await?;
                anyhow::ensure!(
                    ord_terms_match,
                    "eql_v2.ord_term(eql_v2.{}({})) must equal eql_v2.ord_term(<expected payload>) \
                     for plaintext={:?}",
                    $agg_fn, d, extremum,
                );
                Ok(())
            }

            // Empty rowset: aggregate over zero rows returns NULL,
            // structurally distinct from the all-NULL case (no rows fed
            // at all vs. rows fed but every value NULL). Both must
            // return NULL but they exercise different sfunc paths.
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _aggregate_ $op_name _empty>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE empty_agg (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                let result: Option<String> = sqlx::query_scalar(&format!(
                    "SELECT eql_v2.{agg}(value)::text FROM empty_agg",
                    agg = $agg_fn,
                )).fetch_one(&mut *tx).await?;
                anyhow::ensure!(
                    result.is_none(),
                    "empty rowset to eql_v2.{} on {} must return NULL, got {:?}",
                    $agg_fn, d, result,
                );
                tx.commit().await?;
                Ok(())
            }

            // All-NULL input: STRICT sfunc never seeds the state, final
            // result is NULL. No fixture needed.
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _aggregate_ $op_name _all_null>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let sql = format!(
                    "SELECT eql_v2.{agg}(NULL::{d})::text FROM generate_series(1, 3)",
                    agg = $agg_fn,
                );
                let result: Option<String> = sqlx::query_scalar(&sql)
                    .fetch_one(&pool)
                    .await?;
                anyhow::ensure!(
                    result.is_none(),
                    "all-NULL input to eql_v2.{} on {} must return NULL, got {:?}; SQL={}",
                    $agg_fn, d, result, sql,
                );
                Ok(())
            }

            // Mixed NULL / non-NULL: feeds [NULL, mid, NULL, high, NULL] and
            // asserts the aggregate returns the correct extremum of {mid,
            // high}. A non-STRICT sfunc would crash on (state=NULL, value=mid)
            // because `value < state` would be NULL; the STRICT contract
            // skips NULL inputs and seeds with the first non-NULL value.
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _aggregate_ $op_name _mixed_null>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let values: &[$scalar] = <$scalar as ScalarType>::FIXTURE_VALUES;
                anyhow::ensure!(
                    values.len() >= 2,
                    "mixed-NULL test needs >= 2 fixture values; got {}",
                    values.len(),
                );
                let mut sorted: Vec<$scalar> = values.to_vec();
                sorted.sort();
                // Span the fixture's extremes — for signed numeric scalars this
                // exercises the ORE sign-bit edges in addition to pinning STRICT
                // sfunc behaviour.
                let low: $scalar = *sorted.first().expect("non-empty after len check");
                let high: $scalar = *sorted.last().expect("non-empty after len check");
                // .min() / .max() on two values resolves to the correct picker.
                let expected_plaintext: $scalar = low.$picker(high);
                let low_lit = <$scalar as ScalarType>::to_sql_literal(low);
                let high_lit = <$scalar as ScalarType>::to_sql_literal(high);
                let expected_lit = <$scalar as ScalarType>::to_sql_literal(expected_plaintext);

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE mixed_null (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO mixed_null(value) \
                     SELECT NULL::{d} \
                     UNION ALL SELECT payload::{d} FROM {fixture} WHERE plaintext = {low} \
                     UNION ALL SELECT NULL::{d} \
                     UNION ALL SELECT payload::{d} FROM {fixture} WHERE plaintext = {high} \
                     UNION ALL SELECT NULL::{d}", low = low_lit, high = high_lit,
                )).execute(&mut *tx).await?;

                let expected: String = sqlx::query_scalar(&format!(
                    "SELECT payload::text FROM {fixture} WHERE plaintext = {lit}", lit = expected_lit,
                )).fetch_one(&mut *tx).await?;

                let actual: Option<String> = sqlx::query_scalar(&format!(
                    "SELECT eql_v2.{agg}(value)::text FROM mixed_null",
                    agg = $agg_fn,
                )).fetch_one(&mut *tx).await?;

                anyhow::ensure!(
                    actual.as_deref() == Some(expected.as_str()),
                    "eql_v2.{} on mixed NULL/non-NULL must return the {} non-NULL value (plaintext={:?}); want {expected:?}, got {actual:?}",
                    $agg_fn, $agg_fn, expected_plaintext,
                );

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Aggregate GROUP BY category — per (ord domain, op ∈ {min, max}), build a
// temp table partitioned into two groups, populate each with a known
// subset of fixture rows, GROUP BY the group key, and assert that
// `eql_v2.<op>(value)` returns the correct extremum payload per group.
// Pins that the aggregate composes correctly under GROUP BY (state is
// reset between groups, the sfunc routes through the variant's
// comparator inside each partition).
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_group_by_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$($domain:tt),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_aggregate_group_by_mid! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                domain = $domain,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_group_by_mid {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domain = ($dom_name:ident, $variant:ident) $(,)?
    ) => {
        $crate::__scalar_matrix_aggregate_group_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            op_name = min, agg_fn = "min", picker = min,
        }
        $crate::__scalar_matrix_aggregate_group_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            op_name = max, agg_fn = "max", picker = max,
        }
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_group_by_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op_name = $op_name:ident, agg_fn = $agg_fn:literal, picker = $picker:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _aggregate_group_by_ $op_name>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let values: &[$scalar] = <$scalar as ScalarType>::FIXTURE_VALUES;
                anyhow::ensure!(
                    values.len() >= 5,
                    "GROUP BY test needs >= 5 fixture values; got {}",
                    values.len(),
                );

                // Partition FIXTURE_VALUES[..3] into group 1 and [3..5]
                // into group 2. Per-group extremum is computed in Rust as
                // the ground truth.
                let group1: &[$scalar] = &values[..3];
                let group2: &[$scalar] = &values[3..5];
                let group1_extremum: $scalar = group1.iter().copied().$picker()
                    .expect("group 1 is non-empty");
                let group2_extremum: $scalar = group2.iter().copied().$picker()
                    .expect("group 2 is non-empty");
                let g1_lit = <$scalar as ScalarType>::to_sql_literal(group1_extremum);
                let g2_lit = <$scalar as ScalarType>::to_sql_literal(group2_extremum);

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE group_test (group_key int, value {d}) \
ON COMMIT DROP",
                )).execute(&mut *tx).await?;

                // Insert group 1 rows.
                for v in group1 {
                    let lit = <$scalar as ScalarType>::to_sql_literal(*v);
                    sqlx::query(&format!(
                        "INSERT INTO group_test(group_key, value) \
SELECT 1, payload::{d} FROM {fixture} WHERE plaintext = {lit}",
                    )).execute(&mut *tx).await?;
                }
                // Insert group 2 rows.
                for v in group2 {
                    let lit = <$scalar as ScalarType>::to_sql_literal(*v);
                    sqlx::query(&format!(
                        "INSERT INTO group_test(group_key, value) \
SELECT 2, payload::{d} FROM {fixture} WHERE plaintext = {lit}",
                    )).execute(&mut *tx).await?;
                }

                // Lookup the expected payload texts for each group's extremum.
                let g1_expected: String = sqlx::query_scalar(&format!(
                    "SELECT payload::text FROM {fixture} WHERE plaintext = {lit}", lit = g1_lit,
                )).fetch_one(&mut *tx).await?;
                let g2_expected: String = sqlx::query_scalar(&format!(
                    "SELECT payload::text FROM {fixture} WHERE plaintext = {lit}", lit = g2_lit,
                )).fetch_one(&mut *tx).await?;

                let rows: Vec<(i32, String)> = sqlx::query_as(&format!(
                    "SELECT group_key, eql_v2.{agg}(value)::text \
FROM group_test GROUP BY group_key ORDER BY group_key",
                    agg = $agg_fn,
                )).fetch_all(&mut *tx).await?;

                anyhow::ensure!(
                    rows.len() == 2,
                    "GROUP BY must return 2 rows, got {}",
                    rows.len(),
                );
                anyhow::ensure!(
                    rows[0].0 == 1 && rows[0].1 == g1_expected,
                    "group 1 eql_v2.{}({}) must yield payload for plaintext={:?}; \
want ({}, {:?}), got {:?}",
                    $agg_fn, d, group1_extremum, 1, g1_expected, rows[0],
                );
                anyhow::ensure!(
                    rows[1].0 == 2 && rows[1].1 == g2_expected,
                    "group 2 eql_v2.{}({}) must yield payload for plaintext={:?}; \
want ({}, {:?}), got {:?}",
                    $agg_fn, d, group2_extremum, 2, g2_expected, rows[1],
                );

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Aggregate type-safety category — for variants that do NOT support ord
// (Storage, Eq), `eql_v2.min(<variant-column>)` / `eql_v2.max(...)` must
// resolve to "function does not exist" (SQLSTATE 42883). Pins that
// codegen correctly omits MIN/MAX wrappers for these variants — a
// SQL-level regression test complementing the codegen unit test.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_typecheck_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        domains = [$(($dom_name:ident, $variant:ident)),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_aggregate_typecheck_dispatch! {
                suite = $suite, scalar = $scalar,
                dom_name = $dom_name, variant = $variant,
            }
        )+
    };
}

// Dispatch on variant ident: ord-capable variants (Ord, OrdOre) emit no
// typecheck test — they DO declare min/max. Non-ord variants (Storage,
// Eq) emit one test per aggregate op asserting the call fails with
// SQLSTATE 42883.
#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_typecheck_dispatch {
    // Ord, OrdOre: no typecheck test — these variants declare min/max.
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = Ord $(,)?
    ) => {};
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = OrdOre $(,)?
    ) => {};
    // Storage, Eq: emit min + max typecheck tests.
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::__scalar_matrix_aggregate_typecheck_case! {
            suite = $suite, scalar = $scalar,
            dom_name = $dom_name, variant = $variant,
            op_name = min, agg_fn = "min",
        }
        $crate::__scalar_matrix_aggregate_typecheck_case! {
            suite = $suite, scalar = $scalar,
            dom_name = $dom_name, variant = $variant,
            op_name = max, agg_fn = "max",
        }
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_typecheck_case {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        dom_name = $dom_name:ident, variant = $variant:ident,
        op_name = $op_name:ident, agg_fn = $agg_fn:literal $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _aggregate_typecheck_ $op_name>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let payload = $crate::helpers::PLACEHOLDER_PAYLOAD;

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE typecheck_table (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO typecheck_table(value) VALUES ($1::jsonb::{d})",
                )).bind(payload).execute(&mut *tx).await?;

                // Savepoint-isolate the probe so the failed lookup
                // doesn't abort the outer transaction and tx.commit()
                // can succeed cleanly.
                sqlx::query("SAVEPOINT probe").execute(&mut *tx).await?;
                let sql = format!(
                    "SELECT eql_v2.{agg}(value) FROM typecheck_table",
                    agg = $agg_fn,
                );
                let err = sqlx::query_scalar::<_, String>(&sql)
                    .fetch_one(&mut *tx)
                    .await
                    .expect_err(&format!(
                        "eql_v2.{} on non-ord variant {} must raise but succeeded",
                        $agg_fn, d,
                    ));
                // 42883 = undefined_function (no overload defined at all);
                // 42725 = ambiguous_function (multiple overloads resolve,
                // none specific to this variant). Either confirms the
                // variant carries no MIN/MAX of its own — the generic
                // eql_v2_encrypted overload is reachable via cast but
                // can't be resolved unambiguously from a domain-typed
                // column. Both outcomes are acceptable "not supported".
                let db_err = err.as_database_error()
                    .expect("expected database error from typecheck probe");
                let code = db_err.code();
                anyhow::ensure!(
                    code.as_deref() == Some("42883") || code.as_deref() == Some("42725"),
                    "expected SQLSTATE 42883 (undefined_function) or 42725 \
(ambiguous_function) for eql_v2.{}({}), got {:?} (message: {})",
                    $agg_fn, d, code, db_err.message(),
                );
                sqlx::query("ROLLBACK TO SAVEPOINT probe").execute(&mut *tx).await?;

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// COUNT category — pins three forms per variant: plain COUNT(value) on a
// typed column, COUNT(payload::variant) on the fixture, and
// COUNT(DISTINCT extractor(value)) using the variant's own extractor. The
// DISTINCT case dispatches per-variant: Storage has no extractor and so
// emits no DISTINCT test; Eq uses eq_term, Ord/OrdOre use ord_term.
//
// This is net new coverage relative to the legacy aggregate_tests.rs file,
// which only covered plain COUNT and only against the eql_v2_encrypted
// type. Pinning per-variant DISTINCT catches the breakage class where
// picking the wrong extractor would fail at runtime ("function
// eql_v2.eq_term(eql_v2_int4_ord) does not exist") — exactly the kind of
// thing the variant-aware matrix is meant to surface mechanically.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_count_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        domains = [$(($dom_name:ident, $variant:ident)),+ $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_count_case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant,
            }
            $crate::__scalar_matrix_count_distinct_dispatch! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
                dom_name = $dom_name, variant = $variant,
            }
        )+
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_count_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::paste::paste! {
            // COUNT(value) on a typed column — pins that PG's native COUNT
            // works on a domain-typed column without an aggregate declaration.
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _count_typed_column>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let expected = <$scalar as ScalarType>::FIXTURE_VALUES.len() as i64;

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE typed_count (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO typed_count(value) SELECT payload::{d} FROM {fixture}",
                )).execute(&mut *tx).await?;

                let actual: i64 = sqlx::query_scalar(
                    "SELECT COUNT(value) FROM typed_count",
                ).fetch_one(&mut *tx).await?;
                anyhow::ensure!(
                    actual == expected,
                    "COUNT(value) on typed {} column: want {}, got {}",
                    d, expected, actual,
                );

                tx.commit().await?;
                Ok(())
            }

            // COUNT(payload::variant) on the fixture — pins COUNT on a
            // path-cast expression. No temp table; the cast happens inline.
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _count_path_cast>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let expected = <$scalar as ScalarType>::FIXTURE_VALUES.len() as i64;

                let sql = format!(
                    "SELECT COUNT(payload::{d}) FROM {fixture}",
                );
                let actual: i64 = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
                anyhow::ensure!(
                    actual == expected,
                    "COUNT(payload::{}) on {}: want {}, got {}; SQL={}",
                    d, fixture, expected, actual, sql,
                );
                Ok(())
            }
        }
    };
}

// Dispatch on variant ident: Storage has no discriminating extractor, so
// emits no DISTINCT test. The other three (Eq, Ord, OrdOre) each emit one
// test that reads the extractor function name from the runtime
// `ScalarDomainSpec::extractor_fn()` accessor (Eq -> `eql_v2.eq_term`,
// Ord/OrdOre -> `eql_v2.ord_term`) and appends `(value)` at the call site.
#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_count_distinct_dispatch {
    // Storage: no DISTINCT case — no extractor to deduplicate by.
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = Storage $(,)?
    ) => {};
    // Eq, Ord, OrdOre — emit the DISTINCT test.
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        dom_name = $dom_name:ident, variant = $variant:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _count_distinct_extractor>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let extractor_fn = spec.extractor_fn()
                    .expect("non-Storage variant must expose an extractor");
                let extractor = format!("{extractor_fn}(value)");
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let expected = <$scalar as ScalarType>::FIXTURE_VALUES.len() as i64;

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE distinct_count (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO distinct_count(value) SELECT payload::{d} FROM {fixture}",
                )).execute(&mut *tx).await?;

                let sql = format!(
                    "SELECT COUNT(DISTINCT {extr}) FROM distinct_count",
                    extr = extractor,
                );
                let actual: i64 = sqlx::query_scalar(&sql).fetch_one(&mut *tx).await?;
                anyhow::ensure!(
                    actual == expected,
                    "COUNT(DISTINCT {}) on {}: want {} (one per FIXTURE_VALUES row), got {}; SQL={}",
                    extractor, d, expected, actual, sql,
                );

                tx.commit().await?;
                Ok(())
            }
        }
    };
}
