//! Type-generic test matrix for encrypted scalar domains.
//!
//! Two entry points:
//!
//! - **`scalar_matrix!`** — the recommended wrapper. One invocation per type
//!   (~5 lines), with a `caps` capability marker selecting the shape:
//!   `caps = [eq, ord]` for an ordered scalar (i32, i64, date, ...) where all
//!   four variants are present and the full `=`/`<>`/`<`/`>`/`min`/`max`
//!   surface applies; `caps = [eq]` for an equality-only scalar (timestamptz,
//!   bool, ...) where only storage + `_eq` materialise and the ord operators
//!   are blockers. The only other inputs that change per type are the scalar
//!   itself, the suite token (used to derive domain + test names), and the EQL
//!   type name (the fixture `scripts(...)` ref); pivots are derived from the
//!   `ScalarType` impl.
//!
//! - **`scalar_domain_matrix!`** — the lower-level macro the wrapper
//!   expands to. Use directly only for types with a non-standard surface
//!   that neither `caps` shape covers.
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

// ============================================================================
// EXPLAIN plan inspection — node-type-aware index-engagement assertion.
//
// The index-engagement arms (`*_index_engages_*`, `*_ord_routes_through_ob`)
// previously asserted `plan_text.contains(index_name)` on a *text* EXPLAIN.
// That substring match is too weak in two independent ways:
//
//   1. It cannot distinguish an actual index-scan node from an incidental
//      textual mention of the index name (e.g. inside an `Index Cond`, a
//      filter expression, or a "Recheck Cond" line) — any line carrying the
//      string passes, even if the relation is still read in full.
//   2. It says nothing about *which kind* of node read the relation. A
//      Bitmap-recheck that still touches every heap row, or a node that
//      merely references the index, looks identical to a clean Index Scan.
//
// `assert_index_scan_uses` parses `EXPLAIN (FORMAT JSON)` and requires a
// genuine index-scan node (`Index Scan` / `Index Only Scan` /
// `Bitmap Index Scan`) whose `Index Name` is the expected index. This is a
// structurally meaningful assertion even with `enable_seqscan = off`.
//
// LOUD CAVEAT — VALIDITY, NOT PREFERENCE. Even after this upgrade, the
// index-engagement arms run against a ~17-row fixture with
// `SET LOCAL enable_seqscan = off`. With the only cheaper alternative
// (seqscan) forcibly disabled, the planner will pick essentially any usable
// index. So these arms prove the index is USABLE / VALID (the operator
// resolves through the functional index and produces a real index-scan node)
// — they do NOT prove the planner would PREFER the index under realistic
// costs. Cost-preference is proven exclusively by `__scalar_matrix_scale_case`
// (the `*_scale_preference_*` tests), which build ~5000 rows and leave
// `enable_seqscan` ON. Those are `#[cfg(feature = "scale")]` and are OFF in
// default PR CI. Do not read a green index-engagement arm as "the planner
// chooses this index" — it only means "the planner *can* use this index".
// ============================================================================

/// Assert that a JSON EXPLAIN plan contains a real index-scan node whose
/// `Index Name` matches `index_name`.
///
/// Recursively walks the plan tree. A node qualifies only if its `Node Type`
/// is one of `Index Scan`, `Index Only Scan`, or `Bitmap Index Scan` AND its
/// `Index Name` equals `index_name`. This is strictly stronger than a
/// substring match on the text plan, which would also accept an index name
/// appearing in an `Index Cond` / `Recheck Cond` / filter expression without
/// any index-scan node actually reading the relation.
///
/// `query` is the bare SQL (no `EXPLAIN` prefix); it is interpolated directly,
/// so it must be a trusted/hardcoded string. `tx` is any sqlx executor.
///
/// Returns `Err` (with the full pretty-printed plan) if no qualifying node is
/// found, so it composes with the `?` operator inside the generated arms.
pub async fn assert_index_scan_uses<'e, E>(
    executor: E,
    query: &str,
    index_name: &str,
    context: &str,
) -> anyhow::Result<()>
where
    E: sqlx::Executor<'e, Database = sqlx::Postgres>,
{
    let sql = format!("EXPLAIN (FORMAT JSON) {query}");
    let plan: serde_json::Value = sqlx::query_scalar(&sql)
        .fetch_one(executor)
        .await
        .map_err(|e| anyhow::anyhow!("running `{sql}`: {e}"))?;

    let mut index_scan_nodes: Vec<(String, String)> = Vec::new();
    collect_index_scan_nodes(&plan, &mut index_scan_nodes);

    let matched = index_scan_nodes
        .iter()
        .any(|(_node_type, name)| name == index_name);

    anyhow::ensure!(
        matched,
        "{context}: expected an index-scan node (Index Scan / Index Only Scan / \
         Bitmap Index Scan) referencing index `{index_name}`, but found none. \
         Index-scan nodes present: {index_scan_nodes:?}. Full plan:\n{}",
        serde_json::to_string_pretty(&plan).unwrap_or_else(|_| plan.to_string()),
    );
    Ok(())
}

/// Recursively collect `(Node Type, Index Name)` pairs for every index-scan
/// node in a JSON EXPLAIN plan tree. Only the three index-scan node types are
/// collected; other nodes (Seq Scan, Aggregate, Sort, ...) are skipped but
/// their children are still walked.
fn collect_index_scan_nodes(value: &serde_json::Value, found: &mut Vec<(String, String)>) {
    match value {
        serde_json::Value::Object(map) => {
            if let Some(node_type) = map.get("Node Type").and_then(|v| v.as_str()) {
                if matches!(
                    node_type,
                    "Index Scan" | "Index Only Scan" | "Bitmap Index Scan"
                ) {
                    let index_name = map
                        .get("Index Name")
                        .and_then(|v| v.as_str())
                        .unwrap_or("<unnamed>");
                    found.push((node_type.to_string(), index_name.to_string()));
                }
            }
            for v in map.values() {
                collect_index_scan_nodes(v, found);
            }
        }
        serde_json::Value::Array(arr) => {
            for item in arr {
                collect_index_scan_nodes(item, found);
            }
        }
        _ => {}
    }
}

/// Unified convention wrapper for scalar encrypted-domain suites. Replaces the
/// two parallel wrappers (`ordered_numeric_matrix!` + `eq_only_scalar_matrix!`)
/// with one entry point selected by a `caps` capability marker:
///
/// - `caps = [eq, ord]` — the ordered-numeric shape (all four variants;
///   `=`/`<>`/`<`/`<=`/`>`/`>=`; ORDER BY / ORDER BY USING; ORE injectivity;
///   the ordered functional index). Consumers: `int2`/`int4`/`int8`/`date`.
/// - `caps = [eq]` — equality-only (storage + `_eq` only; `=`/`<>` meaningful,
///   the four ord operators are deliberate blockers). The empty `ord_domains`
///   make the order-by / ORE arms emit zero tests. First consumer:
///   `timestamptz`.
///
/// Both arms take the identical `(suite, scalar, eql_type)` signature, so the
/// invocation shape is the same regardless of capability — only the `caps`
/// marker differs. The emitted test names for an ordered type are byte-identical
/// to the old `ordered_numeric_matrix!`; the eq-only name set is exactly that
/// set minus the `_ord` / `order_by` / `routes_through_ob` lines.
///
/// Pivots — the comparison anchors swept by the correctness / cross-shape
/// arms — are the `OrderedScalar` anchors: `min_pivot()`, `max_pivot()`, and the
/// interior `mid_pivot()`. Integer scalars resolve `min`/`max` to
/// `Self::MIN`/`Self::MAX` and `mid` to the origin `0`; temporal scalars use
/// explicit sentinel dates (`mid` = the epoch); `text` uses a real median
/// fixture for `mid` (its `Default` `""` is degenerate for ORE, #262). The
/// fixture must contain those three plaintext rows, since each pivot's
/// ciphertext is fetched at test time via `fetch_fixture_payload`.
#[macro_export]
macro_rules! scalar_matrix {
    (
        suite = $suite:ident,
        scalar = $scalar:ty,
        eql_type = $eql_type:literal,
        caps = [eq, ord] $(,)?
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
                (min, <$scalar as $crate::scalar_domains::OrderedScalar>::min_pivot()),
                (max, <$scalar as $crate::scalar_domains::OrderedScalar>::max_pivot()),
                (mid, <$scalar as $crate::scalar_domains::OrderedScalar>::mid_pivot()),
            ],
            eq_ops = [(eq, "="), (neq, "<>")],
            ord_ops = [(lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")],
            index_combos = [
                (eq, Eq, "eql_v3.eq_term", "btree", [(eq, "=")]),
                (eq, Eq, "eql_v3.eq_term", "hash", [(eq, "=")]),
                (ord, Ord, "eql_v3.ord_term", "btree",
                    [(eq, "="), (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")]),
                (ord_ore, OrdOre, "eql_v3.ord_term", "btree",
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
            // Always-on cost-preference proof (#239 thread 17): the recommended
            // converged ordered domain, ord_term btree. One curated combo keeps
            // PR CI cost bounded.
            scale_default_combos = [
                (ord, Ord, "eql_v3.ord_term", "btree"),
            ],
        }
    };
    (
        suite = $suite:ident,
        scalar = $scalar:ty,
        eql_type = $eql_type:literal,
        caps = [eq] $(,)?
    ) => {
        $crate::scalar_domain_matrix! {
            suite = $suite,
            scalar = $scalar,
            eql_type = $eql_type,
            // Fixed path; see the `caps = [eq, ord]` arm for the rationale.
            fixture_path = "../../../fixtures",
            all_domains = [(storage, Storage), (eq, Eq)],
            eq_domains = [(eq, Eq)],
            ord_domains = [],
            ord_ore_domains = [],
            // Pivots derived from the scalar type exactly like the ordered arm
            // (`OrderedScalar::min_pivot()`/`max_pivot()`/`mid_pivot()`), so the
            // equality correctness / cross-shape arms sweep the same three
            // anchors and the eq-only name set stays a clean subset of the
            // ordered one.
            pivots = [
                (min, <$scalar as $crate::scalar_domains::OrderedScalar>::min_pivot()),
                (max, <$scalar as $crate::scalar_domains::OrderedScalar>::max_pivot()),
                (mid, <$scalar as $crate::scalar_domains::OrderedScalar>::mid_pivot()),
            ],
            eq_ops = [(eq, "="), (neq, "<>")],
            ord_ops = [(lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")],
            index_combos = [
                (eq, Eq, "eql_v3.eq_term", "btree", [(eq, "=")]),
                (eq, Eq, "eql_v3.eq_term", "hash",  [(eq, "=")]),
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
            // Equality-only scalars have no ordered functional index to prefer.
            scale_default_combos = [],
        }
    };
}

/// Reduced behaviour matrix for a SteVec **entry** view type (e.g.
/// `JsonbEntryInt4`). Runs only the leaf drivers that are surface-agnostic
/// once routed through the access-path seam: correctness (d,d only),
/// supported_null, order_by(+nulls/+using), count, index_engages, and — once
/// `src/v3/jsonb/aggregates.sql` exists — aggregate(+group_by/+parallel).
/// Containment / blockers / payload_check / path-op / native-absent /
/// planner-metadata stay in the hand-written `v3_jsonb_tests` suite — they have
/// no scalar analogue or assert document-specific surface.
/// `ord_routes_through_ob` and scalar `ore_injectivity` are also excluded: they
/// are scalar-term invariants and are not semantically correct for
/// `ste_vec_entry` (entry equality routes through `eq_term`, not ORE).
///
/// The single `(entry, Ord)` "domain" is variant-independent — `ste_vec_entry`
/// has one domain. Equality reduces through `eql_v3.eq_term`; ordering, index,
/// count-distinct, and aggregates reduce through `eql_v3.ore_cllw` via the
/// `JsonbEntryInt4` extractor overrides.
#[macro_export]
macro_rules! jsonb_entry_matrix {
    (
        suite = $suite:ident,
        scalar = $scalar:ty,
        eql_type = $eql_type:literal $(,)?
    ) => {
        $crate::__scalar_matrix_dxop_outer! {
            case = __scalar_matrix_correctness_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)],
            ops_list = [(eq, "="), (neq, "<>"), (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")],
            pivots_list = [
                (min, <$scalar as $crate::scalar_domains::OrderedScalar>::min_pivot()),
                (max, <$scalar as $crate::scalar_domains::OrderedScalar>::max_pivot()),
                (mid, <$scalar as $crate::scalar_domains::OrderedScalar>::mid_pivot()),
            ],
        }
        $crate::__scalar_matrix_dxo_outer! {
            case = __scalar_matrix_supported_null_case,
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)],
            ops_list = [(eq, "="), (neq, "<>"), (lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")],
        }
        $crate::__scalar_matrix_order_by_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)],
        }
        $crate::__scalar_matrix_order_by_nulls_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)],
        }
        $crate::__scalar_matrix_order_by_using_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)], ops_list = [(lt, "<"), (lte, "<="), (gt, ">"), (gte, ">=")],
        }
        $crate::__scalar_matrix_count_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)],
        }
        // Index engagement is NOT driven by `__scalar_matrix_index_outer!` for
        // entries: that shared driver also sweeps a bare-jsonb RHS
        // (`value < '<lit>'::jsonb`), which is load-bearing for scalars (they have
        // `(domain, jsonb)` cross-type operators) but UNSAFE for entries —
        // `ste_vec_entry` has no `(entry, jsonb)` operator, so a bare-jsonb RHS
        // flattens to native `jsonb < jsonb` (no ore_cllw, no index) rather than
        // the entry operator. The hand-written `jsonb_entry_int4_index_engages`
        // test in the suite probes index engagement with the domain-cast RHS only.

        // Aggregates: eql_v3.min/max over ste_vec_entry (src/v3/jsonb/aggregates.sql).
        // The aggregate leaf cases compare extrema via the ord-extractor seam
        // (eql_v3.ore_cllw for entries), so the entry min/max route through the
        // `oc` (CLLW ORE) term exactly like the comparison operators.
        $crate::__scalar_matrix_aggregate_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)],
        }
        $crate::__scalar_matrix_aggregate_group_by_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = "../../fixtures",
            domains = [(entry, Ord)],
        }
        $crate::__scalar_matrix_aggregate_parallel_outer! {
            suite = $suite, scalar = $scalar,
            domains = [(entry, Ord)],
        }
    };
}

/// Low-level entry point. Use `scalar_matrix!` instead unless
/// your type's surface deviates from the standard scalar shapes.
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
        blocker_combos = [$($blocker_combo:tt),+ $(,)?],
        // Curated combo(s) that get an ALWAYS-ON cost-preference test (#239
        // thread 17). May be empty (e.g. equality-only scalars have no ordered
        // index to prefer).
        scale_default_combos = [$($scale_default_combo:tt),* $(,)?] $(,)?
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
        $crate::__scalar_matrix_scale_default_outer! {
            suite = $suite, scalar = $scalar, script = $eql_type, script_path = $fixture_path,
            combos = [$($scale_default_combo),*],
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
        $crate::__scalar_matrix_aggregate_parallel_outer! {
            suite = $suite, scalar = $scalar,
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
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, pivot.clone()).await?;
                let lit = $crate::scalar_domains::sql_string_literal(&payload);
                let predicate = format!(
                    "({col})::{d} {op} {lit}::jsonb::{d}",
                    col = &spec.column_expr, d = &spec.sql_domain, op = $op,
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
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, pivot.clone()).await?;
                let lit = $crate::scalar_domains::sql_string_literal(&payload);
                let forward_count =
                    <$scalar as $crate::scalar_domains::ScalarType>::expected_forward($op, pivot.clone())
                        .len() as i64;
                let commuted_count = <$scalar as $crate::scalar_domains::ScalarType>::expected_forward(
                    $crate::scalar_domains::commute_op($op), pivot.clone(),
                ).len() as i64;
                let d = &spec.sql_domain;
                let col = &spec.column_expr;
                let shapes = [
                    ("d_d", format!("({col})::{d} {op} {lit}::jsonb::{d}", op = $op), forward_count),
                    ("d_j", format!("({col})::{d} {op} {lit}::jsonb", op = $op), forward_count),
                    ("j_d", format!("{lit}::jsonb {op} ({col})::{d}", op = $op), commuted_count),
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
                let payload = spec.placeholder_payload;
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
                for key in spec.payload_required_keys() {
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
                      AND ('{d}'::regtype = o.oprleft OR '{d}'::regtype = o.oprright)
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

                let values: &[$scalar] = <$scalar as ScalarType>::fixture_values();
                anyhow::ensure!(values.len() >= 2,
                    "scale test requires >= 2 fixture rows for distinct filler/pivot");
                let filler = values[0].clone();
                let pivot = values[values.len() / 2].clone();
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
                $crate::matrix::assert_index_scan_uses(
                    &mut *tx,
                    &format!("SELECT * FROM {table} WHERE value = '{lit}'::jsonb::{d}"),
                    index,
                    &format!(
                        "with seqscan enabled the planner must prefer the {extractor} {using} index for a selective =",
                        extractor = $extractor, using = $using,
                    ),
                ).await?;

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Scale-preference DEFAULT category — the always-on counterpart of the
// feature-gated scale sweep above (#239 thread 17). For one curated combo
// (the recommended ordered domain, ord_term btree) it builds ~5000 filler
// rows + one selective pivot, ANALYZEs, and — leaving `enable_seqscan` ON —
// asserts the planner PREFERS the functional index under realistic costs.
// Unlike the index-engagement arms (validity only, seqscan forced off), this
// proves cost-preference; unlike the `*_scale_preference_*` sweep it runs in
// default PR CI. The assertion is node-type-aware via `assert_index_scan_uses`
// (a genuine Index/Index-Only/Bitmap-Index-Scan node referencing the index),
// so it cannot be satisfied by an incidental textual mention of the index.
// Curated to a single combo so PR CI cost stays bounded.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_scale_default_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        combos = [$($combo:tt),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_scale_default_case! {
                suite = $suite, scalar = $scalar, script = $script, script_path = $script_path, combo = $combo,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_scale_default_case {
    (
        suite = $suite:ident, scalar = $scalar:ty, script = $script:literal, script_path = $script_path:literal,
        combo = ($dom_name:ident, $variant:ident, $extractor:literal, $using:literal) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _scale_preference_default_ $using>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::ScalarType;
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                let table = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name),
                    "_scaledef_", $using,
                );
                let index = concat!(
                    "matrix_", stringify!($suite), "_", stringify!($dom_name),
                    "_scaledef_", $using, "_idx",
                );

                let values: &[$scalar] = <$scalar as ScalarType>::fixture_values();
                anyhow::ensure!(values.len() >= 2,
                    "scale test requires >= 2 fixture rows for distinct filler/pivot");
                let filler = values[0].clone();
                let pivot = values[values.len() / 2].clone();
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
                // enable_seqscan left ON: this is a cost-preference proof, not a
                // validity check. With ~5000 filler rows and a single selective
                // pivot, a correctly-costed plan must choose the functional index.

                let lit = pivot_payload.replace('\'', "''");
                $crate::matrix::assert_index_scan_uses(
                    &mut *tx,
                    &format!("SELECT * FROM {table} WHERE value = '{lit}'::jsonb::{d}"),
                    index,
                    "with seqscan ON the planner must PREFER the ord_term functional index for a selective =",
                ).await?;

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Fixture-shape category — one test per type that pins the fixture's
// structural invariants: row count matches `T::fixture_values().len()`,
// ids are sequential from 1, plaintext column matches fixture_values() in
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
                let expected: &[$scalar] = <$scalar as ScalarType>::fixture_values();
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
                    let probe = &expected[expected.len() / 2];
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
// `eql_v3.ord_term` (the `ob` term), never HMAC. Strip `hm` from every
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
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_values()[0].clone();
                let pivot_lit =
                    <$scalar as $crate::scalar_domains::ScalarType>::to_sql_literal(&pivot);

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
                    "CREATE INDEX {index} ON {table} USING btree (eql_v3.ord_term(value))",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!("ANALYZE {table}"))
                    .execute(&mut *tx).await?;
                sqlx::query("SET LOCAL enable_seqscan = off")
                    .execute(&mut *tx).await?;

                let pivot_payload: String = sqlx::query_scalar(&format!(
                    "SELECT (payload - 'hm')::text FROM {fixture} WHERE plaintext = {lit}",
                    fixture = fixture_table, lit = pivot_lit,
                )).fetch_one(&mut *tx).await?;

                // The fixture plaintexts are distinct, so the pivot row is
                // unique: `=` via ob must match EXACTLY one row, not "at
                // least one". A weaker `>= 1` here is not independent of the
                // `<>` check below — `expected_neq` is `len - eq_count`, so an
                // `=` that over-matches inflates `eq_count` and deflates
                // `expected_neq` in lockstep and both assertions still pass.
                // Pinning `== 1` makes both this and the derived `<>` count
                // load-bearing.
                let eq_count: i64 = sqlx::query_scalar(&format!(
                    "SELECT count(*) FROM {table} WHERE value = $1::jsonb::{d}",
                )).bind(&pivot_payload).fetch_one(&mut *tx).await?;
                anyhow::ensure!(eq_count == 1,
                    "= must match exactly the pivot row via ob with no hm present (want 1, got {eq_count})");

                // Derive from the pinned `eq_count == 1`: every other fixture
                // row must be `<>`. Kept as `len - eq_count` (not a bare
                // `len - 1`) so that if the `== 1` invariant above is ever
                // relaxed the two assertions cannot silently compensate for
                // each other — the derivation stays honest regardless.
                let expected_neq =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_values().len() as i64
                    - eq_count;
                let neq_count: i64 = sqlx::query_scalar(&format!(
                    "SELECT count(*) FROM {table} WHERE value <> $1::jsonb::{d}",
                )).bind(&pivot_payload).fetch_one(&mut *tx).await?;
                anyhow::ensure!(neq_count == expected_neq,
                    "<> must match every non-pivot fixture row (want {expected_neq}, got {neq_count})",
                );

                // VALIDITY, NOT PREFERENCE: this runs with
                // `enable_seqscan = off` (set above) on the ~17-row fixture,
                // so the planner picks the only usable alternative. A green
                // assertion proves the `eql_v3.ord_term` functional btree is
                // *usable* for `=` with no hm present, NOT that the planner
                // would *prefer* it at realistic scale. Cost-preference lives
                // in the `*_scale_preference_*` tests
                // (`#[cfg(feature = "scale")]`, OFF in PR CI). See the module
                // header on `assert_index_scan_uses` for the full caveat.
                //
                // Node-type-aware (not a name substring): we require a genuine
                // Index/Index-Only/Bitmap-Index-Scan node referencing `index`,
                // so an incidental textual mention of the index name in an
                // Index Cond / filter can no longer satisfy the assertion.
                let lit = pivot_payload.replace('\'', "''");
                $crate::matrix::assert_index_scan_uses(
                    &mut *tx,
                    &format!("SELECT * FROM {table} WHERE value = '{lit}'::jsonb::{d}"),
                    index,
                    "= must engage the eql_v3.ord_term functional btree with no hm",
                ).await?;

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
// ops × rhs-casts asserting EXPLAIN contains a genuine index-scan node
// referencing the index (via `assert_index_scan_uses`, not a name substring).
//
// VALIDITY ONLY: forces `enable_seqscan = off` on the ~17-row fixture, so a
// green arm proves the index is *usable*, NOT that the planner would *prefer*
// it. Cost-preference is the `*_scale_preference_*` tests
// (`#[cfg(feature = "scale")]`, OFF in PR CI). See the module-level comment on
// `assert_index_scan_uses` for the full caveat.
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
                     SELECT plaintext, ({col})::{d} FROM {fixture}", col = &spec.column_expr, d = &spec.sql_domain, fixture = fixture_table,
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "CREATE INDEX {index} ON {table} USING {using} ({extractor}(value))", using = $using, extractor = $extractor,
                )).execute(&mut *tx).await?;
                sqlx::query(&format!("ANALYZE {table}"))
                    .execute(&mut *tx).await?;
                sqlx::query("SET LOCAL enable_seqscan = off").execute(&mut *tx).await?;

                let pivot: $scalar = <$scalar as $crate::scalar_domains::ScalarType>::fixture_values()[0].clone();
                let payload =
                    $crate::scalar_domains::fetch_fixture_payload::<$scalar>(&pool, pivot).await?;
                let lit = $crate::scalar_domains::sql_string_literal(&payload);

                // VALIDITY, NOT PREFERENCE: `enable_seqscan = off` is set
                // above and the table holds only the ~17 fixture rows, so the
                // planner has no cheaper option than the functional index.
                // These arms therefore prove the index is *usable* for each
                // (op, rhs-cast) shape — that the operator resolves through
                // `{extractor}` and produces a real index-scan node — NOT that
                // the planner would *prefer* the index under realistic costs.
                // Cost-preference is proven ONLY by the `*_scale_preference_*`
                // tests (`#[cfg(feature = "scale")]`), which are OFF in default
                // PR CI. See the module header on `assert_index_scan_uses`.
                //
                // The assertion is node-type-aware (Index / Index Only /
                // Bitmap Index Scan referencing `index`), not a bare substring
                // match on the text plan, so an index name that merely appears
                // in an Index Cond / Recheck Cond / filter cannot pass it.
                let rhs_casts = [format!("::{d}", d = &spec.sql_domain), String::new()];
                $(
                    for rhs_cast in &rhs_casts {
                        let query = format!(
                            "SELECT * FROM {table} WHERE value {op} {lit}::jsonb{cast}", op = $op, cast = rhs_cast,
                        );
                        $crate::matrix::assert_index_scan_uses(
                            &mut *tx,
                            &query,
                            index,
                            &format!(
                                "domain={} op={} rhs_cast={:?} must use index={}",
                                &spec.sql_domain, $op, rhs_cast, index,
                            ),
                        ).await?;
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
            mode_name = asc_no_where, direction = "ASC", filter = all,
        }
        $crate::__scalar_matrix_order_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = desc_no_where, direction = "DESC", filter = all,
        }
        $crate::__scalar_matrix_order_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = asc_with_where, direction = "ASC", filter = gt_mid,
        }
        $crate::__scalar_matrix_order_by_case! {
            suite = $suite, scalar = $scalar, script = $script, script_path = $script_path,
            dom_name = $dom_name, variant = $variant,
            mode_name = desc_with_where, direction = "DESC", filter = gt_mid,
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
        filter = $filter:ident $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test(fixtures(path = $script_path, scripts($script)))]
            async fn [<matrix_ $suite _ $dom_name _order_by_ $mode_name>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                use $crate::scalar_domains::{OrderedScalar, ScalarType};
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let fixture_table = <$scalar as ScalarType>::fixture_table_name();

                let mid: $scalar = <$scalar as OrderedScalar>::mid_pivot();
                let gt_mid = stringify!($filter) == "gt_mid";
                // Build the WHERE clause from the interior pivot's SQL literal so
                // it is type-agnostic: `plaintext > 0` for integers, `plaintext >
                // '1970-01-01'` for dates, `plaintext > 'frank'` for text. A
                // hardcoded `> 0` would not typecheck against a non-integer
                // plaintext column.
                let where_clause = if gt_mid {
                    format!(" WHERE plaintext > {}", <$scalar as ScalarType>::to_sql_literal(&mid))
                } else {
                    String::new()
                };
                let col = &spec.column_expr;
                let d = &spec.sql_domain;
                let ord = (spec.ord_extractor)(&format!("({col})::{d}"));
                let sql = format!(
                    "SELECT plaintext FROM {fixture}{where_clause} \
ORDER BY {ord} {dir}",
                    fixture = fixture_table,
                    dir = $direction,
                );
                let actual: Vec<$scalar> = sqlx::query_scalar(&sql).fetch_all(&pool).await?;

                let mut expected: Vec<$scalar> =
                    <$scalar as ScalarType>::fixture_values().to_vec();
                expected.sort();
                if gt_mid {
                    expected.retain(|v| *v > mid);
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
// non-NULL rows stay in plaintext order. `eql_v3.ord_term` is STRICT, so a
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
SELECT plaintext, ({col})::{d} FROM {fixture}", col = &spec.column_expr, fixture = fixture_table,
                )).execute(&mut *tx).await?;
                // NULL-valued rows: NULL plaintext too, so they surface as None
                // and their position is what the assertion pins.
                sqlx::query(&format!(
                    "INSERT INTO {table}(plaintext, value) \
SELECT NULL::{pg}, NULL::{d} FROM generate_series(1, {n})", n = NULL_ROWS,
                )).execute(&mut *tx).await?;

                let ord = (spec.ord_extractor)("value");
                let sql = format!(
                    "SELECT plaintext FROM {table} \
ORDER BY {ord} {dir} NULLS {nulls}",
                    dir = $direction, nulls = $nulls,
                );
                let actual: Vec<Option<$scalar>> =
                    sqlx::query_scalar(&sql).fetch_all(&mut *tx).await?;

                // Ground truth: non-NULL plaintexts sorted (reversed for DESC),
                // with NULL_ROWS Nones at the requested end.
                let mut non_null: Vec<$scalar> =
                    <$scalar as $crate::scalar_domains::ScalarType>::fixture_values().to_vec();
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
                    "SELECT plaintext FROM {fixture} ORDER BY ({col})::{d} USING {op}",
                    fixture = fixture_table, col = &spec.column_expr, d = &spec.sql_domain, op = $op,
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
// the non-NULL subset. Pins that `eql_v3.min` / `eql_v3.max` aggregates
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
                let col = &spec.column_expr;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let extremum: $scalar = <$scalar as ScalarType>::fixture_values()
                    .iter()
                    .cloned()
                    .$picker()
                    .expect("FIXTURE_VALUES must be non-empty");
                let extremum_lit = <$scalar as ScalarType>::to_sql_literal(&extremum);

                let expected: String = sqlx::query_scalar(&format!(
                    "SELECT (({col})::{d})::text FROM {fixture} WHERE plaintext = {lit}", lit = extremum_lit,
                )).fetch_one(&pool).await?;

                let actual: String = sqlx::query_scalar(&format!(
                    "SELECT eql_v3.{agg}(({col})::{d})::text FROM {fixture}",
                    agg = $agg_fn,
                )).fetch_one(&pool).await?;

                assert_eq!(
                    actual, expected,
                    "eql_v3.{}({}) must return the payload of plaintext={:?} (the fixture {})",
                    $agg_fn, d, extremum, $agg_fn,
                );

                // Secondary diagnostic: when the primary identity holds,
                // the ordering comparator must agree. The check is reached only
                // on success of `assert_eq!`, so it's a self-consistency
                // assertion on the comparator — catches the regression
                // where payload text matches but the ordering term resolves to a
                // different value (e.g. due to payload-key reordering). Routed
                // through the ord-extractor seam so scalars use `eql_v3.ord_term`
                // and SteVec entries use `eql_v3.ore_cllw`.
                let lhs_ord = (spec.ord_extractor)(&format!("eql_v3.{}(({col})::{d})", $agg_fn));
                let rhs_ord = (spec.ord_extractor)(&format!("$1::jsonb::{d}"));
                let ord_terms_match: bool = sqlx::query_scalar(&format!(
                    "SELECT {lhs_ord} = {rhs_ord} FROM {fixture}",
                ))
                .bind(&expected)
                .fetch_one(&pool)
                .await?;
                anyhow::ensure!(
                    ord_terms_match,
                    "eql_v3.ord_term(eql_v3.{}({})) must equal eql_v3.ord_term(<expected payload>) \
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
                    "SELECT eql_v3.{agg}(value)::text FROM empty_agg",
                    agg = $agg_fn,
                )).fetch_one(&mut *tx).await?;
                anyhow::ensure!(
                    result.is_none(),
                    "empty rowset to eql_v3.{} on {} must return NULL, got {:?}",
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
                    "SELECT eql_v3.{agg}(NULL::{d})::text FROM generate_series(1, 3)",
                    agg = $agg_fn,
                );
                let result: Option<String> = sqlx::query_scalar(&sql)
                    .fetch_one(&pool)
                    .await?;
                anyhow::ensure!(
                    result.is_none(),
                    "all-NULL input to eql_v3.{} on {} must return NULL, got {:?}; SQL={}",
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
                let col = &spec.column_expr;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let values: &[$scalar] = <$scalar as ScalarType>::fixture_values();
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
                let low: $scalar = sorted.first().expect("non-empty after len check").clone();
                let high: $scalar = sorted.last().expect("non-empty after len check").clone();
                // .min() / .max() on two values resolves to the correct picker.
                // Clone so `low`/`high` survive for the literals below.
                let expected_plaintext: $scalar = low.clone().$picker(high.clone());
                let low_lit = <$scalar as ScalarType>::to_sql_literal(&low);
                let high_lit = <$scalar as ScalarType>::to_sql_literal(&high);
                let expected_lit = <$scalar as ScalarType>::to_sql_literal(&expected_plaintext);

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE mixed_null (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO mixed_null(value) \
                     SELECT NULL::{d} \
                     UNION ALL SELECT ({col})::{d} FROM {fixture} WHERE plaintext = {low} \
                     UNION ALL SELECT NULL::{d} \
                     UNION ALL SELECT ({col})::{d} FROM {fixture} WHERE plaintext = {high} \
                     UNION ALL SELECT NULL::{d}", low = low_lit, high = high_lit,
                )).execute(&mut *tx).await?;

                let expected: String = sqlx::query_scalar(&format!(
                    "SELECT (({col})::{d})::text FROM {fixture} WHERE plaintext = {lit}", lit = expected_lit,
                )).fetch_one(&mut *tx).await?;

                let actual: Option<String> = sqlx::query_scalar(&format!(
                    "SELECT eql_v3.{agg}(value)::text FROM mixed_null",
                    agg = $agg_fn,
                )).fetch_one(&mut *tx).await?;

                anyhow::ensure!(
                    actual.as_deref() == Some(expected.as_str()),
                    "eql_v3.{} on mixed NULL/non-NULL must return the {} non-NULL value (plaintext={:?}); want {expected:?}, got {actual:?}",
                    $agg_fn, $agg_fn, expected_plaintext,
                );

                tx.commit().await?;
                Ok(())
            }
        }
    };
}

// ============================================================================
// Aggregate parallelism category — per ord domain, assert that the catalog
// declares MIN/MAX as PARALLEL SAFE with a combine function. Without those,
// PostgreSQL silently forecloses partial/parallel aggregation on exactly the
// large GROUP BY workloads these ORE aggregates exist to serve (#239 thread
// 22). A catalog-level structural guard (cheap, deterministic, no plan
// dependence) rather than a flaky "force a parallel plan" behavioural test.
// ============================================================================

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_parallel_outer {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        domains = [$($domain:tt),* $(,)?] $(,)?
    ) => {
        $(
            $crate::__scalar_matrix_aggregate_parallel_case! {
                suite = $suite, scalar = $scalar, domain = $domain,
            }
        )*
    };
}

#[macro_export]
#[doc(hidden)]
macro_rules! __scalar_matrix_aggregate_parallel_case {
    (
        suite = $suite:ident, scalar = $scalar:ty,
        domain = ($dom_name:ident, $variant:ident) $(,)?
    ) => {
        $crate::paste::paste! {
            #[sqlx::test]
            async fn [<matrix_ $suite _ $dom_name _aggregate_parallel_safe>](
                pool: sqlx::PgPool,
            ) -> anyhow::Result<()> {
                let spec = $crate::__scalar_matrix_spec!($scalar, $variant);
                let d = &spec.sql_domain;
                for agg in ["min", "max"] {
                    let (proparallel, has_combine): (String, bool) = sqlx::query_as(
                        "SELECT p.proparallel::text, a.aggcombinefn <> 0 \
                         FROM pg_proc p \
                         JOIN pg_aggregate a ON a.aggfnoid = p.oid \
                         WHERE p.proname = $1 \
                           AND p.pronamespace = 'eql_v3'::regnamespace \
                           AND p.proargtypes[0]::regtype = $2::regtype",
                    )
                    .bind(agg)
                    .bind(d)
                    .fetch_one(&pool)
                    .await?;
                    anyhow::ensure!(proparallel == "s",
                        "eql_v3.{agg}({d}) must be PARALLEL SAFE (proparallel='s'), got {proparallel:?}");
                    anyhow::ensure!(has_combine,
                        "eql_v3.{agg}({d}) must declare a combinefunc for partial aggregation");
                }
                Ok(())
            }
        }
    };
}

// ============================================================================
// Aggregate GROUP BY category — per (ord domain, op ∈ {min, max}), build a
// temp table partitioned into two groups, populate each with a known
// subset of fixture rows, GROUP BY the group key, and assert that
// `eql_v3.<op>(value)` returns the correct extremum payload per group.
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
                let col = &spec.column_expr;
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let values: &[$scalar] = <$scalar as ScalarType>::fixture_values();
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
                let group1_extremum: $scalar = group1.iter().cloned().$picker()
                    .expect("group 1 is non-empty");
                let group2_extremum: $scalar = group2.iter().cloned().$picker()
                    .expect("group 2 is non-empty");
                let g1_lit = <$scalar as ScalarType>::to_sql_literal(&group1_extremum);
                let g2_lit = <$scalar as ScalarType>::to_sql_literal(&group2_extremum);

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE group_test (group_key int, value {d}) \
ON COMMIT DROP",
                )).execute(&mut *tx).await?;

                // Insert group 1 rows.
                for v in group1 {
                    let lit = <$scalar as ScalarType>::to_sql_literal(v);
                    sqlx::query(&format!(
                        "INSERT INTO group_test(group_key, value) \
SELECT 1, ({col})::{d} FROM {fixture} WHERE plaintext = {lit}",
                    )).execute(&mut *tx).await?;
                }
                // Insert group 2 rows.
                for v in group2 {
                    let lit = <$scalar as ScalarType>::to_sql_literal(v);
                    sqlx::query(&format!(
                        "INSERT INTO group_test(group_key, value) \
SELECT 2, ({col})::{d} FROM {fixture} WHERE plaintext = {lit}",
                    )).execute(&mut *tx).await?;
                }

                // Lookup the expected payload texts for each group's extremum.
                let g1_expected: String = sqlx::query_scalar(&format!(
                    "SELECT (({col})::{d})::text FROM {fixture} WHERE plaintext = {lit}", lit = g1_lit,
                )).fetch_one(&mut *tx).await?;
                let g2_expected: String = sqlx::query_scalar(&format!(
                    "SELECT (({col})::{d})::text FROM {fixture} WHERE plaintext = {lit}", lit = g2_lit,
                )).fetch_one(&mut *tx).await?;

                let rows: Vec<(i32, String)> = sqlx::query_as(&format!(
                    "SELECT group_key, eql_v3.{agg}(value)::text \
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
                    "group 1 eql_v3.{}({}) must yield payload for plaintext={:?}; \
want ({}, {:?}), got {:?}",
                    $agg_fn, d, group1_extremum, 1, g1_expected, rows[0],
                );
                anyhow::ensure!(
                    rows[1].0 == 2 && rows[1].1 == g2_expected,
                    "group 2 eql_v3.{}({}) must yield payload for plaintext={:?}; \
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
// (Storage, Eq), `eql_v3.min(<variant-column>)` / `eql_v3.max(...)` must
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
                    "SELECT eql_v3.{agg}(value) FROM typecheck_table",
                    agg = $agg_fn,
                );
                let err = sqlx::query_scalar::<_, String>(&sql)
                    .fetch_one(&mut *tx)
                    .await
                    .expect_err(&format!(
                        "eql_v3.{} on non-ord variant {} must raise but succeeded",
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
(ambiguous_function) for eql_v3.{}({}), got {:?} (message: {})",
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
// eql_v3.eq_term(eql_v3.int4_ord) does not exist") — exactly the kind of
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
                let expected = <$scalar as ScalarType>::fixture_values().len() as i64;

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE typed_count (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO typed_count(value) SELECT ({col})::{d} FROM {fixture}",
                    col = &spec.column_expr,
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
                let expected = <$scalar as ScalarType>::fixture_values().len() as i64;

                let sql = format!(
                    "SELECT COUNT(({col})::{d}) FROM {fixture}",
                    col = &spec.column_expr,
                );
                let actual: i64 = sqlx::query_scalar(&sql).fetch_one(&pool).await?;
                anyhow::ensure!(
                    actual == expected,
                    "COUNT(({})::{}) on {}: want {}, got {}; SQL={}",
                    &spec.column_expr, d, fixture, expected, actual, sql,
                );
                Ok(())
            }
        }
    };
}

// Dispatch on variant ident: Storage has no discriminating extractor, so
// emits no DISTINCT test. The other three (Eq, Ord, OrdOre) each emit one
// test that reads the extractor function name from the runtime
// `ScalarDomainSpec::extractor_fn()` accessor (Eq -> `eql_v3.eq_term`,
// Ord/OrdOre -> `eql_v3.ord_term`) and appends `(value)` at the call site.
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
                let extractor = spec.extractor_expr("value")
                    .expect("non-Storage variant must expose an extractor");
                let fixture = <$scalar as ScalarType>::fixture_table_name();
                let expected = <$scalar as ScalarType>::fixture_values().len() as i64;

                let mut tx = pool.begin().await?;
                sqlx::query(&format!(
                    "CREATE TEMP TABLE distinct_count (value {d}) ON COMMIT DROP",
                )).execute(&mut *tx).await?;
                sqlx::query(&format!(
                    "INSERT INTO distinct_count(value) SELECT ({col})::{d} FROM {fixture}",
                    col = &spec.column_expr,
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
