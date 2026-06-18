use std::process::ExitCode;

use eql_codegen::generate::generate_all;
use eql_codegen::repo_root;

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

    // `dump-catalog`: print the catalog surface (types → domains →
    // supported operators) as JSON. Consumed by test:matrix:catalog-coverage
    // (Stage 1) and the log-verification matcher (Stage 4).
    if args.len() == 2 && args[1] == "dump-catalog" {
        let dump = eql_codegen::dump::dump_catalog();
        println!(
            "{}",
            serde_json::to_string_pretty(&dump).expect("serialize catalog dump")
        );
        return ExitCode::SUCCESS;
    }

    if args.len() == 1 {
        // No args: generate every type's gitignored SQL surface.
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
    eprintln!("       eql-codegen dump-catalog (print catalog surface as JSON)");
    ExitCode::from(2)
}
