"""Minimal TOML manifest loader for scalar encrypted-domain codegen."""

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path

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

    return TypeSpec(token=token, domains=domains)
