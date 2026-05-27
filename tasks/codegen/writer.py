"""File writer enforcing the AUTO-GENERATED-header ownership rule.

The generator owns only files carrying the AUTO-GENERATED header. It
preflights expected output paths, deletes generated files to clear stale
orphans, and refuses to overwrite a hand-written file at a generated path.
"""

from pathlib import Path

from .templates import AUTO_GENERATED_HEADER

# The first line of the header is the ownership marker.
_MARKER = AUTO_GENERATED_HEADER.splitlines()[0]


class OwnershipError(Exception):
    """Raised when the generator would clobber a hand-written file."""


def is_generated(path: Path) -> bool:
    """True if the file at `path` carries the AUTO-GENERATED marker."""
    if not path.is_file():
        return False
    with path.open("r", encoding="utf-8") as fh:
        first = fh.readline()
    return first.rstrip("\r\n") == _MARKER


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
    """Write `body` to `path`, prefixed with the AUTO-GENERATED header.

    Refuses (OwnershipError) if `path` exists and is hand-written — a file
    at a generated path that lacks the header is never clobbered."""
    path = Path(path)
    ensure_generated_paths_writable([path])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(AUTO_GENERATED_HEADER + body, encoding="utf-8")
