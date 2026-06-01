"""Top-level scalar encrypted-domain materializer."""

import sys
from collections.abc import Iterator
from pathlib import Path

from .operator_surface import (
    BLOCKER_ONLY_OPERATORS,
    PATH_OPERATORS,
    SYMMETRIC_OPERATORS,
    backing_function,
)
from .spec import DomainSpec, SpecError, TypeSpec, load_spec
from .templates import (
    AGGREGATE_OPS,
    domain_name,
    extractor_for_operator,
    is_ord_capable,
    render_aggregate,
    render_blocker_bool,
    render_blocker_native,
    render_blocker_path,
    render_domain_block,
    render_extractor,
    render_fixture_values_rs,
    render_operator,
    render_wrapper,
    role_phrase,
    supported_operators,
)
from .terms import TERM_CATALOG, Term, term_requires
from .writer import (
    clean_generated_files,
    ensure_generated_paths_writable,
    write_generated_file,
    write_generated_rs,
)

REPO_ROOT = Path(__file__).resolve().parents[2]


def _symmetric_shapes(dom: str) -> list[tuple[str, str]]:
    return [(dom, dom), (dom, "jsonb"), ("jsonb", dom)]


def _path_shapes(dom: str) -> list[tuple[str, str]]:
    return [(dom, "text"), (dom, "integer"), ("jsonb", dom)]


def _blocker_only_shapes(dom: str, op: str) -> list[tuple[str, str, str]]:
    if op in {"?", "?|", "?&"}:
        rhs = "text[]" if op in {"?|", "?&"} else "text"
        return [(dom, rhs, "boolean")]
    if op in {"@?", "@@"}:
        return [(dom, "jsonpath", "boolean")]
    if op == "#>":
        return [(dom, "text[]", "jsonb")]
    if op == "#>>":
        return [(dom, "text[]", "text")]
    if op == "-":
        return [(dom, "text", "jsonb"), (dom, "integer", "jsonb"), (dom, "text[]", "jsonb")]
    if op == "#-":
        return [(dom, "text[]", "jsonb")]
    if op == "||":
        return [(dom, dom, "jsonb"), (dom, "jsonb", "jsonb"), ("jsonb", dom, "jsonb")]
    raise ValueError(f"unhandled blocker-only operator: {op}")


def _types_path(token: str) -> str:
    return f"src/encrypted_domain/{token}/{token}_types.sql"


def fixture_values_rs_path(out_root: Path, token: str) -> Path:
    """Committed Rust fixture-value const for a type. Outside the gitignored
    src/encrypted_domain/ SQL tree because it is consumed (and committed) by
    the Rust test crate."""
    return (
        out_root / "tests" / "sqlx" / "src" / "fixtures" / f"{token}_values.rs"
    )


def render_types_file(spec: TypeSpec) -> str:
    """Body for <T>_types.sql: every domain in one idempotent DO block.

    Iteration order follows the manifest's declared order — the TOML file is
    the source of truth for emit order.
    """
    blocks = [render_domain_block(domain, spec.token) for domain in spec.domains]
    return (
        "-- REQUIRE: src/schema-v3.sql\n\n"
        f"--! @file encrypted_domain/{spec.token}/{spec.token}_types.sql\n"
        f"--! @brief Encrypted-domain type family for {spec.token}.\n\n"
        "DO $$\nBEGIN\n"
        + "\n".join(blocks)
        + "END\n$$;\n"
    )


def _functions_requires(spec: TypeSpec, domain: DomainSpec) -> list[str]:
    reqs = [
        "src/schema.sql",
        "src/schema-v3.sql",
        _types_path(spec.token),
        "src/encrypted_domain/functions.sql",
    ]
    for extra in term_requires(domain.terms):
        if extra not in reqs:
            reqs.append(extra)
    return reqs


def _extractor_terms(domain: DomainSpec) -> Iterator[Term]:
    seen: set[str] = set()
    for term_name in domain.terms:
        term = TERM_CATALOG[term_name]
        if term.extractor not in seen:
            seen.add(term.extractor)
            yield term


def render_functions_file(spec: TypeSpec, domain: DomainSpec) -> str:
    """Body for a domain's _functions.sql."""
    dom = domain_name(domain.name)
    supported = set(supported_operators(domain))
    parts: list[str] = []

    for term in _extractor_terms(domain):
        parts.append(render_extractor(domain, term))

    for op in SYMMETRIC_OPERATORS:
        extractor = extractor_for_operator(domain, op)
        for arg_a, arg_b in _symmetric_shapes(dom):
            if op in supported and extractor is not None:
                parts.append(render_wrapper(domain, op, arg_a, arg_b, extractor))
            else:
                parts.append(render_blocker_bool(domain, op, arg_a, arg_b))

    for op in PATH_OPERATORS:
        for arg_a, arg_b in _path_shapes(dom):
            parts.append(render_blocker_path(domain, op, arg_a, arg_b))

    for op in BLOCKER_ONLY_OPERATORS:
        for arg_a, arg_b, returns in _blocker_only_shapes(dom, op):
            parts.append(render_blocker_native(domain, op, arg_a, arg_b, returns))

    requires = "\n".join(f"-- REQUIRE: {r}" for r in _functions_requires(spec, domain))
    header = (
        requires + "\n\n"
        f"--! @file encrypted_domain/{spec.token}/{domain.name}_functions.sql\n"
        f"--! @brief {role_phrase(domain.terms)} domain of the {spec.token} "
        f"encrypted-domain family — comparison/path functions.\n\n"
    )
    return header + "\n".join(parts)


def render_operators_file(spec: TypeSpec, domain: DomainSpec) -> str:
    """Body for a domain's _operators.sql: 44 CREATE OPERATOR statements."""
    dom = domain_name(domain.name)
    supported = set(supported_operators(domain))
    parts: list[str] = []

    for op in SYMMETRIC_OPERATORS:
        backing = backing_function(op)
        for leftarg, rightarg in _symmetric_shapes(dom):
            parts.append(
                render_operator(
                    op, backing, leftarg, rightarg,
                    supported=op in supported,
                )
            )
    for op in PATH_OPERATORS:
        backing = backing_function(op)
        for leftarg, rightarg in _path_shapes(dom):
            parts.append(
                render_operator(op, backing, leftarg, rightarg, supported=False)
            )
    for op in BLOCKER_ONLY_OPERATORS:
        backing = backing_function(op)
        for leftarg, rightarg, _returns in _blocker_only_shapes(dom, op):
            parts.append(
                render_operator(op, backing, leftarg, rightarg, supported=False)
            )

    requires = (
        "-- REQUIRE: src/schema-v3.sql\n"
        f"-- REQUIRE: {_types_path(spec.token)}\n"
        f"-- REQUIRE: src/encrypted_domain/{spec.token}/"
        f"{domain.name}_functions.sql\n"
    )
    header = (
        requires + "\n"
        f"--! @file encrypted_domain/{spec.token}/{domain.name}_operators.sql\n"
        f"--! @brief {role_phrase(domain.terms)} domain of the {spec.token} "
        f"encrypted-domain family — operator declarations.\n\n"
    )
    return header + "\n".join(parts)


def render_aggregates_file(spec: TypeSpec, domain: DomainSpec) -> str | None:
    """Body for a domain's _aggregates.sql, or None if the domain has no
    ordering comparator (storage/eq variants have no MIN/MAX semantics)."""
    if not is_ord_capable(domain):
        return None
    parts = [render_aggregate(domain, AGGREGATE_OPS[name]) for name in ("min", "max")]
    requires = (
        "-- REQUIRE: src/schema-v3.sql\n"
        f"-- REQUIRE: {_types_path(spec.token)}\n"
        f"-- REQUIRE: src/encrypted_domain/{spec.token}/"
        f"{domain.name}_functions.sql\n"
        f"-- REQUIRE: src/encrypted_domain/{spec.token}/"
        f"{domain.name}_operators.sql\n"
    )
    header = (
        requires + "\n"
        f"--! @file encrypted_domain/{spec.token}/{domain.name}_aggregates.sql\n"
        f"--! @brief {role_phrase(domain.terms)} domain of the {spec.token} "
        f"encrypted-domain family — MIN/MAX aggregates.\n\n"
    )
    return header + "\n".join(parts)


def generate_type(spec: TypeSpec, out_dir: Path) -> list[Path]:
    """Regenerate every generated file for a type."""
    out_dir = Path(out_dir)
    target_paths = [out_dir / f"{spec.token}_types.sql"]
    for domain in spec.domains:
        target_paths.append(out_dir / f"{domain.name}_functions.sql")
        target_paths.append(out_dir / f"{domain.name}_operators.sql")
        if is_ord_capable(domain):
            target_paths.append(out_dir / f"{domain.name}_aggregates.sql")
    ensure_generated_paths_writable(target_paths)
    clean_generated_files(out_dir)

    written: list[Path] = []

    types_path = out_dir / f"{spec.token}_types.sql"
    write_generated_file(types_path, render_types_file(spec))
    written.append(types_path)

    for domain in spec.domains:
        fn_path = out_dir / f"{domain.name}_functions.sql"
        write_generated_file(fn_path, render_functions_file(spec, domain))
        written.append(fn_path)

        op_path = out_dir / f"{domain.name}_operators.sql"
        write_generated_file(op_path, render_operators_file(spec, domain))
        written.append(op_path)

        agg_body = render_aggregates_file(spec, domain)
        if agg_body is not None:
            agg_path = out_dir / f"{domain.name}_aggregates.sql"
            write_generated_file(agg_path, agg_body)
            written.append(agg_path)

    return written


DEFAULT_TYPES_DIR = Path(__file__).parent / "types"


def generate_one(token: str, *, types_dir: Path, out_root: Path) -> int:
    """Regenerate one type from types_dir/<token>.toml.

    Returns 0 on success, 1 when the manifest is missing or its inferred token
    does not match. A malformed manifest raises SpecError — the caller decides
    whether to surface it (single-type CLI) or aggregate it (--all)."""
    toml_path = types_dir / f"{token}.toml"
    if not toml_path.is_file():
        print(f"error: no manifest at {toml_path}", file=sys.stderr)
        return 1
    spec = load_spec(toml_path)
    if spec.token != token:
        print(
            f"error: manifest token '{spec.token}' does not match '{token}'",
            file=sys.stderr,
        )
        return 1
    out_dir = out_root / "src" / "encrypted_domain" / token
    written = generate_type(spec, out_dir)

    if spec.fixture_values is not None:
        rs_path = fixture_values_rs_path(out_root, token)
        write_generated_rs(rs_path, render_fixture_values_rs(spec))
        written.append(rs_path)

    for path in written:
        print(f"generated {path.relative_to(out_root)}")
    print(f"generated {len(written)} files for {token}")
    return 0


def generate_all(*, types_dir: Path, out_root: Path) -> int:
    """Regenerate every type whose manifest lives in types_dir.

    Iterates sorted(types_dir.glob('*.toml')) for deterministic order and
    aggregates return codes: a missing/mismatched/malformed manifest is
    reported and counted as a failure without aborting the remaining types."""
    tokens = [p.stem for p in sorted(types_dir.glob("*.toml"))]
    if not tokens:
        print(f"error: no manifests found in {types_dir}", file=sys.stderr)
        return 1
    rc = 0
    for token in tokens:
        try:
            if generate_one(token, types_dir=types_dir, out_root=out_root) != 0:
                rc = 1
        except SpecError as exc:
            print(f"error: {token}: {exc}", file=sys.stderr)
            rc = 1
    status = "ok" if rc == 0 else "FAILED"
    print(f"codegen --all: {status} ({len(tokens)} types: {', '.join(tokens)})")
    return rc


def main(
    argv: list[str],
    *,
    types_dir: Path | None = None,
    out_root: Path | None = None,
) -> int:
    """CLI entrypoint: generate <type>, or --all for every manifest."""
    types_dir = types_dir or DEFAULT_TYPES_DIR
    out_root = out_root or REPO_ROOT
    if len(argv) == 2 and argv[1] == "--all":
        return generate_all(types_dir=types_dir, out_root=out_root)
    if len(argv) != 2:
        print("Usage: generate.py <type> | generate.py --all", file=sys.stderr)
        return 2
    return generate_one(argv[1], types_dir=types_dir, out_root=out_root)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
