//! Scalar/term catalog for EQL encrypted-domain codegen — the single Rust
//! source of truth for every scalar type and term. Std-only, no dependencies.
//!
//! Capability axes are independent: equality covers every kind; order covers
//! every kind except `jsonb` (ORE compares ciphertext, so it is
//! plaintext-agnostic — `text`/`date` order like integers); only the integer
//! kinds have an i128 range with `Min`/`Max`/`Zero` sentinels. `numeric_value`
//! cannot yet express the order of a non-integer fixture set.
//!
//! Public names are consumed verbatim by the later codegen plans — do not rename.
//!
//! **Layout.** This file holds the *structural* catalog: the `DomainFamily`/
//! `Domain`/`Term`/`Role` definitions, the per-type `DomainFamily` rows, and
//! `CATALOG` — so the structural surface reads top-to-bottom. `DomainFamily` is
//! purely `{ name, domains }`; the native-scalar `kind` and the plaintext
//! `fixtures` are a fixture-layer concern that lives in the `fixtures` module
//! (the `ScalarKind`/`Fixture` vocabulary, the per-type `TypeFixtures` records +
//! `FIXTURES` table, and the materialised `*_VALUES` slices), joined back to a
//! catalog row by `name`. The inherent `impl` blocks for the structural types
//! live in sibling modules (`term`, `spec`); the unit tests live in `tests`. The
//! crate-root `pub use fixtures::{…}` below preserves the public fixture-layer
//! paths.

#[macro_use]
mod fixtures;
mod spec;
mod term;

pub use fixtures::{
    BoundedIntKind, Fixture, ScalarKind, TypeFixtures, BOOL_FIXTURES, DATE_FIXTURES, FIXTURES,
    FLOAT4_FIXTURES, FLOAT8_FIXTURES, INT2_FIXTURES, INT2_VALUES, INT4_FIXTURES, INT4_VALUES,
    INT8_FIXTURES, INT8_VALUES, NUMERIC_FIXTURES, TEXT_FIXTURES, TEXT_VALUES, TIMESTAMPTZ_FIXTURES,
};

/// Always-present payload keys required by every generated domain CHECK,
/// before the domain's term keys, in order: envelope version (`v`), ident
/// (`i`), ciphertext (`c`).
///
/// Lives here — in the catalog — because it is cross-schema contract data
/// consumed on both sides of the generated surface: `eql-codegen` builds
/// every domain CHECK from it, and `eql-bindings` builds its payload structs
/// and parity tests against it. One definition, so the envelope cannot
/// drift between the SQL and the canonical types.
pub const ENVELOPE_KEYS: &[&str] = &["v", "i", "c"];

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
    Bloom,
}

/// The generated-file role of a domain, resolved from its terms by the
/// richest-comparison precedence in [`Role::rank`] (or `Storage` for a term-less
/// domain). Gates ord-only codegen (aggregates) via an exhaustive `==` against
/// [`Role::Ord`] rather than a stringly-typed compare — a typo can no longer
/// silently disable aggregate generation. `label` is the `&'static str` form for
/// any future template/serde consumer.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Role {
    Storage,
    Eq,
    Ord,
    Match,
}

impl Role {
    /// The lowercase label (`"storage"`/`"eq"`/`"ord"`/`"match"`).
    pub const fn label(self) -> &'static str {
        match self {
            Role::Storage => "storage",
            Role::Eq => "eq",
            Role::Ord => "ord",
            Role::Match => "match",
        }
    }

    /// Precedence used by [`Term::role_for_terms`] to resolve a multi-term
    /// domain to a single generated-file role: the richest comparison capability
    /// wins (`Ord > Eq > Match > Storage`). Ordering subsumes equality, so an
    /// `Ore` term anywhere makes the domain ord-shaped; `Match` (containment) is
    /// a weaker standalone surface; `Storage` is the absence of any term. The
    /// current catalog is single-term, so this only disambiguates a hypothetical
    /// future mixed-term domain — and keeps `role_for_terms` consistent with
    /// [`Term::operators_for_terms`], which already unions across all terms.
    pub const fn rank(self) -> u8 {
        match self {
            Role::Storage => 0,
            Role::Match => 1,
            Role::Eq => 2,
            Role::Ord => 3,
        }
    }
}

/// One generated public domain: a bare domain name joined under the family
/// name (codegen owns the `_` separator) plus the fixed index terms it
/// carries. Name `""` is the storage-only domain.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Domain {
    pub name: &'static str,
    pub terms: &'static [Term],
}

/// A scalar encrypted-domain type's structural surface: its SQL `name` and the
/// generated domains. One row of the Rust `CATALOG`. The native-scalar `kind`
/// and the plaintext `fixtures` are a fixture-layer concern and live in the
/// `fixtures` module's `TypeFixtures` records, joined back by `name`.
/// (`domain_name`/`is_eq_only`/… are impl'd in `spec`.)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DomainFamily {
    pub name: &'static str,
    pub domains: &'static [Domain],
}

/// Domains shared by every ordered-integer scalar, in manifest file order:
/// storage (no terms), `_eq` (hm), `_ord_ore` (ore), `_ord` (ore).
const ORDERED_INT_DOMAINS: &[Domain] = &[
    Domain {
        name: "",
        terms: &[],
    },
    Domain {
        name: "eq",
        terms: &[Term::Hm],
    },
    Domain {
        name: "ord_ore",
        terms: &[Term::Ore],
    },
    Domain {
        name: "ord",
        terms: &[Term::Ore],
    },
];

/// Equality-only domains: storage (no terms) + `_eq` (hm). The canonical shape
/// for a scalar type that can hash for equality but is not ORE-orderable.
/// **Currently unused:** `timestamptz` (the previous sole user) was promoted to
/// the ordered shape once `eql_v3.compare_ore_block_256_term` generalized to N
/// blocks and could order its native 12-block ORE width. Retained — and still
/// validated as a known-valid shape by `every_type_uses_a_known_domain_shape` —
/// so a future non-orderable scalar (e.g. a hash-only type) can reuse it without
/// reconstructing the shape.
#[allow(dead_code)]
const EQ_ONLY_DOMAINS: &[Domain] = &[
    Domain {
        name: "",
        terms: &[],
    },
    Domain {
        name: "eq",
        terms: &[Term::Hm],
    },
];

const INT4: DomainFamily = DomainFamily {
    name: "int4",
    domains: ORDERED_INT_DOMAINS,
};

const INT2: DomainFamily = DomainFamily {
    name: "int2",
    domains: ORDERED_INT_DOMAINS,
};

const INT8: DomainFamily = DomainFamily {
    name: "int8",
    domains: ORDERED_INT_DOMAINS,
};

/// `date` — an ordered, non-integer scalar. Reuses `ORDERED_INT_DOMAINS` (the
/// four-domain ordered shape is identical to the integer scalars); only the
/// kind and fixtures (in `DATE_FIXTURES`) differ.
///
/// Public (unlike the integer specs) because the SQLx harness reads
/// `DATE_FIXTURES.values` directly to parse the ISO strings into
/// `chrono::NaiveDate` at runtime — there is no `DATE_VALUES` const (chrono is
/// not `const`-friendly and `eql-domains` stays zero-dep, so no typed slice is
/// materialised here).
pub const DATE: DomainFamily = DomainFamily {
    name: "date",
    domains: ORDERED_INT_DOMAINS,
};

/// `timestamptz` — an **ordered**, UTC-normalized non-integer scalar. Uses the
/// four-domain ordered shape (storage, `_eq`, `_ord`, `_ord_ore`): cipherstash
/// encrypts `Plaintext::Timestamp` at native 12-block ORE width, which the
/// generalized `eql_v3.compare_ore_block_256_term` comparator orders correctly.
/// Values are UTC-normalized (cipherstash has no tz-preserving type) and encrypt
/// under the `timestamp` cast.
///
/// Public (like `DATE`) because the SQLx harness reads
/// `TIMESTAMPTZ_FIXTURES.values` directly to parse the RFC3339 strings into
/// `chrono::DateTime<Utc>` at runtime (no `TIMESTAMPTZ_VALUES` const;
/// `eql-domains` stays zero-dep).
pub const TIMESTAMPTZ: DomainFamily = DomainFamily {
    name: "timestamptz",
    domains: ORDERED_INT_DOMAINS,
};

/// `numeric` — an **ordered** non-integer scalar backed by
/// `rust_decimal::Decimal`. Uses the four-domain ordered shape: cipherstash
/// encrypts `Plaintext::Decimal` at native 14-block ORE width, which the
/// generalized `eql_v3.compare_ore_block_256_term` comparator orders correctly.
/// `numeric_value` returns `None` (no i128 range); ordering is supplied by the
/// harness `Decimal: Ord`, which `ore-rs` guarantees agrees with the ciphertext
/// order (equivalent scales collide, like `Decimal`'s own `Ord`).
///
/// Public (like `DATE` / `TIMESTAMPTZ`) so the SQLx harness reads
/// `NUMERIC_FIXTURES.values` directly to parse the decimal strings into
/// `rust_decimal::Decimal` at runtime (the catalog stays zero-dep: no
/// `rust_decimal`).
pub const NUMERIC: DomainFamily = DomainFamily {
    name: "numeric",
    domains: ORDERED_INT_DOMAINS,
};

/// Domains for `text`: the ordered shape (with exact `hm` equality on the
/// ordered domains), a `_match` domain (`Bloom` containment), and a combined
/// `_search` domain carrying equality + ordering + match in one type.
///
/// **Equality always routes through `hm`.** Every eq-capable text domain leads
/// with `Hm` so `=`/`<>` resolve to `eq_term`/`hm`, never the ORE (`ob`) term —
/// ORE is not exact for `text`. `Term::Ore` keeps its kind-agnostic `=`/`<>`
/// claim; it simply never wins because `Hm` precedes it (Option 1, catalog
/// ordering). Integer kinds keep `[Ore]`-only `_ord` domains — ORE equality is
/// lossless for them.
const TEXT_DOMAINS: &[Domain] = &[
    Domain {
        name: "",
        terms: &[],
    },
    Domain {
        name: "eq",
        terms: &[Term::Hm],
    },
    Domain {
        name: "match",
        terms: &[Term::Bloom],
    },
    Domain {
        name: "ord_ore",
        terms: &[Term::Hm, Term::Ore],
    },
    Domain {
        name: "ord",
        terms: &[Term::Hm, Term::Ore],
    },
    Domain {
        name: "search",
        terms: &[Term::Hm, Term::Ore, Term::Bloom],
    },
];

/// Storage-only domains: a single term-less domain (name `""`). The canonical
/// shape for an **encryption-only** scalar — encrypted at rest, decrypted by the
/// proxy, never searched server-side. No `_eq`/`_ord`, so no SEM index term and
/// no comparison surface (every operator on the domain is a blocker). Used by
/// `bool`, whose two-value cardinality makes any searchable index a plaintext
/// leak. Validated as a known-valid shape by `every_type_uses_a_known_domain_shape`.
const STORAGE_ONLY_DOMAINS: &[Domain] = &[Domain {
    name: "",
    terms: &[],
}];

/// `bool` — an **encryption-only / storage-only** scalar (`ScalarKind::Bool`).
/// One term-less storage domain (`eql_v3.bool`), no `_eq`/`_ord`: a two-value
/// column has too little cardinality for any searchable index without leaking the
/// plaintext, so the value is encrypted at rest and decrypted by the proxy,
/// never searched server-side. Public so the SQLx harness reads
/// `BOOL_FIXTURES.values` directly (there is no `BOOL_VALUES` materializer — the
/// two values are read straight from the record).
pub const BOOL: DomainFamily = DomainFamily {
    name: "bool",
    domains: STORAGE_ONLY_DOMAINS,
};

/// `text` — an ordered, non-integer, unbounded scalar. Adds a `_match` domain
/// (the `Bloom` term) on top of the ordered shape. Public because the SQLx
/// harness reads `TEXT_VALUES` (materialised in the `fixtures` module).
pub const TEXT: DomainFamily = DomainFamily {
    name: "text",
    domains: TEXT_DOMAINS,
};

/// `float4` — an **ordered**, non-integer scalar (Postgres `real`). Reuses the
/// four-domain ordered shape (`ORDERED_INT_DOMAINS`); only kind and fixtures
/// differ. Both float widths encrypt through the SAME f64 crypto path
/// (`Plaintext::Float`), so `float4` vs `float8` is purely a Postgres-surface
/// distinction. Public (like `DATE`/`NUMERIC`) so the SQLx harness reads
/// `FLOAT4_FIXTURES.values` directly to parse the strings into `f32`.
pub const FLOAT4: DomainFamily = DomainFamily {
    name: "float4",
    domains: ORDERED_INT_DOMAINS,
};

/// `float8` — an **ordered**, non-integer scalar (Postgres `double precision`),
/// the native width of the float crypto path. Reuses the ordered shape. Public
/// so the SQLx harness reads `FLOAT8_FIXTURES.values` directly to parse into
/// `f64`.
pub const FLOAT8: DomainFamily = DomainFamily {
    name: "float8",
    domains: ORDERED_INT_DOMAINS,
};

/// The scalar catalog — the single source of truth. Order is significant (it
/// drives generation order). New types are appended as their SQL surface lands.
pub const CATALOG: &[DomainFamily] = &[
    INT4,
    INT2,
    INT8,
    DATE,
    TIMESTAMPTZ,
    NUMERIC,
    TEXT,
    BOOL,
    FLOAT4,
    FLOAT8,
];

#[cfg(test)]
mod tests;

#[cfg(test)]
mod proptest_invariants;
