//! sqlx glue for the v3 domain types (feature `sqlx`).
//!
//! Each domain is a jsonb-backed `eql_v3.*` PostgreSQL DOMAIN, so it encodes and
//! decodes exactly like `jsonb`. The property-test doubles bind a domain struct
//! and cast it in SQL (`$1::eql_v3.int4_eq`), which runs the domain CHECK. The
//! [`jsonb_domain_sqlx`] macro stamps `Type`/`Encode`/`Decode<Postgres>` for a
//! set of domain types by delegating to `sqlx::types::Json` (the canonical
//! jsonb ⇆ Serialize bridge), so every scalar family reuses it.

/// Implement `sqlx::Type`/`Encode`/`Decode<Postgres>` (as jsonb, via `Json`) for
/// each listed domain type.
macro_rules! jsonb_domain_sqlx {
    ($($t:ty),+ $(,)?) => {$(
        impl sqlx::Type<sqlx::Postgres> for $t {
            fn type_info() -> sqlx::postgres::PgTypeInfo {
                <sqlx::types::Json<Self> as sqlx::Type<sqlx::Postgres>>::type_info()
            }
            fn compatible(ty: &sqlx::postgres::PgTypeInfo) -> bool {
                <sqlx::types::Json<Self> as sqlx::Type<sqlx::Postgres>>::compatible(ty)
            }
        }

        impl<'q> sqlx::Encode<'q, sqlx::Postgres> for $t {
            fn encode_by_ref(
                &self,
                buf: &mut sqlx::postgres::PgArgumentBuffer,
            ) -> std::result::Result<sqlx::encode::IsNull, sqlx::error::BoxDynError> {
                sqlx::Encode::<sqlx::Postgres>::encode_by_ref(&sqlx::types::Json(self), buf)
            }
        }

        impl<'r> sqlx::Decode<'r, sqlx::Postgres> for $t {
            fn decode(
                value: sqlx::postgres::PgValueRef<'r>,
            ) -> std::result::Result<Self, sqlx::error::BoxDynError> {
                let json: sqlx::types::Json<Self> =
                    <sqlx::types::Json<Self> as sqlx::Decode<sqlx::Postgres>>::decode(value)?;
                Ok(json.0)
            }
        }
    )+};
}
pub(crate) use jsonb_domain_sqlx;
