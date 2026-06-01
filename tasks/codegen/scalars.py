"""Fixed scalar-kind catalog for fixture-value emission.

A `ScalarKind` knows how to turn a manifest fixture-value token into a Rust
literal of the type's native Rust scalar, and how to resolve it to a numeric
value for the MIN/MAX/zero invariant check. The manifest carries only the
list of value tokens; the per-type behaviour lives here (mirroring terms.py),
not in free-form TOML fields.

Recognised sentinels are ``MIN`` / ``MAX`` / ``ZERO``; every other token is a
numeric literal validated against the type's representable range.
"""

from dataclasses import dataclass


class ScalarError(Exception):
    """Raised for an unknown scalar token or an invalid fixture value."""


_SENTINELS = ("MIN", "MAX", "ZERO")


@dataclass(frozen=True)
class ScalarKind:
    """One scalar type's Rust rendering rules for fixture values."""

    token: str
    rust_type: str
    min_symbol: str
    max_symbol: str
    zero_symbol: str
    min_value: int
    max_value: int

    def _parse(self, value: str) -> int:
        if value == "MIN":
            return self.min_value
        if value == "MAX":
            return self.max_value
        if value == "ZERO":
            return 0
        try:
            n = int(value)
        except ValueError as exc:
            raise ScalarError(
                f"{self.token}: {value!r} is not a valid {self.rust_type} "
                f"literal or sentinel ({'/'.join(_SENTINELS)})"
            ) from exc
        if not (self.min_value <= n <= self.max_value):
            raise ScalarError(
                f"{self.token}: {value!r} out of range for {self.rust_type} "
                f"[{self.min_value}, {self.max_value}]"
            )
        return n

    def numeric_value(self, value: str) -> int:
        """Resolve a fixture token to its numeric value (validates range)."""
        return self._parse(value)

    def render_literal(self, value: str) -> str:
        """Render a fixture token as a Rust literal of this scalar type."""
        symbols = {
            "MIN": self.min_symbol,
            "MAX": self.max_symbol,
            "ZERO": self.zero_symbol,
        }
        if value in symbols:
            return symbols[value]
        return str(self._parse(value))


SCALAR_KINDS: dict[str, ScalarKind] = {
    "int4": ScalarKind(
        token="int4",
        rust_type="i32",
        min_symbol="i32::MIN",
        max_symbol="i32::MAX",
        zero_symbol="0",
        min_value=-2147483648,
        max_value=2147483647,
    ),
}


def require_scalar(token: str) -> ScalarKind:
    """Return the catalog kind for `token`, or raise ScalarError."""
    try:
        return SCALAR_KINDS[token]
    except KeyError as exc:
        raise ScalarError(
            f"unknown scalar token '{token}' "
            f"(expected one of {sorted(SCALAR_KINDS)})"
        ) from exc
