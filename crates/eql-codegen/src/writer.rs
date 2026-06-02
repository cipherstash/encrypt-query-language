//! Ownership-guarded file writer (port of writer.py).

use std::fs;
use std::io;
use std::path::{Path, PathBuf};

use crate::consts::AUTO_GENERATED_HEADER;

/// First line of the SQL header — the ownership marker.
fn sql_marker() -> &'static str {
    AUTO_GENERATED_HEADER.lines().next().unwrap()
}

/// Raised when the generator would clobber a hand-written file.
#[derive(Debug)]
pub enum WriteError {
    Ownership(String),
    Io(io::Error),
}

impl From<io::Error> for WriteError {
    fn from(e: io::Error) -> Self {
        WriteError::Io(e)
    }
}

impl std::fmt::Display for WriteError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            WriteError::Ownership(m) => write!(f, "{m}"),
            WriteError::Io(e) => write!(f, "io error: {e}"),
        }
    }
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

/// True if the file carries the SQL AUTO-GENERATED marker. Port of `is_generated`.
pub fn is_generated(path: &Path) -> bool {
    path.is_file() && first_line(path).map(|l| l == sql_marker()).unwrap_or(false)
}

/// Delete every generated .sql file in `directory`, returning removed paths.
/// Port of `clean_generated_files`.
pub fn clean_generated_files(directory: &Path) -> io::Result<Vec<PathBuf>> {
    if !directory.is_dir() {
        return Ok(Vec::new());
    }
    let mut paths: Vec<PathBuf> = fs::read_dir(directory)?
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| p.extension().and_then(|x| x.to_str()) == Some("sql"))
        .collect();
    paths.sort();
    let mut removed = Vec::new();
    for p in paths {
        if is_generated(&p) {
            fs::remove_file(&p)?;
            removed.push(p);
        }
    }
    Ok(removed)
}

/// Refuse a generation run if any target is hand-written. Port of
/// `ensure_generated_paths_writable`.
pub fn ensure_generated_paths_writable(paths: &[PathBuf]) -> Result<(), WriteError> {
    for path in paths {
        if path.exists() && !is_generated(path) {
            return Err(WriteError::Ownership(format!(
                "refusing to overwrite hand-written file: {} (no AUTO-GENERATED header). \
                 Remove it by hand if it is a one-time generator-adoption target.",
                path.display()
            )));
        }
    }
    Ok(())
}

/// Write the rendered SQL `body` to `path`, after refusing to clobber a
/// hand-written file. The SQL templates emit the `-- AUTOMATICALLY GENERATED
/// FILE.` marker as their own first line, so the writer writes `body` verbatim
/// — it does not prepend a header.
pub fn write_generated_file(path: &Path, body: &str) -> Result<(), WriteError> {
    ensure_generated_paths_writable(std::slice::from_ref(&path.to_path_buf()))?;
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
    fn is_generated_true_for_header() {
        let d = tmp();
        let p = d.path().join("x.sql");
        fs::write(&p, format!("{AUTO_GENERATED_HEADER}SELECT 1;\n")).unwrap();
        assert!(is_generated(&p));
    }

    #[test]
    fn is_generated_false_for_handwritten() {
        let d = tmp();
        let p = d.path().join("x.sql");
        fs::write(&p, "-- REQUIRE: src/schema.sql\nSELECT 1;\n").unwrap();
        assert!(!is_generated(&p));
    }

    #[test]
    fn is_generated_true_for_crlf_header() {
        let d = tmp();
        let p = d.path().join("x.sql");
        let marker = sql_marker();
        fs::write(&p, format!("{marker}\r\nSELECT 1;\n")).unwrap();
        assert!(is_generated(&p));
    }

    #[test]
    fn write_generated_file_writes_rendered_body_verbatim() {
        let d = tmp();
        let p = d.path().join("int4_types.sql");
        // The template render carries the marker on line 1; the writer writes it
        // through unchanged.
        let body = format!("{AUTO_GENERATED_HEADER}DO $$ BEGIN END $$;\n");
        write_generated_file(&p, &body).unwrap();
        let text = fs::read_to_string(&p).unwrap();
        assert_eq!(text, body);
        assert!(is_generated(&p));
    }

    #[test]
    fn write_refuses_to_overwrite_handwritten() {
        let d = tmp();
        let p = d.path().join("int4_types.sql");
        fs::write(&p, "-- REQUIRE: src/schema.sql\n-- hand-written\n").unwrap();
        let err = write_generated_file(&p, "DO $$ BEGIN END $$;\n").unwrap_err();
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
            format!("{AUTO_GENERATED_HEADER}-- old generated\n"),
        )
        .unwrap();
        fs::write(&hand, "-- REQUIRE: src/schema.sql\n-- hand-written\n").unwrap();
        let err = ensure_generated_paths_writable(&[generated.clone(), hand.clone()]).unwrap_err();
        assert!(err.to_string().contains("int4_eq_functions.sql"));
        assert!(generated.exists());
        assert!(hand.exists());
    }

    #[test]
    fn write_overwrites_existing_generated_file() {
        let d = tmp();
        let p = d.path().join("int4_types.sql");
        fs::write(&p, format!("{AUTO_GENERATED_HEADER}-- old content\n")).unwrap();
        write_generated_file(&p, &format!("{AUTO_GENERATED_HEADER}-- new content\n")).unwrap();
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
        fs::write(&gen1, format!("{AUTO_GENERATED_HEADER}SELECT 1;\n")).unwrap();
        fs::write(&gen2, format!("{AUTO_GENERATED_HEADER}SELECT 2;\n")).unwrap();
        fs::write(&hand, "-- REQUIRE: src/schema.sql\n-- hand-written\n").unwrap();
        let removed = clean_generated_files(d.path()).unwrap();
        assert!(!gen1.exists());
        assert!(!gen2.exists());
        assert!(hand.exists());
        assert_eq!(removed.len(), 2);
    }

    #[test]
    fn clean_on_empty_directory() {
        let d = tmp();
        assert!(clean_generated_files(d.path()).unwrap().is_empty());
    }
}
