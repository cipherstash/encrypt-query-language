//! [`ScalarKind`] / [`BoundedIntKind`] — the native scalar a domain maps onto
//! plus the total fixed-width-integer accessors. Defs and impls co-located here
//! (the fixture-layer vocabulary).

/// The fixed-width integer kinds — exactly those scalar kinds with an `i128`
/// range and `MIN`/`MAX`/`Zero` sentinels. These accessors are **total**: every
/// variant answers every method. The non-integer kinds (`Numeric`/`Text`/
/// `Jsonb`/`Date`/`Timestamp`/`Bool`/`F32`/`F64`) are simply not representable
/// here, so there is no partial function to panic — `ScalarKind::Date` cannot
/// call `min_symbol()` because `Date` is not a `BoundedIntKind`. Reach this type
/// from a `ScalarKind` via [`ScalarKind::as_bounded_int`]. (Accessors are impl'd
/// below.)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BoundedIntKind {
    I16,
    I32,
    I64,
}

/// The native scalar a domain type maps onto. The integer kinds (`I16`/`I32`/
/// `I64`) carry i128 bounds; the non-integer kinds (`Numeric`/`Text`/`Jsonb`/
/// `Date`/`Timestamp`/`Bool`/`F32`/`F64`) have no i128 range and string- or
/// bool-backed fixtures. All but `Jsonb` and `Bool` are still ORE-orderable —
/// `Jsonb` has no order, and `Bool` is storage-only (no comparison surface).
/// Capability layer only: `CATALOG` declares which kinds actually exist.
///
/// The bounded-numeric accessors live on the total [`BoundedIntKind`], reached
/// via [`ScalarKind::as_bounded_int`]; non-integer kinds have no such accessor,
/// so misuse is a compile error rather than a runtime panic. (Accessors are
/// impl'd below.)
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
    /// UTC timestamp (`chrono::DateTime<Utc>`). Ordered like the integer kinds
    /// via ORE, but string-backed (RFC3339) at the catalog layer and with no
    /// i128 range — so it is *not* `is_int()` and `as_bounded_int()` returns
    /// `None` for it, like the other non-integer kinds. The bounded-numeric
    /// accessors live on `BoundedIntKind`, which `Timestamp` cannot be, so they
    /// are unreachable for it by construction rather than by a runtime panic.
    /// UTC-normalized: cipherstash has no tz-preserving type, so it maps to the
    /// `timestamp` cast and the SQL `timestamp with time zone` plaintext type.
    /// The value is an instant (Postgres `timestamp with time zone`) wearing the
    /// SQL-standard name `timestamp`, matching the cipherstash cast convention.
    Timestamp,
    /// Boolean (`bool`). **Encryption-only / storage-only**: it carries no index
    /// term and is *not* `is_int()`/`is_temporal()`/`is_text()`. A two-value
    /// column has such low cardinality that any searchable index (even HMAC
    /// equality) would trivially leak the plaintext distribution, so the catalog
    /// gives `bool` a single term-less storage domain and no `_eq`/`_ord` — the
    /// value is encrypted at rest and decrypted by the proxy, never searched
    /// server-side. Like the other non-integer kinds, the bounded-numeric
    /// accessors are unreachable for it by construction.
    Bool,
    /// 32-bit IEEE-754 binary float (`f32`, Postgres `real`/`float4`).
    /// Ordered like the integer kinds via ORE, but with no i128 range
    /// (`as_bounded_int()` returns `None`) and string-backed at the catalog
    /// layer. Encrypts through the single f64 float crypto path
    /// (`Plaintext::Float`) — the f32→f64 widening is exact and monotonic.
    F32,
    /// 64-bit IEEE-754 binary float (`f64`, Postgres `double precision`/
    /// `float8`). The native width of the float crypto path (`F32` widens into
    /// it); otherwise classified exactly like [`ScalarKind::F32`].
    F64,
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
            ScalarKind::Numeric
            | ScalarKind::Text
            | ScalarKind::Jsonb
            | ScalarKind::Bool
            | ScalarKind::F32
            | ScalarKind::F64
            | ScalarKind::Date
            | ScalarKind::Timestamp => None,
        }
    }

    /// True for the fixed-width integer kinds. Gates the bounded-numeric
    /// invariants. Equivalent to `self.as_bounded_int().is_some()`.
    pub const fn is_int(self) -> bool {
        self.as_bounded_int().is_some()
    }

    /// True for chrono-backed temporal kinds (`Date`, `Timestamp`) — the kinds
    /// whose test `ScalarType` impl is generated by `temporal_values!` rather
    /// than the integer proc-macro path. Replaces the `[temporal]` marker.
    pub const fn is_temporal(self) -> bool {
        matches!(self, ScalarKind::Date | ScalarKind::Timestamp)
    }

    /// True for the `Text` kind — an unbounded, owned-`String` scalar. Keeps
    /// "textness" classification in the catalog crate alongside `is_int` /
    /// `is_temporal`, rather than matching the variant at each call site.
    pub const fn is_text(self) -> bool {
        matches!(self, ScalarKind::Text)
    }

    /// True for the IEEE-754 float kinds (`F32`, `F64`) — ordered, non-integer,
    /// string-backed-fixture scalars whose `impl ScalarType` is hand-written in
    /// `scalar_domains.rs` (like `text`/`numeric`). Keeps float classification in
    /// the catalog crate alongside `is_int`/`is_temporal`/`is_text`.
    pub const fn is_float(self) -> bool {
        matches!(self, ScalarKind::F32 | ScalarKind::F64)
    }

    /// Is `=` on a **SteVec JSON leaf** of this kind exact — does `op(a) == op(b)`
    /// imply `a == b`?
    ///
    /// **Determinism is not enough for equality.** `Term::Ope` is deterministic
    /// (equal plaintext ⇒ equal term), which is what makes `op` byte-comparison a
    /// valid *ordering* for every kind. Equality additionally needs **injectivity**
    /// (different plaintext ⇒ different term), and that is a property of the WHOLE
    /// leaf conversion — not of `orderable_to_u64`, which is a bijection but runs
    /// LAST. cipherstash-client applies a lossy step first
    /// (`json_indexer/ste_vec/priv_state/ste_plaintext_term.rs`,
    /// `impl From<&Value> for StePlaintextTerm`):
    ///
    /// ```text
    /// Value::Number(x) => Number(orderable_to_u64(x.as_f64()…))   // rounds to f64
    /// Value::String(x) => String(x) -> orderize_string(x)         // decompose + strip
    /// ```
    ///
    /// So a leaf's `op` is exact only where the kind's whole value domain survives
    /// that step — which is a question about the VALUES, not about which branch
    /// they take:
    ///
    /// | kind | leaf | exact? | why |
    /// |---|---|---|---|
    /// | `I16`, `I32` | number | yes | `|i32| ≤ 2^31 < 2^53`, so every value is an exact f64 |
    /// | `F32`, `F64` | number | yes | widening/identity into f64 — the leaf IS an f64, so f64 equality is the semantic |
    /// | `I64` | number | **no** | a bigint legitimately exceeds 2^53; `2^53` and `2^53+1` round to one f64 |
    /// | `Numeric` | number | **no** | a numeric legitimately carries more precision than f64 |
    /// | `Date`, `Timestamp` | string | yes | ISO-8601/RFC3339 is alphanumeric + ASCII punctuation, which `orderize_string` passes through UNCHANGED (cllw-ore's own `prop_orderize_safe_string_unchanged`) |
    /// | `Text` | string | **no** | arbitrary text collates: `"café"` == `"cafe"`, `"hello😎"` == `"hello"` |
    ///
    /// (`Bool`/`Jsonb` carry no `Ope` domain and never reach this seam.)
    ///
    /// Note `Date`/`Timestamp` are exact BECAUSE their string form is
    /// orderize-invariant — not merely "because they are dates". Being a string
    /// leaf does not imply collision; `orderize_string` only drops characters
    /// outside its safe set, and a timestamp has none.
    ///
    /// **The bar is "wrong when used as intended".** Every `no` row is a FALSE
    /// POSITIVE reachable by correct use: a `bigint` field holding `2^53+1` is
    /// ordinary, and so is a `text` field holding `"café"`. Neither is a client
    /// error, and no client can avoid it — the loss is in cipherstash-client's
    /// encoding, which EQL cannot fix. The only correct response is to not offer
    /// the operator. By contrast an operand encrypted for the wrong column, wrong
    /// selector, or a mismatched plaintext type yields ZERO ROWS — the ordinary
    /// EQL client contract that applies to every operator in the product, and not
    /// something this predicate speaks to.
    ///
    /// Ordering is unaffected throughout: a rounded/collated order is the intended
    /// semantic, and the scalar `_ord` domains already ship exactly it.
    ///
    /// Scalar COLUMNS dodge the equality hazard entirely by listing `Hm` before
    /// `Ope`, so [`crate::Term::extractor_for_operator`] routes `=`/`<>` to the
    /// exact `hm` (see `tests::every_eq_capable_text_domain_resolves_eq_through_hm`).
    /// A SteVec leaf has no `hm` to fall back on — `Value::Number`/`Value::String`
    /// map to `Orderable`, never `Mac` — so a seam comparing leaves must simply not
    /// offer equality where this returns false. That is what this predicate gates.
    pub const fn json_leaf_equality_is_exact(self) -> bool {
        match self {
            // Number leaves whose value domain injects into f64.
            ScalarKind::I16 | ScalarKind::I32 | ScalarKind::F32 | ScalarKind::F64 => true,
            // String leaves whose textual form is orderize-invariant.
            ScalarKind::Date | ScalarKind::Timestamp => true,
            // Number leaves whose values legitimately exceed f64's precision.
            ScalarKind::I64 | ScalarKind::Numeric => false,
            // Arbitrary text — collated.
            ScalarKind::Text => false,
            // No Ope domain; never reaches the leaf seam.
            ScalarKind::Bool | ScalarKind::Jsonb => false,
        }
    }

    /// A debug/identifier string for the kind: the canonical Rust plaintext type
    /// name (`"i32"`, `"chrono::NaiveDate"`, `"rust_decimal::Decimal"`). `Jsonb`
    /// maps to `serde_json::Value` — its plaintext is an arbitrary JSON document.
    /// Its encrypted bindings are NOT the flat-scalar structs the other kinds
    /// generate; they are the hand-written SteVec payload types in
    /// `crates/eql-bindings/src/v3/jsonb.rs` (the SQL generator skips SteVec
    /// shapes). Only call site today is `crates/eql-domains/src/tests.rs`.
    pub const fn rust_type(self) -> &'static str {
        match self {
            ScalarKind::I16 => "i16",
            ScalarKind::I32 => "i32",
            ScalarKind::I64 => "i64",
            ScalarKind::Text => "String",
            ScalarKind::Date => "chrono::NaiveDate",
            ScalarKind::Timestamp => "chrono::DateTime<Utc>",
            ScalarKind::Numeric => "rust_decimal::Decimal",
            ScalarKind::Bool => "bool",
            ScalarKind::F32 => "f32",
            ScalarKind::F64 => "f64",
            ScalarKind::Jsonb => "serde_json::Value",
        }
    }
}
