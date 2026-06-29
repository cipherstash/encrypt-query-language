//! Ownership-guarded file writer.

use std::fs;
use std::io;
use std::path::{Path, PathBuf};

use crate::consts::{AUTO_GENERATED_MARKER, RUST_GENERATED_MARKER};

/// Which generated-file family a writer call targets — selects the ownership
/// marker and the cleanup file extension so one writer serves both the SQL
/// surface (`generate.rs`) and the Rust bindings (`bindings.rs`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GeneratedKind {
    Sql,
    Rust,
}

impl GeneratedKind {
    /// The exact first-line ownership marker for this kind.
    pub const fn marker(self) -> &'static str {
        match self {
            GeneratedKind::Sql => AUTO_GENERATED_MARKER,
            GeneratedKind::Rust => RUST_GENERATED_MARKER,
        }
    }

    /// The file extension `clean_generated_files` filters on for this kind.
    pub const fn extension(self) -> &'static str {
        match self {
            GeneratedKind::Sql => "sql",
            GeneratedKind::Rust => "rs",
        }
    }
}

/// Raised when the generator would clobber a hand-written file, or on an
/// underlying IO error. Implements `std::error::Error` (via `thiserror`) so it
/// composes with `?`, `Box<dyn Error>`, and `source()` chains.
#[derive(Debug, thiserror::Error)]
pub enum WriteError {
    #[error("{0}")]
    Ownership(String),
    #[error("io error: {0}")]
    Io(#[from] io::Error),
}

fn first_line(path: &Path) -> io::Result<String> {
    let content = fs::read_to_string(path)?;
    Ok(content
        .lines()
        .next()
        .unwrap_or("")
        .trim_end_matches(['\r', '\n'])
        .to_string())
}

/// Whether the file carries this kind's AUTO-GENERATED marker as line 1.
///
/// `Ok(false)` means genuinely-not-generated and safe to write over: the path is
/// absent or is not a regular file. An EXISTING regular file that cannot be read
/// (EACCES, invalid UTF-8) returns `Err` rather than being silently reported as
/// not-generated — otherwise the ownership preflight would abort with a
/// misleading "refusing to overwrite hand-written file (no AUTO-GENERATED
/// header)" instead of surfacing the real read failure.
pub fn is_generated(path: &Path, kind: GeneratedKind) -> io::Result<bool> {
    if !path.is_file() {
        return Ok(false);
    }
    Ok(first_line(path)? == kind.marker())
}

/// Delete every generated file of `kind` in `directory`, returning removed paths.
pub fn clean_generated_files(directory: &Path, kind: GeneratedKind) -> io::Result<Vec<PathBuf>> {
    if !directory.is_dir() {
        return Ok(Vec::new());
    }
    let mut paths: Vec<PathBuf> = fs::read_dir(directory)?
        .map(|e| e.map(|e| e.path()))
        .collect::<io::Result<Vec<_>>>()?
        .into_iter()
        .filter(|p| p.extension().and_then(|x| x.to_str()) == Some(kind.extension()))
        .collect();
    paths.sort();
    let mut removed = Vec::new();
    for p in paths {
        if is_generated(&p, kind)? {
            fs::remove_file(&p)?;
            removed.push(p);
        }
    }
    Ok(removed)
}

/// Refuse a generation run if any target is hand-written (lacks this kind's marker).
pub fn ensure_generated_paths_writable(
    paths: &[PathBuf],
    kind: GeneratedKind,
) -> Result<(), WriteError> {
    for path in paths {
        if path.exists() && !is_generated(path, kind)? {
            return Err(WriteError::Ownership(format!(
                "refusing to overwrite hand-written file: {} (no {:?} AUTO-GENERATED header). \
                 Remove it by hand if it is a one-time generator-adoption target.",
                path.display(),
                kind
            )));
        }
    }
    Ok(())
}

/// Write `body` to `path` after refusing to clobber a hand-written file. The
/// renderer is trusted to carry `kind.marker()` as the first line; validate it
/// before writing.
pub fn write_generated_file(
    path: &Path,
    body: &str,
    kind: GeneratedKind,
) -> Result<(), WriteError> {
    ensure_generated_paths_writable(std::slice::from_ref(&path.to_path_buf()), kind)?;
    let first = body
        .lines()
        .next()
        .unwrap_or("")
        .trim_end_matches(['\r', '\n']);
    if first != kind.marker() {
        return Err(WriteError::Ownership(format!(
            "refusing to write generated file without the {:?} AUTO-GENERATED marker as its \
             first line: {} (expected first line {:?}, got {:?}).",
            kind,
            path.display(),
            kind.marker(),
            first
        )));
    }
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(path, body)?;
    Ok(())
}

#[cfg(test)]
pub(crate) mod test_support {
    use std::fs;
    use std::path::{Path, PathBuf};

    pub struct TempDir(PathBuf);
    impl TempDir {
        pub fn path(&self) -> &Path {
            &self.0
        }
    }
    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }
    pub fn tempdir() -> TempDir {
        let mut p = std::env::temp_dir();
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        p.push(format!(
            "eql-codegen-test-{nanos}-{:?}",
            std::thread::current().id()
        ));
        fs::create_dir_all(&p).unwrap();
        TempDir(p)
    }
}

#[cfg(test)]
mod tests {
    use super::test_support::tempdir as tmp;
    use super::*;

    #[test]
    fn is_generated_recognises_rust_marker_and_ignores_sql_in_rs() {
        use crate::consts::RUST_GENERATED_MARKER;
        let d = tmp();
        let rs = d.path().join("int4.rs");
        fs::write(&rs, format!("{RUST_GENERATED_MARKER}\npub struct Int4;\n")).unwrap();
        assert!(is_generated(&rs, GeneratedKind::Rust).unwrap());
        assert!(!is_generated(&rs, GeneratedKind::Sql).unwrap());
    }

    #[test]
    fn clean_filters_by_kind_extension() {
        use crate::consts::RUST_GENERATED_MARKER;
        let d = tmp();
        let gen_rs = d.path().join("int4.rs");
        let gen_sql = d.path().join("int4_types.sql");
        let hand_rs = d.path().join("terms.rs");
        fs::write(
            &gen_rs,
            format!("{RUST_GENERATED_MARKER}\npub struct Int4;\n"),
        )
        .unwrap();
        fs::write(&gen_sql, format!("{AUTO_GENERATED_MARKER}\nSELECT 1;\n")).unwrap();
        fs::write(&hand_rs, "//! hand-written\npub struct Terms;\n").unwrap();
        let removed = clean_generated_files(d.path(), GeneratedKind::Rust).unwrap();
        assert!(!gen_rs.exists());
        assert!(gen_sql.exists(), "different kind, untouched");
        assert!(hand_rs.exists(), "no marker, kept");
        assert_eq!(removed.len(), 1);
    }

    #[test]
    fn is_generated_true_for_header() {
        let d = tmp();
        let p = d.path().join("x.sql");
        fs::write(&p, format!("{AUTO_GENERATED_MARKER}\nSELECT 1;\n")).unwrap();
        assert!(is_generated(&p, GeneratedKind::Sql).unwrap());
    }

    #[test]
    fn is_generated_false_for_handwritten() {
        let d = tmp();
        let p = d.path().join("x.sql");
        fs::write(&p, "-- REQUIRE: src/schema.sql\nSELECT 1;\n").unwrap();
        assert!(!is_generated(&p, GeneratedKind::Sql).unwrap());
    }

    #[test]
    fn is_generated_true_for_crlf_header() {
        let d = tmp();
        let p = d.path().join("x.sql");
        let marker = GeneratedKind::Sql.marker();
        fs::write(&p, format!("{marker}\r\nSELECT 1;\n")).unwrap();
        assert!(is_generated(&p, GeneratedKind::Sql).unwrap());
    }

    #[test]
    fn write_generated_file_writes_rendered_body_verbatim() {
        let d = tmp();
        let p = d.path().join("int4_types.sql");
        // The template render carries the marker on line 1; the writer writes it
        // through unchanged.
        let body = format!("{AUTO_GENERATED_MARKER}\nDO $$ BEGIN END $$;\n");
        write_generated_file(&p, &body, GeneratedKind::Sql).unwrap();
        let text = fs::read_to_string(&p).unwrap();
        assert_eq!(text, body);
        assert!(is_generated(&p, GeneratedKind::Sql).unwrap());
    }

    #[test]
    fn write_rejects_body_without_marker() {
        let d = tmp();
        let p = d.path().join("int4_types.sql");
        // A body whose first line is NOT the AUTO-GENERATED marker must be
        // rejected — the template is required to emit it.
        let body = "-- REQUIRE: src/v3/schema.sql\nDO $$ BEGIN END $$;\n";
        let err = write_generated_file(&p, body, GeneratedKind::Sql).unwrap_err();
        assert!(matches!(err, WriteError::Ownership(_)));
        assert!(err.to_string().contains("AUTO-GENERATED marker"));
        assert!(
            !p.exists(),
            "no file should be written when the marker is missing"
        );
    }

    #[test]
    fn write_refuses_to_overwrite_handwritten() {
        let d = tmp();
        let p = d.path().join("int4_types.sql");
        fs::write(&p, "-- REQUIRE: src/schema.sql\n-- hand-written\n").unwrap();
        let err =
            write_generated_file(&p, "DO $$ BEGIN END $$;\n", GeneratedKind::Sql).unwrap_err();
        assert!(matches!(err, WriteError::Ownership(_)));
        assert!(err.to_string().contains("hand-written"));
    }

    #[test]
    fn preflight_refuses_handwritten_target() {
        let d = tmp();
        let generated = d.path().join("int4_types.sql");
        let hand = d.path().join("int4_eq_functions.sql");
        fs::write(
            &generated,
            format!("{AUTO_GENERATED_MARKER}\n-- old generated\n"),
        )
        .unwrap();
        fs::write(&hand, "-- REQUIRE: src/schema.sql\n-- hand-written\n").unwrap();
        let err =
            ensure_generated_paths_writable(&[generated.clone(), hand.clone()], GeneratedKind::Sql)
                .unwrap_err();
        assert!(err.to_string().contains("int4_eq_functions.sql"));
        assert!(generated.exists());
        assert!(hand.exists());
    }

    #[test]
    fn preflight_surfaces_read_error_not_misleading_handwritten() {
        // An EXISTING generated target that becomes unreadable (here: invalid
        // UTF-8) must not be silently misclassified as hand-written. The old
        // `first_line(...).unwrap_or(false)` collapsed every read error to "not
        // generated", so the preflight aborted with the misleading "refusing to
        // overwrite hand-written file (no AUTO-GENERATED header)". The read
        // failure must surface distinctly instead.
        let d = tmp();
        let p = d.path().join("int4.rs");
        fs::write(&p, [0xff, 0xfe, 0x00]).unwrap();
        let err = ensure_generated_paths_writable(std::slice::from_ref(&p), GeneratedKind::Rust)
            .unwrap_err();
        assert!(matches!(err, WriteError::Io(_)), "expected Io, got {err:?}");
        assert!(
            !err.to_string().contains("hand-written"),
            "must not report an unreadable existing file as hand-written: {err}"
        );
    }

    #[test]
    fn is_generated_errors_on_unreadable_existing_file() {
        // Direct contract: an existing file that cannot be decoded is an Err,
        // never Ok(false) (which would mean "not generated, safe to clobber").
        let d = tmp();
        let p = d.path().join("x.rs");
        fs::write(&p, [0xff, 0xfe, 0x00]).unwrap();
        let err = is_generated(&p, GeneratedKind::Rust).unwrap_err();
        assert_eq!(err.kind(), io::ErrorKind::InvalidData);
    }

    #[test]
    fn is_generated_ok_false_for_absent_or_non_file() {
        // NotFound / non-file paths are genuinely "not generated" (Ok(false)),
        // distinct from a read error on an existing file.
        let d = tmp();
        assert!(!is_generated(&d.path().join("missing.rs"), GeneratedKind::Rust).unwrap());
        assert!(!is_generated(d.path(), GeneratedKind::Rust).unwrap()); // a directory
    }

    #[test]
    fn write_overwrites_existing_generated_file() {
        let d = tmp();
        let p = d.path().join("int4_types.sql");
        fs::write(&p, format!("{AUTO_GENERATED_MARKER}\n-- old content\n")).unwrap();
        write_generated_file(
            &p,
            &format!("{AUTO_GENERATED_MARKER}\n-- new content\n"),
            GeneratedKind::Sql,
        )
        .unwrap();
        let text = fs::read_to_string(&p).unwrap();
        assert!(text.contains("-- new content"));
        assert!(!text.contains("-- old content"));
    }

    #[test]
    fn clean_removes_only_generated_files() {
        let d = tmp();
        let gen1 = d.path().join("int4_eq_functions.sql");
        let gen2 = d.path().join("int4_old_domain_functions.sql");
        let hand = d.path().join("int4_jsonb_extra.sql");
        fs::write(&gen1, format!("{AUTO_GENERATED_MARKER}\nSELECT 1;\n")).unwrap();
        fs::write(&gen2, format!("{AUTO_GENERATED_MARKER}\nSELECT 2;\n")).unwrap();
        fs::write(&hand, "-- REQUIRE: src/schema.sql\n-- hand-written\n").unwrap();
        let removed = clean_generated_files(d.path(), GeneratedKind::Sql).unwrap();
        assert!(!gen1.exists());
        assert!(!gen2.exists());
        assert!(hand.exists());
        assert_eq!(removed.len(), 2);
    }

    #[test]
    fn clean_on_empty_directory() {
        let d = tmp();
        assert!(clean_generated_files(d.path(), GeneratedKind::Sql)
            .unwrap()
            .is_empty());
    }

    #[test]
    fn write_surfaces_io_error_via_from_and_display() {
        // Exercise the `WriteError::Io` arm and its `From<io::Error>` conversion:
        // a marker-valid body whose parent path is a *file* makes `create_dir_all`
        // fail, which `?`-converts into `WriteError::Io`.
        let d = tmp();
        let blocker = d.path().join("not-a-dir");
        fs::write(&blocker, "i am a file\n").unwrap();
        let target = blocker.join("int4_types.sql"); // parent is a file
        let body = format!("{AUTO_GENERATED_MARKER}\nDO $$ BEGIN END $$;\n");
        let err = write_generated_file(&target, &body, GeneratedKind::Sql).unwrap_err();
        assert!(matches!(err, WriteError::Io(_)), "expected Io, got {err:?}");
        assert!(err.to_string().starts_with("io error: "));
    }
}
