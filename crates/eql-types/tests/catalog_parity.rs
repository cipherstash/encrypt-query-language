//! The drift gate: the v3 domain inventory must mirror `eql-scalars::CATALOG`
//! — the same catalog that generates the `eql_v3` SQL surface — exactly:
//! every domain, in catalog order. Append a scalar to the catalog without
//! adding its types (and their `all()` entries) and this fails.
//!
//! Wire-key strictness (required term keys, unknown-key rejection, envelope
//! version) is covered behaviourally per-type in `tests/v3_conformance.rs`,
//! and pinned against the catalog by the JSON Schema parity test in the
//! stacked schemars change.

use eql_scalars::CATALOG;
use eql_types::v3;

#[test]
fn inventory_exactly_covers_catalog() {
    let expected: Vec<String> = CATALOG
        .iter()
        .flat_map(|spec| spec.domains.iter().map(|d| spec.domain_name(d)))
        .collect();
    let actual: Vec<&str> = v3::all().iter().map(|e| e.domain()).collect();
    assert_eq!(
        actual, expected,
        "v3::all() must list every CATALOG domain, in catalog order"
    );
}
