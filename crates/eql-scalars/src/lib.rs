//! Scalar/term catalog for EQL encrypted-domain codegen — the Rust source of
//! truth replacing `tasks/codegen/{scalars,terms,spec}.py` and the
//! `types/*.toml` manifests. Std-only, no dependencies.
//!
//! `Fixture` is value-kind tagged (one non-generic enum, variant = value kind),
//! so a single `CATALOG` spans every scalar kind. Integer literals are
//! range-checked at their definition site by `fixtures!` (`N(-40000)` for `i16`
//! does not compile).
//!
//! Capability axes are independent: equality covers every kind; order covers
//! every kind except `jsonb` (ORE compares ciphertext, so it is
//! plaintext-agnostic — `text`/`date` order like integers); only the integer
//! kinds have an i128 range with `Min`/`Max`/`Zero` sentinels. `numeric_value`
//! cannot yet express the order of a non-integer fixture set.
//!
//! Public names are consumed verbatim by the later codegen plans — do not rename.

/// The fixed-width integer kinds — exactly those scalar kinds with an `i128`
/// range and `MIN`/`MAX`/`Zero` sentinels. These accessors are **total**: every
/// variant answers every method. Non-integer kinds (`Numeric`/`Text`/`Jsonb`/
/// `Date`) are simply not representable here, so there is no partial function to
/// panic — `ScalarKind::Date` cannot call `min_symbol()` because `Date` is not a
/// `BoundedIntKind`. Reach this type from a `ScalarKind` via
/// [`ScalarKind::as_bounded_int`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BoundedIntKind {
    I16,
    I32,
    I64,
}

impl BoundedIntKind {
    /// The Rust type name as it appears in generated source (e.g. `"i32"`).
    pub const fn rust_type(self) -> &'static str {
        match self {
            BoundedIntKind::I16 => "i16",
            BoundedIntKind::I32 => "i32",
            BoundedIntKind::I64 => "i64",
        }
    }

    /// The `MIN` named-constant symbol (e.g. `"i32::MIN"`).
    pub const fn min_symbol(self) -> &'static str {
        match self {
            BoundedIntKind::I16 => "i16::MIN",
            BoundedIntKind::I32 => "i32::MIN",
            BoundedIntKind::I64 => "i64::MIN",
        }
    }

    /// The `MAX` named-constant symbol (e.g. `"i32::MAX"`).
    pub const fn max_symbol(self) -> &'static str {
        match self {
            BoundedIntKind::I16 => "i16::MAX",
            BoundedIntKind::I32 => "i32::MAX",
            BoundedIntKind::I64 => "i64::MAX",
        }
    }

    /// The zero literal symbol (always `"0"`).
    pub const fn zero_symbol(self) -> &'static str {
        "0"
    }

    /// Inclusive lower bound of the representable range, widened to `i128`.
    pub const fn min_value(self) -> i128 {
        match self {
            BoundedIntKind::I16 => i16::MIN as i128,
            BoundedIntKind::I32 => i32::MIN as i128,
            BoundedIntKind::I64 => i64::MIN as i128,
        }
    }

    /// Inclusive upper bound of the representable range, widened to `i128`.
    pub const fn max_value(self) -> i128 {
        match self {
            BoundedIntKind::I16 => i16::MAX as i128,
            BoundedIntKind::I32 => i32::MAX as i128,
            BoundedIntKind::I64 => i64::MAX as i128,
        }
    }
}

/// The native scalar a domain type maps onto. Integer kinds carry i128 bounds;
/// the others (`Numeric`/`Text`/`Jsonb`) have string fixtures and no numeric
/// range — though `Numeric`/`Text` are still ORE-orderable, only `Jsonb` is not.
/// Capability layer only: `CATALOG` declares which kinds actually exist.
///
/// The bounded-numeric accessors live on the total [`BoundedIntKind`], reached
/// via [`ScalarKind::as_bounded_int`]; non-integer kinds have no such accessor,
/// so misuse is a compile error rather than a runtime panic.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ScalarKind {
    I16,
    I32,
    I64,
    Numeric,
    Text,
    Jsonb,
    /// Calendar date (`chrono::NaiveDate`). Ordered like the integer kinds via
    /// ORE, but string-backed (ISO-8601) at the catalog layer and with no i128
    /// range — so it is *not* `is_int()` and `as_bounded_int()` returns `None`
    /// for it, like the other non-integer kinds. The bounded-numeric accessors
    /// live on `BoundedIntKind`, which `Date` cannot be, so they are
    /// unreachable for it by construction rather than by a runtime panic.
    Date,
}

impl ScalarKind {
    /// The fixed-width integer kinds — those with `i128` bounds and
    /// `Min`/`Max`/`Zero` sentinels — projected onto [`BoundedIntKind`], or
    /// `None` for the non-integer kinds. The single boundary where "this kind has
    /// bounds" is decided; the bounded accessors live on `BoundedIntKind` and are
    /// total there. NOT an orderability test: `Numeric`/`Text`/`Date` are
    /// ORE-orderable yet not integers.
    pub const fn as_bounded_int(self) -> Option<BoundedIntKind> {
        match self {
            ScalarKind::I16 => Some(BoundedIntKind::I16),
            ScalarKind::I32 => Some(BoundedIntKind::I32),
            ScalarKind::I64 => Some(BoundedIntKind::I64),
            ScalarKind::Numeric | ScalarKind::Text | ScalarKind::Jsonb | ScalarKind::Date => None,
        }
    }

    /// True for the fixed-width integer kinds. Gates the bounded-numeric
    /// invariants. Equivalent to `self.as_bounded_int().is_some()`.
    pub const fn is_int(self) -> bool {
        self.as_bounded_int().is_some()
    }

    /// True for chrono-backed temporal kinds (`Date`; `Timestamptz` once added) —
    /// the kinds whose test `ScalarType` impl is generated by `temporal_values!`
    /// rather than the integer proc-macro path. Replaces the `[temporal]` marker.
    pub const fn is_temporal(self) -> bool {
        matches!(self, ScalarKind::Date)
    }

    /// The Rust type name as it appears in generated source (e.g. `"i32"`).
    pub const fn rust_type(self) -> &'static str {
        match self {
            ScalarKind::I16 => "i16",
            ScalarKind::I32 => "i32",
            ScalarKind::I64 => "i64",
            ScalarKind::Numeric => "numeric",
            ScalarKind::Text => "text",
            ScalarKind::Jsonb => "jsonb",
            ScalarKind::Date => "chrono::NaiveDate",
        }
    }
}

/// A fixed index term known to the scalar materializer.
///
/// Mirrors `terms.py`'s `TERM_CATALOG`. `Hm` provides equality; `Ore` provides
/// equality plus ordering. The `json_key`/`extractor`/`returns`/`ctor` values
/// are the cross-schema SQL contract and are copied verbatim from `terms.py` —
/// changing one is a generated-SQL behaviour change, not a refactor.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Term {
    Hm,
    Ore,
}

impl Term {
    /// JSON payload key carrying this term (`"hm"` / `"ob"`).
    pub const fn json_key(self) -> &'static str {
        match self {
            Term::Hm => "hm",
            Term::Ore => "ob",
        }
    }

    /// The generated extractor function name (`"eq_term"` / `"ord_term"`).
    pub const fn extractor(self) -> &'static str {
        match self {
            Term::Hm => "eq_term",
            Term::Ore => "ord_term",
        }
    }

    /// Constructor name for the index-term type (unqualified).
    pub const fn ctor(self) -> &'static str {
        match self {
            Term::Hm => "hmac_256",
            Term::Ore => "ore_block_u64_8_256",
        }
    }

    /// Generated-file role label for a domain whose first term is this one.
    pub const fn role(self) -> &'static str {
        match self {
            Term::Hm => "eq",
            Term::Ore => "ord",
        }
    }

    /// SQL operators this term supports, in catalog order.
    pub const fn operators(self) -> &'static [&'static str] {
        match self {
            Term::Hm => &["=", "<>"],
            Term::Ore => &["=", "<>", "<", "<=", ">", ">="],
        }
    }

    /// SQL `-- REQUIRE:` edges this term pulls in, in catalog order.
    pub const fn requires(self) -> &'static [&'static str] {
        match self {
            Term::Hm => &["src/v3/sem/hmac_256/functions.sql"],
            Term::Ore => &[
                "src/v3/sem/ore_block_u64_8_256/functions.sql",
                "src/v3/sem/ore_block_u64_8_256/operators.sql",
            ],
        }
    }
}

impl Term {
    /// Stable dedupe — first occurrence wins. The Rust analogue of
    /// `terms.py`'s `dict.fromkeys` ordering contract.
    fn dedupe_preserving_order<'a>(items: impl IntoIterator<Item = &'a str>) -> Vec<&'a str> {
        let mut out: Vec<&'a str> = Vec::new();
        for item in items {
            if !out.contains(&item) {
                out.push(item);
            }
        }
        out
    }

    /// Supported operators for the union of a domain's terms (catalog order,
    /// deduped). Mirrors `terms.py::operators_for_terms`.
    pub fn operators_for_terms(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().flat_map(|t| t.operators().iter().copied()))
    }

    /// JSON payload keys required by these terms (deduped, in order).
    /// Mirrors `terms.py::term_json_keys`.
    pub fn term_json_keys(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().map(|t| t.json_key()))
    }

    /// SQL `-- REQUIRE:` edges needed by these terms (deduped, in order).
    /// Mirrors `terms.py::term_requires`.
    pub fn term_requires(terms: &[Term]) -> Vec<&'static str> {
        Self::dedupe_preserving_order(terms.iter().flat_map(|t| t.requires().iter().copied()))
    }

    /// The extractor that supports `op` for a domain carrying `terms`, or
    /// `None`. First supporting term wins. Mirrors
    /// `terms.py::extractor_for_operator`.
    pub fn extractor_for_operator(terms: &[Term], op: &str) -> Option<&'static str> {
        terms
            .iter()
            .find(|t| t.operators().contains(&op))
            .map(|t| t.extractor())
    }

    /// Generated-file role label for a domain with these terms. No terms =>
    /// `"storage"`; otherwise the first term's role. Mirrors
    /// `terms.py::role_for_terms`.
    pub fn role_for_terms(terms: &[Term]) -> &'static str {
        match terms.first() {
            None => "storage",
            Some(t) => t.role(),
        }
    }
}

/// A single fixture plaintext value, value-kind tagged: `Min`/`Max`/`Zero` are
/// the integer matrix pivots (resolved per-kind); `Int` is an integer literal;
/// `Numeric`/`Text`/`Jsonb` carry rendered string literals.
///
/// `fixtures!` range-checks `Int` literals at compile time, but a hand-built
/// `Fixture::Int(n)` is not — hence the runtime invariant tests. `Int(MIN)` and
/// `Min` resolve equal but render differently (`"-32768"` vs `"i16::MIN"`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Fixture {
    Min,
    Max,
    Zero,
    Int(i128),
    Numeric(&'static str),
    Text(&'static str),
    Jsonb(&'static str),
    /// An ISO-8601 date string (`"1970-01-01"`). The catalog stays zero-dep, so
    /// the string is parsed into a `chrono::NaiveDate` in the SQLx harness, not
    /// here. Distinct by literal, like the other string-backed fixtures.
    Date(&'static str),
}

impl Fixture {
    /// The integer value for this fixture (`Min`/`Max` -> kind bounds, `Zero` ->
    /// 0, `Int(n)` -> n), or `None` for the string-backed kinds. Does not
    /// range-check; `every_fixture_value_is_within_kind_bounds` guards the bounds.
    ///
    /// `const fn` so the `int_values!` materialiser can resolve a whole fixture
    /// list into a typed `&'static` array at compile time.
    pub const fn numeric_value(self, kind: ScalarKind) -> Option<i128> {
        match self {
            // `?` is not allowed in `const fn`, so match `as_bounded_int()`
            // explicitly. A pivot on a non-integer kind resolves to `None`; the
            // `pivot_sentinels_only_appear_with_integer_kinds` catalog test
            // guarantees that combination never reaches a real `CATALOG` row.
            Fixture::Min => match kind.as_bounded_int() {
                Some(k) => Some(k.min_value()),
                None => None,
            },
            Fixture::Max => match kind.as_bounded_int() {
                Some(k) => Some(k.max_value()),
                None => None,
            },
            Fixture::Zero => Some(0),
            Fixture::Int(n) => Some(n),
            Fixture::Numeric(_) | Fixture::Text(_) | Fixture::Jsonb(_) | Fixture::Date(_) => None,
        }
    }

    /// Render as a Rust source literal: sentinels -> named constant, `Int` -> the
    /// number, string kinds -> a `Debug`-quoted (Rust-escaped, not SQL) literal.
    pub fn render_literal(self, kind: ScalarKind) -> String {
        const PIVOT_MSG: &str = "Min/Max/Zero fixtures require an integer kind";
        match self {
            Fixture::Min => kind
                .as_bounded_int()
                .expect(PIVOT_MSG)
                .min_symbol()
                .to_string(),
            Fixture::Max => kind
                .as_bounded_int()
                .expect(PIVOT_MSG)
                .max_symbol()
                .to_string(),
            Fixture::Zero => kind
                .as_bounded_int()
                .expect(PIVOT_MSG)
                .zero_symbol()
                .to_string(),
            Fixture::Int(n) => n.to_string(),
            Fixture::Numeric(s) | Fixture::Text(s) | Fixture::Jsonb(s) | Fixture::Date(s) => {
                format!("{s:?}")
            }
        }
    }
}

/// One generated public domain: a suffix appended to the type token and the
/// fixed index terms it carries. Suffix `""` is the storage-only domain.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DomainSpec {
    pub suffix: &'static str,
    pub terms: &'static [Term],
}

/// A scalar encrypted-domain type: its SQL token, native Rust type, generated
/// domains, and fixture plaintext list. The Rust analogue of one `*.toml`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ScalarSpec {
    pub token: &'static str,
    pub kind: ScalarKind,
    pub domains: &'static [DomainSpec],
    pub fixtures: &'static [Fixture],
}

impl ScalarSpec {
    /// The fully-qualified domain name: `token` + `suffix`. Makes the old
    /// "domain name must start with the token" validation structural.
    pub fn domain_name(&self, domain: &DomainSpec) -> String {
        format!("{}{}", self.token, domain.suffix)
    }

    /// True when this type declares no ordered (`_ord`) domain — i.e. equality-only
    /// (storage + `_eq`). Replaces the future `[eq_only]` marker: the domain set
    /// already carries this. The `_ord_ore` twin only appears alongside `_ord`, so
    /// testing `_ord` suffices.
    pub fn is_eq_only(&self) -> bool {
        !self.domains.iter().any(|d| d.suffix == "_ord")
    }
}

/// Domains shared by every ordered-integer scalar, in manifest file order:
/// storage (no terms), `_eq` (hm), `_ord_ore` (ore), `_ord` (ore).
const ORDERED_INT_DOMAINS: &[DomainSpec] = &[
    DomainSpec {
        suffix: "",
        terms: &[],
    },
    DomainSpec {
        suffix: "_eq",
        terms: &[Term::Hm],
    },
    DomainSpec {
        suffix: "_ord_ore",
        terms: &[Term::Ore],
    },
    DomainSpec {
        suffix: "_ord",
        terms: &[Term::Ore],
    },
];

/// Builds a `&[Fixture]`. The `int <ty>;` arm (a tt-muncher over `Min`/`Max`/
/// `Zero` and `N(<lit>)`) range-checks each literal against `<ty>` at compile
/// time via `const _RANGE_CHECK`, so out-of-range literals do not compile;
/// `text;`/`numeric;`/`jsonb;` wrap string literals. The reject case has no
/// in-crate test (macro isn't exported, no `trybuild` under zero-deps) — verify
/// by hand with a bad `N(..)`.
macro_rules! fixtures {
    (int $t:ty; $($body:tt)*) => { fixtures!(@int $t; [] $($body)*) };
    (@int $t:ty; [$($acc:expr),*]) => { &[$($acc),*] };
    (@int $t:ty; [$($acc:expr),*] , $($r:tt)*) => { fixtures!(@int $t; [$($acc),*] $($r)*) };
    (@int $t:ty; [$($acc:expr),*] Min  $($r:tt)*) => { fixtures!(@int $t; [$($acc,)* Fixture::Min ] $($r)*) };
    (@int $t:ty; [$($acc:expr),*] Max  $($r:tt)*) => { fixtures!(@int $t; [$($acc,)* Fixture::Max ] $($r)*) };
    (@int $t:ty; [$($acc:expr),*] Zero $($r:tt)*) => { fixtures!(@int $t; [$($acc,)* Fixture::Zero] $($r)*) };
    (@int $t:ty; [$($acc:expr),*] N($v:literal) $($r:tt)*) => {
        fixtures!(@int $t; [$($acc,)* Fixture::Int({ const _RANGE_CHECK: $t = $v; $v as i128 })] $($r)*)
    };
    (text;    $($s:literal),* $(,)?) => { &[$(Fixture::Text($s)),*] };
    (numeric; $($s:literal),* $(,)?) => { &[$(Fixture::Numeric($s)),*] };
    (jsonb;   $($s:literal),* $(,)?) => { &[$(Fixture::Jsonb($s)),*] };
    (date;    $($s:literal),* $(,)?) => { &[$(Fixture::Date($s)),*] };
}

/// int4 fixture plaintexts — verbatim from `tasks/codegen/types/int4.toml`.
/// `N(..)` literals are range-checked against `i32` at compile time.
const INT4_FIXTURES: &[Fixture] = fixtures!(int i32;
    Min, N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17), N(25),
    N(42), N(50), N(100), N(250), N(1000), N(9999), Max);

/// int2 fixture plaintexts — verbatim from `tasks/codegen/types/int2.toml`.
/// `N(..)` literals are range-checked against `i16` at compile time.
const INT2_FIXTURES: &[Fixture] = fixtures!(int i16;
    Min, N(-30000), N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17),
    N(25), N(42), N(50), N(100), N(250), N(1000), N(9999), N(30000), Max);

/// int8 fixture plaintexts — the int4 set plus two values beyond the i32 range
/// (`±5_000_000_000`) so the matrix exercises the full 64-bit width. `N(..)`
/// literals are range-checked against `i64` at compile time.
const INT8_FIXTURES: &[Fixture] = fixtures!(int i64;
    Min, N(-5000000000), N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17),
    N(25), N(42), N(50), N(100), N(250), N(1000), N(9999), N(5000000000), Max);

/// date fixture plaintexts — ISO-8601 (`YYYY-MM-DD`) strings, parsed into
/// `chrono::NaiveDate` in the SQLx harness (the catalog stays zero-dep). The
/// three temporal pivots MUST be present verbatim: `"1900-01-01"` (min_pivot),
/// `"1970-01-01"` (zero = `NaiveDate::default()`), and `"2099-12-31"`
/// (max_pivot) — the matrix fetches each one's ciphertext via
/// `fetch_fixture_payload`, which fails loudly if a row is absent. The interior
/// dates span varied years/months so range operators yield distinguishable
/// counts. All distinct.
const DATE_FIXTURES: &[Fixture] = fixtures!(date;
    "1900-01-01", "1950-07-15", "1969-12-31", "1970-01-01", "1970-01-02",
    "1980-02-29", "1991-11-09", "1999-12-31", "2000-01-01", "2004-02-29",
    "2012-06-30", "2016-03-15", "2020-10-21", "2024-02-29", "2038-01-19",
    "2099-12-31");

const INT4: ScalarSpec = ScalarSpec {
    token: "int4",
    kind: ScalarKind::I32,
    domains: ORDERED_INT_DOMAINS,
    fixtures: INT4_FIXTURES,
};

const INT2: ScalarSpec = ScalarSpec {
    token: "int2",
    kind: ScalarKind::I16,
    domains: ORDERED_INT_DOMAINS,
    fixtures: INT2_FIXTURES,
};

const INT8: ScalarSpec = ScalarSpec {
    token: "int8",
    kind: ScalarKind::I64,
    domains: ORDERED_INT_DOMAINS,
    fixtures: INT8_FIXTURES,
};

/// `date` — an ordered, non-integer scalar. Reuses `ORDERED_INT_DOMAINS` (the
/// four-domain ordered shape is identical to the integer scalars); only the
/// kind and fixtures differ.
///
/// Public (unlike the integer specs) because the SQLx harness reads
/// `DATE.fixtures` directly to parse the ISO strings into `chrono::NaiveDate`
/// at runtime — there is no `DATE_VALUES` const (chrono is not `const`-friendly
/// and `eql-scalars` stays zero-dep, so no typed slice is materialised here).
pub const DATE: ScalarSpec = ScalarSpec {
    token: "date",
    kind: ScalarKind::Date,
    domains: ORDERED_INT_DOMAINS,
    fixtures: DATE_FIXTURES,
};

/// The scalar catalog — the single source of truth. Order is significant (it
/// drives generation order). New types are appended as their SQL surface lands.
pub const CATALOG: &[ScalarSpec] = &[INT4, INT2, INT8, DATE];

/// Materialise an integer scalar's fixtures into a typed `&'static` slice at
/// compile time. This is the **single-sourced** plaintext list the SQLx test
/// matrix reads via `ScalarType::fixture_values()` and the fixture generator
/// encrypts — derived from the same `CATALOG` row that drives SQL generation,
/// so the oracle cannot drift from the fixture. (It replaces the old generated,
/// committed `tests/sqlx/src/fixtures/<T>_values.rs` — a Rust source of truth no
/// longer needs to round-trip through generated Rust.)
///
/// Integer kinds only: a non-numeric fixture (`Text`/`Numeric`/`Jsonb`) is a
/// const-eval error, mirroring `numeric_value`'s `None`.
macro_rules! int_values {
    ($name:ident, $ty:ty, $spec:expr) => {
        #[doc = concat!("Distinct plaintext fixture values for `", stringify!($spec), "`, ")]
        #[doc = "materialised from its `CATALOG` row (see `int_values!`)."]
        pub const $name: &[$ty] = {
            const SPEC: ScalarSpec = $spec;
            const N: usize = SPEC.fixtures.len();
            const ARR: [$ty; N] = {
                let mut out = [0 as $ty; N];
                let mut i = 0;
                while i < N {
                    out[i] = match SPEC.fixtures[i].numeric_value(SPEC.kind) {
                        Some(v) => {
                            // Const-eval bounds check: a fixture value that does
                            // not fit the narrowed target type would otherwise be
                            // silently truncated/wrapped by `as`. Make it a
                            // compile-time error instead.
                            if v < <$ty>::MIN as i128 || v > <$ty>::MAX as i128 {
                                panic!(concat!(
                                    "integer scalar fixture value out of range for `",
                                    stringify!($ty),
                                    "`"
                                ));
                            }
                            v as $ty
                        }
                        None => panic!("integer scalar fixture must resolve to a number"),
                    };
                    i += 1;
                }
                out
            };
            &ARR
        };
    };
}

int_values!(INT4_VALUES, i32, INT4);
int_values!(INT2_VALUES, i16, INT2);
int_values!(INT8_VALUES, i64, INT8);

#[cfg(test)]
mod rust_tests {
    use super::*;

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

    /// The structural guarantee that replaces the old runtime panics: a
    /// `Min`/`Max`/`Zero` pivot sentinel may only appear in a `CATALOG` row whose
    /// kind is an integer kind. `render_literal` would `expect`-panic and
    /// `numeric_value` would resolve to `None` for a pivot on a non-integer kind;
    /// this test makes such a row a test failure at the source of truth.
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
        assert!(!ScalarKind::I16.is_temporal());
        assert!(!ScalarKind::I32.is_temporal());
        assert!(!ScalarKind::I64.is_temporal());
        // Timestamptz arrives in Phase 5; assert it here once present.
    }

    #[test]
    fn is_eq_only_detects_absence_of_ord_domains() {
        let int4 = CATALOG.iter().find(|s| s.token == "int4").unwrap();
        assert!(!int4.is_eq_only(), "int4 is ordered");
        let date = CATALOG.iter().find(|s| s.token == "date").unwrap();
        assert!(!date.is_eq_only(), "date is ordered");
    }
}

#[cfg(test)]
mod term_tests {
    use super::*;

    #[test]
    fn hm_term_provides_equality() {
        let hm = Term::Hm;
        assert_eq!(hm.json_key(), "hm");
        assert_eq!(hm.extractor(), "eq_term");
        assert_eq!(hm.ctor(), "hmac_256");
        assert_eq!(hm.role(), "eq");
        assert_eq!(hm.operators(), &["=", "<>"]);
        assert_eq!(hm.requires(), &["src/v3/sem/hmac_256/functions.sql"]);
    }

    #[test]
    fn ore_term_preserves_int4_sql_contract() {
        let ore = Term::Ore;
        assert_eq!(ore.json_key(), "ob");
        assert_eq!(ore.extractor(), "ord_term");
        assert_eq!(ore.ctor(), "ore_block_u64_8_256");
        assert_eq!(ore.role(), "ord");
        assert_eq!(ore.operators(), &["=", "<>", "<", "<=", ">", ">="]);
        assert_eq!(
            ore.requires(),
            &[
                "src/v3/sem/ore_block_u64_8_256/functions.sql",
                "src/v3/sem/ore_block_u64_8_256/operators.sql",
            ]
        );
    }
}

#[cfg(test)]
mod term_helper_tests {
    use super::*;

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
        assert_eq!(Term::role_for_terms(&[]), "storage");
        assert_eq!(Term::role_for_terms(&[Term::Hm]), "eq");
        assert_eq!(Term::role_for_terms(&[Term::Ore]), "ord");
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

#[cfg(test)]
mod fixture_tests {
    use super::*;

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
    }

    #[test]
    fn render_literal_maps_sentinels() {
        assert_eq!(Fixture::Min.render_literal(ScalarKind::I32), "i32::MIN");
        assert_eq!(Fixture::Max.render_literal(ScalarKind::I32), "i32::MAX");
        assert_eq!(Fixture::Zero.render_literal(ScalarKind::I32), "0");
        assert_eq!(Fixture::Min.render_literal(ScalarKind::I16), "i16::MIN");
        assert_eq!(Fixture::Max.render_literal(ScalarKind::I64), "i64::MAX");
    }

    #[test]
    fn render_literal_passes_through_numeric() {
        assert_eq!(Fixture::Int(-100).render_literal(ScalarKind::I32), "-100");
        assert_eq!(Fixture::Int(9999).render_literal(ScalarKind::I32), "9999");
        assert_eq!(
            Fixture::Int(5_000_000_000).render_literal(ScalarKind::I64),
            "5000000000"
        );
    }

    #[test]
    fn render_literal_quotes_string_variants() {
        // String-backed kinds render a valid quoted Rust literal.
        assert_eq!(
            Fixture::Text("alice").render_literal(ScalarKind::Text),
            "\"alice\""
        );
        assert_eq!(
            Fixture::Numeric("3.14").render_literal(ScalarKind::Numeric),
            "\"3.14\""
        );
        assert_eq!(
            Fixture::Jsonb(r#"{"a":1}"#).render_literal(ScalarKind::Jsonb),
            r#""{\"a\":1}""#
        );
        assert_eq!(
            Fixture::Date("1970-01-01").render_literal(ScalarKind::Date),
            "\"1970-01-01\""
        );
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

#[cfg(test)]
mod catalog_tests {
    use super::*;

    fn scalar(token: &str) -> &'static ScalarSpec {
        CATALOG
            .iter()
            .find(|s| s.token == token)
            .unwrap_or_else(|| panic!("{token} missing from CATALOG"))
    }

    #[test]
    fn catalog_has_int4_int2_int8_date_in_order() {
        let tokens: Vec<&str> = CATALOG.iter().map(|s| s.token).collect();
        assert_eq!(tokens, vec!["int4", "int2", "int8", "date"]);
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

    #[test]
    fn all_types_share_the_same_domain_shape() {
        // Every scalar declares the same four domains with the same terms;
        // only the token differs (the matrix-snapshot collapse depends on this).
        // Generic over CATALOG, so it covers every type — including new ones —
        // and subsumes the old per-type `<T>_maps_to_*_with_four_domains` /
        // `<T>_domain_terms_match_manifest` tests (which only restated the
        // catalog literal for one token).
        for s in CATALOG {
            let shape: Vec<(&str, &[Term])> =
                s.domains.iter().map(|d| (d.suffix, d.terms)).collect();
            assert_eq!(
                shape,
                vec![
                    ("", &[] as &[Term]),
                    ("_eq", &[Term::Hm][..]),
                    ("_ord_ore", &[Term::Ore][..]),
                    ("_ord", &[Term::Ore][..]),
                ],
                "{} has unexpected domain shape",
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

#[cfg(test)]
mod values_tests {
    use super::*;

    /// Every materialised `<T>_VALUES` array equals its catalog row's fixtures,
    /// resolved per kind, in order. Computed from the fixtures — no hardcoded
    /// expected array — so it cannot drift and adding a type needs only one
    /// `check(&INTx, INTx_VALUES)` line, not a duplicated golden list. Subsumes
    /// the old per-type `<T>_values_materialise_to_typed_array` goldens and
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
}

#[cfg(test)]
mod invariant_tests {
    use super::*;
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
            Fixture::Numeric(s) | Fixture::Text(s) | Fixture::Jsonb(s) | Fixture::Date(s) => {
                DistinctKey::Str(s)
            }
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
        assert_eq!(Term::role_for_terms(s.domains[0].terms), "storage");
        assert!(Term::operators_for_terms(s.domains[0].terms).is_empty());
        // _eq domain: hm => equality only.
        assert_eq!(Term::role_for_terms(s.domains[1].terms), "eq");
        assert_eq!(
            Term::operators_for_terms(s.domains[1].terms),
            vec!["=", "<>"]
        );
        assert_eq!(Term::term_json_keys(s.domains[1].terms), vec!["hm"]);
        // _ord domain: ore => full ordering.
        assert_eq!(Term::role_for_terms(s.domains[3].terms), "ord");
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
