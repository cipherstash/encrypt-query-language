use std::path::PathBuf;
use std::process::ExitCode;

use eql_codegen::generate::{clean_all, generate_all};
use eql_codegen::repo_root;

/// Output root for the SQL surface. Defaults to the repo root; overridable via
/// `EQL_CODEGEN_OUT_ROOT` so `tasks/codegen-parity.sh` can regenerate into a
/// throwaway temp tree and leave the live `src/v3/scalars` untouched.
fn out_root() -> PathBuf {
    match std::env::var_os("EQL_CODEGEN_OUT_ROOT") {
        Some(p) => PathBuf::from(p),
        None => repo_root(),
    }
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();

    // `list-types`: print catalog tokens, one per line. Consumed by Plan 3's
    // fixtures-all and matrix-inventory enumeration.
    if args.len() == 2 && args[1] == "list-types" {
        for spec in eql_domains::scalar_families() {
            println!("{}", spec.name);
        }
        return ExitCode::SUCCESS;
    }

    // `list-schemas`: print the schemas the eql_v3 surface owns, public first,
    // one per line. Consumed by `mise run test:schemas:parity`, which compares
    // this against the SQL `eql_v3_internal.owned_schemas()` array in
    // src/v3/schema.sql so the Rust consts and the SQL cannot drift.
    if args.len() == 2 && args[1] == "list-schemas" {
        for schema in eql_codegen::owned_schemas() {
            println!("{schema}");
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

    // `bindings`: regenerate the committed Rust payload bindings under
    // crates/eql-bindings/src/v3. The default no-arg run stays SQL-only; this
    // is wired as the first step of `mise run types:generate`.
    if args.len() == 2 && args[1] == "bindings" {
        match eql_codegen::bindings::generate_bindings(&out_root()) {
            Ok(written) => {
                for p in &written {
                    let rel = p.strip_prefix(out_root()).unwrap_or(p);
                    println!("generated {}", rel.display());
                }
                println!("bindings: ok ({} files)", written.len());
                return ExitCode::SUCCESS;
            }
            Err(e) => {
                eprintln!("error: {e}");
                return ExitCode::FAILURE;
            }
        }
    }

    // `clean`: remove the generated SQL surface (marker-aware) under every
    // src/v3/scalars/* type dir. Replaces build.sh's filename-pattern sweep;
    // hand-written files (no AUTO-GENERATED marker) are preserved.
    if args.len() == 2 && args[1] == "clean" {
        match clean_all(&out_root()) {
            Ok(removed) => {
                for p in &removed {
                    let rel = p.strip_prefix(out_root()).unwrap_or(p);
                    println!("removed {}", rel.display());
                }
                println!("clean: ok ({} files)", removed.len());
                return ExitCode::SUCCESS;
            }
            Err(e) => {
                eprintln!("error: {e}");
                return ExitCode::FAILURE;
            }
        }
    }

    if args.len() == 1 {
        // No args: generate every type's gitignored SQL surface.
        match generate_all(&out_root()) {
            Ok(0) => return ExitCode::SUCCESS,
            Ok(_) => return ExitCode::FAILURE, // any non-zero codegen result is a failure
            Err(e) => {
                eprintln!("error: {e}");
                return ExitCode::FAILURE;
            }
        }
    }

    eprintln!("Usage: eql-codegen            (generate all types)");
    eprintln!("       eql-codegen clean      (remove the generated SQL surface)");
    eprintln!("       eql-codegen list-types (print catalog tokens)");
    eprintln!("       eql-codegen list-schemas (print owned schemas, public first)");
    eprintln!("       eql-codegen dump-catalog (print catalog surface as JSON)");
    eprintln!("       eql-codegen bindings   (regenerate eql-bindings Rust payload types)");
    ExitCode::from(2)
}
