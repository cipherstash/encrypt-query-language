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

    // `ledger <raw-log> <out-json>`: normalize a captured logging-Postgres raw
    // log into the per-statement ledger keyed on the inline /* eqlmatrix:… */
    // tag. Consumed by the Stage 4 matcher. No judgement happens here.
    //
    // The raw log is read as a stream (line-by-line, gunzipped when the path ends
    // in `.gz`) so a multi-GB capture is never held whole in memory.
    if args.len() == 4 && args[1] == "ledger" {
        let reader = match eql_codegen::ledger::open_log_reader(std::path::Path::new(&args[2])) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("error: reading raw log {}: {e}", args[2]);
                return ExitCode::FAILURE;
            }
        };
        let ledger = eql_codegen::ledger::parse_ledger_reader(reader);
        let json = serde_json::to_string_pretty(&ledger).expect("serialize ledger");
        if let Err(e) = std::fs::write(&args[3], json) {
            eprintln!("error: writing ledger {}: {e}", args[3]);
            return ExitCode::FAILURE;
        }
        eprintln!("wrote ledger with {} records to {}", ledger.records.len(), args[3]);
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
    eprintln!("       eql-codegen ledger <raw-log> <out-json> (normalize a capture log to a ledger)");
    ExitCode::from(2)
}
