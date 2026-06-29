//! The hand-written `DomainType` trait and its `PhantomData` enumeration
//! plumbing — the stable, NON-generated core of the v3 bindings surface. The
//! per-family payload structs and the `inventory.rs` `all()` list are generated
//! from `eql-domains::CATALOG` by `eql-codegen`; this trait, the schema-id base,
//! and the blanket `PhantomData` impl are authored by hand.

use std::marker::PhantomData;

use schemars::{schema_for, JsonSchema, Schema};

/// The PostgreSQL schema every domain in this module inhabits.
pub const SQL_SCHEMA: &str = "eql_v3";

/// Base URL for the canonical `$id` of every published v3 JSON Schema.
/// The per-domain `$id` is `{SCHEMA_ID_BASE}{domain}.json` (see
/// [`DomainType::schema_id`]); `tests/export.rs` injects it at write time.
pub const SCHEMA_ID_BASE: &str = "https://schemas.cipherstash.com/eql/v3/";

/// One v3 domain type — implemented by every payload type, so any payload
/// value can report the SQL domain it inhabits (`payload.sql_domain()`).
///
/// Each token file implements this next to the type it describes; the SQL
/// domain string is defined exactly once, in that impl. `all()` is generated
/// from `eql-domains::CATALOG` (`inventory.rs`), so it cannot drift; the
/// published JSON Schema wire contract is pinned by `tests/catalog_parity.rs`.
/// Public so FFI consumers can enumerate the protocol surface too.
pub trait DomainType {
    /// Fully-qualified SQL domain name, e.g. `"eql_v3.int4_eq"` — the
    /// per-type fact everything else derives from, defined once in each
    /// type's impl.
    ///
    /// `where Self: Sized` keeps the trait object-safe (the method is
    /// excluded from the vtable); through `dyn DomainType`, use
    /// [`Self::sql_domain`].
    fn sql_domain_static() -> &'static str
    where
        Self: Sized;

    /// Fully-qualified SQL domain name of this payload value.
    fn sql_domain(&self) -> &'static str;

    /// Unqualified SQL domain name (e.g. `"int4_eq"`) — [`Self::sql_domain`]
    /// minus the schema qualifier; matches `eql-domains`
    /// `DomainFamily::domain_name`.
    fn domain(&self) -> &'static str {
        self.sql_domain()
            .strip_prefix("eql_v3.")
            .expect("sql_domain must be qualified with the eql_v3 schema")
    }

    /// Canonical `$id` for this domain's published JSON Schema —
    /// `{SCHEMA_ID_BASE}{domain}.json`. The single source of truth for the
    /// identity `tests/export.rs` injects; pinned by `tests/catalog_parity.rs`.
    fn schema_id(&self) -> String {
        format!("{SCHEMA_ID_BASE}{}.json", self.domain())
    }

    /// The type's JSON Schema.
    fn schema(&self) -> Schema;
}

/// Type-level handle: lets [`all`] enumerate the domain types without
/// payload values to box — `Box::new(PhantomData::<Int4Eq>)` is zero-sized,
/// and the delegation goes through [`DomainType::sql_domain_static`], so no
/// payload instance is ever constructed.
///
/// [`all`]: super::all
impl<T> DomainType for PhantomData<T>
where
    T: DomainType + JsonSchema,
{
    fn sql_domain_static() -> &'static str {
        T::sql_domain_static()
    }

    fn sql_domain(&self) -> &'static str {
        T::sql_domain_static()
    }

    fn schema(&self) -> Schema {
        schema_for!(T)
    }
}
