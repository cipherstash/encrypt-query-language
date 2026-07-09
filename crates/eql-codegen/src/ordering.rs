//! Deterministic topological ordering of the whole `src/v3` SQL surface.
//!
//! One enumeration orders every file: hand-written and generated alike are
//! walked off disk, their `-- REQUIRE:` edges parsed, and the result linearized
//! by [`surface_order`]. There is deliberately no generated/hand-written
//! classifier here. An earlier design split the surface into two blocks — a
//! shell glob that skipped the `-- AUTOMATICALLY GENERATED FILE.` marker, and a
//! codegen-emitted manifest of `render_type` output — and a cross-family
//! generated file (`scalars/ore_fallback.sql`, rendered outside `render_type`)
//! matched neither predicate and was silently dropped from the installer. You
//! order exactly the set you walk, so that class of bug is unrepresentable.

use std::cmp::Reverse;
use std::collections::{BTreeMap, BTreeSet, BinaryHeap};
use std::fs;
use std::io;
use std::path::Path;

/// The surface root, relative to the repo root. Every node and every
/// `-- REQUIRE:` target must live under it — the eql_v3 installer is
/// self-contained and owns no edge pointing outside this tree.
pub const SURFACE_ROOT: &str = "src/v3";

/// A dependency cycle among generated files — the topo-sort could not linearize.
#[derive(Debug)]
pub struct CycleError {
    /// The nodes that never reached in-degree 0 (participate in / are blocked by a cycle).
    pub remaining: Vec<String>,
}

impl std::fmt::Display for CycleError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "dependency cycle among generated files: {}",
            self.remaining.join(", ")
        )
    }
}
impl std::error::Error for CycleError {}

/// A `-- REQUIRE:` target that is not a node in the surface, or points outside it.
#[derive(Debug)]
pub enum OrderError {
    /// Targets naming a file that does not exist in the walked surface. Subsumes
    /// the old `verify_deps_exist` shell gate, which only checked the converse
    /// (every *listed* file exists on disk) and so never noticed a file on disk
    /// that no block listed.
    UnknownTargets(Vec<(String, String)>),
    /// Targets outside `src/v3`. The v3 installer is self-contained: an edge to
    /// (say) `src/v2/foo.sql` would pull non-v3 SQL into the artefact. Subsumes
    /// the old `verify_v3_self_contained` shell gate.
    OutsideSurface(Vec<(String, String)>),
    /// The edges do not linearize.
    Cycle(CycleError),
}

impl std::fmt::Display for OrderError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        // Every offender is listed, not just the first: a REQUIRE typo tends to
        // come in batches (a renamed file breaks every dependent at once), and
        // one-at-a-time diagnostics turn that into one build per typo.
        match self {
            Self::UnknownTargets(v) => {
                writeln!(f, "-- REQUIRE: target does not exist:")?;
                for (file, dep) in v {
                    writeln!(f, "  {file} requires {dep}")?;
                }
                write!(f, "check the -- REQUIRE: directives above for typos")
            }
            Self::OutsideSurface(v) => {
                writeln!(f, "-- REQUIRE: target outside {SURFACE_ROOT}:")?;
                for (file, dep) in v {
                    writeln!(f, "  {file} requires {dep}")?;
                }
                write!(
                    f,
                    "the eql_v3 surface must be self-contained — no edge may leave {SURFACE_ROOT}"
                )
            }
            Self::Cycle(e) => write!(f, "{e}"),
        }
    }
}
impl std::error::Error for OrderError {}

/// Linearize the whole surface. `files` is `(repo-relative path, its REQUIRE
/// targets)` for EVERY `.sql` file in the surface.
///
/// Unlike [`topo_order`], which tolerates edges to non-nodes, this validates
/// first: every target must be a node, and must live under [`SURFACE_ROOT`].
/// Both gates ran in shell before; keeping them here means the invariant travels
/// with the sort rather than with whoever remembers to call the checker.
pub fn surface_order(files: &[(String, Vec<String>)]) -> Result<Vec<String>, OrderError> {
    let nodes: BTreeSet<&str> = files.iter().map(|(p, _)| p.as_str()).collect();
    let (mut outside, mut unknown) = (Vec::new(), Vec::new());
    for (file, deps) in files {
        for dep in deps {
            let prefix = format!("{SURFACE_ROOT}/");
            if !dep.starts_with(&prefix) {
                outside.push((file.clone(), dep.clone()));
            } else if !nodes.contains(dep.as_str()) {
                unknown.push((file.clone(), dep.clone()));
            }
        }
    }
    // Outside-surface first: such a target is also "unknown" (it is not a node),
    // and the self-containment breach is the more actionable diagnosis.
    if !outside.is_empty() {
        return Err(OrderError::OutsideSurface(outside));
    }
    if !unknown.is_empty() {
        return Err(OrderError::UnknownTargets(unknown));
    }
    topo_order(files).map_err(OrderError::Cycle)
}

/// Walk `<root>/src/v3` for the surface: every `.sql` file paired with its
/// `-- REQUIRE:` targets, sorted by path. `*_test.sql` is excluded (it is not
/// part of the installer).
///
/// Symlinked subdirectories are NOT followed — `file_type()` reports the link
/// itself, where `Path::is_dir()` would resolve it and could walk out of the
/// tree. Mirrors the orphan-sweep guard in `generate.rs`.
pub fn walk_v3_surface(root: &Path) -> io::Result<Vec<(String, Vec<String>)>> {
    let mut files = Vec::new();
    let mut stack = vec![root.join(SURFACE_ROOT)];
    while let Some(dir) = stack.pop() {
        for entry in fs::read_dir(&dir)? {
            let entry = entry?;
            let path = entry.path();
            if entry.file_type()?.is_dir() {
                stack.push(path);
                continue;
            }
            let name = entry.file_name().to_string_lossy().into_owned();
            if !name.ends_with(".sql") || name.ends_with("_test.sql") {
                continue;
            }
            let rel = path
                .strip_prefix(root)
                .unwrap_or(&path)
                .to_string_lossy()
                .replace('\\', "/");
            files.push((rel, requires_of(&fs::read_to_string(&path)?)));
        }
    }
    files.sort();
    Ok(files)
}

/// Read back the anchored `-- REQUIRE:` targets from a SQL body — either a body
/// rendered in-process from the typed `requires` vec, or one read off disk.
pub fn requires_of(body: &str) -> Vec<String> {
    body.lines()
        .filter_map(|l| l.trim_start().strip_prefix("-- REQUIRE:"))
        .flat_map(|rest| rest.split_whitespace().map(str::to_string))
        .collect()
}

/// Deterministic topological order of generated files. `files` is
/// `(repo-relative path, its REQUIRE targets)`. Edges whose target is NOT a key
/// in `files` (hand-written prerequisites) are ignored: the generated block is
/// emitted wholesale AFTER the hand-written block, so those edges are satisfied
/// by construction. Kahn's algorithm with a min-heap keyed by path string gives
/// name-sorted tie-breaking ⇒ byte-reproducible output.
pub fn topo_order(files: &[(String, Vec<String>)]) -> Result<Vec<String>, CycleError> {
    let nodes: BTreeSet<&str> = files.iter().map(|(p, _)| p.as_str()).collect();
    let mut indeg: BTreeMap<&str, usize> = nodes.iter().map(|n| (*n, 0usize)).collect();
    let mut dependents: BTreeMap<&str, Vec<&str>> = BTreeMap::new();
    for (p, reqs) in files {
        for dep in reqs {
            let dep = dep.as_str();
            if dep != p.as_str() && nodes.contains(dep) {
                *indeg.get_mut(p.as_str()).unwrap() += 1;
                dependents.entry(dep).or_default().push(p.as_str());
            }
        }
    }
    let mut ready: BinaryHeap<Reverse<&str>> = indeg
        .iter()
        .filter(|(_, d)| **d == 0)
        .map(|(p, _)| Reverse(*p))
        .collect();
    let mut order: Vec<String> = Vec::with_capacity(files.len());
    while let Some(Reverse(n)) = ready.pop() {
        order.push(n.to_string());
        if let Some(deps) = dependents.get(n) {
            let mut ds = deps.clone();
            ds.sort_unstable();
            for d in ds {
                let e = indeg.get_mut(d).unwrap();
                *e -= 1;
                if *e == 0 {
                    ready.push(Reverse(d));
                }
            }
        }
    }
    if order.len() != nodes.len() {
        let done: BTreeSet<&str> = order.iter().map(|s| s.as_str()).collect();
        let remaining = nodes
            .iter()
            .filter(|n| !done.contains(**n))
            .map(|s| s.to_string())
            .collect();
        return Err(CycleError { remaining });
    }
    Ok(order)
}

#[cfg(test)]
mod tests {
    use super::*;

    // Two independent nodes must come out in byte (name) order — reproducible.
    #[test]
    fn topo_order_is_name_sorted_for_independent_nodes() {
        let files = vec![("b.sql".to_string(), vec![]), ("a.sql".to_string(), vec![])];
        assert_eq!(topo_order(&files).unwrap(), vec!["a.sql", "b.sql"]);
    }

    // A dependency edge (file requires dep) orders dep first.
    #[test]
    fn topo_order_respects_intra_generated_edges() {
        let files = vec![
            ("ops.sql".to_string(), vec!["types.sql".to_string()]),
            ("types.sql".to_string(), vec![]),
            (
                "agg.sql".to_string(),
                vec!["ops.sql".to_string(), "types.sql".to_string()],
            ),
        ];
        let out = topo_order(&files).unwrap();
        let pos = |n: &str| out.iter().position(|x| x == n).unwrap();
        assert!(pos("types.sql") < pos("ops.sql"));
        assert!(pos("ops.sql") < pos("agg.sql"));
    }

    // Edges to files NOT in the set (hand-written prerequisites) are ignored:
    // they never block ordering and never appear in the output.
    #[test]
    fn topo_order_ignores_external_edges() {
        let files = vec![("t.sql".to_string(), vec!["src/v3/schema.sql".to_string()])];
        assert_eq!(topo_order(&files).unwrap(), vec!["t.sql"]);
    }

    // Identical input twice ⇒ identical output (determinism invariant).
    #[test]
    fn topo_order_is_deterministic() {
        let files = vec![
            ("c.sql".to_string(), vec!["a.sql".to_string()]),
            ("a.sql".to_string(), vec![]),
            ("b.sql".to_string(), vec!["a.sql".to_string()]),
        ];
        assert_eq!(topo_order(&files).unwrap(), topo_order(&files).unwrap());
        // a first, then b, c by name.
        assert_eq!(topo_order(&files).unwrap(), vec!["a.sql", "b.sql", "c.sql"]);
    }

    // A cycle is a hard error naming the stuck nodes.
    #[test]
    fn topo_order_detects_cycle() {
        let files = vec![
            ("a.sql".to_string(), vec!["b.sql".to_string()]),
            ("b.sql".to_string(), vec!["a.sql".to_string()]),
        ];
        let err = topo_order(&files).unwrap_err();
        assert!(err.remaining.contains(&"a.sql".to_string()));
        assert!(err.remaining.contains(&"b.sql".to_string()));
    }

    fn f(path: &str, deps: &[&str]) -> (String, Vec<String>) {
        (
            path.to_string(),
            deps.iter().map(|d| d.to_string()).collect(),
        )
    }

    // The happy path: every target is a node under src/v3, and edges are honoured.
    #[test]
    fn surface_order_linearizes_a_valid_surface() {
        let files = vec![
            f("src/v3/ops.sql", &["src/v3/types.sql"]),
            f("src/v3/types.sql", &["src/v3/schema.sql"]),
            f("src/v3/schema.sql", &[]),
            f("src/v3/orphan.sql", &[]), // no edges: must still be emitted
        ];
        let out = surface_order(&files).unwrap();
        let pos = |n: &str| out.iter().position(|x| x == n).unwrap();
        assert!(pos("src/v3/schema.sql") < pos("src/v3/types.sql"));
        assert!(pos("src/v3/types.sql") < pos("src/v3/ops.sql"));
        assert!(out.contains(&"src/v3/orphan.sql".to_string()));
        assert_eq!(out.len(), 4);
    }

    // A REQUIRE naming a file that is not in the surface is a hard error. This is
    // the gate the old shell `verify_deps_exist` could not express.
    #[test]
    fn surface_order_rejects_unknown_target() {
        let files = vec![f("src/v3/a.sql", &["src/v3/missing.sql"])];
        let err = surface_order(&files).unwrap_err();
        let OrderError::UnknownTargets(v) = &err else {
            panic!("expected UnknownTargets, got {err:?}");
        };
        assert_eq!(
            v.as_slice(),
            &[("src/v3/a.sql".into(), "src/v3/missing.sql".into())]
        );
        assert!(err.to_string().contains("src/v3/missing.sql"));
    }

    // An edge leaving src/v3 breaks self-containment, and is reported as such
    // rather than as a generic unknown target.
    #[test]
    fn surface_order_rejects_target_outside_the_surface() {
        let files = vec![f("src/v3/a.sql", &["src/v2/x.sql"]), f("src/v2/x.sql", &[])];
        let err = surface_order(&files).unwrap_err();
        assert!(
            matches!(err, OrderError::OutsideSurface(_)),
            "expected OutsideSurface, got {err:?}"
        );
        assert!(err.to_string().contains("self-contained"));
    }

    // `src/v3xyz/` must not pass the prefix check on a bare `starts_with("src/v3")`.
    #[test]
    fn surface_order_prefix_check_is_path_segment_exact() {
        let files = vec![f("src/v3/a.sql", &["src/v3suffix/x.sql"])];
        assert!(matches!(
            surface_order(&files).unwrap_err(),
            OrderError::OutsideSurface(_)
        ));
    }

    // A cycle surfaces as a cycle, not as a silently truncated order.
    #[test]
    fn surface_order_propagates_cycles() {
        let files = vec![
            f("src/v3/a.sql", &["src/v3/b.sql"]),
            f("src/v3/b.sql", &["src/v3/a.sql"]),
        ];
        assert!(matches!(
            surface_order(&files).unwrap_err(),
            OrderError::Cycle(_)
        ));
    }

    // Identical input twice => identical output. The build's byte-reproducibility
    // rests on this (the monolith is concatenated in this order).
    #[test]
    fn surface_order_is_deterministic() {
        let files = vec![
            f("src/v3/c.sql", &["src/v3/a.sql"]),
            f("src/v3/a.sql", &[]),
            f("src/v3/b.sql", &["src/v3/a.sql"]),
        ];
        assert_eq!(
            surface_order(&files).unwrap(),
            surface_order(&files).unwrap()
        );
        assert_eq!(
            surface_order(&files).unwrap(),
            vec!["src/v3/a.sql", "src/v3/b.sql", "src/v3/c.sql"]
        );
    }

    // The walk finds nested files, reads their edges, skips `*_test.sql`, and is
    // blind to the generated/hand-written marker (both kinds are ordered together).
    #[test]
    fn walk_v3_surface_collects_every_sql_file_with_its_edges() {
        let d = crate::writer::test_support::tempdir();
        let v3 = d.path().join("src/v3");
        fs::create_dir_all(v3.join("scalars/integer")).unwrap();
        fs::write(v3.join("schema.sql"), "CREATE SCHEMA eql_v3;\n").unwrap();
        fs::write(
            v3.join("scalars/ore_fallback.sql"),
            "-- AUTOMATICALLY GENERATED FILE.\n-- REQUIRE: src/v3/schema.sql\n",
        )
        .unwrap();
        fs::write(
            v3.join("scalars/integer/integer_types.sql"),
            "-- REQUIRE: src/v3/schema.sql\n",
        )
        .unwrap();
        fs::write(v3.join("scalars/integer/x_test.sql"), "SELECT 1;\n").unwrap();
        fs::write(v3.join("notes.md"), "not sql\n").unwrap();

        let files = walk_v3_surface(d.path()).unwrap();
        let paths: Vec<&str> = files.iter().map(|(p, _)| p.as_str()).collect();
        // Path-sorted, so `scalars/` precedes `schema.sql`. The walk order carries
        // no dependency meaning — surface_order supplies that, below.
        assert_eq!(
            paths,
            vec![
                "src/v3/scalars/integer/integer_types.sql",
                "src/v3/scalars/ore_fallback.sql",
                "src/v3/schema.sql",
            ],
            "walk must be sorted, skip *_test.sql and non-sql, and include the \
             cross-family generated file the two-block build used to drop"
        );
        assert_eq!(files[1].1, vec!["src/v3/schema.sql"]);
        // And the walked surface linearizes: schema.sql moves ahead of its dependents.
        assert_eq!(surface_order(&files).unwrap()[0], "src/v3/schema.sql");
    }

    // A symlinked subdirectory is not followed: `file_type()` reports the link,
    // where `Path::is_dir()` would resolve it and walk outside the tree.
    #[cfg(unix)]
    #[test]
    fn walk_v3_surface_does_not_follow_symlinked_subdir() {
        let d = crate::writer::test_support::tempdir();
        let v3 = d.path().join("src/v3");
        fs::create_dir_all(&v3).unwrap();
        fs::write(v3.join("schema.sql"), "SELECT 1;\n").unwrap();
        let outside = d.path().join("outside");
        fs::create_dir_all(&outside).unwrap();
        fs::write(outside.join("stray.sql"), "SELECT 2;\n").unwrap();
        std::os::unix::fs::symlink(&outside, v3.join("linked")).unwrap();

        let files = walk_v3_surface(d.path()).unwrap();
        let paths: Vec<&str> = files.iter().map(|(p, _)| p.as_str()).collect();
        assert_eq!(paths, vec!["src/v3/schema.sql"]);
    }

    // requires_of reads back anchored `-- REQUIRE:` lines from a rendered body.
    #[test]
    fn requires_of_reads_anchored_directives() {
        let body = "-- AUTOMATICALLY GENERATED FILE.\n-- REQUIRE: src/v3/schema.sql\n-- REQUIRE: a.sql b.sql\nSELECT 1; -- REQUIRE in prose\n";
        assert_eq!(
            requires_of(body),
            vec![
                "src/v3/schema.sql".to_string(),
                "a.sql".to_string(),
                "b.sql".to_string()
            ]
        );
    }
}
