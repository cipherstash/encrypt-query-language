"""Encrypted-domain SQL code generator for EQL scalar domain families."""

from .generate import generate_type, main
from .spec import DomainSpec, SpecError, TypeSpec, load_spec
from .terms import TERM_CATALOG, Term, TermError

__all__ = [
    "DomainSpec",
    "SpecError",
    "TERM_CATALOG",
    "Term",
    "TermError",
    "TypeSpec",
    "generate_type",
    "load_spec",
    "main",
]
