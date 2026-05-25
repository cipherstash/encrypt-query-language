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
pub fn column_config_for(
    spec_indexes: &[FixtureIdentifier],
    cast: Cast,
) -> Result<ColumnConfig> {
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

/// Encrypt a single plaintext value for storage and return the resulting
/// EQL ciphertext as a `serde_json::Value` ready to bind into a `jsonb`
/// column.
///
/// Uses `EqlOperation::Store`, which yields a full storage payload
/// (`{"k": "ct", "v": 2, "i": …, "c": …, "hm": …, "ob": …}`) — the same
/// shape Proxy produced for the working table. `EqlEncryptOpts::default()`
/// uses the cipher's default keyset, no lock context, no service token, no
/// index filter — the same defaults Proxy uses for column-config-driven
/// inserts.
pub async fn encrypt_store<T: EqlPlaintext>(
    table: &str,
    column: &str,
    value: T,
    config: &ColumnConfig,
) -> Result<serde_json::Value> {
    let cipher = cipher().await?;

    let prepared = PreparedPlaintext::new(
        Cow::Borrowed(config),
        Identifier::new(table, column),
        value.to_plaintext(),
        EqlOperation::Store,
    );

    let opts = EqlEncryptOpts::default();
    let mut outputs = encrypt_eql(cipher, vec![prepared], &opts)
        .await
        .with_context(|| format!("encrypting value for {table}.{column}"))?;

    let output = outputs
        .pop()
        .ok_or_else(|| anyhow!("encrypt_eql returned no outputs"))?;

    let ciphertext: EqlCiphertext = match output {
        EqlOutput::Store(ct) => ct,
        EqlOutput::Query(_) => {
            // EqlOperation::Store always yields EqlOutput::Store; treating
            // the other arm as unreachable would hide a future API drift.
            return Err(anyhow!(
                "encrypt_eql returned a Query output for an EqlOperation::Store input"
            ));
        }
    };

    serde_json::to_value(&ciphertext).context("serialising EqlCiphertext to JSON")
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
