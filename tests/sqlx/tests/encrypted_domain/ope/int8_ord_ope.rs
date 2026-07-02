//! `eql_v3.int8_ord_ope` smoke suite — the shared `_ord_ope` literal-payload
//! tests (see `ope/support.rs`). The ope surface is byte-identical across the
//! ordered families modulo the domain name; the deeper single-type behaviour
//! (prefix order, blockers, ORDER BY forms, aggregates) lives on the int4
//! reference in `ope/int4_ord_ope.rs`.

crate::ope_ord_smoke!("int8_ord_ope");
