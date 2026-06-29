//! Unit tests for the scalar/term catalog. Kept as one `#[cfg(test)]` module
//! (declared from `lib.rs`) rather than co-located with each impl file because
//! `rust_tests` spans `BoundedIntKind` + `ScalarKind` + `Fixture` +
//! `DomainFamily`. Each inner module imports the crate-root catalog with
//! `use crate::*;`; the crate-local `fixtures!` macro is in scope here via the
//! `#[macro_use] mod fixtures;` chain in `lib.rs` (it is defined in
//! `fixtures/fixture.rs`).

mod rust_tests {
    use crate::*;

    #[test]
    fn bounded_int_kind_accessors_are_total() {
        assert_eq!(BoundedIntKind::I16.rust_type(), "i16");
        assert_eq!(BoundedIntKind::I16.min_symbol(), "i16::MIN");
        assert_eq!(BoundedIntKind::I16.max_symbol(), "i16::MAX");
        assert_eq!(BoundedIntKind::I16.zero_symbol(), "0");
        assert_eq!(BoundedIntKind::I16.min_value(), -32_768_i128);
        assert_eq!(BoundedIntKind::I16.max_value(), 32_767_i128);

        assert_eq!(BoundedIntKind::I32.min_symbol(), "i32::MIN");
        assert_eq!(BoundedIntKind::I32.min_value(), -2_147_483_648_i128);
        assert_eq!(BoundedIntKind::I32.max_value(), 2_147_483_647_i128);

        assert_eq!(BoundedIntKind::I64.max_symbol(), "i64::MAX");
        assert_eq!(
            BoundedIntKind::I64.min_value(),
            -9_223_372_036_854_775_808_i128
        );
        assert_eq!(
            BoundedIntKind::I64.max_value(),
            9_223_372_036_854_775_807_i128
        );
    }

    #[test]
    fn as_bounded_int_maps_integer_kinds_only() {
        assert_eq!(ScalarKind::I16.as_bounded_int(), Some(BoundedIntKind::I16));
        assert_eq!(ScalarKind::I32.as_bounded_int(), Some(BoundedIntKind::I32));
        assert_eq!(ScalarKind::I64.as_bounded_int(), Some(BoundedIntKind::I64));
        assert_eq!(ScalarKind::Numeric.as_bounded_int(), None);
        assert_eq!(ScalarKind::Text.as_bounded_int(), None);
        assert_eq!(ScalarKind::Jsonb.as_bounded_int(), None);
        assert_eq!(ScalarKind::Date.as_bounded_int(), None);
        assert_eq!(ScalarKind::Timestamptz.as_bounded_int(), None);
        assert_eq!(ScalarKind::F32.as_bounded_int(), None);
        assert_eq!(ScalarKind::F64.as_bounded_int(), None);
    }

    #[test]
    fn i32_facts_match_int4() {
        assert_eq!(ScalarKind::I32.rust_type(), "i32");
        let k = ScalarKind::I32
            .as_bounded_int()
            .expect("I32 is an integer kind");
        assert_eq!(k.min_symbol(), "i32::MIN");
        assert_eq!(k.max_symbol(), "i32::MAX");
        assert_eq!(k.zero_symbol(), "0");
        assert_eq!(k.min_value(), -2_147_483_648_i128);
        assert_eq!(k.max_value(), 2_147_483_647_i128);
    }

    #[test]
    fn i16_facts_match_int2() {
        assert_eq!(ScalarKind::I16.rust_type(), "i16");
        let k = ScalarKind::I16
            .as_bounded_int()
            .expect("I16 is an integer kind");
        assert_eq!(k.min_symbol(), "i16::MIN");
        assert_eq!(k.max_symbol(), "i16::MAX");
        assert_eq!(k.zero_symbol(), "0");
        assert_eq!(k.min_value(), -32_768_i128);
        assert_eq!(k.max_value(), 32_767_i128);
    }

    #[test]
    fn is_int_classifies_kinds() {
        assert!(ScalarKind::I16.is_int());
        assert!(ScalarKind::I32.is_int());
        assert!(ScalarKind::I64.is_int());
        assert!(!ScalarKind::Numeric.is_int());
        assert!(!ScalarKind::Text.is_int());
        assert!(!ScalarKind::Jsonb.is_int());
        assert!(!ScalarKind::Date.is_int());
        assert!(!ScalarKind::Timestamptz.is_int());
        assert!(!ScalarKind::F32.is_int());
        assert!(!ScalarKind::F64.is_int());
    }

    #[test]
    fn is_text_classifies_only_text() {
        assert!(ScalarKind::Text.is_text());
        for k in [
            ScalarKind::I16,
            ScalarKind::I32,
            ScalarKind::I64,
            ScalarKind::Numeric,
            ScalarKind::Jsonb,
            ScalarKind::Date,
            ScalarKind::Timestamptz,
            ScalarKind::F32,
            ScalarKind::F64,
        ] {
            assert!(!k.is_text());
        }
    }

    #[test]
    fn i64_facts() {
        // Capability-layer fact: i64 is the Rust kind a future int8 maps onto.
        // Present here so adding int8 later is a pure `CATALOG` append.
        assert_eq!(ScalarKind::I64.rust_type(), "i64");
        let k = ScalarKind::I64
            .as_bounded_int()
            .expect("I64 is an integer kind");
        assert_eq!(k.min_symbol(), "i64::MIN");
        assert_eq!(k.max_symbol(), "i64::MAX");
        assert_eq!(k.zero_symbol(), "0");
        assert_eq!(k.min_value(), -9_223_372_036_854_775_808_i128);
        assert_eq!(k.max_value(), 9_223_372_036_854_775_807_i128);
    }

    #[test]
    fn date_maps_to_naive_date() {
        // Ordered, non-integer kind: it carries a rust type but no i128 range,
        // so it is not `is_int()` and `as_bounded_int()` returns `None` — the
        // bounded accessors are simply not reachable for it.
        assert_eq!(ScalarKind::Date.rust_type(), "chrono::NaiveDate");
        assert!(!ScalarKind::Date.is_int());
        assert_eq!(ScalarKind::Date.as_bounded_int(), None);
    }

    #[test]
    fn timestamptz_maps_to_datetime() {
        // Temporal, non-integer, ordered kind: it carries a rust type but no
        // i128 range, so it is not `is_int()` and `as_bounded_int()` returns
        // `None` — the bounded accessors are not reachable for it.
        assert_eq!(ScalarKind::Timestamptz.rust_type(), "chrono::DateTime<Utc>");
        assert!(!ScalarKind::Timestamptz.is_int());
        assert_eq!(ScalarKind::Timestamptz.as_bounded_int(), None);
    }

    #[test]
    fn text_maps_to_string() {
        // `rust_type()` is the canonical Rust *plaintext* type name, not the SQL
        // token: `text` maps onto an owned `String`, matching the other arms
        // (`chrono::NaiveDate`, `rust_decimal::Decimal`) which all name Rust types.
        assert_eq!(ScalarKind::Text.rust_type(), "String");
        assert!(ScalarKind::Text.is_text());
        assert!(!ScalarKind::Text.is_int());
        assert_eq!(ScalarKind::Text.as_bounded_int(), None);
    }

    #[test]
    fn numeric_maps_to_decimal() {
        // Ordered, non-integer, non-chrono kind (14-block ORE): carries a rust
        // type but no i128 range, so it is not `is_int()` and `as_bounded_int()`
        // returns `None`. Pins the now-real `rust_type` arm (it no longer panics).
        assert_eq!(ScalarKind::Numeric.rust_type(), "rust_decimal::Decimal");
        assert!(!ScalarKind::Numeric.is_int());
        assert_eq!(ScalarKind::Numeric.as_bounded_int(), None);
    }

    /// The structural guarantee that replaces the old runtime panics: a
    /// `Min`/`Max`/`Zero` pivot sentinel may only appear in a `CATALOG` row whose
    /// kind is an integer kind. `numeric_value` would resolve to `None` for a
    /// pivot on a non-integer kind; this test makes such a row a test failure at
    /// the source of truth.
    #[test]
    fn pivot_sentinels_only_appear_with_integer_kinds() {
        for rec in FIXTURES {
            for fixture in rec.values {
                if matches!(fixture, Fixture::Min | Fixture::Max | Fixture::Zero) {
                    assert!(
                        rec.kind.is_int(),
                        "pivot sentinel {fixture:?} on non-integer kind {:?} (token `{}`)",
                        rec.kind,
                        rec.family.name,
                    );
                }
            }
        }
    }

    #[test]
    fn is_temporal_classifies_chrono_kinds() {
        assert!(ScalarKind::Date.is_temporal());
        assert!(ScalarKind::Timestamptz.is_temporal());
        assert!(!ScalarKind::I16.is_temporal());
        assert!(!ScalarKind::I32.is_temporal());
        assert!(!ScalarKind::I64.is_temporal());
        assert!(!ScalarKind::F32.is_temporal());
        assert!(!ScalarKind::F64.is_temporal());
    }

    #[test]
    fn is_eq_only_detects_absence_of_ord_domains() {
        let int4 = CATALOG.iter().find(|s| s.name == "int4").unwrap();
        assert!(!int4.is_eq_only(), "int4 is ordered");
        let date = CATALOG.iter().find(|s| s.name == "date").unwrap();
        assert!(!date.is_eq_only(), "date is ordered");
        let ts = CATALOG.iter().find(|s| s.name == "timestamptz").unwrap();
        assert!(
            !ts.is_eq_only(),
            "timestamptz is now ordered (native 12-block ORE, comparator generalized to N blocks)"
        );

        // No catalog type is currently eq-only, so exercise `is_eq_only()`'s
        // positive path with a synthetic spec built on the retained
        // `EQ_ONLY_DOMAINS` shape (storage + `_eq`, no `_ord`).
        let eq_only = DomainFamily {
            name: "synthetic_eq_only",
            domains: EQ_ONLY_DOMAINS,
        };
        assert!(
            eq_only.is_eq_only(),
            "a storage+_eq spec (no _ord) must be detected as eq-only"
        );
    }
}

mod term_tests {
    use crate::*;

    #[test]
    fn hm_term_provides_equality() {
        let hm = Term::Hm;
        assert_eq!(hm.json_key(), "hm");
        assert_eq!(hm.extractor(), "eq_term");
        assert_eq!(hm.ctor(), "hmac_256");
        assert_eq!(hm.role(), Role::Eq);
        assert_eq!(hm.operators(), &["=", "<>"]);
        assert_eq!(hm.requires(), &["src/v3/sem/hmac_256/functions.sql"]);
    }

    #[test]
    fn ore_term_preserves_int4_sql_contract() {
        let ore = Term::Ore;
        assert_eq!(ore.json_key(), "ob");
        assert_eq!(ore.extractor(), "ord_term");
        assert_eq!(ore.ctor(), "ore_block_256");
        assert_eq!(ore.role(), Role::Ord);
        assert_eq!(ore.operators(), &["=", "<>", "<", "<=", ">", ">="]);
        assert_eq!(
            ore.requires(),
            &[
                "src/v3/sem/ore_block_256/functions.sql",
                "src/v3/sem/ore_block_256/operators.sql",
            ]
        );
    }

    #[test]
    fn bloom_term_contract() {
        let b = Term::Bloom;
        assert_eq!(b.json_key(), "bf");
        assert_eq!(b.extractor(), "match_term");
        assert_eq!(b.ctor(), "bloom_filter");
        assert_eq!(b.role(), Role::Match);
        assert_eq!(b.operators(), &["@>", "<@"]);
        assert_eq!(b.requires(), &["src/v3/sem/bloom_filter/functions.sql"]);
    }

    #[test]
    fn bloom_extractor_routes_match_operators() {
        let terms = &[Term::Bloom];
        assert_eq!(
            Term::extractor_for_operator(terms, "@>"),
            Some("match_term")
        );
        assert_eq!(
            Term::extractor_for_operator(terms, "<@"),
            Some("match_term")
        );
        assert_eq!(Term::extractor_for_operator(terms, "="), None);
    }

    #[test]
    fn bloom_role_is_match_not_ord() {
        assert_eq!(Term::role_for_terms(&[Term::Bloom]), Role::Match);
        // match is not ord-capable: no aggregates.
        assert_ne!(Term::role_for_terms(&[Term::Bloom]), Role::Ord);
    }

    #[test]
    fn role_labels_are_stable() {
        assert_eq!(Role::Storage.label(), "storage");
        assert_eq!(Role::Eq.label(), "eq");
        assert_eq!(Role::Ord.label(), "ord");
        assert_eq!(Role::Match.label(), "match");
    }
}

mod term_helper_tests {
    use crate::*;

    #[test]
    fn operators_are_union_in_catalog_order() {
        // ore then hm: ore's six ops first, hm adds nothing new.
        assert_eq!(
            Term::operators_for_terms(&[Term::Ore, Term::Hm]),
            vec!["=", "<>", "<", "<=", ">", ">="]
        );
    }

    #[test]
    fn operators_for_terms_handles_empty() {
        assert!(Term::operators_for_terms(&[]).is_empty());
    }

    #[test]
    fn json_keys_come_from_catalog() {
        assert_eq!(
            Term::term_json_keys(&[Term::Hm, Term::Ore]),
            vec!["hm", "ob"]
        );
        assert!(Term::term_json_keys(&[]).is_empty());
    }

    #[test]
    fn nonempty_array_key_is_ob_only_for_ore() {
        assert_eq!(Term::Ore.nonempty_array_key(), Some("ob"));
        assert_eq!(Term::Hm.nonempty_array_key(), None);
        assert_eq!(Term::Bloom.nonempty_array_key(), None);
    }

    #[test]
    fn nonempty_array_keys_collects_only_ore() {
        // text_search-shaped term set: only the ORE term contributes a key.
        assert_eq!(
            Term::nonempty_array_keys(&[Term::Hm, Term::Ore, Term::Bloom]),
            vec!["ob"]
        );
        // No ORE term => no non-empty-array CHECK.
        assert!(Term::nonempty_array_keys(&[Term::Hm]).is_empty());
        assert!(Term::nonempty_array_keys(&[Term::Bloom]).is_empty());
        assert!(Term::nonempty_array_keys(&[]).is_empty());
    }

    #[test]
    fn requires_are_deduplicated_in_order() {
        assert_eq!(
            Term::term_requires(&[Term::Ore, Term::Ore, Term::Hm]),
            vec![
                "src/v3/sem/ore_block_256/functions.sql",
                "src/v3/sem/ore_block_256/operators.sql",
                "src/v3/sem/hmac_256/functions.sql",
            ]
        );
        assert!(Term::term_requires(&[]).is_empty());
    }

    #[test]
    fn role_for_terms_handles_storage_eq_ord() {
        assert_eq!(Term::role_for_terms(&[]), Role::Storage);
        assert_eq!(Term::role_for_terms(&[Term::Hm]), Role::Eq);
        assert_eq!(Term::role_for_terms(&[Term::Ore]), Role::Ord);
    }

    #[test]
    fn role_for_terms_takes_richest_role_order_independently() {
        // A mixed-term domain resolves to the richest role by Role::rank
        // precedence (Ord > Eq > Match > Storage), regardless of term order —
        // consistent with operators_for_terms' union, not the first term. No
        // catalog domain is multi-term today; this pins the semantics so a future
        // `[Hm, Ore]` domain generates the ord surface (and its aggregates).
        assert_eq!(Term::role_for_terms(&[Term::Hm, Term::Ore]), Role::Ord);
        assert_eq!(Term::role_for_terms(&[Term::Ore, Term::Hm]), Role::Ord);
        assert_eq!(Term::role_for_terms(&[Term::Hm, Term::Bloom]), Role::Eq);
        assert_eq!(Term::role_for_terms(&[Term::Bloom, Term::Hm]), Role::Eq);
    }

    #[test]
    fn role_rank_orders_richest_comparison_highest() {
        assert!(Role::Ord.rank() > Role::Eq.rank());
        assert!(Role::Eq.rank() > Role::Match.rank());
        assert!(Role::Match.rank() > Role::Storage.rank());
    }

    #[test]
    fn extractor_terms_dedupes_by_extractor_first_occurrence_wins() {
        // No catalog domain currently carries two terms sharing an extractor, so
        // this exercises the dedupe branch directly: Hm and Ore have distinct
        // extractors (eq_term / ord_term) and survive; the repeated term collapses.
        assert_eq!(
            Term::extractor_terms(&[Term::Hm, Term::Ore, Term::Hm]),
            vec![Term::Hm, Term::Ore]
        );
        // First-occurrence order: Ore before Hm stays Ore, Hm.
        assert_eq!(
            Term::extractor_terms(&[Term::Ore, Term::Hm, Term::Ore]),
            vec![Term::Ore, Term::Hm]
        );
        assert_eq!(Term::extractor_terms(&[]), Vec::<Term>::new());
    }

    #[test]
    fn extractor_for_operator_picks_first_supporting_term() {
        assert_eq!(
            Term::extractor_for_operator(&[Term::Hm], "="),
            Some("eq_term")
        );
        assert_eq!(
            Term::extractor_for_operator(&[Term::Ore], "<"),
            Some("ord_term")
        );
        assert_eq!(
            Term::extractor_for_operator(&[Term::Hm, Term::Ore], "="),
            Some("eq_term")
        );
        assert_eq!(
            Term::extractor_for_operator(&[Term::Hm, Term::Ore], "<"),
            Some("ord_term")
        );
    }

    #[test]
    fn extractor_for_operator_none_when_unsupported() {
        assert_eq!(Term::extractor_for_operator(&[Term::Hm], "<"), None);
        assert_eq!(Term::extractor_for_operator(&[], "="), None);
    }
}

mod fixture_tests {
    use crate::*;

    #[test]
    fn numeric_value_resolves_sentinels_and_literals_for_i32() {
        assert_eq!(
            Fixture::Min.numeric_value(ScalarKind::I32),
            Some(-2_147_483_648)
        );
        assert_eq!(
            Fixture::Max.numeric_value(ScalarKind::I32),
            Some(2_147_483_647)
        );
        assert_eq!(Fixture::Zero.numeric_value(ScalarKind::I32), Some(0));
        assert_eq!(Fixture::Int(42).numeric_value(ScalarKind::I32), Some(42));
        assert_eq!(Fixture::Int(-1).numeric_value(ScalarKind::I32), Some(-1));
    }

    #[test]
    fn numeric_value_resolves_sentinels_per_kind() {
        // Sentinels resolve to the kind's bounds; zero is always 0.
        assert_eq!(Fixture::Min.numeric_value(ScalarKind::I16), Some(-32_768));
        assert_eq!(Fixture::Max.numeric_value(ScalarKind::I16), Some(32_767));
        assert_eq!(
            Fixture::Min.numeric_value(ScalarKind::I64),
            Some(-9_223_372_036_854_775_808)
        );
        assert_eq!(
            Fixture::Max.numeric_value(ScalarKind::I64),
            Some(9_223_372_036_854_775_807)
        );
        assert_eq!(Fixture::Zero.numeric_value(ScalarKind::I64), Some(0));
        // `Int` resolves verbatim; no runtime range-check here.
        assert_eq!(
            Fixture::Int(5_000_000_000).numeric_value(ScalarKind::I64),
            Some(5_000_000_000)
        );
    }

    #[test]
    fn numeric_value_is_none_for_string_variants() {
        assert_eq!(Fixture::Text("alice").numeric_value(ScalarKind::Text), None);
        assert_eq!(
            Fixture::Numeric("3.14").numeric_value(ScalarKind::Numeric),
            None
        );
        assert_eq!(
            Fixture::Jsonb(r#"{"a":1}"#).numeric_value(ScalarKind::Jsonb),
            None
        );
        assert_eq!(
            Fixture::Date("1970-01-01").numeric_value(ScalarKind::Date),
            None
        );
        assert_eq!(
            Fixture::Timestamptz("1970-01-01T00:00:00Z").numeric_value(ScalarKind::Timestamptz),
            None
        );
    }

    #[test]
    fn sentinel_value_is_none_on_non_integer_kinds() {
        // Directly pins the `kind.as_bounded_int() => None` arm of
        // `numeric_value` for the pivot sentinels. Previously `Fixture::Zero`
        // returned `Some(0)` unconditionally; a refactor that restored that
        // would make the two `Zero` cases below fail. The
        // `pivot_sentinels_only_appear_with_integer_kinds` catalog invariant
        // guards this only indirectly.
        assert_eq!(Fixture::Zero.numeric_value(ScalarKind::Date), None);
        assert_eq!(Fixture::Zero.numeric_value(ScalarKind::Text), None);
        assert_eq!(Fixture::Min.numeric_value(ScalarKind::Text), None);
        assert_eq!(Fixture::Max.numeric_value(ScalarKind::Date), None);
    }

    #[test]
    fn int_literal_value_is_none_on_non_integer_kinds() {
        // `Fixture::Int(n)` is gated on the integer kinds like the sentinels: a
        // hand-built literal paired with a non-integer kind has no integer
        // projection and must resolve to `None`, not fabricate `Some(n)`.
        assert_eq!(Fixture::Int(7).numeric_value(ScalarKind::Text), None);
        assert_eq!(Fixture::Int(7).numeric_value(ScalarKind::Date), None);
        assert_eq!(Fixture::Int(7).numeric_value(ScalarKind::Bool), None);
        // Still resolves verbatim on an integer kind.
        assert_eq!(Fixture::Int(7).numeric_value(ScalarKind::I32), Some(7));
    }

    #[test]
    fn fixtures_macro_builds_each_kind() {
        // The int arm range-checks at compile time; sentinels + literals mix.
        const INTS: &[Fixture] = fixtures!(int i16; Min, N(-1), Zero, N(30000), Max);
        assert_eq!(
            INTS,
            &[
                Fixture::Min,
                Fixture::Int(-1),
                Fixture::Zero,
                Fixture::Int(30000),
                Fixture::Max
            ]
        );
        // The string arms wrap into the matching variant.
        const TEXTS: &[Fixture] = fixtures!(text; "alice", "bob");
        assert_eq!(TEXTS, &[Fixture::Text("alice"), Fixture::Text("bob")]);
        const NUMS: &[Fixture] = fixtures!(numeric; "0.1", "-2.5");
        assert_eq!(NUMS, &[Fixture::Numeric("0.1"), Fixture::Numeric("-2.5")]);
        const JSONS: &[Fixture] = fixtures!(jsonb; r#"{"a":1}"#);
        assert_eq!(JSONS, &[Fixture::Jsonb(r#"{"a":1}"#)]);
        const DATES: &[Fixture] = fixtures!(date; "1970-01-01", "2099-12-31");
        assert_eq!(
            DATES,
            &[Fixture::Date("1970-01-01"), Fixture::Date("2099-12-31")]
        );
        const STAMPS: &[Fixture] =
            fixtures!(timestamptz; "1970-01-01T00:00:00Z", "2099-12-31T23:59:59Z");
        assert_eq!(
            STAMPS,
            &[
                Fixture::Timestamptz("1970-01-01T00:00:00Z"),
                Fixture::Timestamptz("2099-12-31T23:59:59Z")
            ]
        );
    }

    #[test]
    fn fixtures_macro_handles_degenerate_inputs() {
        // Empty list — every arm accepts zero elements.
        const NO_INT: &[Fixture] = fixtures!(int i32;);
        const NO_TEXT: &[Fixture] = fixtures!(text;);
        assert_eq!(NO_INT, &[] as &[Fixture]);
        assert_eq!(NO_TEXT, &[] as &[Fixture]);
        // Trailing comma — int muncher (leading-comma rule) and string arm `$(,)?`.
        const TRAILING_INT: &[Fixture] = fixtures!(int i32; Min, N(1),);
        const TRAILING_TEXT: &[Fixture] = fixtures!(text; "a",);
        assert_eq!(TRAILING_INT, &[Fixture::Min, Fixture::Int(1)]);
        assert_eq!(TRAILING_TEXT, &[Fixture::Text("a")]);
        // Sentinels-only, no `N(..)`.
        const SENTINELS: &[Fixture] = fixtures!(int i32; Min, Zero, Max);
        assert_eq!(SENTINELS, &[Fixture::Min, Fixture::Zero, Fixture::Max]);
    }
}

mod catalog_tests {
    use crate::*;

    fn scalar(token: &str) -> &'static DomainFamily {
        CATALOG
            .iter()
            .find(|s| s.name == token)
            .unwrap_or_else(|| panic!("{token} missing from CATALOG"))
    }

    fn fixtures(token: &str) -> &'static TypeFixtures {
        FIXTURES
            .iter()
            .find(|f| f.family.name == token)
            .unwrap_or_else(|| panic!("{token} missing from FIXTURES"))
    }

    #[test]
    fn catalog_has_all_tokens_in_order() {
        let tokens: Vec<&str> = CATALOG.iter().map(|s| s.name).collect();
        assert_eq!(
            tokens,
            vec![
                "int4",
                "int2",
                "int8",
                "date",
                "timestamptz",
                "numeric",
                "text",
                "bool",
                "float4",
                "float8"
            ]
        );
    }

    #[test]
    fn bool_spec_is_storage_only_encryption_only() {
        let b = scalar("bool");
        let bf = fixtures("bool");
        assert_eq!(bf.kind, ScalarKind::Bool);
        assert_eq!(bf.kind.rust_type(), "bool");
        // Storage-only: exactly one term-less domain, no `_eq`/`_ord` — no SEM
        // index term, no comparison surface.
        let shape: Vec<(&str, &[Term])> = b.domains.iter().map(|d| (d.name, d.terms)).collect();
        assert_eq!(shape, vec![("", &[] as &[Term])]);
        // bool is none of the comparison-capable kinds.
        assert!(!bf.kind.is_int());
        assert!(!bf.kind.is_temporal());
        assert!(!bf.kind.is_text());
        assert_eq!(bf.kind.as_bounded_int(), None);
        // is_eq_only() is true (no `_ord` domain), but the shape is strictly
        // smaller than eq-only — there is no `_eq` domain either, so it is
        // storage-only.
        assert!(b.is_eq_only());
        assert!(b.is_storage_only());
        assert!(b.domain_by_name("eq").is_none());
        // Both boolean plaintexts are present as fixtures.
        assert_eq!(bf.values, &[Fixture::Bool(false), Fixture::Bool(true)]);
    }

    #[test]
    fn storage_only_is_exclusive_to_bool() {
        // Only `bool` is storage-only today; every comparison-capable type has at
        // least an `_eq` domain and must NOT report storage-only.
        for s in CATALOG {
            assert_eq!(
                s.is_storage_only(),
                s.name == "bool",
                "{} storage-only classification is wrong",
                s.name
            );
        }
    }

    #[test]
    fn text_spec_is_in_catalog() {
        let text = scalar("text");
        assert_eq!(fixtures("text").kind, ScalarKind::Text);
        let names: Vec<_> = text.domains.iter().map(|d| d.name).collect();
        assert_eq!(names, vec!["", "eq", "match", "ord_ore", "ord", "search"]);
    }

    #[test]
    fn text_match_domain_carries_only_bloom() {
        let text = scalar("text");
        let m = text.domains.iter().find(|d| d.name == "match").unwrap();
        assert_eq!(m.terms, &[Term::Bloom]);
    }

    #[test]
    fn provides_ordering_is_true_only_for_ore() {
        // Per-term ordering capability — distinct from Role (the whole-domain
        // file role derived from the first term). Only Ore provides `< <= > >=`.
        assert!(Term::Ore.provides_ordering());
        assert!(!Term::Hm.provides_ordering());
        assert!(!Term::Bloom.provides_ordering());
    }

    #[test]
    fn every_eq_capable_text_domain_resolves_eq_through_hm() {
        // ORE is not exact for text: `=`/`<>` must resolve to eq_term/hm on every
        // text domain that advertises equality. `text_match` ([Bloom]) never
        // advertises `=`, so it is excluded.
        let text = scalar("text");
        for d in text.domains {
            let supports_eq = Term::operators_for_terms(d.terms).contains(&"=");
            if !supports_eq {
                continue;
            }
            for op in ["=", "<>"] {
                assert_eq!(
                    Term::extractor_for_operator(d.terms, op),
                    Some("eq_term"),
                    "text{} must resolve `{op}` to eq_term (exact hm), not ORE",
                    d.name
                );
            }
            // And the payload requires hm for these domains.
            assert!(
                Term::term_json_keys(d.terms).contains(&"hm"),
                "text{} must require the `hm` payload key",
                d.name
            );
        }
    }

    #[test]
    fn domain_by_name_finds_declared_names() {
        let text = scalar("text");
        assert_eq!(
            text.domain_by_name("search").map(|d| d.name),
            Some("search")
        );
        assert!(text.domain_by_name("nope").is_none());
    }

    #[test]
    fn text_search_domain_carries_all_three_terms_and_is_ord_capable() {
        let text = scalar("text");
        let search = text
            .domains
            .iter()
            .find(|d| d.name == "search")
            .expect("text must declare a _search domain");
        assert_eq!(
            search.terms,
            &[Term::Hm, Term::Ore, Term::Bloom],
            "text_search must carry [Hm, Ore, Bloom]"
        );
        // ord-capable: some term provides ordering.
        assert!(
            search.terms.iter().any(|t| t.provides_ordering()),
            "text_search must be ord-capable"
        );
        // Required JSON keys are hm + ob + bf, in term order.
        assert_eq!(
            Term::term_json_keys(search.terms),
            vec!["hm", "ob", "bf"],
            "text_search CHECK must require hm, ob, bf"
        );
        // Equality still routes through hm; ordering through ob; match through bf.
        assert_eq!(
            Term::extractor_for_operator(search.terms, "="),
            Some("eq_term")
        );
        assert_eq!(
            Term::extractor_for_operator(search.terms, "<"),
            Some("ord_term")
        );
        assert_eq!(
            Term::extractor_for_operator(search.terms, "@>"),
            Some("match_term")
        );
    }

    /// The three temporal matrix pivots must be present verbatim in DATE's
    /// fixture strings — `fetch_fixture_payload` fetches each one's ciphertext,
    /// failing loudly if absent. The integer `fixtures_include_min_max_and_zero`
    /// invariant filters `is_int()` and skips date, so this is its temporal
    /// analogue.
    #[test]
    fn temporal_fixtures_include_pivot_plaintexts() {
        let strings: Vec<&str> = fixtures("date")
            .values
            .iter()
            .filter_map(|f| match f {
                Fixture::Date(s) => Some(*s),
                _ => None,
            })
            .collect();
        for pivot in ["1900-01-01", "1970-01-01", "2099-12-31"] {
            assert!(
                strings.contains(&pivot),
                "date fixtures missing temporal pivot {pivot}"
            );
        }
    }

    /// The three temporal matrix pivots must be present verbatim in
    /// TIMESTAMPTZ's fixture strings — the timestamptz analogue of
    /// `temporal_fixtures_include_pivot_plaintexts`.
    #[test]
    fn timestamptz_fixtures_include_pivot_plaintexts() {
        let strings: Vec<&str> = fixtures("timestamptz")
            .values
            .iter()
            .filter_map(|f| match f {
                Fixture::Timestamptz(s) => Some(*s),
                _ => None,
            })
            .collect();
        for pivot in [
            "1900-01-01T00:00:00Z",
            "1970-01-01T00:00:00Z",
            "2099-12-31T23:59:59Z",
        ] {
            assert!(
                strings.contains(&pivot),
                "timestamptz fixtures missing temporal pivot {pivot}"
            );
        }
    }

    #[test]
    fn every_type_uses_a_known_domain_shape() {
        // Each scalar's domain shape must be one of the known-valid shapes:
        // the four-domain ORDERED shape (storage + `_eq` + `_ord_ore` + `_ord`),
        // the two-domain EQ-ONLY shape (storage + `_eq`), the one-domain
        // STORAGE-ONLY shape (storage only — encryption-only scalars like
        // `bool`), or the ORDERED shape plus a `_match` domain (text's Bloom
        // containment). This catches accidental drift — a typo'd domain name, a wrong
        // term, a dropped domain — without hardcoding which token gets which
        // shape (that is the catalog's job; the matrix dispatch and the inventory
        // snapshots are shape-aware). Subsumes the old per-type
        // `<T>_maps_to_*_with_four_domains` / `<T>_domain_terms_match_manifest` tests.
        let ordered: Vec<(&str, &[Term])> = vec![
            ("", &[] as &[Term]),
            ("eq", &[Term::Hm][..]),
            ("ord_ore", &[Term::Ore][..]),
            ("ord", &[Term::Ore][..]),
        ];
        let eq_only: Vec<(&str, &[Term])> = vec![("", &[] as &[Term]), ("eq", &[Term::Hm][..])];
        let storage_only: Vec<(&str, &[Term])> = vec![("", &[] as &[Term])];
        let ordered_match: Vec<(&str, &[Term])> = vec![
            ("", &[] as &[Term]),
            ("eq", &[Term::Hm][..]),
            ("match", &[Term::Bloom][..]),
            ("ord_ore", &[Term::Ore][..]),
            ("ord", &[Term::Ore][..]),
        ];
        // text's current shape: equality is exact on the ordered domains (they
        // lead with `Hm`), plus a combined `_search` domain carrying all three
        // terms. `=`/`<>` route through `hm` on every eq-capable text domain.
        let text_search: Vec<(&str, &[Term])> = vec![
            ("", &[] as &[Term]),
            ("eq", &[Term::Hm][..]),
            ("match", &[Term::Bloom][..]),
            ("ord_ore", &[Term::Hm, Term::Ore][..]),
            ("ord", &[Term::Hm, Term::Ore][..]),
            ("search", &[Term::Hm, Term::Ore, Term::Bloom][..]),
        ];
        for s in CATALOG {
            let shape: Vec<(&str, &[Term])> = s.domains.iter().map(|d| (d.name, d.terms)).collect();
            assert!(
                shape == ordered
                    || shape == eq_only
                    || shape == storage_only
                    || shape == ordered_match
                    || shape == text_search,
                "{} has an unrecognised domain shape: {shape:?}",
                s.name
            );
        }
    }

    #[test]
    fn ordered_and_eq_only_shapes_are_used_as_declared() {
        // No catalog type is the two-domain equality-only shape: the ordered
        // types use the four-domain shape (timestamptz was promoted to ordered
        // once the ORE comparator generalized to N blocks — see the numeric/ORE
        // work), and `bool` is the one-domain storage-only shape (strictly
        // smaller than eq-only). So `domains.len() == 2` should appear nowhere.
        for s in CATALOG {
            let is_eq_only = s.domains.len() == 2;
            assert!(
                !is_eq_only,
                "{} is unexpectedly eq-only; no catalog type is eq-only currently",
                s.name
            );
        }
    }

    #[test]
    fn every_int_kind_matches_its_rust_type() {
        // The kind↔rust-type pairing for every integer scalar, generic over
        // CATALOG. Replaces the per-type `<T>_maps_to_iNN` / `<T>_rust_type`
        // restatements.
        for rec in FIXTURES.iter().filter(|r| r.kind.is_int()) {
            let expected = match rec.family.name {
                "int2" => ScalarKind::I16,
                "int4" => ScalarKind::I32,
                "int8" => ScalarKind::I64,
                other => panic!("unmapped integer scalar token {other}"),
            };
            assert_eq!(
                rec.kind, expected,
                "{} maps to the wrong kind",
                rec.family.name
            );
        }
    }

    /// Catalog-wide `family.name` ↔ `kind` guard over EVERY record, not just the
    /// integer ones. `TypeFixtures` carries `family` and `kind` as independent
    /// fields, and the compile-time parity block checks only `family.name` +
    /// length — so `TypeFixtures { family: &INT8, kind: I16, .. }` would compile
    /// and the parity block would pass. This test is the single guard that binds
    /// every record's `kind` to the kind its family is supposed to map onto, for
    /// all kinds (the non-integer kinds are otherwise only checked by individual
    /// `*_spec` tests). A mismatched or swapped `kind` fails here.
    #[test]
    fn every_record_kind_matches_its_family() {
        for rec in FIXTURES {
            let expected = match rec.family.name {
                "int2" => ScalarKind::I16,
                "int4" => ScalarKind::I32,
                "int8" => ScalarKind::I64,
                "date" => ScalarKind::Date,
                "timestamptz" => ScalarKind::Timestamptz,
                "numeric" => ScalarKind::Numeric,
                "text" => ScalarKind::Text,
                "bool" => ScalarKind::Bool,
                "float4" => ScalarKind::F32,
                "float8" => ScalarKind::F64,
                other => panic!("unmapped scalar token {other} in FIXTURES"),
            };
            assert_eq!(
                rec.kind, expected,
                "{} record carries the wrong kind",
                rec.family.name
            );
        }
    }

    #[test]
    fn domain_name_concatenates_token_and_suffix() {
        let s = scalar("int4");
        assert_eq!(s.domain_name(&s.domains[0]), "int4"); // storage
        assert_eq!(s.domain_name(&s.domains[1]), "int4_eq");
        assert_eq!(s.domain_name(&s.domains[3]), "int4_ord");
    }
}

mod values_tests {
    use crate::*;

    /// Every materialised `<T>_VALUES` array equals its catalog row's fixtures,
    /// resolved per kind, in order. Computed from the fixtures — no hardcoded
    /// expected array — so it cannot drift and adding a type needs only one
    /// `check(&INTx, INTx_VALUES)` line, not a duplicated reference list. Subsumes
    /// the old per-type `<T>_values_materialise_to_typed_array` references and
    /// `materialised_values_track_their_fixture_lists`.
    fn check<T: Copy + Into<i128>>(rec: &TypeFixtures, values: &[T]) {
        assert_eq!(
            values.len(),
            rec.values.len(),
            "{}: value count != fixture count",
            rec.family.name
        );
        for (i, (v, f)) in values.iter().zip(rec.values).enumerate() {
            assert_eq!(
                (*v).into(),
                f.numeric_value(rec.kind)
                    .expect("integer scalar fixture resolves to a number"),
                "{}: value[{i}] does not match resolved fixture {f:?}",
                rec.family.name
            );
        }
    }

    #[test]
    fn materialised_values_match_resolved_fixtures() {
        check(&INT4_FIXTURES, INT4_VALUES);
        check(&INT2_FIXTURES, INT2_VALUES);
        check(&INT8_FIXTURES, INT8_VALUES);
    }

    #[test]
    // `TEXT_VALUES` is a compile-time const slice, so clippy can prove the
    // non-emptiness guard true; keep it as an explicit invariant regardless.
    #[allow(clippy::const_is_empty)]
    fn text_values_are_distinct_and_nonempty() {
        assert!(!TEXT_VALUES.is_empty());
        let mut seen = std::collections::HashSet::new();
        for v in TEXT_VALUES {
            assert!(seen.insert(*v), "duplicate text fixture: {v}");
        }
        // The interior `mid_pivot` ("frank") must be present; the empty string
        // must NOT (text has no numeric origin — see issue #262).
        assert!(
            TEXT_VALUES.contains(&"frank"),
            "TEXT_VALUES must include the mid pivot \"frank\""
        );
        assert!(
            !TEXT_VALUES.contains(&""),
            "TEXT_VALUES must not include the empty string"
        );
    }

    #[test]
    fn text_values_match_fixtures_in_order() {
        let from_fixtures: Vec<&str> = TEXT_FIXTURES
            .values
            .iter()
            .map(|f| match f {
                Fixture::Text(s) => *s,
                other => panic!("text fixture must be Fixture::Text, got {other:?}"),
            })
            .collect();
        assert_eq!(TEXT_VALUES.to_vec(), from_fixtures);
    }

    #[test]
    // The divergence pair (`HAY`/`NEEDLE`) added to TEXT_FIXTURES for G3 4b must
    // stay diverging at the plaintext level: NEEDLE's contiguous 3-grams are all
    // present in HAY's 3-gram set, yet NEEDLE is NOT a contiguous substring of HAY.
    // That is exactly the bloom-`@>`-true / `LIKE`-false condition the SQLx test
    // `bloom_matches_where_like_would_not` relies on. This guard is creds-free and
    // fails fast if anyone edits the fixture words so they stop diverging.
    fn divergence_pair_is_contiguity_diverging() {
        const HAY: &str = "qabcqbcaqcabqabd";
        const NEEDLE: &str = "abcabd";

        // Both must actually be present in the fixture corpus.
        assert!(
            TEXT_VALUES.contains(&HAY),
            "TEXT_VALUES must contain HAY {HAY:?}"
        );
        assert!(
            TEXT_VALUES.contains(&NEEDLE),
            "TEXT_VALUES must contain NEEDLE {NEEDLE:?}"
        );

        // Contiguous 3-grams of a string (the documented bloom tokenization:
        // contiguous 3-grams, no padding).
        fn trigrams(s: &str) -> std::collections::HashSet<&str> {
            let b = s.as_bytes();
            if b.len() < 3 {
                // Sub-3 strings tokenize to the whole string; not used here but keep total.
                return std::iter::once(s).collect();
            }
            (0..=b.len() - 3).map(|i| &s[i..i + 3]).collect()
        }

        let hay_grams = trigrams(HAY);
        let needle_grams = trigrams(NEEDLE);

        // (1) needle 3-grams ⊆ haystack 3-grams  → bloom `@>` would match.
        assert!(
            needle_grams.is_subset(&hay_grams),
            "NEEDLE 3-grams {needle_grams:?} must be a subset of HAY 3-grams {hay_grams:?}"
        );
        // (2) needle is NOT a contiguous substring → `LIKE '%NEEDLE%'` would NOT match.
        assert!(
            !HAY.contains(NEEDLE),
            "NEEDLE {NEEDLE:?} must NOT be a contiguous substring of HAY {HAY:?}"
        );
    }
}

mod float_tests {
    use crate::*;

    fn scalar(token: &str) -> &'static DomainFamily {
        CATALOG
            .iter()
            .find(|s| s.name == token)
            .unwrap_or_else(|| panic!("{token} missing from CATALOG"))
    }

    fn fixtures(token: &str) -> &'static TypeFixtures {
        FIXTURES
            .iter()
            .find(|f| f.family.name == token)
            .unwrap_or_else(|| panic!("{token} missing from FIXTURES"))
    }

    #[test]
    fn float_specs_are_in_catalog_with_ordered_shape() {
        for family_name in ["float4", "float8"] {
            let s = scalar(family_name);
            let names: Vec<_> = s.domains.iter().map(|d| d.name).collect();
            assert_eq!(names, vec!["", "eq", "ord_ore", "ord"]);
        }
        assert_eq!(fixtures("float4").kind, ScalarKind::F32);
        assert_eq!(fixtures("float8").kind, ScalarKind::F64);
    }

    #[test]
    fn float_kinds_are_not_bounded_int_temporal_or_text() {
        for k in [ScalarKind::F32, ScalarKind::F64] {
            assert_eq!(k.as_bounded_int(), None);
            assert!(!k.is_int());
            assert!(!k.is_temporal());
            assert!(!k.is_text());
            assert!(k.is_float());
        }
    }

    #[test]
    fn float_rust_types_are_f32_and_f64() {
        assert_eq!(ScalarKind::F32.rust_type(), "f32");
        assert_eq!(ScalarKind::F64.rust_type(), "f64");
    }

    /// NaN and -0.0 must never be fixtures: NaN is unordered/unspecified in the
    /// encoder; -0.0 canonicalizes to +0.0 and would duplicate the +0.0 row.
    /// ±Inf MUST be present (the boundary pivots).
    #[test]
    fn float_fixtures_exclude_nan_and_negative_zero_and_include_infinities() {
        for family_name in ["float4", "float8"] {
            let strings: Vec<&str> = fixtures(family_name)
                .values
                .iter()
                .map(|f| match f {
                    Fixture::Float(v) => *v,
                    other => panic!("{family_name} fixture must be Fixture::Float, got {other:?}"),
                })
                .collect();
            for v in &strings {
                let parsed: f64 = v
                    .parse()
                    .unwrap_or_else(|_| panic!("{family_name} fixture {v:?} must parse as f64"));
                assert!(!parsed.is_nan(), "{family_name} fixture {v:?} is NaN");
                assert!(
                    !(parsed == 0.0 && parsed.is_sign_negative()),
                    "{family_name} fixture {v:?} is -0.0"
                );
            }
            assert!(
                strings.contains(&"inf"),
                "{family_name} must include +inf pivot"
            );
            assert!(
                strings.contains(&"-inf"),
                "{family_name} must include -inf pivot"
            );
            assert!(
                strings.contains(&"0"),
                "{family_name} must include 0 (origin)"
            );
        }
    }

    /// Distinct by parsed f64 value (the catalog dedupes only by literal string;
    /// the fixture table keys on the value, so an aliasing pair would break
    /// fetch_fixture_payload's fetch_one).
    #[test]
    fn float_fixtures_are_distinct_by_value() {
        for family_name in ["float4", "float8"] {
            let parsed: Vec<u64> = fixtures(family_name)
                .values
                .iter()
                .map(|f| match f {
                    Fixture::Float(v) => {
                        let x: f64 = v.parse().unwrap();
                        // total_cmp bit key; -0.0 already excluded so +0.0 is unique.
                        x.to_bits()
                    }
                    other => panic!("non-float fixture: {other:?}"),
                })
                .collect();
            let mut sorted = parsed.clone();
            sorted.sort_unstable();
            sorted.dedup();
            assert_eq!(
                sorted.len(),
                parsed.len(),
                "{family_name} has duplicate fixtures"
            );
        }
    }
}

mod invariant_tests {
    use crate::*;
    use std::collections::HashMap;

    #[test]
    fn every_domain_name_starts_with_its_family_name() {
        for s in CATALOG {
            for d in s.domains {
                let name = s.domain_name(d);
                assert!(
                    name == s.name || name.starts_with(&format!("{}_", s.name)),
                    "{name} does not start with family name {}",
                    s.name
                );
            }
        }
    }

    #[test]
    fn every_type_has_at_least_one_domain() {
        for s in CATALOG {
            assert!(!s.domains.is_empty(), "{} has no domains", s.name);
        }
    }

    /// Cross-kind distinctness key: integer fixtures dedupe by their resolved
    /// number, string-backed fixtures by their literal. Generalises the Python
    /// distinct-plaintext contract to every scalar kind.
    #[derive(Debug, PartialEq, Eq, Hash)]
    enum DistinctKey {
        Num(i128),
        Str(&'static str),
    }

    fn distinct_key(f: Fixture, kind: ScalarKind) -> DistinctKey {
        match f {
            Fixture::Numeric(s)
            | Fixture::Text(s)
            | Fixture::Jsonb(s)
            | Fixture::Date(s)
            | Fixture::Timestamptz(s)
            // Float fixtures dedupe by their literal here, like the other
            // string-backed kinds (every float literal is distinct; the harness
            // `float_fixtures_are_distinct_by_value` guard pins value-distinctness).
            | Fixture::Float(s) => DistinctKey::Str(s),
            // `bool` is storage-only and string-backed for distinctness: the two
            // values dedupe by their literal, like the other non-numeric kinds.
            Fixture::Bool(b) => DistinctKey::Str(if b { "true" } else { "false" }),
            _ => DistinctKey::Num(
                f.numeric_value(kind)
                    .expect("sentinel/Int fixtures resolve to a number"),
            ),
        }
    }

    #[test]
    fn fixtures_include_min_max_and_zero() {
        // The MIN/MAX/ZERO pivots are an integer-kind invariant; non-integer
        // kinds (text/numeric/jsonb) have no such pivots.
        for rec in FIXTURES.iter().filter(|r| r.kind.is_int()) {
            let bk = rec
                .kind
                .as_bounded_int()
                .expect("loop is filtered to integer kinds");
            let resolved: Vec<i128> = rec
                .values
                .iter()
                .filter_map(|f| f.numeric_value(rec.kind))
                .collect();
            assert!(
                resolved.contains(&bk.min_value()),
                "{} fixtures missing MIN",
                rec.family.name
            );
            assert!(
                resolved.contains(&bk.max_value()),
                "{} fixtures missing MAX",
                rec.family.name
            );
            assert!(
                resolved.contains(&0),
                "{} fixtures missing zero",
                rec.family.name
            );
        }
    }

    #[test]
    fn fixture_values_are_distinct_by_resolved_number() {
        for rec in FIXTURES {
            let mut seen: HashMap<DistinctKey, Fixture> = HashMap::new();
            for f in rec.values {
                if let Some(prev) = seen.insert(distinct_key(*f, rec.kind), *f) {
                    panic!("{}: {f:?} duplicates {prev:?}", rec.family.name);
                }
            }
        }
    }

    #[test]
    fn distinct_key_separates_string_fixtures() {
        // CATALOG is int-only, so the `Str` path is otherwise unexercised.
        assert_eq!(
            distinct_key(Fixture::Text("a"), ScalarKind::Text),
            distinct_key(Fixture::Text("a"), ScalarKind::Text)
        );
        assert_ne!(
            distinct_key(Fixture::Text("a"), ScalarKind::Text),
            distinct_key(Fixture::Text("b"), ScalarKind::Text)
        );
        assert_eq!(
            distinct_key(Fixture::Numeric("x"), ScalarKind::Numeric),
            distinct_key(Fixture::Jsonb("x"), ScalarKind::Jsonb)
        );
        // Str and Num keys never collide.
        assert_ne!(
            distinct_key(Fixture::Text("0"), ScalarKind::Text),
            distinct_key(Fixture::Zero, ScalarKind::I32)
        );
    }

    #[test]
    fn every_fixture_value_is_within_kind_bounds() {
        // Asserts the resolved sentinels stay within bounds (integer kinds only).
        for rec in FIXTURES.iter().filter(|r| r.kind.is_int()) {
            let bk = rec
                .kind
                .as_bounded_int()
                .expect("loop is filtered to integer kinds");
            let (lo, hi) = (bk.min_value(), bk.max_value());
            for f in rec.values {
                let Some(n) = f.numeric_value(rec.kind) else {
                    continue;
                };
                assert!(
                    n >= lo && n <= hi,
                    "{}: fixture {f:?} resolves to {n}, out of range [{lo}, {hi}]",
                    rec.family.name
                );
            }
        }
    }

    #[test]
    fn helper_outputs_match_for_known_domains() {
        // Cross-check the Term helpers against a known domain shape on int4.
        let s = CATALOG.iter().find(|s| s.name == "int4").unwrap();
        // storage domain: no terms.
        assert_eq!(Term::role_for_terms(s.domains[0].terms), Role::Storage);
        assert!(Term::operators_for_terms(s.domains[0].terms).is_empty());
        // _eq domain: hm => equality only.
        assert_eq!(Term::role_for_terms(s.domains[1].terms), Role::Eq);
        assert_eq!(
            Term::operators_for_terms(s.domains[1].terms),
            vec!["=", "<>"]
        );
        assert_eq!(Term::term_json_keys(s.domains[1].terms), vec!["hm"]);
        // _ord domain: ore => full ordering.
        assert_eq!(Term::role_for_terms(s.domains[3].terms), Role::Ord);
        assert_eq!(
            Term::operators_for_terms(s.domains[3].terms),
            vec!["=", "<>", "<", "<=", ">", ">="]
        );
        assert_eq!(Term::term_json_keys(s.domains[3].terms), vec!["ob"]);
        assert_eq!(
            Term::extractor_for_operator(s.domains[3].terms, "<"),
            Some("ord_term")
        );
    }
}
