//! Component trait for SQL file dependencies

/// Marker trait for dependency specifications
pub trait Dependencies {
    /// Collect all dependency SQL files in dependency order (dependencies first)
    fn collect_sql_files(files: &mut Vec<&'static str>);
}

/// Unit type represents no dependencies
impl Dependencies for () {
    fn collect_sql_files(_files: &mut Vec<&'static str>) {
        // No dependencies
    }
}

/// Single dependency
impl<T: Component> Dependencies for T {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        // First collect transitive dependencies
        T::Dependencies::collect_sql_files(files);
        // Then add this dependency
        if !files.contains(&T::sql_file()) {
            files.push(T::sql_file());
        }
    }
}

/// Two dependencies
impl<A: Component, B: Component> Dependencies for (A, B) {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        A::Dependencies::collect_sql_files(files);
        if !files.contains(&A::sql_file()) {
            files.push(A::sql_file());
        }
        B::Dependencies::collect_sql_files(files);
        if !files.contains(&B::sql_file()) {
            files.push(B::sql_file());
        }
    }
}

/// Three dependencies
impl<A: Component, B: Component, C: Component> Dependencies for (A, B, C) {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        A::Dependencies::collect_sql_files(files);
        if !files.contains(&A::sql_file()) {
            files.push(A::sql_file());
        }
        B::Dependencies::collect_sql_files(files);
        if !files.contains(&B::sql_file()) {
            files.push(B::sql_file());
        }
        C::Dependencies::collect_sql_files(files);
        if !files.contains(&C::sql_file()) {
            files.push(C::sql_file());
        }
    }
}

/// Four dependencies
impl<A: Component, B: Component, C: Component, D: Component> Dependencies for (A, B, C, D) {
    fn collect_sql_files(files: &mut Vec<&'static str>) {
        A::Dependencies::collect_sql_files(files);
        if !files.contains(&A::sql_file()) {
            files.push(A::sql_file());
        }
        B::Dependencies::collect_sql_files(files);
        if !files.contains(&B::sql_file()) {
            files.push(B::sql_file());
        }
        C::Dependencies::collect_sql_files(files);
        if !files.contains(&C::sql_file()) {
            files.push(C::sql_file());
        }
        D::Dependencies::collect_sql_files(files);
        if !files.contains(&D::sql_file()) {
            files.push(D::sql_file());
        }
    }
}

/// A component represents a single SQL file with its dependencies
pub trait Component {
    /// Type specifying what this component depends on
    type Dependencies: Dependencies;

    /// Path to the SQL file containing this component's implementation
    fn sql_file() -> &'static str;

    /// Collect this component and all its dependencies in load order
    fn collect_dependencies() -> Vec<&'static str> {
        let mut files = Vec::new();
        // First collect all transitive dependencies
        Self::Dependencies::collect_sql_files(&mut files);
        // Then add self
        if !files.contains(&Self::sql_file()) {
            files.push(Self::sql_file());
        }
        files
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct A;
    impl Component for A {
        type Dependencies = ();
        fn sql_file() -> &'static str { "a.sql" }
    }

    struct B;
    impl Component for B {
        type Dependencies = A;
        fn sql_file() -> &'static str { "b.sql" }
    }

    struct C;
    impl Component for C {
        type Dependencies = (A, B);
        fn sql_file() -> &'static str { "c.sql" }
    }

    #[test]
    fn test_no_dependencies() {
        let deps = A::collect_dependencies();
        assert_eq!(deps, vec!["a.sql"]);
    }

    #[test]
    fn test_single_dependency() {
        let deps = B::collect_dependencies();
        assert_eq!(deps, vec!["a.sql", "b.sql"]);
    }

    #[test]
    fn test_multiple_dependencies() {
        let deps = C::collect_dependencies();
        assert_eq!(deps, vec!["a.sql", "b.sql", "c.sql"]);
    }

    #[test]
    fn test_deduplication() {
        // C depends on both A and B, but A should only appear once
        let deps = C::collect_dependencies();
        let a_count = deps.iter().filter(|&&f| f == "a.sql").count();
        assert_eq!(a_count, 1, "a.sql should only appear once");
    }
}
