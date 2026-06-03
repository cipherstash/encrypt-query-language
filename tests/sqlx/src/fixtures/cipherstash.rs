//! Direct `cipherstash-client` integration — the encryption oracle for the
//! SQLx fixture generator.
//!
//! Earlier revisions of the generator started a CipherStash Proxy container,
//! wrote `add_search_config` rows so Proxy knew which columns to encrypt,
//! restarted the container so it reloaded that config, then INSERTed
//! plaintexts through a Proxy-mediated Postgres connection. That whole loop
//! existed only because the Proxy was the encryption oracle.
//!
//! `cipherstash-client` 0.35 exposes the same surface natively. This module
//! owns the bootstrap — `build_cipher()` builds a `ScopedCipher<AutoStrategy>` —
//! and the batched helper `encrypt_store()` that wraps `eql::encrypt_eql` and
//! returns the resulting EQL ciphertexts as `serde_json::Value`s ready to bind
//! into a `jsonb` column. A fixture-generator process makes exactly one
//! `encrypt_store` call, so the cipher is built once per process by
//! construction — no static cache, no cross-runtime hazard.
//!
//! `column_config_for` maps the fixture spec's typed `IndexKind` values onto
//! the `IndexType` enum cipherstash-config uses. Extending index coverage
//! requires one new `IndexKind` variant and one checked mapping arm.

use std::borrow::Cow;
use std::sync::Arc;

use anyhow::{anyhow, Context, Result};
use cipherstash_client::encryption::ScopedCipher;
use cipherstash_client::eql::{
    encrypt_eql, EqlCiphertext, EqlEncryptOpts, EqlOperation, EqlOutput, Identifier,
    PreparedPlaintext,
};
use cipherstash_client::schema::column::{Index, IndexType};
use cipherstash_client::schema::{ColumnConfig, ColumnType};
use cipherstash_client::zerokms::{EnvKeyProvider, ZeroKMSBuilder};
use cipherstash_client::AutoStrategy;

use super::eql_plaintext::{Cast, EqlPlaintext};
use super::index_kind::IndexKind;

/// Build a fresh `ScopedCipher`. Performs `AutoStrategy::detect()`, the
/// ZeroKMS handshake, and the keyset load on every call — fine because
/// every fixture-generator process calls this exactly once via the
/// single batched `encrypt_store`.
async fn build_cipher() -> Result<Arc<ScopedCipher<AutoStrategy>>> {
    let zerokms = ZeroKMSBuilder::auto()?
        .with_key_provider(EnvKeyProvider)
        .build()
        .await?;

    let cipher = ScopedCipher::init_default(Arc::new(zerokms)).await?;

    Ok(Arc::new(cipher))
}

/// Build a `ColumnConfig` from the fixture spec's index list + cast.
///
/// `IndexKind` is a typed enum — every value is a real EQL index by
/// construction, so the mapping is total and `column_config_for` cannot
/// fail on an unknown index name. Extending fixture coverage to a new
/// index is one variant on `IndexKind` plus one arm here, both compile-
/// time checked.
pub fn column_config_for(spec_indexes: &[IndexKind], cast: Cast) -> Result<ColumnConfig> {
    let column_type = cast_to_column_type(cast)?;
    let mut config = ColumnConfig::build("payload").casts_as(column_type);

    for ix in spec_indexes {
        config = config.add_index(Index::new(index_type_for(*ix)));
    }

    Ok(config)
}

/// Map an `EqlPlaintext::Cast` onto cipherstash-config's `ColumnType`. The
/// `Cast` newtype's allowlist is structural, so the only failure mode is
/// "we extended `EqlPlaintext` with a new variant but forgot to extend
/// this mapping" — explicit error rather than a `_ => unreachable!()`
/// gives the maintainer a clear breadcrumb.
fn cast_to_column_type(cast: Cast) -> Result<ColumnType> {
    match cast.as_str() {
        "int" => Ok(ColumnType::Int),
        "small_int" => Ok(ColumnType::SmallInt),
        "big_int" => Ok(ColumnType::BigInt),
        "boolean" => Ok(ColumnType::Boolean),
        "date" => Ok(ColumnType::Date),
        "decimal" => Ok(ColumnType::Decimal),
        "float" | "real" | "double" => Ok(ColumnType::Float),
        "text" => Ok(ColumnType::Text),
        "jsonb" | "json" => Ok(ColumnType::Json),
        "timestamp" => Ok(ColumnType::Timestamp),
        other => Err(anyhow!(
            "no cipherstash-config ColumnType mapping for cast {other:?} — \
             extend cipherstash::cast_to_column_type when adding a new \
             EqlPlaintext variant"
        )),
    }
}

/// Map an `IndexKind` variant onto cipherstash-config's `IndexType`.
/// Reuses the canonical constructors on `Index` (`Index::new_unique`,
/// etc.) so the defaults stay in sync with whatever cipherstash-config
/// considers the canonical shape for each index. Total — every variant
/// has an arm; adding a new variant is a compile error here, which is
/// the point.
fn index_type_for(kind: IndexKind) -> IndexType {
    match kind {
        IndexKind::Unique => Index::new_unique().index_type,
        IndexKind::Ore => IndexType::Ore,
        IndexKind::Match => Index::new_match().index_type,
    }
}

/// Encrypt a batch of plaintext values for storage and return one EQL
/// ciphertext per input as a `serde_json::Value` ready to bind into a
/// `jsonb` column.
///
/// One `encrypt_eql` call regardless of `values.len()` — ZeroKMS does the
/// round trip once, not N times. The per-value field in each
/// `PreparedPlaintext` is `value.to_plaintext()`; the config, identifier,
/// and `EqlOperation::Store` are shared across the batch.
///
/// Uses `EqlOperation::Store`, which yields a full storage payload
/// (`{"k": "ct", "v": 2, "i": …, "c": …, "hm": …, "ob": …}`) — the same
/// shape Proxy produced for the working table. `EqlEncryptOpts::default()`
/// uses the cipher's default keyset, no lock context, no service token, no
/// index filter — the same defaults Proxy uses for column-config-driven
/// inserts.
///
/// An empty `values` slice short-circuits before `build_cipher()` so a
/// caller with nothing to encrypt does not pay the ZeroKMS bootstrap
/// cost.
pub async fn encrypt_store<T: EqlPlaintext>(
    table: &str,
    column: &str,
    values: &[T],
    config: &ColumnConfig,
) -> Result<Vec<serde_json::Value>> {
    if values.is_empty() {
        return Ok(Vec::new());
    }

    let cipher = build_cipher().await?;

    // `Identifier::new` does two `String` allocations per call — cheap
    // enough that constructing per-iteration is preferred over assuming
    // the upstream type implements `Clone`.
    let prepared: Vec<PreparedPlaintext> = values
        .iter()
        .map(|value| {
            PreparedPlaintext::new(
                Cow::Borrowed(config),
                Identifier::new(table, column),
                value.to_plaintext(),
                EqlOperation::Store,
            )
        })
        .collect();

    let opts = EqlEncryptOpts::default();
    let outputs = encrypt_eql(cipher, prepared, &opts)
        .await
        .with_context(|| {
            format!(
                "encrypting batch of {} values for {table}.{column}",
                values.len()
            )
        })?;

    if outputs.len() != values.len() {
        return Err(anyhow!(
            "encrypt_eql returned {} outputs for {} inputs",
            outputs.len(),
            values.len()
        ));
    }

    outputs
        .into_iter()
        .map(|output| {
            let ciphertext: EqlCiphertext = match output {
                EqlOutput::Store(ct) => ct,
                EqlOutput::Query(_) => {
                    // EqlOperation::Store always yields EqlOutput::Store;
                    // treating the other arm as unreachable would hide a
                    // future API drift.
                    return Err(anyhow!(
                        "encrypt_eql returned a Query output for an EqlOperation::Store input"
                    ));
                }
            };
            serde_json::to_value(&ciphertext).context("serialising EqlCiphertext to JSON")
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn column_config_for_int_with_unique_and_ore_builds_a_two_index_config() {
        let indexes = [IndexKind::Unique, IndexKind::Ore];
        let config = column_config_for(&indexes, Cast::INT).unwrap();

        assert_eq!(config.name, "payload");
        assert!(matches!(config.cast_type, ColumnType::Int));
        assert_eq!(config.indexes.len(), 2);
        assert!(config.indexes.iter().any(|i| i.is_unique()));
        assert!(config.indexes.iter().any(|i| i.is_ore()));
    }

    // Note: the "unknown index name rejected at runtime" test is gone —
    // `IndexKind` is a closed enum, so a typo is a compile error.

    #[test]
    fn index_type_for_maps_every_variant_to_its_canonical_index_type() {
        // Each `IndexKind` variant round-trips into the `IndexType`
        // cipherstash-config considers canonical for that name. Compared
        // via the public `Index` surface (`is_unique`, `is_ore`,
        // `is_match`) so the assertion does not depend on the shape of
        // the non-exhaustive `IndexType` enum.
        let unique = Index::new(index_type_for(IndexKind::Unique));
        assert!(unique.is_unique(), "Unique must map to the unique index");

        let ore = Index::new(index_type_for(IndexKind::Ore));
        assert!(ore.is_ore(), "Ore must map to the ORE index");

        let m = Index::new(index_type_for(IndexKind::Match));
        assert!(m.is_match(), "Match must map to the match (bloom) index");
    }

    #[tokio::test]
    async fn encrypt_store_with_empty_values_returns_an_empty_vec_without_building_cipher() {
        // Empty input short-circuits before `build_cipher()` so a caller
        // with nothing to encrypt does not pay the ZeroKMS bootstrap cost.
        // Running this test under `cargo test` (no `fixture-gen` feature,
        // no CS_* env vars) proves the short-circuit: if `build_cipher()`
        // were reached, the missing credentials would surface as an error.
        let config = column_config_for(&[IndexKind::Unique], Cast::INT).unwrap();
        let out = encrypt_store::<i32>("t", "c", &[], &config).await.unwrap();
        assert!(out.is_empty(), "empty input must yield empty output");
    }

    #[test]
    fn cast_to_column_type_covers_every_eql_plaintext_cast_constant() {
        // Every Cast constant on EqlPlaintext must round-trip into a
        // ColumnType — otherwise a freshly-added EqlPlaintext variant
        // would crash the generator at run time instead of failing the
        // build. Listed explicitly so a new `pub const` on Cast forces an
        // update here.
        for cast in [
            Cast::TEXT,
            Cast::INT,
            Cast::SMALL_INT,
            Cast::BIG_INT,
            Cast::REAL,
            Cast::DOUBLE,
            Cast::BOOLEAN,
            Cast::DATE,
            Cast::JSONB,
            Cast::JSON,
            Cast::FLOAT,
            Cast::DECIMAL,
            Cast::TIMESTAMP,
        ] {
            cast_to_column_type(cast).unwrap_or_else(|e| {
                panic!("Cast::{} has no ColumnType mapping: {e}", cast.as_str())
            });
        }
    }
}

/// Live `encrypt_store` round-trips against a real ZeroKMS keyset. Gated
/// by `fixture-gen` so default `cargo test` runs do not require
/// `CS_CLIENT_ACCESS_KEY` / `CS_WORKSPACE_CRN`. Each test is
/// `#[ignore]` so it only runs under
/// `cargo test --features fixture-gen -- --ignored`, mirroring the
/// `generate` test in `eql_v2_int4.rs`.
///
/// These complement the structural fixture-tests in
/// the `__scalar_matrix_fixture_shape!` arm in `tests/sqlx/src/matrix.rs`: those assert over the
/// regenerated SQL file end-to-end; these isolate the
/// `encrypt_store` call so an SDK API drift surfaces here before the
/// whole fixture pipeline fails.
#[cfg(all(test, feature = "fixture-gen"))]
mod live_tests {
    use super::*;
    use serde_json::Value;

    /// Config used by every live test — `Unique` drives the `hm` term,
    /// `Ore` drives the `ob` term, so the returned payloads carry both.
    fn int_config_with_hm_and_ob() -> ColumnConfig {
        column_config_for(&[IndexKind::Unique, IndexKind::Ore], Cast::INT).unwrap()
    }

    /// Assert the well-formed Store shape: the payload is a JSON object
    /// with non-null `v`, `c`, `hm`, `ob`, and `i` fields. Mirrors the
    /// per-key assertions in the generated `scalars::int4` matrix suite
    /// (emitted from the `scalar_harness!` list in `scalar_harness.rs`).
    fn assert_store_shape(payload: &Value) {
        let obj = payload.as_object().expect("payload must be a JSON object");
        for key in ["v", "c", "hm", "ob", "i"] {
            assert!(
                obj.get(key).is_some_and(|v| !v.is_null()),
                "payload must carry a non-null `{key}` field; got {payload}"
            );
        }
        // `v` is the EQL payload-format version. The cipherstash-client
        // JSON encodes it as the integer 2; the existing fixture tests
        // check `payload->>'v' = '2'` via Postgres's text-cast operator.
        // Asserting the number here matches the source format directly.
        assert_eq!(
            obj.get("v").and_then(Value::as_i64),
            Some(2),
            "payload must declare v = 2; got {payload}"
        );
    }

    #[tokio::test]
    #[ignore = "live ZeroKMS — run via `cargo test --features fixture-gen -- --ignored`"]
    async fn encrypt_store_single_value_returns_one_eql_payload() {
        let config = int_config_with_hm_and_ob();
        let out = encrypt_store("live_one", "payload", &[42_i32], &config)
            .await
            .expect("encrypt_store should succeed against live ZeroKMS");
        assert_eq!(out.len(), 1, "single input should produce single output");
        assert_store_shape(&out[0]);
    }

    #[tokio::test]
    #[ignore = "live ZeroKMS — run via `cargo test --features fixture-gen -- --ignored`"]
    async fn encrypt_store_batch_returns_one_payload_per_input_in_input_order() {
        let config = int_config_with_hm_and_ob();
        let values = [-1_i32, 1, 42];
        let out = encrypt_store("live_batch", "payload", &values, &config)
            .await
            .expect("encrypt_store should succeed against live ZeroKMS");
        assert_eq!(
            out.len(),
            values.len(),
            "batch length must equal input length"
        );
        for (i, payload) in out.iter().enumerate() {
            assert_store_shape(payload);
            // Each payload's `i.t` should match the table identifier we
            // supplied — that's the field consuming code uses to bind a
            // payload to its source column.
            let identifier_t = payload
                .get("i")
                .and_then(Value::as_object)
                .and_then(|o| o.get("t"))
                .and_then(Value::as_str);
            assert_eq!(
                identifier_t,
                Some("live_batch"),
                "payload[{i}].i.t must match the table argument; got {payload}"
            );
        }
    }

    #[tokio::test]
    #[ignore = "live ZeroKMS — run via `cargo test --features fixture-gen -- --ignored`"]
    async fn encrypt_store_batch_distinct_plaintexts_yield_distinct_hm() {
        // HMAC is the equality term — three distinct plaintexts must
        // yield three distinct `hm` strings. Mirrors
        // `hmac_equality_terms_are_distinct_for_distinct_values` in the
        // fixture-tests but at the unit-test layer.
        let config = int_config_with_hm_and_ob();
        let out = encrypt_store("live_distinct", "payload", &[-1_i32, 1, 42], &config)
            .await
            .expect("encrypt_store should succeed against live ZeroKMS");

        let hms: Vec<&str> = out
            .iter()
            .map(|p| {
                p.get("hm")
                    .and_then(Value::as_str)
                    .expect("payload must carry a string `hm` term")
            })
            .collect();
        let unique: std::collections::HashSet<&&str> = hms.iter().collect();
        assert_eq!(
            unique.len(),
            hms.len(),
            "distinct plaintexts must yield distinct hm terms; got {hms:?}"
        );
    }
}
