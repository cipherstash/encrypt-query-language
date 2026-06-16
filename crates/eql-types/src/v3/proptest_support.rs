//! SQL-backed property-test harness (feature `proptest`).
//!
//! The pure-Rust tests (`tests/catalog_parity.rs`, `tests/v3_conformance.rs`)
//! prove the types match the catalog and round-trip through serde. They do not
//! prove the types are wire-compatible with the **actual `eql_v3.*` SQL
//! functions** — the Rust structs and the SQL domains are defined
//! independently (issue #237). This module closes that gap with the
//! "function double" pattern: generate a plaintext, encrypt it to a real EQL
//! payload (via `cipherstash-client`), bind it into the generated SQL function
//! for a domain, and assert the SQL result agrees with the plaintext oracle.
//!
//! ## The domain "trait"
//!
//! Each `eql_v3` scalar domain has a set of generated SQL functions, loosely a
//! trait: a term extractor (`eq_term` → `hm`, `ord_term` → `ob`), and a
//! comparison function per supported operator (`eq`/`neq`/`lt`/`lte`/`gt`/`gte`),
//! each with three overloads — `(domain, domain)`, `(domain, jsonb)`,
//! `(jsonb, domain)`. The [`Runner`] exposes one method per function, each a
//! 1:1 wrapper (`eq_term`/`ord_term` return the extracted term; `eq`/`lt`/…
//! return a comparison result). The comparison overload is chosen by the
//! operand *types* (not a runtime flag): a bare `&payload` is cast to its
//! domain, a [`Jsonb`]`(&payload)` is left as raw jsonb — so `r.eq(&x, &y)`,
//! `r.eq(&x, Jsonb(&y))`, and `r.eq(Jsonb(&x), &y)` hit the three overloads.
//! Capability traits ([`EqTerm`], [`OrdTerm`], [`Comparable`], [`Ordered`])
//! gate the methods so a domain can only be passed to the functions it actually
//! generates. Each domain's test module stamps those markers (via
//! [`impl_eq_domain`] / [`impl_ord_domain`]) then lists one spec macro per
//! generated SQL function (`eq_term!` / `ord_term!` / `eq!` / `neq!` / `lt!` /
//! `lte!` / `gt!` / `gte!`) — see the macro section below; the block reads as a
//! 1:1 specification of the domain's SQL surface.
//!
//! ## v2 → v3
//!
//! `cipherstash-client` only encrypts to the general EQL **v2** storage payload
//! ([`EncryptedPayload`] — `v`/`i`/`c` + optional `hm`/`bf`/`ob`). The narrow,
//! capability-specific v3 domain structs are built from it by per-domain
//! conversions that live in each domain's own test module (e.g.
//! `From<&EncryptedPayload> for Int4Eq` in `int4.rs`).
//!
//! ## Auth (no skipping)
//!
//! The cipher is built in auto mode (`ZeroKMSBuilder::auto`): `AutoStrategy`
//! resolves the ZeroKMS *auth* from the environment (CI: `CS_*`) or an on-disk
//! profile (`stash auth login`). The dataset *key* is separate — a
//! `FallbackKeyProvider` tries `EnvKeyProvider` (env) then the profile
//! (`ProfileStore`), so both CI and a local login work. If neither yields auth
//! the build **panics** with guidance — the property tests never silently skip.

use std::borrow::Cow;
use std::sync::{Arc, LazyLock};

use cipherstash_client::encryption::{Plaintext, ScopedCipher};
use cipherstash_client::eql::{
    encrypt_eql, EncryptedPayload, EqlCiphertext, EqlEncryptOpts, EqlOperation, EqlOutput,
    Identifier as EqlIdentifier, PreparedPlaintext,
};
use cipherstash_client::schema::column::{Index, IndexType};
use cipherstash_client::schema::{ColumnConfig, ColumnType};
use cipherstash_client::zerokms::{EnvKeyProvider, FallbackKeyProvider, ZeroKMSBuilder};
use cipherstash_client::AutoStrategy;
use sqlx::PgPool;

use crate::v3::terms::{Hmac256, OreBlockU64_8_256};
use crate::v3::DomainType;

/// Table/column identity stamped into every generated payload's `i` key. The
/// `eql_v3.*` comparison functions ignore `i`; the domain CHECK only requires
/// its presence. Exposed so the per-domain conversions can rebuild the
/// eql-types `Identifier` without depending on the client's `i` serialisation.
pub const PROPTEST_TABLE: &str = "eql_types_proptest";
pub const PROPTEST_COLUMN: &str = "int4";

/// The encrypted-payload column name handed to `cipherstash-client`.
const PAYLOAD_COLUMN: &str = "payload";
/// Fallback when `DATABASE_URL` is unset — the project's standard local DB.
const DEFAULT_DATABASE_URL: &str = "postgresql://cipherstash:password@localhost:7432/cipherstash";

/// The shared runtime bridging sync quickcheck → async sqlx / cipher.
fn runtime() -> &'static tokio::runtime::Runtime {
    static RT: LazyLock<tokio::runtime::Runtime> = LazyLock::new(|| {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .expect("build shared tokio runtime")
    });
    &RT
}

/// Lazily-initialised shared pool against `DATABASE_URL` (or the default).
/// `async` (via `tokio::sync::OnceCell`) so it's awaited inside each double's
/// single `block_on` — never a nested `block_on`.
async fn pool() -> &'static PgPool {
    static POOL: tokio::sync::OnceCell<PgPool> = tokio::sync::OnceCell::const_new();
    POOL.get_or_init(|| async {
        let url = std::env::var("DATABASE_URL").unwrap_or_else(|_| DEFAULT_DATABASE_URL.to_owned());
        sqlx::postgres::PgPoolOptions::new()
            .max_connections(4)
            .connect(&url)
            .await
            .expect("connect to the eql-types property-test database")
    })
    .await
}

/// Lazily-built cipher. The ZeroKMS handshake + keyset load happen once.
/// Auto mode (`ZeroKMSBuilder::auto`) resolves the ZeroKMS *auth* from env or an
/// on-disk profile, but the dataset *key* is a separate concern: a
/// `FallbackKeyProvider` tries `EnvKeyProvider` (CI: `CS_CLIENT_ID`/`CS_CLIENT_KEY`)
/// then the `stash auth login` profile (`ProfileStore`). Panics with guidance if
/// neither yields a key — we do not skip. `async` like `pool` (awaited inside
/// the caller's `block_on`).
async fn cipher() -> Arc<ScopedCipher<AutoStrategy>> {
    static CIPHER: tokio::sync::OnceCell<Arc<ScopedCipher<AutoStrategy>>> =
        tokio::sync::OnceCell::const_new();
    CIPHER
        .get_or_init(|| async {
            let zerokms = ZeroKMSBuilder::auto()
                .expect("detect ZeroKMS auth — set CS_* env or run `stash auth login`")
                .with_key_provider(FallbackKeyProvider::new(
                    EnvKeyProvider,
                    stack_profile::ProfileStore::default(),
                ))
                .build()
                .await
                .expect("connect to ZeroKMS — set CS_* env or run `stash auth login`");
            Arc::new(
                ScopedCipher::init_default(Arc::new(zerokms))
                    .await
                    .expect("initialise cipher / load keyset"),
            )
        })
        .await
        .clone()
}

/// Which index term the encrypted payload should carry: `Hm` (unique/HMAC,
/// backs `_eq`) or `Ore` (block ORE, backs `_ord`/`_ord_ore`).
#[derive(Clone, Copy, Debug)]
pub enum TermKind {
    Hm,
    Ore,
}

/// A plaintext scalar the harness can encrypt: maps the Rust value to a
/// cipherstash-client `Plaintext` and names the PostgreSQL column cast.
/// Implemented for each scalar's native Rust type (`i32` → int4, `i64` → int8).
pub trait ProptestScalar: Copy + 'static {
    fn to_plaintext(self) -> Plaintext;
    fn column_type() -> ColumnType;
}

impl ProptestScalar for i32 {
    fn to_plaintext(self) -> Plaintext {
        Plaintext::Int(Some(self))
    }
    fn column_type() -> ColumnType {
        ColumnType::Int
    }
}

impl ProptestScalar for i64 {
    fn to_plaintext(self) -> Plaintext {
        Plaintext::BigInt(Some(self))
    }
    fn column_type() -> ColumnType {
        ColumnType::BigInt
    }
}

/// The fixed identifier every generated payload carries. Built locally (not
/// parsed from the client output): the `eql_v3.*` comparison functions ignore
/// `i`; the domain CHECK only requires its presence.
pub fn identifier() -> crate::Identifier {
    crate::Identifier {
        t: PROPTEST_TABLE.to_owned(),
        c: PROPTEST_COLUMN.to_owned(),
    }
}

fn config_for<S: ProptestScalar>(kind: TermKind) -> ColumnConfig {
    let base = ColumnConfig::build(PAYLOAD_COLUMN).casts_as(S::column_type());
    match kind {
        TermKind::Hm => base.add_index(Index::new_unique()),
        TermKind::Ore => base.add_index(Index::new(IndexType::Ore)),
    }
}

/// Encrypt one scalar `value` to the cipherstash-client EQL v2 storage payload
/// ([`EncryptedPayload`]), carrying the requested index term. Panics on
/// failure — only reached inside a property body, which fails the test.
pub fn encrypt<S: ProptestScalar>(value: S, kind: TermKind) -> EncryptedPayload {
    let prepared = PreparedPlaintext::new(
        Cow::Owned(config_for::<S>(kind)),
        EqlIdentifier::new(PROPTEST_TABLE, PROPTEST_COLUMN),
        value.to_plaintext(),
        EqlOperation::Store,
    );
    let outputs = runtime().block_on(async {
        encrypt_eql(cipher().await, vec![prepared], &EqlEncryptOpts::default())
            .await
            .expect("encrypt_eql")
    });
    match outputs.into_iter().next().expect("one output per input") {
        EqlOutput::Store(EqlCiphertext::Encrypted(payload)) => payload,
        // A scalar column config never yields a SteVec payload or a Query output.
        _ => {
            panic!("scalar Store encryption must yield EqlOutput::Store(EqlCiphertext::Encrypted)")
        }
    }
}

/// The mp_base85 source ciphertext (`c`) of a payload. [`EncryptedPayload`]'s
/// `c` is an opaque `EncryptedRecord` whose wire form is only produced by
/// serializing, so we serialize once and read the `c` field. (Serializing
/// `EncryptedPayload` directly — not the `EqlCiphertext` enum — omits the
/// v2-only `k` tag, so there is no discriminator to strip.)
pub fn ciphertext_b85(payload: &EncryptedPayload) -> String {
    serde_json::to_value(payload)
        .expect("serialise EncryptedPayload")
        .get("c")
        .and_then(|v| v.as_str())
        .expect("EncryptedPayload always serialises a string `c`")
        .to_owned()
}

/// A v3 domain type a property test can build from a plaintext by encrypting it
/// (shared cipher) and converting the v2 payload. `Plaintext` is the scalar's
/// native Rust type (`i32` for int4, `i64` for int8). Backs both the
/// `quickcheck::Arbitrary` impls (the unary extractor properties, where the
/// plaintext is not needed) and the encrypt-in-body of the comparison
/// properties (where the plaintexts are the oracle — the same shape as
/// cllw-ore's compare test). Usually implemented via [`impl_eq_domain`] /
/// [`impl_ord_domain`].
pub trait EncryptableScalar: Sized {
    type Plaintext: quickcheck::Arbitrary;
    fn encrypt_value(plaintext: Self::Plaintext) -> Self;
}

/// A v3 domain payload that can be bound into a query as jsonb (the bundle of
/// sqlx bounds the doubles need). Blanket-implemented for every domain type
/// with the `sqlx` feature impls.
pub trait Bind:
    DomainType
    + Clone
    + Send
    + Sync
    + 'static
    + sqlx::Type<sqlx::Postgres>
    + for<'q> sqlx::Encode<'q, sqlx::Postgres>
{
}
impl<T> Bind for T where
    T: DomainType
        + Clone
        + Send
        + Sync
        + 'static
        + sqlx::Type<sqlx::Postgres>
        + for<'q> sqlx::Encode<'q, sqlx::Postgres>
{
}

/// A scalar a double can read back out of a query (the bundle of sqlx decode
/// bounds). Blanket-implemented for `bool`, `String`, `Vec<String>`, …
pub trait ScalarOut:
    for<'r> sqlx::Decode<'r, sqlx::Postgres> + sqlx::Type<sqlx::Postgres> + Send + Unpin
{
}
impl<O> ScalarOut for O where
    O: for<'r> sqlx::Decode<'r, sqlx::Postgres> + sqlx::Type<sqlx::Postgres> + Send + Unpin
{
}

// --- Operands: the comparison overload, chosen by the operand's type ---------
//
// Every comparison operator generates three overloads — `(domain, domain)`,
// `(domain, jsonb)`, `(jsonb, domain)`. Rather than a runtime enum, the operand
// *type* picks the overload: a bare `&T` is cast to its domain (`$n::<dom>`); a
// `Jsonb(&T)` is left as raw jsonb (`$n`) so PG selects the jsonb overload.
// Both bind the same payload as jsonb — only the SQL cast differs.

/// One operand of a comparison-function double.
pub trait Operand {
    /// The domain payload this operand carries.
    type Payload: Bind;
    /// SQL for this operand at `placeholder` (e.g. `$1::eql_v3.int4_eq` or `$1`).
    fn render(&self, placeholder: &str) -> String;
    /// The payload to bind (owned clone — bound as jsonb).
    fn payload(&self) -> Self::Payload;
}

/// A domain operand: cast to its `eql_v3.*` domain (the typed path).
impl<T: Bind> Operand for &T {
    type Payload = T;
    fn render(&self, placeholder: &str) -> String {
        format!("{placeholder}::{}", self.sql_domain())
    }
    fn payload(&self) -> T {
        (*self).clone()
    }
}

/// A bare-jsonb operand: no cast, so PG picks the `(…, jsonb)` / `(jsonb, …)`
/// overload. Wraps the same domain payload (bound as jsonb).
pub struct Jsonb<'a, T>(pub &'a T);

impl<T: Bind> Operand for Jsonb<'_, T> {
    type Payload = T;
    fn render(&self, placeholder: &str) -> String {
        placeholder.to_owned()
    }
    fn payload(&self) -> T {
        self.0.clone()
    }
}

// --- Capability traits: the generated SQL surface of a domain, as a trait ----
//
// Each domain implements the markers for the functions it actually generates,
// so the `Runner` methods are gated at compile time — calling `lt` on an
// `_eq`-only domain, or `eq_term` on an ORE domain, is a type error.

/// Domains exposing `eql_v3.eq_term(<dom>) -> hmac_256` (carry an `hm` term).
pub trait EqTerm: Bind {}
/// Domains exposing `eql_v3.ord_term(<dom>) -> ore_block_u64_8_256` (`ob`).
pub trait OrdTerm: Bind {}
/// Domains supporting the equality comparisons (`eq`/`neq`).
pub trait Comparable: Bind {}
/// Domains supporting the ordered comparisons (`lt`/`lte`/`gt`/`gte`).
pub trait Ordered: Comparable {}

/// Runs the generated SQL function doubles against the shared pool. Each method
/// is a 1:1 wrapper of one `eql_v3.*` function; the DB logic (bind + execute)
/// lives here. Zero-sized — the expensive state (pool, cipher) is memoized in
/// process-wide `OnceLock`s the methods reach into.
#[derive(Clone, Copy, Default)]
pub struct Runner;

/// The shared runner — `runner().eq_term(&a)`. Zero-sized, but the pool and
/// cipher it drives are built once and cached, so this is the single entry
/// point property tests use.
pub fn runner() -> Runner {
    Runner
}

impl Runner {
    pub fn new() -> Self {
        Self
    }

    /// `SELECT <expr>` with one jsonb-bound operand, decoded to `O`.
    fn fetch1<T: Bind, O: ScalarOut>(&self, expr: &str, a: &T) -> O {
        let sql = format!("SELECT {expr}");
        runtime().block_on(async {
            sqlx::query_scalar::<_, O>(&sql)
                .bind(a.clone())
                .fetch_one(pool().await)
                .await
                .unwrap_or_else(|e| panic!("{sql} failed: {e}"))
        })
    }

    /// `eql_v3.eq_term(<dom>)` — the `hm` equality term. `eql_v3.hmac_256` is a
    /// domain over `text` (`(VALUE->>'hm')::eql_v3.hmac_256`), so the term
    /// comes back as its hex string verbatim.
    pub fn eq_term<T: EqTerm>(&self, a: &T) -> Hmac256 {
        let dom = a.sql_domain();
        Hmac256::from(self.fetch1::<T, String>(&format!("eql_v3.eq_term($1::{dom})"), a))
    }

    /// `eql_v3.ord_term(<dom>)` — the `ob` order term. The result is a
    /// composite of `(bytes bytea)` blocks, so we re-render each block as hex
    /// (lower-case, like the stored `ob`) to reconstruct the array.
    pub fn ord_term<T: OrdTerm>(&self, a: &T) -> OreBlockU64_8_256 {
        let dom = a.sql_domain();
        // `unnest` of a `(bytes bytea)[]` in FROM expands the single-field
        // composite to its column, so each row `t` is already the `bytea` (no
        // `(t).bytes`). Re-encode lower-case hex to match the stored `ob`.
        let blocks: Vec<String> = self.fetch1(
            &format!(
                "array(SELECT encode(t, 'hex') \
                 FROM unnest((eql_v3.ord_term($1::{dom})).terms) WITH ORDINALITY AS u(t, n) \
                 ORDER BY n)"
            ),
            a,
        );
        OreBlockU64_8_256::from(blocks)
    }

    /// `SELECT eql_v3.<func>(<a>, <b>)`. The operand types pick the overload
    /// (`&T` casts to the domain, `Jsonb(&T)` stays bare jsonb); both payloads
    /// bind as jsonb.
    fn cmp<L: Operand, R: Operand>(&self, func: &str, a: L, b: R) -> bool {
        let sql = format!(
            "SELECT eql_v3.{func}({}, {})",
            a.render("$1"),
            b.render("$2")
        );
        runtime().block_on(async {
            sqlx::query_scalar::<_, bool>(&sql)
                .bind(a.payload())
                .bind(b.payload())
                .fetch_one(pool().await)
                .await
                .unwrap_or_else(|e| panic!("eql_v3.{func} double failed: {e}"))
        })
    }

    /// `eql_v3.eq` double. Both operands must wrap the same `Comparable` domain.
    pub fn eq<L, R>(&self, a: L, b: R) -> bool
    where
        L: Operand,
        R: Operand<Payload = L::Payload>,
        L::Payload: Comparable,
    {
        self.cmp("eq", a, b)
    }
    /// `eql_v3.neq` double.
    pub fn neq<L, R>(&self, a: L, b: R) -> bool
    where
        L: Operand,
        R: Operand<Payload = L::Payload>,
        L::Payload: Comparable,
    {
        self.cmp("neq", a, b)
    }
    /// `eql_v3.lt` double.
    pub fn lt<L, R>(&self, a: L, b: R) -> bool
    where
        L: Operand,
        R: Operand<Payload = L::Payload>,
        L::Payload: Ordered,
    {
        self.cmp("lt", a, b)
    }
    /// `eql_v3.lte` double.
    pub fn lte<L, R>(&self, a: L, b: R) -> bool
    where
        L: Operand,
        R: Operand<Payload = L::Payload>,
        L::Payload: Ordered,
    {
        self.cmp("lte", a, b)
    }
    /// `eql_v3.gt` double.
    pub fn gt<L, R>(&self, a: L, b: R) -> bool
    where
        L: Operand,
        R: Operand<Payload = L::Payload>,
        L::Payload: Ordered,
    {
        self.cmp("gt", a, b)
    }
    /// `eql_v3.gte` double.
    pub fn gte<L, R>(&self, a: L, b: R) -> bool
    where
        L: Operand,
        R: Operand<Payload = L::Payload>,
        L::Payload: Ordered,
    {
        self.cmp("gte", a, b)
    }
}

// --- The spec macros: one line per generated SQL function ---------------------
//
// A domain's property tests read as a 1:1 specification of its generated SQL
// surface — one macro invocation per `eql_v3.*` function, the operand types
// spelled out so each comparison overload is explicit:
//
//     mod int4_ord {
//         use super::*;
//         ord_term!(Int4Ord);                 // eql_v3.ord_term(int4_ord)
//         lt!(Int4Ord, Int4Ord);              // eql_v3.lt(int4_ord, int4_ord)
//         lt!(Int4Ord, Jsonb<Int4Ord>);       // eql_v3.lt(int4_ord, jsonb)
//         lt!(Jsonb<Int4Ord>, Int4Ord);       // eql_v3.lt(jsonb, int4_ord)
//         // …neq!, lte!, gt!, gte! likewise
//     }
//
// Each macro expands to one `quickcheck`-backed `#[test]` (we can't nest these
// inside upstream `quickcheck! { … }` — its grammar only matches `fn` items, and
// it receives our macro calls un-expanded — so each macro carries its own
// `quickcheck!`). The generated test is named for the overload it covers
// (`lt_dom_dom` / `lt_dom_json` / `lt_json_dom`), so a failure names the exact
// function + overload that disagreed and prints the generating plaintext.
//
// The comparison macros generate the property over `<Domain as
// EncryptableScalar>::Plaintext` (bounded `Arbitrary`), so quickcheck supplies
// the plaintext pair, the body encrypts both and the plaintexts *are* the oracle
// (`a $op b`). The extractor macros take a whole `Arbitrary` domain value and
// assert the SQL-extracted term equals the one carried in the payload.

/// `eql_v3.eq_term(<dom>)` — assert the SQL-extracted `hm` equals the term in
/// the (randomly encrypted) payload. Unary: `eq_term!(Int4Eq)`.
#[cfg(test)]
macro_rules! eq_term {
    ($t:ident) => {
        ::quickcheck::quickcheck! {
            fn eq_term(a: $t) -> () {
                ::core::assert_eq!(
                    $crate::v3::proptest_support::runner().eq_term(&a),
                    a.hm,
                    "eql_v3.eq_term({})",
                    <$t as $crate::v3::DomainType>::sql_domain_static(),
                );
            }
        }
    };
}
#[cfg(test)]
pub(crate) use eq_term;

/// `eql_v3.ord_term(<dom>)` — assert the SQL-extracted `ob` equals the term in
/// the payload. Unary: `ord_term!(Int4Ord)`.
#[cfg(test)]
macro_rules! ord_term {
    ($t:ident) => {
        ::quickcheck::quickcheck! {
            fn ord_term(a: $t) -> () {
                ::core::assert_eq!(
                    $crate::v3::proptest_support::runner().ord_term(&a),
                    a.ob,
                    "eql_v3.ord_term({})",
                    <$t as $crate::v3::DomainType>::sql_domain_static(),
                );
            }
        }
    };
}
#[cfg(test)]
pub(crate) use ord_term;

/// One comparison-overload property: encrypt a plaintext pair, run the chosen
/// `eql_v3.<func>` overload, assert it agrees with `a <oracle> b`. Internal —
/// the per-operator macros (`eq!`/`lt!`/…) supply `$func` + `$oracle`; the
/// operand forms (`$dom` vs `Jsonb<$dom>`) pick which of the three overloads.
#[cfg(test)]
macro_rules! cmp_overload {
    // (domain, domain)
    ($func:ident, $oracle:tt, $l:ident, $r:ident) => {
        ::paste::paste! {
            ::quickcheck::quickcheck! {
                fn [< $func _ dom _ dom >](
                    a: <$l as $crate::v3::proptest_support::EncryptableScalar>::Plaintext,
                    b: <$r as $crate::v3::proptest_support::EncryptableScalar>::Plaintext
                ) -> () {
                    let expected = a $oracle b;
                    let l = <$l as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(a);
                    let r = <$r as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(b);
                    ::core::assert_eq!(
                        $crate::v3::proptest_support::runner().$func(&l, &r),
                        expected,
                        "eql_v3.{}({}, {})",
                        ::core::stringify!($func),
                        <$l as $crate::v3::DomainType>::sql_domain_static(),
                        <$r as $crate::v3::DomainType>::sql_domain_static(),
                    );
                }
            }
        }
    };
    // (domain, jsonb)
    ($func:ident, $oracle:tt, $l:ident, Jsonb<$r:ident>) => {
        ::paste::paste! {
            ::quickcheck::quickcheck! {
                fn [< $func _ dom _ json >](
                    a: <$l as $crate::v3::proptest_support::EncryptableScalar>::Plaintext,
                    b: <$r as $crate::v3::proptest_support::EncryptableScalar>::Plaintext
                ) -> () {
                    let expected = a $oracle b;
                    let l = <$l as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(a);
                    let r = <$r as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(b);
                    ::core::assert_eq!(
                        $crate::v3::proptest_support::runner()
                            .$func(&l, $crate::v3::proptest_support::Jsonb(&r)),
                        expected,
                        "eql_v3.{}({}, jsonb)",
                        ::core::stringify!($func),
                        <$l as $crate::v3::DomainType>::sql_domain_static(),
                    );
                }
            }
        }
    };
    // (jsonb, domain)
    ($func:ident, $oracle:tt, Jsonb<$l:ident>, $r:ident) => {
        ::paste::paste! {
            ::quickcheck::quickcheck! {
                fn [< $func _ json _ dom >](
                    a: <$l as $crate::v3::proptest_support::EncryptableScalar>::Plaintext,
                    b: <$r as $crate::v3::proptest_support::EncryptableScalar>::Plaintext
                ) -> () {
                    let expected = a $oracle b;
                    let l = <$l as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(a);
                    let r = <$r as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(b);
                    ::core::assert_eq!(
                        $crate::v3::proptest_support::runner()
                            .$func($crate::v3::proptest_support::Jsonb(&l), &r),
                        expected,
                        "eql_v3.{}(jsonb, {})",
                        ::core::stringify!($func),
                        <$r as $crate::v3::DomainType>::sql_domain_static(),
                    );
                }
            }
        }
    };
}
#[cfg(test)]
pub(crate) use cmp_overload;

// The per-operator spec macros. Each takes one overload's operand forms — a bare
// `Domain` (cast to its `eql_v3.*` domain) or `Jsonb<Domain>` (bound as raw
// jsonb) — e.g. `eq!(Int4Eq, Int4Eq)`, `eq!(Int4Eq, Jsonb<Int4Eq>)`,
// `eq!(Jsonb<Int4Eq>, Int4Eq)`, and forwards them to `cmp_overload!` with the
// SQL function name + plaintext oracle operator. The operand forms select the
// overload; the capability bound on the `Runner` method (`Comparable` for
// eq/neq, `Ordered` for lt/lte/gt/gte) compile-checks that the domain actually
// generates the operator.
//
// One macro per operator (rather than generating them from a macro) because a
// `macro_rules!` that defines a `macro_rules!` with its own metavariables needs
// the unstable `$$` expansion; the bodies are one forwarding line each.
#[cfg(test)]
macro_rules! eq {
    ($($operands:tt)*) => {
        $crate::v3::proptest_support::cmp_overload!(eq, ==, $($operands)*);
    };
}
#[cfg(test)]
pub(crate) use eq;

#[cfg(test)]
macro_rules! neq {
    ($($operands:tt)*) => {
        $crate::v3::proptest_support::cmp_overload!(neq, !=, $($operands)*);
    };
}
#[cfg(test)]
pub(crate) use neq;

#[cfg(test)]
macro_rules! lt {
    ($($operands:tt)*) => {
        $crate::v3::proptest_support::cmp_overload!(lt, <, $($operands)*);
    };
}
#[cfg(test)]
pub(crate) use lt;

#[cfg(test)]
macro_rules! lte {
    ($($operands:tt)*) => {
        $crate::v3::proptest_support::cmp_overload!(lte, <=, $($operands)*);
    };
}
#[cfg(test)]
pub(crate) use lte;

#[cfg(test)]
macro_rules! gt {
    ($($operands:tt)*) => {
        $crate::v3::proptest_support::cmp_overload!(gt, >, $($operands)*);
    };
}
#[cfg(test)]
pub(crate) use gt;

#[cfg(test)]
macro_rules! gte {
    ($($operands:tt)*) => {
        $crate::v3::proptest_support::cmp_overload!(gte, >=, $($operands)*);
    };
}
#[cfg(test)]
pub(crate) use gte;

/// Generate the proptest wiring for an `_eq`-shaped domain (`v`/`i`/`c`/`hm`):
/// the v2→v3 `From<&EncryptedPayload>` conversion, [`EncryptableScalar`],
/// `quickcheck::Arbitrary`, and the [`EqTerm`] + [`Comparable`] capability
/// markers. `$pt` is the scalar's plaintext Rust type (`i32`, `i64`, …). Mirrors
/// `eql-scalars`'s shared `_eq` domain shape, so every scalar family reuses it.
#[cfg(test)]
macro_rules! impl_eq_domain {
    ($t:ident, $pt:ty) => {
        impl ::core::convert::From<&::cipherstash_client::eql::EncryptedPayload> for $t {
            fn from(payload: &::cipherstash_client::eql::EncryptedPayload) -> Self {
                $t {
                    v: $crate::SchemaVersion::CURRENT,
                    i: $crate::v3::proptest_support::identifier(),
                    c: $crate::v3::terms::Ciphertext::from(
                        $crate::v3::proptest_support::ciphertext_b85(payload),
                    ),
                    hm: $crate::v3::terms::Hmac256::from(
                        payload
                            .hmac_256
                            .clone()
                            .expect(concat!(stringify!($t), " payload is missing the `hm` term")),
                    ),
                }
            }
        }
        impl $crate::v3::proptest_support::EncryptableScalar for $t {
            type Plaintext = $pt;
            fn encrypt_value(plaintext: $pt) -> Self {
                <$t>::from(&$crate::v3::proptest_support::encrypt(
                    plaintext,
                    $crate::v3::proptest_support::TermKind::Hm,
                ))
            }
        }
        impl ::quickcheck::Arbitrary for $t {
            fn arbitrary(g: &mut ::quickcheck::Gen) -> Self {
                <$t as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(
                    <$pt as ::quickcheck::Arbitrary>::arbitrary(g),
                )
            }
        }
        impl $crate::v3::proptest_support::EqTerm for $t {}
        impl $crate::v3::proptest_support::Comparable for $t {}
    };
}
#[cfg(test)]
pub(crate) use impl_eq_domain;

/// Generate the proptest wiring for an `_ord`/`_ord_ore`-shaped domain
/// (`v`/`i`/`c`/`ob`): the v2→v3 conversion, [`EncryptableScalar`], `Arbitrary`,
/// and the [`OrdTerm`] + [`Comparable`] + [`Ordered`] markers.
#[cfg(test)]
macro_rules! impl_ord_domain {
    ($t:ident, $pt:ty) => {
        impl ::core::convert::From<&::cipherstash_client::eql::EncryptedPayload> for $t {
            fn from(payload: &::cipherstash_client::eql::EncryptedPayload) -> Self {
                $t {
                    v: $crate::SchemaVersion::CURRENT,
                    i: $crate::v3::proptest_support::identifier(),
                    c: $crate::v3::terms::Ciphertext::from(
                        $crate::v3::proptest_support::ciphertext_b85(payload),
                    ),
                    ob: $crate::v3::terms::OreBlockU64_8_256::from(
                        payload
                            .ore_block_u64_8_256
                            .clone()
                            .expect(concat!(stringify!($t), " payload is missing the `ob` term")),
                    ),
                }
            }
        }
        impl $crate::v3::proptest_support::EncryptableScalar for $t {
            type Plaintext = $pt;
            fn encrypt_value(plaintext: $pt) -> Self {
                <$t>::from(&$crate::v3::proptest_support::encrypt(
                    plaintext,
                    $crate::v3::proptest_support::TermKind::Ore,
                ))
            }
        }
        impl ::quickcheck::Arbitrary for $t {
            fn arbitrary(g: &mut ::quickcheck::Gen) -> Self {
                <$t as $crate::v3::proptest_support::EncryptableScalar>::encrypt_value(
                    <$pt as ::quickcheck::Arbitrary>::arbitrary(g),
                )
            }
        }
        impl $crate::v3::proptest_support::OrdTerm for $t {}
        impl $crate::v3::proptest_support::Comparable for $t {}
        impl $crate::v3::proptest_support::Ordered for $t {}
    };
}
#[cfg(test)]
pub(crate) use impl_ord_domain;
