"""Minimal TOML manifest loader for scalar encrypted-domain codegen."""

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path

from .scalars import ScalarError, require_scalar
from .terms import TermError, require_terms


_SQL_IDENTIFIER = re.compile(r"^[a-z][a-z0-9_]*$")


class SpecError(Exception):
    """Raised when a TOML manifest is missing or invalid."""


@dataclass(frozen=True)
class DomainSpec:
    """One generated public domain and the fixed terms it carries."""

    name: str
    terms: list[str]


@dataclass(frozen=True)
class TypeSpec:
    """A scalar encrypted-domain manifest loaded from one TOML file."""

    token: str
    domains: list[DomainSpec]
    fixture_values: list[str] | None = None


def _load_fixture_values(raw: dict, token: str) -> list[str] | None:
    """Parse and validate the optional [fixture] table.

    Returns the ordered list of value tokens, or None when no [fixture] table
    is present. The tokens are the manifest source of truth for the generated
    Rust fixture-value const; the scalar kind validates each one and the set
    must include MIN, MAX, and zero (the matrix comparison pivots)."""
    if "fixture" not in raw:
        return None

    fixture_table = raw["fixture"]
    if not isinstance(fixture_table, dict) or "values" not in fixture_table:
        raise SpecError("[fixture]: missing required key 'values'")

    values = fixture_table["values"]
    if not isinstance(values, list):
        raise SpecError("[fixture] values: must be a list of value tokens")
    if not values:
        raise SpecError("[fixture] values: must not be empty")
    if any(not isinstance(v, str) for v in values):
        raise SpecError("[fixture] values: must be strings")

    try:
        kind = require_scalar(token)
        resolved = [(v, kind.numeric_value(v)) for v in values]
        for v in values:
            kind.render_literal(v)
    except ScalarError as exc:
        raise SpecError(f"[fixture] values: {exc}") from exc

    # Distinct-plaintext contract: the matrix oracle treats each fixture value
    # as a distinct plaintext, and the generated Rust const must not repeat a
    # literal. Detect duplicates against the *resolved numeric* value so that
    # both copy-paste token dups ("1", "1") and sentinel/literal aliases
    # (e.g. "MIN" alongside the same number as a literal) are rejected.
    seen: dict[int, str] = {}
    duplicates: list[str] = []
    for token_value, number in resolved:
        if number in seen:
            duplicates.append(
                f"{token_value!r} duplicates {seen[number]!r} (both resolve to {number})"
                if token_value != seen[number]
                else f"{token_value!r}"
            )
        else:
            seen[number] = token_value
    if duplicates:
        raise SpecError(
            "[fixture] values: must be distinct, but found duplicate values: "
            + ", ".join(duplicates)
        )

    numbers = set(seen)
    if not ({kind.min_value, kind.max_value, 0} <= numbers):
        raise SpecError(
            "[fixture] values: must include MIN, MAX, and zero "
            "(the matrix comparison pivots)"
        )

    return list(values)


def load_spec(path: Path | str) -> TypeSpec:
    """Load and validate a per-type scalar-domain manifest."""
    path = Path(path)
    with path.open("rb") as fh:
        raw = tomllib.load(fh)

    if "domain" not in raw:
        raise SpecError("spec: missing required table '[domain]'")

    domain_table = raw["domain"]
    if not isinstance(domain_table, dict) or not domain_table:
        raise SpecError("[domain]: at least one domain is required")

    token = path.stem
    if not _SQL_IDENTIFIER.match(token):
        raise SpecError(
            f"spec: token {token!r} must match {_SQL_IDENTIFIER.pattern}"
        )
    domains: list[DomainSpec] = []
    for name, terms in domain_table.items():
        if not isinstance(name, str) or not _SQL_IDENTIFIER.match(name):
            raise SpecError(
                f"[domain] {name}: domain name {name!r} must match "
                f"{_SQL_IDENTIFIER.pattern}"
            )
        if name != token and not name.startswith(f"{token}_"):
            raise SpecError(
                f"[domain] {name}: domain name must start with '{token}'"
            )
        if not isinstance(terms, list):
            raise SpecError(
                f"[domain] {name}: value must be a list of term names"
            )
        if any(not isinstance(term, str) for term in terms):
            raise SpecError(f"[domain] {name}: term names must be strings")
        try:
            require_terms(list(terms))
        except TermError as exc:
            raise SpecError(f"[domain] {name}: {exc}") from exc
        domains.append(DomainSpec(name=name, terms=list(terms)))

    fixture_values = _load_fixture_values(raw, token)

    return TypeSpec(token=token, domains=domains, fixture_values=fixture_values)
