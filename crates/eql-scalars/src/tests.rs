//! Unit tests for the scalar/term catalog. Kept as one `#[cfg(test)]` module
//! (declared from `lib.rs`) rather than co-located with each impl file because
//! `rust_tests` spans `BoundedIntKind` + `ScalarKind` + `Fixture` +
//! `ScalarSpec`. Each inner module imports the crate-root catalog with
//! `use crate::*;`; the crate-local `fixtures!` macro is in scope here by textual
//! scoping (this module is declared after the macro definition in `lib.rs`).

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
        // Temporal, non-integer, equality-only kind: it carries a rust type but
        // no i128 range, so it is not `is_int()` and `as_bounded_int()` returns
        // `None` — the bounded accessors are not reachable for it.
        assert_eq!(ScalarKind::Timestamptz.rust_type(), "chrono::DateTime<Utc>");
        assert!(!ScalarKind::Timestamptz.is_int());
        assert_eq!(ScalarKind::Timestamptz.as_bounded_int(), None);
    }

    /// The structural guarantee that replaces the old runtime panics: a
    /// `Min`/`Max`/`Zero` pivot sentinel may only appear in a `CATALOG` row whose
    /// kind is an integer kind. `numeric_value` would resolve to `None` for a
    /// pivot on a non-integer kind; this test makes such a row a test failure at
    /// the source of truth.
    #[test]
    fn pivot_sentinels_only_appear_with_integer_kinds() {
        for spec in CATALOG {
            for fixture in spec.fixtures {
                if matches!(fixture, Fixture::Min | Fixture::Max | Fixture::Zero) {
                    assert!(
                        spec.kind.is_int(),
                        "pivot sentinel {fixture:?} on non-integer kind {:?} (token `{}`)",
                        spec.kind,
                        spec.token,
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
    }

    #[test]
    fn is_eq_only_detects_absence_of_ord_domains() {
        let int4 = CATALOG.iter().find(|s| s.token == "int4").unwrap();
        assert!(!int4.is_eq_only(), "int4 is ordered");
        let date = CATALOG.iter().find(|s| s.token == "date").unwrap();
        assert!(!date.is_eq_only(), "date is ordered");
        let ts = CATALOG.iter().find(|s| s.token == "timestamptz").unwrap();
        assert!(ts.is_eq_only(), "timestamptz is equality-only");
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
        assert_eq!(ore.ctor(), "ore_block_u64_8_256");
        assert_eq!(ore.role(), Role::Ord);
        assert_eq!(ore.operators(), &["=", "<>", "<", "<=", ">", ">="]);
        assert_eq!(
            ore.requires(),
            &[
                "src/v3/sem/ore_block_u64_8_256/functions.sql",
                "src/v3/sem/ore_block_u64_8_256/operators.sql",
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
    fn requires_are_deduplicated_in_order() {
        assert_eq!(
            Term::term_requires(&[Term::Ore, Term::Ore, Term::Hm]),
            vec![
                "src/v3/sem/ore_block_u64_8_256/functions.sql",
                "src/v3/sem/ore_block_u64_8_256/operators.sql",
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

    fn scalar(token: &str) -> &'static ScalarSpec {
        CATALOG
            .iter()
            .find(|s| s.token == token)
            .unwrap_or_else(|| panic!("{token} missing from CATALOG"))
    }

    #[test]
    fn catalog_has_int4_int2_int8_date_timestamptz_text_in_order() {
        let tokens: Vec<&str> = CATALOG.iter().map(|s| s.token).collect();
        assert_eq!(
            tokens,
            vec!["int4", "int2", "int8", "date", "timestamptz", "text"]
        );
    }

    #[test]
    fn text_spec_is_in_catalog() {
        let text = scalar("text");
        assert_eq!(text.kind, ScalarKind::Text);
        let suffixes: Vec<_> = text.domains.iter().map(|d| d.suffix).collect();
        assert_eq!(suffixes, vec!["", "_eq", "_match", "_ord_ore", "_ord"]);
    }

    #[test]
    fn text_match_domain_carries_only_bloom() {
        let text = scalar("text");
        let m = text.domains.iter().find(|d| d.suffix == "_match").unwrap();
        assert_eq!(m.terms, &[Term::Bloom]);
    }

    /// The three temporal matrix pivots must be present verbatim in DATE's
    /// fixture strings — `fetch_fixture_payload` fetches each one's ciphertext,
    /// failing loudly if absent. The integer `fixtures_include_min_max_and_zero`
    /// invariant filters `is_int()` and skips date, so this is its temporal
    /// analogue.
    #[test]
    fn temporal_fixtures_include_pivot_plaintexts() {
        let date = scalar("date");
        let strings: Vec<&str> = date
            .fixtures
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
        let ts = scalar("timestamptz");
        let strings: Vec<&str> = ts
            .fixtures
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
        // the two-domain EQ-ONLY shape (storage + `_eq`), or the ORDERED shape
        // plus a `_match` domain (text's Bloom containment). This catches
        // accidental drift — a typo'd suffix, a wrong term, a dropped domain —
        // without hardcoding which token gets which shape (that is the catalog's
        // job; the matrix dispatch and the inventory snapshots are shape-aware).
        // Subsumes the old per-type `<T>_maps_to_*_with_four_domains` /
        // `<T>_domain_terms_match_manifest` tests.
        let ordered: Vec<(&str, &[Term])> = vec![
            ("", &[] as &[Term]),
            ("_eq", &[Term::Hm][..]),
            ("_ord_ore", &[Term::Ore][..]),
            ("_ord", &[Term::Ore][..]),
        ];
        let eq_only: Vec<(&str, &[Term])> = vec![("", &[] as &[Term]), ("_eq", &[Term::Hm][..])];
        let ordered_match: Vec<(&str, &[Term])> = vec![
            ("", &[] as &[Term]),
            ("_eq", &[Term::Hm][..]),
            ("_match", &[Term::Bloom][..]),
            ("_ord_ore", &[Term::Ore][..]),
            ("_ord", &[Term::Ore][..]),
        ];
        for s in CATALOG {
            let shape: Vec<(&str, &[Term])> =
                s.domains.iter().map(|d| (d.suffix, d.terms)).collect();
            assert!(
                shape == ordered || shape == eq_only || shape == ordered_match,
                "{} has an unrecognised domain shape: {shape:?}",
                s.token
            );
        }
    }

    #[test]
    fn ordered_and_eq_only_shapes_are_used_as_declared() {
        // Pin which catalog tokens carry which shape, so a row silently flipping
        // ORDERED_INT_DOMAINS <-> EQ_ONLY_DOMAINS is caught. timestamptz is
        // equality-only (12-block ORE vs 8-block comparator); the rest ordered
        // (text adds a `_match` domain on top, so it is not eq_only either).
        for s in CATALOG {
            let is_eq_only = s.domains.len() == 2;
            let expect_eq_only = s.token == "timestamptz";
            assert_eq!(
                is_eq_only, expect_eq_only,
                "{} domain shape (eq_only={is_eq_only}) does not match expectation",
                s.token
            );
        }
    }

    #[test]
    fn every_int_kind_matches_its_rust_type() {
        // The kind↔rust-type pairing for every integer scalar, generic over
        // CATALOG. Replaces the per-type `<T>_maps_to_iNN` / `<T>_rust_type`
        // restatements.
        for s in CATALOG.iter().filter(|s| s.kind.is_int()) {
            let expected = match s.token {
                "int2" => ScalarKind::I16,
                "int4" => ScalarKind::I32,
                "int8" => ScalarKind::I64,
                other => panic!("unmapped integer scalar token {other}"),
            };
            assert_eq!(s.kind, expected, "{} maps to the wrong kind", s.token);
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
    fn check<T: Copy + Into<i128>>(spec: &ScalarSpec, values: &[T]) {
        assert_eq!(
            values.len(),
            spec.fixtures.len(),
            "{}: value count != fixture count",
            spec.token
        );
        for (i, (v, f)) in values.iter().zip(spec.fixtures).enumerate() {
            assert_eq!(
                (*v).into(),
                f.numeric_value(spec.kind)
                    .expect("integer scalar fixture resolves to a number"),
                "{}: value[{i}] does not match resolved fixture {f:?}",
                spec.token
            );
        }
    }

    #[test]
    fn materialised_values_match_resolved_fixtures() {
        check(&INT4, INT4_VALUES);
        check(&INT2, INT2_VALUES);
        check(&INT8, INT8_VALUES);
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
            .iter()
            .map(|f| match f {
                Fixture::Text(s) => *s,
                other => panic!("text fixture must be Fixture::Text, got {other:?}"),
            })
            .collect();
        assert_eq!(TEXT_VALUES.to_vec(), from_fixtures);
    }
}

mod invariant_tests {
    use crate::*;
    use std::collections::HashMap;

    #[test]
    fn every_domain_name_starts_with_its_token() {
        for s in CATALOG {
            for d in s.domains {
                let name = s.domain_name(d);
                assert!(
                    name == s.token || name.starts_with(&format!("{}_", s.token)),
                    "{name} does not start with token {}",
                    s.token
                );
            }
        }
    }

    #[test]
    fn every_type_has_at_least_one_domain() {
        for s in CATALOG {
            assert!(!s.domains.is_empty(), "{} has no domains", s.token);
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
            | Fixture::Timestamptz(s) => DistinctKey::Str(s),
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
        for s in CATALOG.iter().filter(|s| s.kind.is_int()) {
            let bk = s
                .kind
                .as_bounded_int()
                .expect("loop is filtered to integer kinds");
            let resolved: Vec<i128> = s
                .fixtures
                .iter()
                .filter_map(|f| f.numeric_value(s.kind))
                .collect();
            assert!(
                resolved.contains(&bk.min_value()),
                "{} fixtures missing MIN",
                s.token
            );
            assert!(
                resolved.contains(&bk.max_value()),
                "{} fixtures missing MAX",
                s.token
            );
            assert!(resolved.contains(&0), "{} fixtures missing zero", s.token);
        }
    }

    #[test]
    fn fixture_values_are_distinct_by_resolved_number() {
        for s in CATALOG {
            let mut seen: HashMap<DistinctKey, Fixture> = HashMap::new();
            for f in s.fixtures {
                if let Some(prev) = seen.insert(distinct_key(*f, s.kind), *f) {
                    panic!("{}: {f:?} duplicates {prev:?}", s.token);
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
        for s in CATALOG.iter().filter(|s| s.kind.is_int()) {
            let bk = s
                .kind
                .as_bounded_int()
                .expect("loop is filtered to integer kinds");
            let (lo, hi) = (bk.min_value(), bk.max_value());
            for f in s.fixtures {
                let Some(n) = f.numeric_value(s.kind) else {
                    continue;
                };
                assert!(
                    n >= lo && n <= hi,
                    "{}: fixture {f:?} resolves to {n}, out of range [{lo}, {hi}]",
                    s.token
                );
            }
        }
    }

    #[test]
    fn helper_outputs_match_for_known_domains() {
        // Cross-check the Term helpers against a known domain shape on int4.
        let s = CATALOG.iter().find(|s| s.token == "int4").unwrap();
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
