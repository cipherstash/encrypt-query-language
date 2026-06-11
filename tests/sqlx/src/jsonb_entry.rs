//! SteVec **entry** view type for the behaviour matrix. A `JsonbEntryInt4`
//! reuses the `i32` plaintext oracle (`expected_forward`, pivots,
//! `fixture_values`) but reaches its comparable value by extracting the entry
//! at `v3_doc_int4::SELECTOR` and casting to `eql_v3.ste_vec_entry`, so the
//! matrix's correctness/ordering/null/order-by/count/index generators run
//! against jsonb-entry comparisons instead of whole-column scalar casts.
//!
//! It is deliberately NOT a `eql_scalars::CATALOG` scalar (it has no generated
//! domain family and must stay out of the scalar matrix inventory). The entry
//! suite invokes it through the reduced `jsonb_entry_matrix!` macro.

use crate::fixtures::v3_doc_int4;
use crate::scalar_domains::{OrderedScalar, ScalarType, Variant};

/// Newtype over `i32`. `Display`/`Ord`/`Default` delegate to the inner value so
/// the inherited `expected_forward` oracle is identical to int4's.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, PartialOrd, Ord)]
pub struct JsonbEntryInt4(pub i32);

impl std::fmt::Display for JsonbEntryInt4 {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl sqlx::Type<sqlx::Postgres> for JsonbEntryInt4 {
    fn type_info() -> sqlx::postgres::PgTypeInfo {
        <i32 as sqlx::Type<sqlx::Postgres>>::type_info()
    }
}

impl<'r> sqlx::Decode<'r, sqlx::Postgres> for JsonbEntryInt4 {
    fn decode(value: sqlx::postgres::PgValueRef<'r>) -> Result<Self, sqlx::error::BoxDynError> {
        Ok(JsonbEntryInt4(
            <i32 as sqlx::Decode<sqlx::Postgres>>::decode(value)?,
        ))
    }
}

/// Fixture values: int4's list, wrapped. Materialised once into a `LazyLock`
/// because the trait returns `&'static [Self]` and `i32`'s const slice cannot
/// be reinterpreted as `&[JsonbEntryInt4]` without an allocation.
static VALUES: std::sync::LazyLock<Vec<JsonbEntryInt4>> = std::sync::LazyLock::new(|| {
    eql_scalars::INT4_VALUES
        .iter()
        .copied()
        .map(JsonbEntryInt4)
        .collect()
});

impl ScalarType for JsonbEntryInt4 {
    /// Drives `fixture_table_name()`'s default; overridden below, but kept
    /// honest (the entry is an int4-shaped document).
    const PG_TYPE: &'static str = "int4";

    fn fixture_values() -> &'static [Self] {
        &VALUES
    }

    /// The scalar-shaped document fixture, not `fixtures.eql_v2_int4`.
    fn fixture_table_name() -> String {
        "fixtures.v3_doc_int4".to_string()
    }

    /// Single entry domain, variant-independent.
    fn sql_domain(_variant: Variant) -> String {
        "eql_v3.ste_vec_entry".to_string()
    }

    /// Extract the entry at the pinned selector. `->` already yields
    /// `eql_v3.ste_vec_entry`; the call sites' `::eql_v3.ste_vec_entry` cast is
    /// a no-op. The selector literal is explicitly typed as text so Postgres
    /// resolves the `eql_v3.json -> text` operator instead of native jsonb path
    /// lookup. Parenthesised by the call sites (`({col})::{d}`).
    fn column_expr() -> String {
        format!("payload -> '{}'::text", v3_doc_int4::SELECTOR)
    }

    fn to_sql_literal(value: &Self) -> String {
        value.0.to_string()
    }

    /// Valid `eql_v3.ste_vec_entry` literal for tests that only need a non-NULL
    /// operand shape (NULL propagation). Must satisfy the domain CHECK: string
    /// `s`, string `c`, exactly one of `hm`/`oc`.
    fn placeholder_payload() -> &'static str {
        r#"{"s":"placeholder","c":"sample","oc":"00"}"#
    }

    fn eq_extractor_expr(value_expr: &str) -> String {
        format!("eql_v3.eq_term({value_expr})")
    }

    fn ord_extractor_expr(value_expr: &str) -> String {
        format!("eql_v3.ore_cllw({value_expr})")
    }
}

impl OrderedScalar for JsonbEntryInt4 {
    fn min_pivot() -> Self {
        JsonbEntryInt4(<i32 as OrderedScalar>::min_pivot())
    }
    fn max_pivot() -> Self {
        JsonbEntryInt4(<i32 as OrderedScalar>::max_pivot())
    }
    fn mid_pivot() -> Self {
        JsonbEntryInt4(<i32 as OrderedScalar>::mid_pivot())
    }
}

// `JsonbEntryInt4` is deliberately NOT `SignedScalar` — the entry suite does
// not run the signed-only sign-boundary test. `expected_forward` is the
// inherited default from `ScalarType` (it works for any `Ord` type), so the
// oracle is automatically int4-identical.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn delegates_oracle_to_int4() {
        // Same forward result set as i32 for a representative op/pivot.
        let got = <JsonbEntryInt4 as ScalarType>::expected_forward(">", JsonbEntryInt4(0));
        let want: Vec<JsonbEntryInt4> = <i32 as ScalarType>::expected_forward(">", 0)
            .into_iter()
            .map(JsonbEntryInt4)
            .collect();
        assert_eq!(got, want);
    }

    #[test]
    fn extracts_entry_at_selector() {
        assert_eq!(
            <JsonbEntryInt4 as ScalarType>::column_expr(),
            format!("payload -> '{}'::text", v3_doc_int4::SELECTOR),
        );
        assert_eq!(
            <JsonbEntryInt4 as ScalarType>::sql_domain(Variant::Ord),
            "eql_v3.ste_vec_entry",
        );
        assert_eq!(
            <JsonbEntryInt4 as ScalarType>::ord_extractor_expr("value"),
            "eql_v3.ore_cllw(value)",
        );
        assert_eq!(
            <JsonbEntryInt4 as ScalarType>::eq_extractor_expr("value"),
            "eql_v3.eq_term(value)",
        );
    }

    #[test]
    fn fixture_values_wrap_int4_values_in_order() {
        let got: Vec<i32> = <JsonbEntryInt4 as ScalarType>::fixture_values()
            .iter()
            .map(|e| e.0)
            .collect();
        assert_eq!(got, eql_scalars::INT4_VALUES.to_vec());
    }

    #[test]
    fn pivots_delegate_to_int4() {
        assert_eq!(<JsonbEntryInt4 as OrderedScalar>::min_pivot().0, i32::MIN);
        assert_eq!(<JsonbEntryInt4 as OrderedScalar>::max_pivot().0, i32::MAX);
        assert_eq!(<JsonbEntryInt4 as OrderedScalar>::mid_pivot().0, 0);
    }

    /// The placeholder must satisfy the `eql_v3.ste_vec_entry` CHECK shape:
    /// string `s`, string `c`, exactly one of `hm`/`oc`. (SQL-level validity is
    /// asserted in the integration `jsonb_entry` suite against the live domain.)
    #[test]
    fn placeholder_is_a_valid_entry_shape() {
        let v: serde_json::Value =
            serde_json::from_str(<JsonbEntryInt4 as ScalarType>::placeholder_payload()).unwrap();
        assert!(v.get("s").and_then(|x| x.as_str()).is_some());
        assert!(v.get("c").and_then(|x| x.as_str()).is_some());
        let has_hm = v.get("hm").is_some();
        let has_oc = v.get("oc").is_some();
        assert!(has_hm ^ has_oc, "exactly one of hm/oc must be present");
    }
}
