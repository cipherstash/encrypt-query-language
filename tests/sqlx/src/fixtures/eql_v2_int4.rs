//! The `eql_v2_int4` fixture — the framework's reference example and proof.
//!
//! 17 integers spanning a negative boundary, the i32 signed extremes
//! (`MIN`/`MAX`), zero, and small/medium/large magnitudes. The generated
//! `tests/sqlx/fixtures/eql_v2_int4.sql` is a plain `jsonb`-payload table with
//! no EQL dependency; #225 layers the `eql_v2_int4` domain on top by casting
//! `payload` per query.

use super::int4_values::VALUES;

crate::scalar_fixture!("eql_v2_int4", i32, VALUES);
