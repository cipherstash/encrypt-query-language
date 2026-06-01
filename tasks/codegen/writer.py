"""File writer enforcing the AUTO-GENERATED-header ownership rule.

The generator owns only files carrying the AUTO-GENERATED header. It
preflights expected output paths, deletes generated files to clear stale
orphans, and refuses to overwrite a hand-written file at a generated path.
"""

from pathlib import Path

from .templates import AUTO_GENERATED_HEADER, AUTO_GENERATED_HEADER_RS

# The first line of each header is the ownership marker.
_MARKER = AUTO_GENERATED_HEADER.splitlines()[0]
_RS_MARKER = AUTO_GENERATED_HEADER_RS.splitlines()[0]


class OwnershipError(Exception):
    """Raised when the generator would clobber a hand-written file."""


def _first_line(path: Path) -> str:
    with path.open("r", encoding="utf-8") as fh:
        return fh.readline().rstrip("\r\n")


def is_generated(path: Path) -> bool:
    """True if the file at `path` carries the SQL AUTO-GENERATED marker."""
    if not path.is_file():
        return False
    return _first_line(path) == _MARKER


def is_generated_rs(path: Path) -> bool:
    """True if the file at `path` carries the Rust AUTO-GENERATED marker."""
    if not path.is_file():
        return False
    return _first_line(path) == _RS_MARKER


def clean_generated_files(directory: Path) -> list[Path]:
    """Delete every generated .sql file in `directory`. Returns the list
    of removed paths. Hand-written files are left untouched. A no-op on a
    directory that does not exist or holds no generated files."""
    directory = Path(directory)
    if not directory.is_dir():
        return []
    removed: list[Path] = []
    for path in sorted(directory.glob("*.sql")):
        if is_generated(path):
            path.unlink()
            removed.append(path)
    return removed


def ensure_generated_paths_writable(paths: list[Path]) -> None:
    """Refuse a generation run before cleanup if any target is hand-written."""
    for path in paths:
        path = Path(path)
        if path.exists() and not is_generated(path):
            raise OwnershipError(
                f"refusing to overwrite hand-written file: {path} "
                f"(no AUTO-GENERATED header). Remove it by hand if it is a "
                f"one-time generator-adoption target."
            )


def write_generated_file(path: Path, body: str) -> None:
    """Write `body` to `path`, prefixed with the SQL AUTO-GENERATED header.

    Refuses (OwnershipError) if `path` exists and is hand-written — a file
    at a generated path that lacks the header is never clobbered."""
    path = Path(path)
    ensure_generated_paths_writable([path])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(AUTO_GENERATED_HEADER + body, encoding="utf-8")


def write_generated_rs(path: Path, body: str) -> None:
    """Write `body` to a Rust file, prefixed with the Rust AUTO-GENERATED
    header. Unlike the SQL surface this file is committed; the header still
    guards against clobbering a hand-written file at the same path."""
    path = Path(path)
    if path.exists() and not is_generated_rs(path):
        raise OwnershipError(
            f"refusing to overwrite hand-written file: {path} "
            f"(no AUTO-GENERATED header)."
        )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(AUTO_GENERATED_HEADER_RS + body, encoding="utf-8")
