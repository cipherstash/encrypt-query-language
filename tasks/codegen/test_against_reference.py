"""Identity guard: the generator must reproduce the frozen manual
reference under tests/codegen/reference/<T>/ byte-for-byte.

The reference is the reviewed manual implementation. If the generator's
output diverges from the reference, either the generator regressed (fix
it) or the reference is being deliberately updated (commit the new
reference in this PR).

Compares in-memory `render_*_file` output directly against the reference,
so it runs anywhere regardless of whether the build has materialised
src/encrypted_domain/<T>/ (those files are gitignored — `tasks/build.sh`
regenerates them on each build).
"""
from pathlib import Path

import pytest

from tasks.codegen.generate import (
    REPO_ROOT,
    render_aggregates_file,
    render_functions_file,
    render_operators_file,
    render_types_file,
)
from tasks.codegen.spec import load_spec

_REFERENCE_ROOT = REPO_ROOT / "tests" / "codegen" / "reference"
_TYPES_DIR = REPO_ROOT / "tasks" / "codegen" / "types"


def _strip_reference_marker(text: str) -> str:
    """Drop any leading `-- REFERENCE: ...` lines. They label the file as the
    parity baseline (see tests/codegen/reference/README.md) and are not part
    of the generator's output."""
    lines = text.splitlines(keepends=True)
    while lines and lines[0].startswith("-- REFERENCE:"):
        lines.pop(0)
    return "".join(lines)


def _reference_files() -> list[Path]:
    """Every SQL file under tests/codegen/reference/<T>/."""
    if not _REFERENCE_ROOT.is_dir():
        return []
    return sorted(_REFERENCE_ROOT.glob("*/*.sql"))


def _render(reference_path: Path) -> str:
    """Render the corresponding generator output for a reference file."""
    token = reference_path.parent.name
    name = reference_path.name
    spec = load_spec(_TYPES_DIR / f"{token}.toml")

    if name == f"{token}_types.sql":
        return render_types_file(spec)

    for domain in spec.domains:
        if name == f"{domain.name}_functions.sql":
            return render_functions_file(spec, domain)
        if name == f"{domain.name}_operators.sql":
            return render_operators_file(spec, domain)
        if name == f"{domain.name}_aggregates.sql":
            body = render_aggregates_file(spec, domain)
            if body is None:
                pytest.fail(
                    f"reference {reference_path.relative_to(REPO_ROOT)} exists "
                    f"but the generator skipped this variant (not ord-capable). "
                    f"Remove the reference file or update the manifest."
                )
            return body

    pytest.fail(f"unrecognised reference filename: {name}")


@pytest.mark.parametrize(
    "reference_path",
    _reference_files(),
    ids=lambda p: f"{p.parent.name}/{p.name}",
)
def test_generator_matches_manual_reference(reference_path: Path):
    """Generator render output must equal the reviewed reference."""
    token = reference_path.parent.name
    fix = (
        f"either the generator regressed (fix tasks/codegen/) or the "
        f"manual reference is being updated deliberately — commit the "
        f"new reference at {reference_path.relative_to(REPO_ROOT)} in "
        f"this PR. Regenerate via: mise run codegen:domain {token}"
    )

    expected = _strip_reference_marker(reference_path.read_text(encoding="utf-8"))
    actual = _render(reference_path)

    assert actual == expected, f"{reference_path.name}: {fix}"
