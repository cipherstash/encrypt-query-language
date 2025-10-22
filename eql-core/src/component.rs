//! Component trait for SQL file dependencies

/// Declare a SQL component with automatic path inference and boilerplate reduction.
///
/// This macro generates a component struct and its `Component` trait implementation,
/// automatically inferring the SQL file path from the module and component name.
///
/// # Syntax
///
/// ```ignore
/// // Infer path from module::ComponentName (converts PascalCase → snake_case)
/// sql_component!(config::AddColumn);
/// sql_component!(config::AddColumn, deps: [Dep1, Dep2, ...]);
///
/// // Override path when it doesn't match convention
/// sql_component!(config::ConfigTypes => "types.sql");
/// sql_component!(config::ConfigTypes => "types.sql", deps: [Dep1]);
///
/// // Full custom path
/// sql_component!(RemoveColumn => "not_implemented.sql");
/// ```
///
/// # Examples
///
/// ```ignore
/// // Simple component, infers "config/add_column.sql"
/// sql_component!(config::AddColumn, deps: [
///     ConfigPrivateFunctions,
///     MigrateActivate,
/// ]);
///
/// // Override filename (still in config/ directory)
/// sql_component!(config::ConfigTypes => "types.sql");
///
/// // Custom path (not following module structure)
/// sql_component!(Placeholder => "not_implemented.sql");
/// ```
#[macro_export]
macro_rules! sql_component {
    // Pattern 1: module::Component (no deps, infer path)
    ($module:ident :: $name:ident) => {
        $crate::paste::paste! {
            pub struct $name;

            impl $crate::Component for $name {
                type Dependencies = ();

                fn sql_file() -> &'static str {
                    concat!(
                        env!("CARGO_MANIFEST_DIR"),
                        "/src/sql/",
                        stringify!($module),
                        "/",
                        stringify!([<$name:snake>]),
                        ".sql"
                    )
                }
            }
        }
    };

    // Pattern 2: module::Component with single dependency (infer path)
    ($module:ident :: $name:ident, deps: [$dep:ty]) => {
        $crate::paste::paste! {
            pub struct $name;

            impl $crate::Component for $name {
                type Dependencies = $dep;

                fn sql_file() -> &'static str {
                    concat!(
                        env!("CARGO_MANIFEST_DIR"),
                        "/src/sql/",
                        stringify!($module),
                        "/",
                        stringify!([<$name:snake>]),
                        ".sql"
                    )
                }
            }
        }
    };

    // Pattern 3: module::Component with multiple dependencies (infer path)
    ($module:ident :: $name:ident, deps: [$dep1:ty, $dep2:ty $(, $deps:ty)* $(,)?]) => {
        $crate::paste::paste! {
            pub struct $name;

            impl $crate::Component for $name {
                type Dependencies = ($dep1, $dep2 $(, $deps)*);

                fn sql_file() -> &'static str {
                    concat!(
                        env!("CARGO_MANIFEST_DIR"),
                        "/src/sql/",
                        stringify!($module),
                        "/",
                        stringify!([<$name:snake>]),
                        ".sql"
                    )
                }
            }
        }
    };

    // Pattern 4: module::Component => "filename.sql" (override filename, keep module)
    ($module:ident :: $name:ident => $filename:literal) => {
        pub struct $name;

        impl $crate::Component for $name {
            type Dependencies = ();

            fn sql_file() -> &'static str {
                concat!(
                    env!("CARGO_MANIFEST_DIR"),
                    "/src/sql/",
                    stringify!($module),
                    "/",
                    $filename
                )
            }
        }
    };

    // Pattern 5: module::Component => "filename.sql" with single dependency
    ($module:ident :: $name:ident => $filename:literal, deps: [$dep:ty]) => {
        pub struct $name;

        impl $crate::Component for $name {
            type Dependencies = $dep;

            fn sql_file() -> &'static str {
                concat!(
                    env!("CARGO_MANIFEST_DIR"),
                    "/src/sql/",
                    stringify!($module),
                    "/",
                    $filename
                )
            }
        }
    };

    // Pattern 6: module::Component => "filename.sql" with multiple dependencies
    ($module:ident :: $name:ident => $filename:literal, deps: [$dep1:ty, $dep2:ty $(, $deps:ty)* $(,)?]) => {
        pub struct $name;

        impl $crate::Component for $name {
            type Dependencies = ($dep1, $dep2 $(, $deps)*);

            fn sql_file() -> &'static str {
                concat!(
                    env!("CARGO_MANIFEST_DIR"),
                    "/src/sql/",
                    stringify!($module),
                    "/",
                    $filename
                )
            }
        }
    };

    // Pattern 7: Component => "full/path.sql" (complete path override, no module)
    ($name:ident => $path:literal) => {
        pub struct $name;

        impl $crate::Component for $name {
            type Dependencies = ();

            fn sql_file() -> &'static str {
                concat!(env!("CARGO_MANIFEST_DIR"), "/src/sql/", $path)
            }
        }
    };

    // Pattern 8: Component => "full/path.sql" with single dependency
    ($name:ident => $path:literal, deps: [$dep:ty]) => {
        pub struct $name;

        impl $crate::Component for $name {
            type Dependencies = $dep;

            fn sql_file() -> &'static str {
                concat!(env!("CARGO_MANIFEST_DIR"), "/src/sql/", $path)
            }
        }
    };

    // Pattern 9: Component => "full/path.sql" with multiple dependencies
    ($name:ident => $path:literal, deps: [$dep1:ty, $dep2:ty $(, $deps:ty)* $(,)?]) => {
        pub struct $name;

        impl $crate::Component for $name {
            type Dependencies = ($dep1, $dep2 $(, $deps)*);

            fn sql_file() -> &'static str {
                concat!(env!("CARGO_MANIFEST_DIR"), "/src/sql/", $path)
            }
        }
    };
}

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
