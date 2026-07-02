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
    INT8_FIXTURES, INT8_VALUES, JSONB_FIXTURES, NUMERIC_FIXTURES, TEXT_FIXTURES, TEXT_VALUES,
    TIMESTAMP_FIXTURES,
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
/// `Hm` provides equality; `Ore` and `Ope` provide equality plus ordering —
/// `Ore` is the block-ORE array term (`ob`, compared by the custom N-block
/// protocol) and `Ope` is the CLLW-OPE term (`op`, a hex-encoded ciphertext
/// that is natively bytea-sortable after hex-decode: no custom comparison
/// protocol). `Ope`'s `=`/`<>` claim on the integer families rests on OPE
/// being deterministic — an order-preserving encryption maps equal
/// plaintexts to equal ciphertexts (a randomized term would make `op`-routed
/// equality silently return false negatives); re-verify against real
/// ciphertexts once cipherstash-client emits `op` and the fixture pipeline
/// covers the `_ord_ope` domains. The `json_key`/`extractor`/`ctor` values
/// are the cross-schema SQL contract — changing one is a generated-SQL
/// behaviour change, not a refactor. (The per-term accessors and
/// `*_for_terms` helpers are impl'd in `term`.)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Term {
    Hm,
    Ore,
    Bloom,
    Ope,
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

/// The structural shape of a domain's payload. Every existing scalar family is
/// [`Shape::Scalar`] (flat `{v,i,c,+terms}`). The SteVec shapes belong to the
/// `jsonb` family and carry document/entry/query payloads whose keys are NOT the
/// flat envelope+term set — `Term`, `Role`, `operators_for_terms`, and
/// `capability_label` continue to assume flat-scalar semantics and are simply
/// never invoked on a SteVec domain (consumers filter/branch on `Shape`).
///
/// Coupling invariant (pinned by `tests::shape_and_terms_are_consistent`): a
/// non-`Scalar` domain always has empty `terms`, and any domain with non-empty
/// `terms` is `Scalar`. Empty `terms` here does NOT mean "no index capability":
/// a SteVec domain is fully searchable (hash-equality via `hm`, ordered via `oc`
/// CLLW-ORE). Its index terms live *inside* the payload shape — per `sv` leaf,
/// `hm` XOR `oc` — rather than as a flat family-level `Term` list. The `terms`
/// field models only the flat-scalar term set that `Term`/`Role`/
/// `operators_for_terms`/`capability_label` consume; SteVec capability is carried
/// structurally by the `Shape` and is invisible to those flat-term consumers by
/// construction.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Shape {
    /// Flat `{v, i, c, +terms}` — every existing scalar family (default).
    Scalar,
    /// A `jsonb` family payload: `eql_v3.json` (`{v, i, sv: [entry]}`),
    /// `eql_v3.jsonb_entry` (`{s, c, a?, #[flatten] SteVecTerm}`), or
    /// `eql_v3.jsonb_query` (`{sv: [query-entry]}`). The three differ in
    /// payload body but share the non-flat-scalar shape, so a single variant
    /// covers them; `Domain.name` (`"json"`/`"entry"`/`"query"`) already
    /// disambiguates which one a given domain is (see `Domain::full_name` /
    /// `Domain::rust_struct_name`).
    SteVec,
}

/// One generated public domain: a bare domain name joined under the family
/// name (codegen owns the `_` separator) plus the fixed index terms it
/// carries. Name `""` is the storage-only domain.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Domain {
    pub name: &'static str,
    pub terms: &'static [Term],
    pub shape: Shape,
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
/// storage (no terms), `_eq` (hm), `_ord_ore` (ore), `_ord` (ore),
/// `_ord_ope` (ope). `_ord_ope` carries the CLLW-OPE term (`op`): a
/// hex-encoded ciphertext ordered by native bytea comparison after
/// hex-decode — unlike `_ord`/`_ord_ore` it needs no custom comparator.
const ORDERED_INT_DOMAINS: &[Domain] = &[
    Domain {
        name: "",
        terms: &[],
        shape: Shape::Scalar,
    },
    Domain {
        name: "eq",
        terms: &[Term::Hm],
        shape: Shape::Scalar,
    },
    Domain {
        name: "ord_ore",
        terms: &[Term::Ore],
        shape: Shape::Scalar,
    },
    Domain {
        name: "ord",
        terms: &[Term::Ore],
        shape: Shape::Scalar,
    },
    Domain {
        name: "ord_ope",
        terms: &[Term::Ope],
        shape: Shape::Scalar,
    },
];

/// Equality-only domains: storage (no terms) + `_eq` (hm). The canonical shape
/// for a scalar type that can hash for equality but is not ORE-orderable.
/// **Currently unused:** `timestamp` (the previous sole user) was promoted to
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
        shape: Shape::Scalar,
    },
    Domain {
        name: "eq",
        terms: &[Term::Hm],
        shape: Shape::Scalar,
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

/// `timestamp` — an **ordered**, UTC-normalized non-integer scalar. Uses the
/// four-domain ordered shape (storage, `_eq`, `_ord`, `_ord_ore`): cipherstash
/// encrypts `Plaintext::Timestamp` at native 12-block ORE width, which the
/// generalized `eql_v3.compare_ore_block_256_term` comparator orders correctly.
/// Values are UTC-normalized (cipherstash has no tz-preserving type) and encrypt
/// under the `timestamp` cast. NOTE: the value is an instant (Postgres `timestamp
/// with time zone`); it wears the SQL-standard name `timestamp` to match the
/// cipherstash cast/`ColumnType`/`Plaintext` convention. A genuinely
/// without-time-zone `timestamp` (naive wall-clock) is a future, additive type,
/// blocked on cipherstash-client ORE pre-indexing for naive datetimes.
///
/// Public (like `DATE`) because the SQLx harness reads
/// `TIMESTAMP_FIXTURES.values` directly to parse the RFC3339 strings into
/// `chrono::DateTime<Utc>` at runtime (no `TIMESTAMP_VALUES` const;
/// `eql-domains` stays zero-dep).
pub const TIMESTAMP: DomainFamily = DomainFamily {
    name: "timestamp",
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
/// Public (like `DATE` / `TIMESTAMP`) so the SQLx harness reads
/// `NUMERIC_FIXTURES.values` directly to parse the decimal strings into
/// `rust_decimal::Decimal` at runtime (the catalog stays zero-dep: no
/// `rust_decimal`).
pub const NUMERIC: DomainFamily = DomainFamily {
    name: "numeric",
    domains: ORDERED_INT_DOMAINS,
};

/// Domains for `text`: the ordered shape (with exact `hm` equality on the
/// ordered domains), a `_match` domain (`Bloom` containment), an `_ord_ope`
/// domain (CLLW-OPE ordering), and a combined `_search` domain carrying
/// equality + ordering + match in one type.
///
/// **Equality always routes through `hm`.** Every eq-capable text domain leads
/// with `Hm` so `=`/`<>` resolve to `eq_term`/`hm`, never the ORE (`ob`) or
/// OPE (`op`) ordering term — text ordering terms are not equality-lossless.
/// `Term::Ore`/`Term::Ope` keep their kind-agnostic `=`/`<>` claim; they
/// simply never win because `Hm` precedes them (Option 1, catalog ordering).
/// Integer kinds keep `[Ore]`-only `_ord` and `[Ope]`-only `_ord_ope` domains
/// — ordering-term equality is lossless for them.
const TEXT_DOMAINS: &[Domain] = &[
    Domain {
        name: "",
        terms: &[],
        shape: Shape::Scalar,
    },
    Domain {
        name: "eq",
        terms: &[Term::Hm],
        shape: Shape::Scalar,
    },
    Domain {
        name: "match",
        terms: &[Term::Bloom],
        shape: Shape::Scalar,
    },
    Domain {
        name: "ord_ore",
        terms: &[Term::Hm, Term::Ore],
        shape: Shape::Scalar,
    },
    Domain {
        name: "ord",
        terms: &[Term::Hm, Term::Ore],
        shape: Shape::Scalar,
    },
    Domain {
        name: "ord_ope",
        terms: &[Term::Hm, Term::Ope],
        shape: Shape::Scalar,
    },
    Domain {
        name: "search",
        terms: &[Term::Hm, Term::Ore, Term::Bloom],
        shape: Shape::Scalar,
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
    shape: Shape::Scalar,
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

/// The SteVec (encrypted-JSONB) domains of the `jsonb` family. Every one has
/// empty `terms` — but these domains ARE searchable: each carries its index
/// terms *structurally*, inside the payload (`hm` for hash-equality, `oc` for
/// CLLW-ORE ordering, one per `sv` leaf), not as a flat family-level `Term`.
/// Empty `terms` records "no flat-scalar term surface," never "no index
/// capability"; the capability is described by the `Shape` and enforced by the
/// hand-written SQL CHECKs under `src/v3/jsonb/`. The coupling is pinned by
/// `tests::shape_and_terms_are_consistent`. The SQL
/// surface is hand-written under `src/v3/jsonb/` (the SQL generator SKIPS these),
/// and the Rust payload structs are hand-written in
/// `crates/eql-bindings/src/v3/jsonb.rs` (their fields/serde are not derivable
/// from the catalog); the catalog drives only their inventory membership + order.
const JSONB_DOMAINS: &[Domain] = &[
    Domain {
        // The established document name `eql_v3.json` predates the catalog and
        // does not follow the family+suffix convention (family is "jsonb", not
        // "json") — an explicit literal name, not the empty-suffix
        // bare-family-name convention every scalar storage domain uses.
        // `Domain::full_name` special-cases the name `"json"` to return it
        // verbatim instead of concatenating.
        name: "json",
        terms: &[],
        shape: Shape::SteVec,
    },
    Domain {
        name: "entry",
        terms: &[],
        shape: Shape::SteVec,
    },
    Domain {
        name: "query",
        terms: &[],
        shape: Shape::SteVec,
    },
];

/// `jsonb` — the encrypted-JSONB (SteVec) family: `eql_v3.json` (document, the
/// one explicit-name exception — see `JSONB_DOMAINS`), `eql_v3.jsonb_entry`
/// (one sv element), `eql_v3.jsonb_query` (containment needle). The Rust
/// struct *bodies* are hand-written (`crates/eql-bindings/src/v3/jsonb.rs`,
/// not derivable from the catalog); `Domain::rust_struct_name` derives their
/// *identifiers* (`SteVecDocument`/`SteVecEntry`/`SteVecQuery`) from
/// `Domain.name` so codegen's inventory renderer doesn't need its own copy of
/// the mapping. Added to `CATALOG` at the flip task.
pub const JSONB: DomainFamily = DomainFamily {
    name: "jsonb",
    domains: JSONB_DOMAINS,
};

/// The scalar catalog — the single source of truth. Order is significant (it
/// drives generation order). New types are appended as their SQL surface lands.
pub const CATALOG: &[DomainFamily] = &[
    INT4, INT2, INT8, DATE, TIMESTAMP, NUMERIC, TEXT, BOOL, FLOAT4, FLOAT8, JSONB,
];

/// The scalar (flat) families of `CATALOG`, in order — everything except the
/// SteVec `jsonb` family. The DRY entry point for the ~9 scalar-only consumers
/// (`generate_all`, `list-types`, the scalar matrix) so they never re-inline the
/// `is_scalar()` filter.
pub fn scalar_families() -> impl Iterator<Item = &'static DomainFamily> {
    CATALOG.iter().filter(|f| f.is_scalar())
}

#[cfg(test)]
mod tests;

#[cfg(test)]
mod proptest_invariants;
