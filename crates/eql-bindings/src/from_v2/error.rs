//! The `from_v2` error enum — hand-rolled `Display`/`Error` (this crate's
//! dependency set is pinned to serde/serde_json/ts-rs/schemars, so no
//! thiserror).

use std::error::Error;
use std::fmt;

/// Why a v2 → v3 conversion was refused. Every variant is fail-closed: the
/// converter never emits a v3 payload it could not validate.
#[derive(Debug)]
pub enum FromV2Error {
    /// The input's envelope version (`v`) is not the v2 wire version `2` —
    /// `found: Some(3)` for an already-converted v3 payload, `None` when `v`
    /// is absent or not an integer (e.g. plaintext JSON).
    UnsupportedVersion {
        /// The integer `v` the input carried, if any.
        found: Option<u64>,
    },
    /// The input's kind discriminator (`k`) is neither `"ct"` nor `"sv"`
    /// (`found: None` when `k` is absent or not a string).
    UnknownKind {
        /// The `k` string the input carried, if any.
        found: Option<String>,
    },
    /// [`TargetDomain::parse`](super::TargetDomain::parse) did not find the
    /// name in the catalog-generated inventory (or it names a SteVec shape —
    /// `jsonb_entry` / `query_json` — that is not a conversion target).
    UnknownDomain {
        /// The name that failed to resolve.
        name: String,
    },
    /// A term key the target domain requires is absent from the input. For
    /// SteVec entries `key` is `"hm|op"`: an entry must carry exactly one of
    /// the two, and this variant reports the "neither" half (the "both" half
    /// is [`FromV2Error::AmbiguousTerm`]) with `entry` locating the offender.
    MissingTerm {
        /// The (unqualified) target domain name, e.g. `text_eq`, or the
        /// SteVec shape (`json` / `query_json`) for per-entry terms.
        domain: String,
        /// The missing wire key (`hm`/`ob`/`bf`/`op`, or `hm|op` for entries).
        key: String,
        /// Zero-based index of the term-less `sv` entry; `None` for flat
        /// scalar payloads, which have no entries to index.
        entry: Option<usize>,
    },
    /// A SteVec entry carries BOTH `hm` and `op`; the v2 and v3 contracts
    /// both require exactly one, and picking one would silently drop a term.
    AmbiguousTerm {
        /// Zero-based index of the offending `sv` entry.
        entry: usize,
    },
    /// A SteVec entry carries a CLLW-ORE ordering term (`oc`), which v3
    /// cannot represent: v3 orders SteVec entries by the CLLW-OPE `op` term
    /// (native byte order), and CLLW-ORE ciphertext bytes do not order under
    /// byte comparison — passing them through would silently misorder. An
    /// `oc`-bearing v2 document must be re-encrypted through a client that
    /// emits OPE SteVec terms; no mechanical conversion exists.
    UnconvertibleOreTerm {
        /// Zero-based index of the offending `sv` entry.
        entry: usize,
    },
    /// A v2 SteVec **document** has no v3 representation: the v3 envelope
    /// wire format stores one key header (`h`) per document with per-entry
    /// ciphertexts encrypted under selector-derived nonces, none of which can
    /// be derived from a v2 payload by JSON transformation — that is
    /// re-encryption. Encrypt the document through a v3-emitting client
    /// (`encrypt_eql_v3`).
    UnconvertibleSteVecDocument,
    /// A v2 SteVec query entry carries a per-entry `hm` equality term, which
    /// v3 cannot represent: v3 exact matching is value-inclusive **selector
    /// presence**, and the value selector cannot be derived from an HMAC
    /// term. Produce the needle through a v3-emitting client.
    UnconvertibleEqualityTerm {
        /// Zero-based index of the offending `sv` entry.
        entry: usize,
    },
    /// The input's kind contradicts the target: an `sv` payload for a scalar
    /// target, or a `ct` payload for [`TargetDomain::Json`](super::TargetDomain::Json).
    KindMismatch {
        /// The input's `k` discriminator (`ct` or `sv`).
        kind: String,
        /// The requested target (a domain name, or `json`).
        target: String,
    },
    /// A `bf` element is outside both the signed `i16` range and the unsigned
    /// upper half (`32768..=65535`) that reinterprets into it — it cannot be
    /// a PostgreSQL `smallint[]` bit position.
    BloomOutOfRange {
        /// Zero-based index of the offending `bf` element.
        index: usize,
        /// The out-of-range element value.
        value: i64,
    },
    /// [`from_v2_query`](super::from_v2_query) was asked for a scalar target,
    /// but no v3 scalar query wire shape exists (every scalar domain CHECK
    /// requires the ciphertext `c` a query payload omits). Scalar query
    /// conversion is pending the mapper redesign; this crate will not invent
    /// a wire shape ahead of it.
    UnsupportedQueryTarget {
        /// The (unqualified) scalar domain name that was requested.
        domain: String,
    },
    /// The converted payload failed the final strict parse through the target
    /// domain's binding struct (`deny_unknown_fields` + `SchemaVersion`), or
    /// the input was structurally malformed (e.g. a non-array `sv` or `bf`).
    Invalid(serde_json::Error),
}

impl fmt::Display for FromV2Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::UnsupportedVersion { found: Some(v) } => {
                write!(f, "unsupported EQL payload version {v} (expected 2)")
            }
            Self::UnsupportedVersion { found: None } => {
                write!(
                    f,
                    "input carries no integer EQL version key `v` (expected 2)"
                )
            }
            Self::UnknownKind { found: Some(k) } => {
                write!(
                    f,
                    "unknown EQL payload kind {k:?} (expected \"ct\" or \"sv\")"
                )
            }
            Self::UnknownKind { found: None } => {
                write!(
                    f,
                    "input carries no kind key `k` (expected \"ct\" or \"sv\")"
                )
            }
            Self::UnknownDomain { name } => {
                write!(f, "unknown target domain {name:?}")
            }
            Self::MissingTerm {
                domain,
                key,
                entry: Some(entry),
            } => {
                write!(
                    f,
                    "sv entry {entry} carries no term key `{key}` required by `{domain}`"
                )
            }
            Self::MissingTerm {
                domain,
                key,
                entry: None,
            } => {
                write!(f, "target domain `{domain}` requires term key `{key}`, absent from the v2 payload")
            }
            Self::AmbiguousTerm { entry } => {
                write!(
                    f,
                    "sv entry {entry} carries both `hm` and `op` (exactly one is required)"
                )
            }
            Self::UnconvertibleOreTerm { entry } => {
                write!(
                    f,
                    "sv entry {entry} carries a CLLW-ORE ordering term `oc`; v3 orders SteVec \
                     entries by the CLLW-OPE `op` term, and ORE ciphertext bytes cannot be \
                     converted — re-encrypt through a client that emits OPE SteVec terms"
                )
            }
            Self::UnconvertibleSteVecDocument => {
                write!(
                    f,
                    "a v2 SteVec document cannot be converted to the v3 envelope wire format \
                     (per-document key header + selector-derived entry nonces) — that is \
                     re-encryption, not a JSON transformation; encrypt through encrypt_eql_v3"
                )
            }
            Self::UnconvertibleEqualityTerm { entry } => {
                write!(
                    f,
                    "sv query entry {entry} carries a per-entry `hm` equality term; v3 exact \
                     matching is value-inclusive selector presence, which cannot be derived \
                     from an HMAC term — produce the needle through a v3-emitting client"
                )
            }
            Self::KindMismatch { kind, target } => {
                write!(
                    f,
                    "v2 payload kind `{kind}` cannot convert to target `{target}`"
                )
            }
            Self::BloomOutOfRange { index, value } => {
                write!(
                    f,
                    "bf element {index} ({value}) is outside the smallint bit-position range"
                )
            }
            Self::UnsupportedQueryTarget { domain } => {
                write!(
                    f,
                    "no v3 scalar query wire shape exists for `{domain}` (pending the mapper redesign)"
                )
            }
            Self::Invalid(e) => {
                write!(f, "converted payload failed v3 validation: {e}")
            }
        }
    }
}

impl Error for FromV2Error {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Invalid(e) => Some(e),
            _ => None,
        }
    }
}
