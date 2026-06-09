//! Scalar/term catalog for EQL encrypted-domain codegen — the single Rust
//! source of truth for every scalar type, term, and fixture. Std-only, no
//! dependencies.
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
//!
//! **Layout.** This file holds the *definitions* — the type vocabulary and the
//! catalog data — so the whole catalog reads top-to-bottom. The inherent `impl`
//! blocks live in sibling modules (`kind`, `term`, `fixture`, `spec`); the unit
//! tests live in `tests`. The methods travel with their types, so nothing here
//! re-exports them.

mod fixture;
mod kind;
mod spec;
mod term;

/// The fixed-width integer kinds — exactly those scalar kinds with an `i128`
/// range and `MIN`/`MAX`/`Zero` sentinels. These accessors are **total**: every
/// variant answers every method. Non-integer kinds (`Numeric`/`Text`/`Jsonb`/
/// `Date`) are simply not representable here, so there is no partial function to
/// panic — `ScalarKind::Date` cannot call `min_symbol()` because `Date` is not a
/// `BoundedIntKind`. Reach this type from a `ScalarKind` via
/// [`ScalarKind::as_bounded_int`]. (Accessors are impl'd in `kind`.)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BoundedIntKind {
    I16,
    I32,
    I64,
}

/// The native scalar a domain type maps onto. Integer kinds carry i128 bounds;
/// the others (`Numeric`/`Text`/`Jsonb`) have string fixtures and no numeric
/// range — though `Numeric`/`Text` are still ORE-orderable, only `Jsonb` is not.
/// Capability layer only: `CATALOG` declares which kinds actually exist.
///
/// The bounded-numeric accessors live on the total [`BoundedIntKind`], reached
/// via [`ScalarKind::as_bounded_int`]; non-integer kinds have no such accessor,
/// so misuse is a compile error rather than a runtime panic. (Accessors are
/// impl'd in `kind`.)
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

/// A fixed index term known to the scalar materializer.
///
/// `Hm` provides equality; `Ore` provides equality plus ordering. The
/// `json_key`/`extractor`/`ctor` values are the cross-schema SQL contract —
/// changing one is a generated-SQL behaviour change, not a refactor. (The
/// per-term accessors and `*_for_terms` helpers are impl'd in `term`.)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Term {
    Hm,
    Ore,
}

/// A single fixture plaintext value, value-kind tagged: `Min`/`Max`/`Zero` are
/// the integer matrix pivots (resolved per-kind); `Int` is an integer literal;
/// `Numeric`/`Text`/`Jsonb` carry rendered string literals.
///
/// `fixtures!` range-checks `Int` literals at compile time, but a hand-built
/// `Fixture::Int(n)` is not — hence the runtime invariant tests. `Int(MIN)` and
/// `Min` resolve equal but render differently (`"-32768"` vs `"i16::MIN"`).
/// (`numeric_value`/`render_literal` are impl'd in `fixture`.)
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

/// One generated public domain: a suffix appended to the type token and the
/// fixed index terms it carries. Suffix `""` is the storage-only domain.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DomainSpec {
    pub suffix: &'static str,
    pub terms: &'static [Term],
}

/// A scalar encrypted-domain type: its SQL token, native Rust type, generated
/// domains, and fixture plaintext list. The Rust analogue of one `*.toml`.
/// (`domain_name`/`is_eq_only` are impl'd in `spec`.)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ScalarSpec {
    pub token: &'static str,
    pub kind: ScalarKind,
    pub domains: &'static [DomainSpec],
    pub fixtures: &'static [Fixture],
}

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

/// int4 fixture plaintexts.
/// `N(..)` literals are range-checked against `i32` at compile time.
const INT4_FIXTURES: &[Fixture] = fixtures!(int i32;
    Min, N(-100), N(-1), Zero, N(1), N(2), N(5), N(10), N(17), N(25),
    N(42), N(50), N(100), N(250), N(1000), N(9999), Max);

/// int2 fixture plaintexts.
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
mod tests;
