//! Deterministic topological ordering of the generated SQL surface.

use std::cmp::Reverse;
use std::collections::{BTreeMap, BTreeSet, BinaryHeap};

/// A dependency cycle among generated files — the topo-sort could not linearize.
#[derive(Debug)]
pub struct CycleError {
    /// The nodes that never reached in-degree 0 (participate in / are blocked by a cycle).
    pub remaining: Vec<String>,
}

impl std::fmt::Display for CycleError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "dependency cycle among generated files: {}", self.remaining.join(", "))
    }
}
impl std::error::Error for CycleError {}

/// Read back the anchored `-- REQUIRE:` targets from a rendered SQL body. The
/// body was produced in-process from the typed `requires` vec via the template,
/// so this is a deterministic readback of the same data — not the fragile
/// cross-platform shell glob of 220 on-disk files this refactor removes.
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
        let remaining = nodes.iter().filter(|n| !done.contains(**n)).map(|s| s.to_string()).collect();
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
        let files = vec![
            ("b.sql".to_string(), vec![]),
            ("a.sql".to_string(), vec![]),
        ];
        assert_eq!(topo_order(&files).unwrap(), vec!["a.sql", "b.sql"]);
    }

    // A dependency edge (file requires dep) orders dep first.
    #[test]
    fn topo_order_respects_intra_generated_edges() {
        let files = vec![
            ("ops.sql".to_string(), vec!["types.sql".to_string()]),
            ("types.sql".to_string(), vec![]),
            ("agg.sql".to_string(), vec!["ops.sql".to_string(), "types.sql".to_string()]),
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
        let files = vec![
            ("t.sql".to_string(), vec!["src/v3/schema.sql".to_string()]),
        ];
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

    // requires_of reads back anchored `-- REQUIRE:` lines from a rendered body.
    #[test]
    fn requires_of_reads_anchored_directives() {
        let body = "-- AUTOMATICALLY GENERATED FILE.\n-- REQUIRE: src/v3/schema.sql\n-- REQUIRE: a.sql b.sql\nSELECT 1; -- REQUIRE in prose\n";
        assert_eq!(
            requires_of(body),
            vec!["src/v3/schema.sql".to_string(), "a.sql".to_string(), "b.sql".to_string()]
        );
    }
}
