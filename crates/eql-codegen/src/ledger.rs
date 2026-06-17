//! Ledger normalizer — turn a captured logging-Postgres raw log into a
//! deterministic, per-statement ledger keyed on the inline /* eqlmatrix:… */
//! tag (Stage 2 of the matrix log-verification design). No judgement happens
//! here; this is the Stage 4 matcher's input, reusable unchanged.
//!
//! The producer behind `eql-codegen -- ledger <raw-log> <out-json>`. The record
//! shape and the canonical normalized-statement form (the §9 "match contract")
//! are frozen here so the Stage 4 manifest can be normalized identically and
//! compared by exact string equality.

use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::path::Path;

use flate2::read::GzDecoder;
use serde::Serialize;

/// The outcome of a logged statement — a typed enum, not a stringly `outcome` +
/// separate `error_message` pair, so the two illegal states (success carrying a
/// message; error carrying no message) are unrepresentable. Mirrors the
/// project's `Role` enum precedent in `crates/eql-scalars/src/lib.rs:95-130`
/// (introduced so "a typo can no longer silently disable" behaviour).
///
/// Serde shape: `#[serde(tag = "outcome", rename_all = "lowercase")]` renders
///   Success      → `{"outcome":"success"}`
///   Error { msg } → `{"outcome":"error","error_message":"<msg>"}`
/// which, when `#[serde(flatten)]`ed into `LedgerRecord`, yields the flat
/// record shape the Stage 4 matcher consumes (the `error_message` key is
/// present iff `outcome == "error"`).
#[derive(Serialize, Debug, PartialEq, Clone)]
#[serde(tag = "outcome", rename_all = "lowercase")]
pub enum Outcome {
    Success,
    Error { error_message: String },
}

/// One normalized statement from the captured log.
#[derive(Serialize, Debug, PartialEq)]
pub struct LedgerRecord {
    /// The inline tag value (`""` when the statement was untagged).
    pub case_id: String,
    /// 0-based position in log order — stable ordering for the matcher.
    pub seq: usize,
    /// Canonical §9 form: tag stripped, keywords lowercased, literals/params
    /// replaced with `$`, ephemeral DB names stripped, whitespace collapsed.
    pub normalized_statement: String,
    /// The auto_explain JSON plan attached to this statement, if any.
    pub plan: Option<serde_json::Value>,
    /// Success, or Error with its message. Flattened so `outcome` and (for
    /// errors) `error_message` appear as top-level keys of the record.
    #[serde(flatten)]
    pub outcome: Outcome,
}

#[derive(Serialize, Debug)]
pub struct Ledger {
    pub records: Vec<LedgerRecord>,
}

/// Extract the `case_id` from a statement carrying `/* eqlmatrix:<id> */`.
/// Returns `""` when no tag is present.
///
/// NOTE: the delimiter byte strings below are a manual byte-identical copy of
/// `eqlmatrix::{TAG_OPEN, TAG_CLOSE}` in `tests/sqlx/src/eqlmatrix.rs` (the
/// producer) and of the same consts in `strip_eqlmatrix_comment` below — three
/// independent copies across two non-dependent crates. There is no shared
/// source; keeping them identical is a manual obligation. The fixture-driven
/// parser test (Step 6) catches a drift across the producer/consumer boundary.
pub fn extract_case_id(statement: &str) -> &str {
    const OPEN: &str = "/* eqlmatrix:";
    const CLOSE: &str = " */";
    if let Some(start) = statement.find(OPEN) {
        let rest = &statement[start + OPEN.len()..];
        if let Some(end) = rest.find(CLOSE) {
            return &rest[..end];
        }
    }
    ""
}

/// The §9 match-contract canonical normalization. MUST stay byte-identical to
/// the manifest-side normalization the Stage 4 generator will apply, since
/// "matched" is exact string equality after this function.
///
/// Steps, in order:
///  1. strip the leading `/* eqlmatrix:… */` comment,
///  2. strip ephemeral sqlx DB names (`_sqlx_test_<n>` style identifiers),
///  3. replace quoted string/number literals and `$N` params with `$`,
///  4. lowercase ASCII (keywords + identifiers; identifiers are
///     case-insensitive in Postgres unless quoted, which we don't emit),
///  5. collapse all whitespace runs to single spaces and trim.
pub fn normalize_statement(statement: &str) -> String {
    // 1. strip the eqlmatrix comment (anywhere; it is always leading in
    //    practice, but find/replace the whole comment to be safe).
    let mut s = strip_eqlmatrix_comment(statement);

    // 2. strip ephemeral DB names: sqlx test databases are named like
    //    `_sqlx_test_<hex>`; collapse any such identifier to a fixed token so
    //    run-to-run DB names do not defeat equality.
    s = strip_ephemeral_db_names(&s);

    // 3. replace literals + params with `$`.
    s = replace_literals(&s);

    // 4. lowercase.
    s = s.to_ascii_lowercase();

    // 5. collapse whitespace.
    s.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn strip_eqlmatrix_comment(s: &str) -> String {
    const OPEN: &str = "/* eqlmatrix:";
    const CLOSE: &str = " */";
    if let Some(start) = s.find(OPEN) {
        if let Some(rel_end) = s[start..].find(CLOSE) {
            let end = start + rel_end + CLOSE.len();
            let mut out = String::with_capacity(s.len());
            out.push_str(&s[..start]);
            out.push_str(&s[end..]);
            return out;
        }
    }
    s.to_string()
}

fn strip_ephemeral_db_names(s: &str) -> String {
    // Replace `_sqlx_test_<alnum>` identifiers with `_sqlx_test`. Operate over
    // `char_indices` (NOT `bytes[i] as char`, which mangles any non-ASCII byte
    // by reinterpreting a UTF-8 continuation byte as a `char`) — uniform with
    // `replace_literals`, which already walks `chars`.
    let mut out = String::with_capacity(s.len());
    let needle = "_sqlx_test_";
    let mut chars = s.char_indices().peekable();
    while let Some(&(i, _)) = chars.peek() {
        if s[i..].starts_with(needle) {
            out.push_str("_sqlx_test");
            // advance past the needle.
            for _ in 0..needle.chars().count() {
                chars.next();
            }
            // consume the trailing identifier chars (ascii alnum or `_`).
            while let Some(&(_, c)) = chars.peek() {
                if c.is_ascii_alphanumeric() || c == '_' {
                    chars.next();
                } else {
                    break;
                }
            }
        } else {
            // SAFETY of correctness: push the whole char, not a byte.
            let (_, c) = chars.next().unwrap();
            out.push(c);
        }
    }
    out
}

fn replace_literals(s: &str) -> String {
    // Replace single-quoted strings, then numeric literals, then `$N` params
    // with a single `$` token. Deliberately simple and deterministic; the
    // matrix statements are hardcoded shapes, not arbitrary SQL.
    let mut out = String::with_capacity(s.len());
    let chars: Vec<char> = s.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        if c == '\'' {
            // consume a single-quoted string (handle '' escapes).
            i += 1;
            while i < chars.len() {
                if chars[i] == '\'' {
                    if i + 1 < chars.len() && chars[i + 1] == '\'' {
                        i += 2;
                        continue;
                    }
                    i += 1;
                    break;
                }
                i += 1;
            }
            out.push('$');
        } else if c == '$' && i + 1 < chars.len() && chars[i + 1].is_ascii_digit() {
            // `$N` bind param.
            i += 1;
            while i < chars.len() && chars[i].is_ascii_digit() {
                i += 1;
            }
            out.push('$');
        } else if c.is_ascii_digit()
            && (i == 0 || !chars[i - 1].is_ascii_alphanumeric() && chars[i - 1] != '_')
        {
            // a standalone numeric literal (not part of an identifier like
            // `int4` or `ord_term`).
            while i < chars.len() && (chars[i].is_ascii_digit() || chars[i] == '.') {
                i += 1;
            }
            out.push('$');
        } else {
            out.push(c);
            i += 1;
        }
    }
    out
}

/// One classified log line. Keeping classification separate from the record-
/// building loop (mirroring how `normalize_statement` is split into small
/// single-purpose helpers) makes each piece independently unit-testable.
enum LineKind<'a> {
    /// `LOG: statement:` — begins a statement record. Carries the post-marker text.
    Statement(&'a str),
    /// `LOG: duration: … plan:` — introduces an auto_explain JSON plan block.
    PlanIntro,
    /// `ERROR:` — carries the post-marker message text.
    Error(&'a str),
    /// `STATEMENT:` — the tag-bearing echo that follows an `ERROR:`.
    StatementEcho(&'a str),
    /// Anything else (continuation, blank, unrelated LOG).
    Other,
}

/// Classify a single log line by its marker. Order matters: `statement:` is
/// matched before generic `LOG:`. `STATEMENT:` (the error echo) is distinct from
/// `statement:` (the executed-statement log) — Postgres uppercases the former.
fn classify_line(line: &str) -> LineKind<'_> {
    if let Some(rest) = after_marker(line, "STATEMENT:") {
        LineKind::StatementEcho(rest)
    } else if let Some(rest) = after_marker(line, "statement:") {
        LineKind::Statement(rest)
    } else if line.contains("plan:") && line.contains("duration:") {
        LineKind::PlanIntro
    } else if let Some(rest) = after_marker(line, "ERROR:") {
        LineKind::Error(rest)
    } else {
        LineKind::Other
    }
}

/// Build a fresh success record from a gathered statement text.
fn build_statement_record(text: &str, seq: usize) -> LedgerRecord {
    LedgerRecord {
        case_id: extract_case_id(text).to_string(),
        seq,
        normalized_statement: normalize_statement(text),
        plan: None,
        outcome: Outcome::Success,
    }
}

/// Normalize a parsed plan JSON to the inner plan **object**, defensively
/// accepting BOTH container shapes:
///   - a bare object `{ "Query Text": …, "Plan": … }` — auto_explain's
///     `log_format=json` per-statement shape (the shape observed in the real
///     capture fixture), and
///   - a single-element array `[ { "Query Text": …, "Plan": … } ]` — the shape
///     bare `EXPLAIN (FORMAT JSON)` returns (the repo's own `explain_json`
///     helper documents "PostgreSQL returns a single-element JSON array" and
///     indexes it `plan[0]["Plan"]…`). auto_explain *usually* emits the bare
///     object, but PG-version / config variation (and the in-process tagged
///     `EXPLAIN` echo) can surface the array form, so we unwrap a length-1 array
///     rather than silently failing `.get("Query Text")` on an `Array` (which
///     returns `None`, mis-attributing the plan to case_id `""`).
fn plan_object(plan: serde_json::Value) -> serde_json::Value {
    match plan {
        serde_json::Value::Array(mut arr) if arr.len() == 1 => arr.remove(0),
        other => other,
    }
}

/// Attach a parsed plan to the most recent plan-less record with the same
/// case_id, or push a fresh plan-only record. The `.rev().find(case_id)` bind is
/// what makes plan attachment correct under interleaved backends: two cases'
/// lines can interleave in the shared log, so we match on the tag, not position.
/// The plan is first unwrapped via `plan_object` so a single-element-array
/// `[ {…} ]` container (bare EXPLAIN shape) is handled identically to the bare
/// object auto_explain usually emits.
fn attach_plan(records: &mut Vec<LedgerRecord>, seq: &mut usize, plan: serde_json::Value) {
    let plan = plan_object(plan);
    let case_id = plan
        .get("Query Text")
        .and_then(|v| v.as_str())
        .map(extract_case_id)
        .unwrap_or("")
        .to_string();
    if let Some(rec) = records
        .iter_mut()
        .rev()
        .find(|r| r.case_id == case_id && r.plan.is_none())
    {
        rec.plan = Some(plan);
    } else {
        let normalized = plan
            .get("Query Text")
            .and_then(|v| v.as_str())
            .map(normalize_statement)
            .unwrap_or_default();
        records.push(LedgerRecord {
            case_id,
            seq: *seq,
            normalized_statement: normalized,
            plan: Some(plan),
            outcome: Outcome::Success,
        });
        *seq += 1;
    }
}

/// Attach an error to the most recent record for `case_id`, or push an
/// error-only record. Again keyed on the tag, not on PID/position — correct
/// under interleaving.
fn attach_error(records: &mut Vec<LedgerRecord>, seq: &mut usize, case_id: &str, message: String) {
    if let Some(rec) = records.iter_mut().rev().find(|r| r.case_id == case_id) {
        rec.outcome = Outcome::Error {
            error_message: message,
        };
    } else {
        records.push(LedgerRecord {
            case_id: case_id.to_string(),
            seq: *seq,
            normalized_statement: String::new(),
            plan: None,
            outcome: Outcome::Error {
                error_message: message,
            },
        });
        *seq += 1;
    }
}

/// Parse a captured logging-Postgres raw log into a `Ledger`.
///
/// Strategy (no PID grouping — the inline tag is the key):
///  - A `LOG:  statement:` line begins a record; its tag is the case_id and the
///    rest of the line (plus any continuation) is the statement text.
///  - A `duration: … plan:` block introduces an auto_explain JSON plan; the
///    plan's "Query Text" carries the same tag, so we attach the parsed JSON to
///    the most recent record with that case_id (or to a fresh plan-only record
///    if the matching statement was logged via auto_explain only).
///  - An `ERROR:` line records the message; the following `STATEMENT:` line
///    carries the tag, so the error is attached to that case_id. %p/%x only
///    assist *local* adjacency when two records share a case_id in one tx.
///
/// EMPIRICAL NOTE (sqlx extended protocol): the scalar matrix issues its load-
/// bearing statements via prepared statements, so they are logged as
/// `LOG:  execute sqlx_s_N: /* eqlmatrix:… */ …` (NOT `LOG:  statement:`) — the
/// real captured fixture has zero tagged `statement:` lines. Successful tagged
/// statements are therefore recorded via their `auto_explain` plan block (the
/// plan's "Query Text" carries the tag → `attach_plan`); blocker statements,
/// which raise, are recorded via the `ERROR:` + `STATEMENT:` pair. The
/// `statement:` arm still handles any simple-protocol statements that appear.
///
/// Records are emitted in first-seen log order with a 0-based `seq`. Note: a
/// tagged blocker statement with NO following `ERROR:` line stays
/// `Outcome::Success` — that is intentional, so the Stage 4 matcher can flag the
/// STRICT-NULL regression (a blocker that should have raised but did not).
///
/// In-memory entry point: splits the whole log and runs the state machine over
/// it. Routes through `parse_ledger_reader` so the in-crate tests (which feed a
/// `&str` via `include_str!`) exercise the exact streaming path the CLI uses.
pub fn parse_ledger(raw_log: &str) -> Ledger {
    parse_ledger_reader(io::Cursor::new(raw_log.as_bytes()))
}

/// Streaming entry point: parse the log from any `BufRead` WITHOUT materializing
/// the whole (possibly multi-GB, possibly gzip-decoded) text in memory. Lines are
/// read into a small rolling buffer that holds at most one **region** — a single
/// primary log entry plus its continuation / JSON-plan / error-annotation /
/// `STATEMENT:`-echo tail, terminated at the next primary entry. A region is
/// bounded by the largest single auto_explain plan, never the whole file.
///
/// Each region is handed to `run_lines`, so the record semantics are identical to
/// processing the whole split at once: the only forward look-aheads the state
/// machine performs (a JSON plan block, and an `ERROR:` → `STATEMENT:` echo scan)
/// never cross a region boundary — a plan block contains no primary log line, and
/// an error's annotation/echo tail precedes the next primary entry. Cross-region
/// state (the `records` accumulator that `attach_plan`/`attach_error` scan
/// backward over) is threaded through explicitly.
pub fn parse_ledger_reader<R: BufRead>(reader: R) -> Ledger {
    let mut records: Vec<LedgerRecord> = Vec::new();
    let mut seq = 0usize;
    let mut cursor = RegionCursor::new(reader);
    while let Some(region) = cursor.next_region() {
        let view: Vec<&str> = region.iter().map(String::as_str).collect();
        run_lines(&view, &mut records, &mut seq);
    }
    Ledger { records }
}

/// The core state machine over a contiguous slice of already-split log lines.
/// Extracted from the old `parse_ledger` body verbatim so both the in-memory and
/// streaming entry points share one implementation. Appends to `records` and
/// advances `seq`.
fn run_lines(lines: &[&str], records: &mut Vec<LedgerRecord>, seq: &mut usize) {
    let mut i = 0;
    while i < lines.len() {
        match classify_line(lines[i]) {
            LineKind::Statement(stmt) => {
                let (text, consumed) = gather_continuation(lines, i, stmt);
                i += consumed;
                records.push(build_statement_record(&text, *seq));
                *seq += 1;
            }
            LineKind::PlanIntro => {
                let (json_text, consumed) = gather_json_block(lines, i + 1);
                i += 1 + consumed;
                if let Ok(plan) = serde_json::from_str::<serde_json::Value>(&json_text) {
                    attach_plan(records, seq, plan);
                }
            }
            LineKind::Error(msg) => {
                let (err_text, _consumed) = gather_continuation(lines, i, msg);
                // The STATEMENT: echo that follows carries the tag.
                let case_id = find_following_statement_case_id(lines, i);
                attach_error(records, seq, &case_id, err_text.trim().to_string());
                i += 1;
            }
            LineKind::StatementEcho(_) | LineKind::Other => {
                i += 1;
            }
        }
    }
}

/// True if `line` starts a new primary log entry — a region boundary. A primary
/// entry is log-prefixed (`is_log_prefixed`) AND is neither an error-annotation
/// line (`CONTEXT:`/`DETAIL:`/… belong to the preceding `ERROR:`) nor a
/// `STATEMENT:` echo (which belongs to the preceding `ERROR:`'s region). Anything
/// else — indented continuations, JSON-plan body lines, blanks — is NOT a
/// boundary, so it stays in the current region.
fn is_region_boundary(line: &str) -> bool {
    is_log_prefixed(line)
        && !is_error_annotation(line)
        && !matches!(classify_line(line), LineKind::StatementEcho(_))
}

/// Reads a `BufRead` line-by-line and yields one bounded region per
/// `next_region()` call. The carried-over `front` line (the boundary that ended
/// the previous region) becomes the first line of the next region, so no line is
/// dropped or duplicated across regions.
struct RegionCursor<R: BufRead> {
    reader: R,
    front: Option<String>,
    eof: bool,
}

impl<R: BufRead> RegionCursor<R> {
    fn new(reader: R) -> Self {
        RegionCursor {
            reader,
            front: None,
            eof: false,
        }
    }

    /// Read one line, stripping the trailing newline (matching `str::lines()`).
    /// Returns `None` at EOF or on a read error (treated as EOF).
    fn read_line(&mut self) -> Option<String> {
        if self.eof {
            return None;
        }
        let mut s = String::new();
        match self.reader.read_line(&mut s) {
            Ok(0) => {
                self.eof = true;
                None
            }
            Ok(_) => {
                while s.ends_with('\n') || s.ends_with('\r') {
                    s.pop();
                }
                Some(s)
            }
            Err(_) => {
                self.eof = true;
                None
            }
        }
    }

    /// Yield the next region: its first line (a carried-over boundary, or the
    /// very first line of the log), then every following non-boundary line. The
    /// next boundary is held back in `front` for the following call. Returns
    /// `None` once the log is exhausted.
    fn next_region(&mut self) -> Option<Vec<String>> {
        let first = match self.front.take() {
            Some(l) => l,
            None => self.read_line()?,
        };
        let mut region = vec![first];
        loop {
            match self.read_line() {
                None => break,
                Some(l) => {
                    if is_region_boundary(&l) {
                        self.front = Some(l);
                        break;
                    }
                    region.push(l);
                }
            }
        }
        Some(region)
    }
}

/// Open a captured raw log for streaming, transparently gunzipping when the path
/// ends in `.gz` (the compressed shape `tasks/test/capture.sh` writes) and
/// reading plain text otherwise (the committed fixture, and any pre-existing
/// uncompressed capture). Returns a `BufRead` so the file is never read whole
/// into memory — pair with `parse_ledger_reader`.
pub fn open_log_reader(path: &Path) -> io::Result<Box<dyn BufRead>> {
    let file = File::open(path)?;
    if path.extension().and_then(|e| e.to_str()) == Some("gz") {
        Ok(Box::new(BufReader::new(GzDecoder::new(file))))
    } else {
        Ok(Box::new(BufReader::new(file)))
    }
}

/// True if `line` is one of PostgreSQL's secondary error-annotation lines
/// (`DETAIL:`/`HINT:`/`CONTEXT:`/`QUERY:`/`LOCATION:`). These sit BETWEEN the
/// primary `ERROR:` line and its tag-bearing `STATEMENT:` echo in real Postgres
/// output (observed in the captured fixture: `ERROR:` → `CONTEXT:` →
/// `STATEMENT:` for the plpgsql blocker's RAISE), so the error→statement scan
/// must skip them rather than stop at them.
fn is_error_annotation(line: &str) -> bool {
    ["DETAIL:", "HINT:", "CONTEXT:", "QUERY:", "LOCATION:"]
        .iter()
        .any(|m| after_marker(line, m).is_some())
}

/// Look ahead from an `ERROR:` line for the `STATEMENT:` echo and return its
/// tag's case_id (`""` if none found before the next unrelated primary entry).
///
/// EMPIRICAL FIX: PostgreSQL emits an error's secondary annotation lines
/// (`CONTEXT:`/`DETAIL:`/`HINT:`) between the `ERROR:` and the `STATEMENT:` echo
/// — these are log-prefixed (carry the `%m [%p] %x ` timestamp) but belong to
/// the SAME error report. The earlier "break on any log-prefixed line" rule
/// stopped at the `CONTEXT:` line and never reached the tagged `STATEMENT:`,
/// losing the blocker's case_id (`""`). We now skip those annotation lines and
/// break only at the next genuine primary entry (a new `LOG:`/`ERROR:`/… line
/// that is neither a `STATEMENT:` echo nor an error annotation).
fn find_following_statement_case_id(lines: &[&str], err_idx: usize) -> String {
    let mut j = err_idx + 1;
    while j < lines.len() {
        if let LineKind::StatementEcho(stmt) = classify_line(lines[j]) {
            let (text, _c) = gather_continuation(lines, j, stmt);
            return extract_case_id(&text).to_string();
        }
        if is_log_prefixed(lines[j]) && !is_error_annotation(lines[j]) {
            break;
        }
        j += 1;
    }
    String::new()
}

/// Return the text after a `LOG:`/`ERROR:`/`STATEMENT:` marker on a log line,
/// or None if the marker is absent.
fn after_marker<'a>(line: &'a str, marker: &str) -> Option<&'a str> {
    line.find(marker)
        .map(|idx| line[idx + marker.len()..].trim_start())
}

/// True if a line begins with the `log_line_prefix` timestamp (`%m` →
/// `YYYY-MM-DD HH:MM:SS…`). A new log entry starts with a 4-(or-more)-digit
/// year run immediately followed by `-`; continuation lines (indented statement
/// or JSON-plan bodies) never have this — even a continuation that *starts with
/// a digit* (a wrapped JSON value, or a statement wrapped mid-number) lacks the
/// `digits-then-dash` ISO date shape, so it is correctly classified as a
/// continuation. This anchors on the real prefix instead of the fragile
/// "first char is a digit" heuristic the earlier draft used (which misclassified
/// any digit-leading continuation as a new entry, truncating the record).
fn is_log_prefixed(line: &str) -> bool {
    let t = line.trim_start();
    let mut digits = 0usize;
    let bytes = t.as_bytes();
    while digits < bytes.len() && bytes[digits].is_ascii_digit() {
        digits += 1;
    }
    // A timestamp year is ≥ 4 digits, immediately followed by the ISO `-`.
    digits >= 4 && bytes.get(digits) == Some(&b'-')
}

/// Gather a statement that may continue across indented following lines.
/// Returns (full_text, lines_consumed_including_the_first).
fn gather_continuation(lines: &[&str], start: usize, first: &str) -> (String, usize) {
    let mut text = first.to_string();
    let mut consumed = 1;
    let mut k = start + 1;
    while k < lines.len() && !is_log_prefixed(lines[k]) {
        text.push('\n');
        text.push_str(lines[k]);
        consumed += 1;
        k += 1;
    }
    (text, consumed)
}

/// Gather an indented JSON block (auto_explain plan) until the next
/// log-prefixed line. Returns (json_text, lines_consumed).
fn gather_json_block(lines: &[&str], start: usize) -> (String, usize) {
    let mut text = String::new();
    let mut consumed = 0;
    let mut k = start;
    while k < lines.len() && !is_log_prefixed(lines[k]) {
        text.push_str(lines[k]);
        text.push('\n');
        consumed += 1;
        k += 1;
    }
    (text, consumed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extract_case_id_reads_the_tag() {
        assert_eq!(
            extract_case_id("/* eqlmatrix:matrix_int4_eq_eq_pivot_mid_correctness */ SELECT 1"),
            "matrix_int4_eq_eq_pivot_mid_correctness"
        );
        assert_eq!(extract_case_id("SELECT 1"), "");
        assert_eq!(extract_case_id("/* eqlmatrix: */ SELECT 1"), "");
    }

    #[test]
    fn normalize_strips_tag_lowercases_and_replaces_literals() {
        let raw =
            "/* eqlmatrix:c */ SELECT count(*) FROM t WHERE value = '{\"v\":2}'::jsonb::int4_eq";
        let norm = normalize_statement(raw);
        assert_eq!(
            norm,
            "select count(*) from t where value = $::jsonb::int4_eq"
        );
    }

    #[test]
    fn normalize_replaces_bind_params_and_collapses_whitespace() {
        let raw = "/* eqlmatrix:x */ SELECT   $1::jsonb::int4_eq  <  $2::jsonb::int4_eq";
        assert_eq!(
            normalize_statement(raw),
            "select $::jsonb::int4_eq < $::jsonb::int4_eq"
        );
    }

    #[test]
    fn normalize_strips_ephemeral_db_names() {
        let raw = "SELECT * FROM _sqlx_test_1234abcd.foo";
        assert_eq!(normalize_statement(raw), "select * from _sqlx_test.foo");
    }

    #[test]
    fn normalize_keeps_domain_type_digits() {
        // `int4` / `int2` digits are identifier chars, not literals.
        let raw = "/* eqlmatrix:x */ SELECT payload::int4_ord";
        assert_eq!(normalize_statement(raw), "select payload::int4_ord");
    }

    #[test]
    fn normalize_handles_real_payload_literal_shape() {
        // The HIGHEST-FREQUENCY real input: the literal `sql_string_literal`
        // (tests/sqlx/src/scalar_domains.rs) emits is the encrypted JSONB
        // ciphertext payload `'{"c":"<base64>"}'` cast through the domain, not
        // the toy `'{"v":2}'` of the test above. Pin that exact shape.
        let raw = "/* eqlmatrix:c */ SELECT count(*) FROM t WHERE payload::int4_eq = '{\"c\":\"AAECawoBh9k=\"}'::jsonb::int4_eq";
        assert_eq!(
            normalize_statement(raw),
            "select count(*) from t where payload::int4_eq = $::jsonb::int4_eq"
        );
    }

    #[test]
    fn normalize_is_idempotent() {
        // Load-bearing: the Stage 4 manifest side and the ledger side normalize
        // INDEPENDENTLY and the matcher compares by EXACT string equality.
        // normalize(normalize(x)) == normalize(x) guarantees a once-normalized
        // manifest shape is a fixed point — re-normalizing it (or normalizing an
        // already-canonical string) cannot drift. Fixed corpus of the real
        // statement shapes the matrix emits.
        let corpus = [
            "/* eqlmatrix:a */ SELECT count(*) FROM t WHERE payload::int4_eq = '{\"c\":\"AAEC\"}'::jsonb::int4_eq",
            "/* eqlmatrix:b */ SELECT   $1::jsonb::int4_ord  <  $2::jsonb::int4_ord",
            "SELECT * FROM _sqlx_test_9f3a.fixture_int4 ORDER BY plaintext",
            "/* eqlmatrix:c */ SELECT $1::jsonb::int4 = $2::jsonb::int4",
        ];
        for raw in corpus {
            let once = normalize_statement(raw);
            let twice = normalize_statement(&once);
            assert_eq!(once, twice, "normalize not idempotent on {raw:?}");
        }
    }

    #[test]
    fn tag_extract_case_id_round_trips() {
        // The producer's tag() and the consumer's extract_case_id() are the two
        // halves of the join key; prove they round-trip for the generated
        // case_id grammar ([A-Za-z0-9_]+). (tag() lives in the tests-sqlx crate,
        // so reproduce its output shape here rather than depend on it.)
        for case_id in [
            "matrix_int4_eq_eq_pivot_mid_correctness",
            "matrix_int4_storage_eq_blocker",
            "matrix_int4_eq_index_engages_eq_btree",
        ] {
            let tagged = format!("/* eqlmatrix:{case_id} */ SELECT 1");
            assert_eq!(extract_case_id(&tagged), case_id);
        }
    }

    #[test]
    fn parses_the_real_captured_fixture() {
        // The committed real-log fragment is the empirical contract. This is the
        // gate (was: manual jq inspection): the parser MUST extract, from a real
        // capture, at least one plan-bearing record and one blocker error paired
        // via its tag. If auto_explain's real line shape differs from the
        // skeleton's assumption, THIS fails — fix the parser against the fixture.
        let raw = include_str!("../tests/fixtures/sample-capture.log");
        let ledger = parse_ledger(raw);
        assert!(!ledger.records.is_empty(), "fixture produced no records");
        assert!(
            ledger.records.iter().any(|r| r.plan.is_some()),
            "fixture produced no plan-bearing record — auto_explain JSON shape likely mis-parsed"
        );
        assert!(
            ledger.records.iter().any(|r| matches!(
                &r.outcome,
                Outcome::Error { error_message } if error_message.contains("is not supported for")
            )),
            "fixture produced no blocker ERROR record paired to its tag"
        );
        // The plan-bearing record carries the tagged index case_id, and its plan
        // is the executed Index Scan witness (proves the §4 plan-witness B path).
        let plan_rec = ledger
            .records
            .iter()
            .find(|r| r.case_id == "matrix_int4_ord_index_engages_btree")
            .expect("tagged index plan record present");
        let plan = plan_rec.plan.as_ref().expect("plan attached");
        assert_eq!(plan["Plan"]["Plans"][0]["Node Type"], "Index Scan");
        // EMPIRICAL: the blocker error's case_id MUST survive the intervening
        // CONTEXT: line between ERROR: and STATEMENT: in the real log. If
        // find_following_statement_case_id stopped at CONTEXT:, this would be ""
        // and the false-green guard would be defeated.
        let blocker = ledger
            .records
            .iter()
            .find(|r| matches!(&r.outcome, Outcome::Error { .. }))
            .expect("blocker error record present");
        assert_eq!(
            blocker.case_id, "matrix_int4_storage_eq_blocker",
            "blocker case_id must be recovered past the CONTEXT: annotation line"
        );
    }

    #[test]
    fn parse_pairs_statement_with_its_error_via_tag() {
        let raw = "\
2026-06-15 10:00:00.000 UTC [100] 0  LOG:  statement: /* eqlmatrix:matrix_int4_storage_eq_blocker */ SELECT $1::jsonb::int4 = $2::jsonb::int4
2026-06-15 10:00:00.001 UTC [100] 0  ERROR:  operator = is not supported for int4
2026-06-15 10:00:00.001 UTC [100] 0  STATEMENT:  /* eqlmatrix:matrix_int4_storage_eq_blocker */ SELECT $1::jsonb::int4 = $2::jsonb::int4";
        let ledger = parse_ledger(raw);
        let rec = ledger
            .records
            .iter()
            .find(|r| r.case_id == "matrix_int4_storage_eq_blocker")
            .expect("blocker record present");
        assert!(matches!(
            &rec.outcome,
            Outcome::Error { error_message }
                if error_message.contains("operator = is not supported for int4")
        ));
        assert_eq!(
            rec.normalized_statement,
            "select $::jsonb::int4 = $::jsonb::int4"
        );
    }

    #[test]
    fn parse_skips_context_annotation_between_error_and_statement() {
        // Real-shape regression: plpgsql RAISE emits ERROR → CONTEXT → STATEMENT.
        // The case_id must be recovered from the STATEMENT echo despite the
        // intervening (log-prefixed) CONTEXT line.
        let raw = "\
2026-06-15 10:00:00.001 UTC [100] 0 ERROR:  operator = is not supported for eql_v3.int4
2026-06-15 10:00:00.001 UTC [100] 0 CONTEXT:  PL/pgSQL function eql_v3.eq(eql_v3.int4,eql_v3.int4) line 1 at RAISE
2026-06-15 10:00:00.001 UTC [100] 0 STATEMENT:  /* eqlmatrix:matrix_int4_storage_eq_blocker */ SELECT $1::jsonb::eql_v3.int4 = $2::jsonb::eql_v3.int4";
        let ledger = parse_ledger(raw);
        let rec = ledger
            .records
            .iter()
            .find(|r| matches!(&r.outcome, Outcome::Error { .. }))
            .expect("error record present");
        assert_eq!(rec.case_id, "matrix_int4_storage_eq_blocker");
    }

    #[test]
    fn parse_records_a_plain_successful_statement() {
        let raw = "2026-06-15 10:00:00.000 UTC [100] 0  LOG:  statement: /* eqlmatrix:matrix_int4_eq_eq_pivot_mid_correctness */ SELECT plaintext FROM t WHERE payload::int4_eq = '{}'::jsonb::int4_eq ORDER BY plaintext";
        let ledger = parse_ledger(raw);
        assert_eq!(ledger.records.len(), 1);
        let rec = &ledger.records[0];
        assert_eq!(rec.case_id, "matrix_int4_eq_eq_pivot_mid_correctness");
        assert_eq!(rec.outcome, Outcome::Success);
    }

    #[test]
    fn parse_does_not_split_on_a_digit_leading_continuation() {
        // A continuation/JSON-plan line can START WITH A DIGIT (a wrapped JSON
        // numeric value, or a statement wrapped mid-number). The old "first char
        // is a digit" classifier would treat it as a NEW log entry and truncate
        // the statement. is_log_prefixed now requires `digits-then-dash` (the
        // ISO date), so a bare digit-leading line is correctly a continuation.
        let raw = "\
2026-06-15 10:00:00.000 UTC [100] 0  LOG:  statement: /* eqlmatrix:matrix_int4_ord_lt_pivot_max_cross_shape */ SELECT count(*) FROM t WHERE value <
42::jsonb::int4_ord";
        let ledger = parse_ledger(raw);
        assert_eq!(
            ledger.records.len(),
            1,
            "digit-leading continuation wrongly split the record"
        );
        let rec = &ledger.records[0];
        assert_eq!(rec.case_id, "matrix_int4_ord_lt_pivot_max_cross_shape");
        // The `42` literal (now on the continuation line) is folded into `$`.
        assert_eq!(
            rec.normalized_statement,
            "select count(*) from t where value < $::jsonb::int4_ord"
        );
    }

    #[test]
    fn parse_attaches_plan_to_correct_record_when_backends_interleave() {
        // The whole justification for the inline tag is sqlx's 5-connection pool
        // interleaving backends in the shared log. Two cases' lines interleave
        // here (PIDs 100 and 200); attach_plan's `.rev().find(case_id)` must bind
        // each plan to its OWN case, not to log-position-adjacent lines.
        let raw = "\
2026-06-15 10:00:00.000 UTC [100] 0  LOG:  statement: /* eqlmatrix:caseA */ SELECT count(*) FROM a WHERE value = '{}'::jsonb::int4_eq
2026-06-15 10:00:00.001 UTC [200] 0  LOG:  statement: /* eqlmatrix:caseB */ SELECT count(*) FROM b WHERE value = '{}'::jsonb::int4_eq
2026-06-15 10:00:00.002 UTC [200] 0  LOG:  duration: 0.2 ms  plan:
\t{ \"Query Text\": \"/* eqlmatrix:caseB */ SELECT count(*) FROM b WHERE value = '{}'::jsonb::int4_eq\", \"Plan\": { \"Node Type\": \"Index Scan\", \"Index Name\": \"b_idx\" } }
2026-06-15 10:00:00.003 UTC [100] 0  LOG:  duration: 0.3 ms  plan:
\t{ \"Query Text\": \"/* eqlmatrix:caseA */ SELECT count(*) FROM a WHERE value = '{}'::jsonb::int4_eq\", \"Plan\": { \"Node Type\": \"Index Scan\", \"Index Name\": \"a_idx\" } }";
        let ledger = parse_ledger(raw);
        let a = ledger
            .records
            .iter()
            .find(|r| r.case_id == "caseA")
            .expect("caseA");
        let b = ledger
            .records
            .iter()
            .find(|r| r.case_id == "caseB")
            .expect("caseB");
        // Each plan binds to its own case despite the interleaved order.
        assert_eq!(a.plan.as_ref().unwrap()["Plan"]["Index Name"], "a_idx");
        assert_eq!(b.plan.as_ref().unwrap()["Plan"]["Index Name"], "b_idx");
    }

    #[test]
    fn plan_object_unwraps_single_element_array() {
        // Unit-level guard for the container-shape defense, independent of the
        // log layout: a bare object passes through unchanged, and a
        // single-element array `[ {…} ]` (bare EXPLAIN (FORMAT JSON) shape) is
        // unwrapped to its inner object so `.get("Query Text")` works on either.
        let obj = serde_json::json!({ "Query Text": "x", "Plan": { "Node Type": "Index Scan" } });
        assert_eq!(plan_object(obj.clone()), obj);
        let arr =
            serde_json::json!([ { "Query Text": "x", "Plan": { "Node Type": "Index Scan" } } ]);
        assert_eq!(plan_object(arr), obj);
    }

    #[test]
    fn parse_attaches_array_wrapped_plan_to_its_record() {
        // Deterministic (no real-log fixture needed): some auto_explain / EXPLAIN
        // configurations emit the plan JSON wrapped in a single-element array
        // `[ { "Query Text": …, "Plan": … } ]` rather than a bare object. The
        // parser MUST still attach it to the tagged statement's record — a naive
        // `plan.get("Query Text")` on an `Array` returns None and would
        // mis-attribute the plan to case_id "". `plan_object` unwraps the array
        // first, so attachment works and the stored `plan` is the inner object.
        let raw = "\
2026-06-15 10:00:00.000 UTC [100] 0  LOG:  statement: /* eqlmatrix:matrix_int4_eq_index_engages_eq_btree */ SELECT count(*) FROM t WHERE value = '{}'::jsonb::int4_eq
2026-06-15 10:00:00.002 UTC [100] 0  LOG:  duration: 0.2 ms  plan:
\t[ { \"Query Text\": \"/* eqlmatrix:matrix_int4_eq_index_engages_eq_btree */ SELECT count(*) FROM t WHERE value = '{}'::jsonb::int4_eq\", \"Plan\": { \"Node Type\": \"Index Scan\", \"Index Name\": \"t_idx\" } } ]";
        let ledger = parse_ledger(raw);
        let rec = ledger
            .records
            .iter()
            .find(|r| r.case_id == "matrix_int4_eq_index_engages_eq_btree")
            .expect("index record present");
        let plan = rec
            .plan
            .as_ref()
            .expect("array-wrapped plan attached to its record");
        // Stored plan is the unwrapped inner OBJECT, not the wrapper array.
        assert!(plan.is_object(), "stored plan must be the unwrapped object");
        assert_eq!(plan["Plan"]["Index Name"], "t_idx");
    }

    #[test]
    fn parse_leaves_blocker_without_error_as_success_for_stage4_to_flag() {
        // The parser-side false-green half: a tagged blocker statement with NO
        // following ERROR line stays Outcome::Success. The parser makes NO
        // judgement — it records what the log shows. Stage 4 compares against the
        // manifest (which expects this case to raise) and flags the mismatch:
        // the STRICT-NULL regression (a blocker that returned NULL instead of
        // raising). If the parser silently "fixed" this to Error, the regression
        // would be invisible.
        let raw = "2026-06-15 10:00:00.000 UTC [100] 0  LOG:  statement: /* eqlmatrix:matrix_int4_storage_eq_blocker */ SELECT $1::jsonb::int4 = $2::jsonb::int4";
        let ledger = parse_ledger(raw);
        let rec = ledger
            .records
            .iter()
            .find(|r| r.case_id == "matrix_int4_storage_eq_blocker")
            .expect("blocker record present");
        assert_eq!(
            rec.outcome,
            Outcome::Success,
            "no ERROR line ⇒ Success, so Stage 4 can flag the missing raise"
        );
    }

    #[test]
    fn streaming_reader_matches_whole_string_parse() {
        // The region-streaming driver must produce byte-identical records to
        // feeding the parser the whole split at once. `parse_ledger` already
        // routes through `parse_ledger_reader`, so we compare a plain `BufReader`
        // over the bytes against an explicit line-split run of the SAME state
        // machine to prove the region boundaries don't change the output.
        let raw = include_str!("../tests/fixtures/sample-capture.log");
        let streamed = parse_ledger(raw);

        // Reference: run the state machine over the whole split in one shot.
        let mut records = Vec::new();
        let mut seq = 0usize;
        let lines: Vec<&str> = raw.lines().collect();
        run_lines(&lines, &mut records, &mut seq);

        assert_eq!(
            streamed.records, records,
            "region-streamed records diverge from whole-log processing"
        );
    }

    #[test]
    fn gzip_roundtrip_matches_plain_parse() {
        // The CLI gunzips `.log.gz` captures transparently. Compress the real
        // fixture, decode it through `GzDecoder` + `parse_ledger_reader`, and
        // assert the resulting ledger is identical to parsing the plain text —
        // so a gzipped capture and a plain one yield the same ledger.
        use flate2::write::GzEncoder;
        use flate2::Compression;
        use std::io::Write;

        let raw = include_str!("../tests/fixtures/sample-capture.log");
        let plain = parse_ledger(raw);

        let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
        encoder.write_all(raw.as_bytes()).unwrap();
        let gz = encoder.finish().unwrap();

        let decoder = GzDecoder::new(io::Cursor::new(gz));
        let from_gz = parse_ledger_reader(BufReader::new(decoder));

        assert_eq!(
            plain.records, from_gz.records,
            "gzip round-trip ledger diverges from plain-text ledger"
        );
        // Spot-check the load-bearing records survived the round-trip.
        assert!(from_gz.records.iter().any(|r| r.plan.is_some()));
        assert!(from_gz.records.iter().any(|r| matches!(
            &r.outcome,
            Outcome::Error { error_message } if error_message.contains("is not supported for")
        )));
    }
}
