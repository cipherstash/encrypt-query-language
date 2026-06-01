//! The `eql_v2_int8` fixture — the int4 reference, widened to 64 bits.
//!
//! 19 integers spanning a negative boundary, the i64 signed extremes
//! (`MIN`/`MAX`), zero, a pair beyond the ±2^31 int4 boundary, and
//! small/medium/large magnitudes. The generated
//! `tests/sqlx/fixtures/eql_v2_int8.sql` is a plain `jsonb`-payload table with
//! no EQL dependency; the `eql_v2_int8` domain is layered on top by casting
//! `payload` per query.

use super::int8_values::VALUES;

crate::scalar_fixture!("eql_v2_int8", i64, VALUES);
