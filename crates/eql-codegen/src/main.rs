use std::path::PathBuf;
use std::process::ExitCode;

use eql_codegen::generate::generate_all;

fn repo_root() -> PathBuf {
    // The binary runs from the repo root via `cargo run`; CARGO_MANIFEST_DIR
    // points at crates/eql-codegen, so the repo root is two parents up.
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();

    // `list-types`: print catalog tokens, one per line. Consumed by Plan 3's
    // fixtures-all and matrix-inventory enumeration.
    if args.len() == 2 && args[1] == "list-types" {
        for spec in eql_scalars::CATALOG {
            println!("{}", spec.token);
        }
        return ExitCode::SUCCESS;
    }

    if args.len() == 1 {
        // No args: generate every type's SQL + <T>_values.rs.
        match generate_all(&repo_root()) {
            Ok(0) => return ExitCode::SUCCESS,
            Ok(_) => return ExitCode::FAILURE, // any non-zero codegen result is a failure
            Err(e) => {
                eprintln!("error: {e}");
                return ExitCode::FAILURE;
            }
        }
    }

    eprintln!("Usage: eql-codegen            (generate all types)");
    eprintln!("       eql-codegen list-types (print catalog tokens)");
    ExitCode::from(2)
}
