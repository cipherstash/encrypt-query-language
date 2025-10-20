//! Build tool for extracting SQL files in dependency order

use anyhow::Result;
use std::fs;

mod builder;

use builder::Builder;

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: eql-build <database>");
        eprintln!("  database: postgres");
        std::process::exit(1);
    }

    let database = &args[1];

    match database.as_str() {
        "postgres" => build_postgres()?,
        _ => anyhow::bail!("Unknown database: {}", database),
    }

    Ok(())
}

fn build_postgres() -> Result<()> {
    use eql_postgres::config::AddColumn;
    use eql_core::Component;

    println!("Building PostgreSQL installer...");

    let mut builder = Builder::new("CipherStash EQL for PostgreSQL");

    // Use automatic dependency resolution
    let deps = AddColumn::collect_dependencies();
    println!("Resolved {} dependencies", deps.len());

    for (i, sql_file) in deps.iter().enumerate() {
        println!("  {}. {}", i + 1, sql_file.split('/').last().unwrap_or(sql_file));
        builder.add_sql_file(sql_file)?;
    }

    // Write output
    fs::create_dir_all("release")?;
    let output = builder.build();
    fs::write("release/cipherstash-encrypt-postgres-poc.sql", output)?;

    println!("✓ Generated release/cipherstash-encrypt-postgres-poc.sql");

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_build_creates_output_file() {
        // Clean up any previous output
        let _ = std::fs::remove_file("release/cipherstash-encrypt-postgres-poc.sql");

        // Run build
        build_postgres().expect("Build should succeed");

        // Verify output exists
        assert!(
            std::path::Path::new("release/cipherstash-encrypt-postgres-poc.sql").exists(),
            "Build should create output file"
        );

        // Verify it contains expected SQL
        let content = std::fs::read_to_string("release/cipherstash-encrypt-postgres-poc.sql")
            .expect("Should be able to read output");

        assert!(content.contains("eql_v2_configuration_state"), "Should contain config types");
        assert!(content.contains("CREATE FUNCTION eql_v2.add_column"), "Should contain add_column function");
        assert!(content.contains("CREATE FUNCTION eql_v2.config_default"), "Should contain helper functions");
    }

    #[test]
    fn test_build_dependency_order() {
        build_postgres().expect("Build should succeed");

        let content = std::fs::read_to_string("release/cipherstash-encrypt-postgres-poc.sql")
            .expect("Should be able to read output");

        // types.sql should come before functions_private.sql
        let types_pos = content.find("eql_v2_configuration_state")
            .expect("Should contain types");
        let private_pos = content.find("CREATE FUNCTION eql_v2.config_default")
            .expect("Should contain private functions");

        assert!(
            types_pos < private_pos,
            "Types should be defined before functions that use them"
        );

        // check_encrypted should come before add_encrypted_constraint
        let check_pos = content.find("CREATE FUNCTION eql_v2.check_encrypted")
            .expect("Should contain check_encrypted");
        let constraint_pos = content.find("CREATE FUNCTION eql_v2.add_encrypted_constraint")
            .expect("Should contain add_encrypted_constraint");

        assert!(
            check_pos < constraint_pos,
            "check_encrypted should be defined before add_encrypted_constraint"
        );
    }
}
