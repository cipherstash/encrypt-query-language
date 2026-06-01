//! The `eql_v2_int2` fixture — the int4 reference, clamped to 16 bits.
//!
//! 19 integers spanning a negative boundary, the i16 signed extremes
//! (`MIN`/`MAX`), zero, a pair near the ±32767 boundary, and
//! small/medium/large magnitudes. The generated
//! `tests/sqlx/fixtures/eql_v2_int2.sql` is a plain `jsonb`-payload table with
//! no EQL dependency; the `eql_v2_int2` domain is layered on top by casting
//! `payload` per query.

use super::int2_values::VALUES;

crate::scalar_fixture!("eql_v2_int2", i16, VALUES);
