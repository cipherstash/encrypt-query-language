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
//! owns the bootstrap — `cipher()` lazily builds a process-wide
//! `ScopedCipher<AutoStrategy>` — and the per-value helper
//! `encrypt_store()` that wraps `eql::encrypt_eql` and returns the resulting
//! EQL ciphertext as a `serde_json::Value` ready to bind into a `jsonb`
//! column.
//!
//! `column_config_for` is the bridge between the fixture spec's string-typed
//! index names (`"unique"`, `"ore"`, …) and the typed `IndexType` enum
//! cipherstash-config uses. Unknown names raise immediately so a typo at
//! spec construction fails fast.

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
use tokio::sync::OnceCell;

use super::eql_plaintext::{Cast, EqlPlaintext};
use super::validation::FixtureIdentifier;

/// Process-wide `ScopedCipher`. Built on first use and held for the lifetime
/// of the test binary — `ScopedCipher` is documented as
/// "initialise once per process, hold an `Arc` for the process lifetime"
/// (see the upstream doc comment in `scoped_cipher.rs`). Re-initialising it
/// per call discards the warm reqwest pool and the cached auth token, and
/// makes the generator slower for no benefit.
static CIPHER: OnceCell<Arc<ScopedCipher<AutoStrategy>>> = OnceCell::const_new();

/// Lazily initialise the process-wide cipher. On the first call this performs
/// the AutoStrategy detection, the ZeroKMS handshake, and the keyset load —
/// each subsequent call is an `Arc` clone.
///
/// Errors surface as `anyhow::Error` with `.context(...)` naming the step
/// that failed (credential detection vs ZeroKMS connect vs keyset load).
pub async fn cipher() -> Result<Arc<ScopedCipher<AutoStrategy>>> {
    CIPHER
        .get_or_try_init(|| async {
            let zerokms = ZeroKMSBuilder::auto()
                .context(
                    "building ZeroKMSBuilder via AutoStrategy::detect() — check \
                     CS_CLIENT_ACCESS_KEY or CS_WORKSPACE_CRN env vars",
                )?
                .with_key_provider(EnvKeyProvider)
                .build()
                .await
                .context(
                    "building ZeroKMS client — check CS_CLIENT_ID + CS_CLIENT_KEY \
                     env vars (loaded by EnvKeyProvider)",
                )?;

            let cipher = ScopedCipher::init_default(Arc::new(zerokms))
                .await
                .context("initialising ScopedCipher for the default keyset")?;

            Ok::<_, anyhow::Error>(Arc::new(cipher))
        })
        .await
        .cloned()
}

/// Build a `ColumnConfig` from the fixture spec's index list + cast.
///
/// The fixture spec uses EQL's string-typed index identifiers (`"unique"`,
/// `"ore"`, `"match"`, `"ste_vec"`); cipherstash-config uses the typed
/// `IndexType` enum. The mapping here is the single point of contact
/// between the two — extending fixture coverage to a new index means one
/// new arm here plus the corresponding `EqlPlaintext::CAST` constant.
///
/// Unknown identifiers raise immediately with the offending name in the
/// error so a typo at spec-construction surfaces at run time (the
/// `FixtureIdentifier` newtype only proves the string is a valid SQL
/// identifier, not that it names a real index type).
pub fn column_config_for(spec_indexes: &[FixtureIdentifier], cast: Cast) -> Result<ColumnConfig> {
    let column_type = cast_to_column_type(cast)?;
    let mut config = ColumnConfig::build("payload").casts_as(column_type);

    for ix in spec_indexes {
        let index_type = index_type_for(ix.as_str())?;
        config = config.add_index(Index::new(index_type));
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

/// Map the fixture spec's string-typed index identifier onto a typed
/// `IndexType`. Reuses the canonical constructors on `Index`
/// (`Index::new_unique`, etc.) so the defaults stay in sync with whatever
/// cipherstash-config considers the canonical shape for each index.
fn index_type_for(name: &str) -> Result<IndexType> {
    match name {
        "unique" => Ok(Index::new_unique().index_type),
        "ore" => Ok(IndexType::Ore),
        "match" => Ok(Index::new_match().index_type),
        other => Err(anyhow!(
            "unknown EQL index identifier {other:?} — supported: \
             unique, ore, match"
        )),
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
/// An empty `values` slice short-circuits before `cipher()` so a caller
/// with nothing to encrypt does not pay the ZeroKMS bootstrap cost.
pub async fn encrypt_store<T: EqlPlaintext + Copy>(
    table: &str,
    column: &str,
    values: &[T],
    config: &ColumnConfig,
) -> Result<Vec<serde_json::Value>> {
    if values.is_empty() {
        return Ok(Vec::new());
    }

    let cipher = cipher().await?;

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

    fn ident(s: &str) -> FixtureIdentifier {
        FixtureIdentifier::try_from(s).unwrap()
    }

    #[test]
    fn column_config_for_int_with_unique_and_ore_builds_a_two_index_config() {
        let indexes = [ident("unique"), ident("ore")];
        let config = column_config_for(&indexes, Cast::INT).unwrap();

        assert_eq!(config.name, "payload");
        assert!(matches!(config.cast_type, ColumnType::Int));
        assert_eq!(config.indexes.len(), 2);
        assert!(config.indexes.iter().any(|i| i.is_unique()));
        assert!(config.indexes.iter().any(|i| i.is_ore()));
    }

    #[test]
    fn column_config_for_rejects_an_unknown_index_name() {
        let indexes = [ident("bogus")];
        let err = column_config_for(&indexes, Cast::INT).unwrap_err();
        assert!(
            format!("{err:#}").contains("unknown EQL index identifier"),
            "error should name the unknown identifier: {err:#}"
        );
    }

    #[test]
    fn index_type_for_maps_known_names_to_their_canonical_index_type() {
        // The named EQL index identifiers each round-trip into the
        // `IndexType` cipherstash-config considers canonical for that
        // name. Compared via the public `Index` surface (`is_unique`,
        // `is_ore`, `is_match`) so the assertion does not depend on the
        // shape of the non-exhaustive `IndexType` enum.
        let unique = Index::new(index_type_for("unique").unwrap());
        assert!(unique.is_unique(), "'unique' must map to the unique index");

        let ore = Index::new(index_type_for("ore").unwrap());
        assert!(ore.is_ore(), "'ore' must map to the ORE index");

        let m = Index::new(index_type_for("match").unwrap());
        assert!(m.is_match(), "'match' must map to the match (bloom) index");
    }

    #[test]
    fn index_type_for_rejects_an_unknown_index_name() {
        let err = index_type_for("bogus").unwrap_err();
        let msg = format!("{err:#}");
        assert!(
            msg.contains("unknown EQL index identifier") && msg.contains("bogus"),
            "error should name the offending identifier: {msg}"
        );
    }

    #[tokio::test]
    async fn encrypt_store_with_empty_values_returns_an_empty_vec_without_calling_cipher() {
        // Empty input short-circuits before `cipher()` so a caller with
        // nothing to encrypt does not pay the ZeroKMS bootstrap cost.
        // Running this test under `cargo test` (no `fixture-gen` feature,
        // no CS_* env vars) proves the short-circuit: if `cipher()` were
        // reached, the missing credentials would surface as an error.
        let config = column_config_for(&[ident("unique")], Cast::INT).unwrap();
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
/// `cargo test --features fixture-gen -- --ignored --test-threads=1`,
/// mirroring the `generate` test in `eql_v2_int4.rs`.
///
/// **Must run serially (`--test-threads=1`).** The process-wide
/// `CIPHER` `OnceCell` caches a `ScopedCipher` whose reqwest connection
/// pool is bound to the tokio runtime that initialised it. Each
/// `#[tokio::test]` builds its own runtime, so under parallel
/// execution the second test's calls go through a pool whose
/// dispatcher has been dropped — failing with
/// "SendRequest: dispatch task is gone". Production fixture runs (one
/// `#[tokio::main]` runtime) are unaffected.
///
/// These complement the structural fixture-tests in
/// `tests/sqlx/tests/eql_v2_int4_fixture_tests.rs`: those assert over the
/// regenerated SQL file end-to-end; these isolate the
/// `encrypt_store` call so an SDK API drift surfaces here before the
/// whole fixture pipeline fails.
#[cfg(all(test, feature = "fixture-gen"))]
mod live_tests {
    use super::*;
    use serde_json::Value;

    fn ident(s: &str) -> FixtureIdentifier {
        FixtureIdentifier::try_from(s).unwrap()
    }

    /// Config used by every live test — `unique` drives the `hm` term,
    /// `ore` drives the `ob` term, so the returned payloads carry both.
    fn int_config_with_hm_and_ob() -> ColumnConfig {
        column_config_for(&[ident("unique"), ident("ore")], Cast::INT).unwrap()
    }

    /// Assert the well-formed Store shape: the payload is a JSON object
    /// with non-null `v`, `c`, `hm`, `ob`, and `i` fields. Mirrors the
    /// per-key assertions in `eql_v2_int4_fixture_tests.rs`.
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
