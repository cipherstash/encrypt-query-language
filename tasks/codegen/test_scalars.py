"""Tests for the scalar-kind catalog driving fixture-value emission."""

import pytest

from tasks.codegen.scalars import (
    ScalarError,
    require_scalar,
    SCALAR_KINDS,
)


def test_int4_kind_fields():
    kind = require_scalar("int4")
    assert kind.token == "int4"
    assert kind.rust_type == "i32"
    assert kind.min_symbol == "i32::MIN"
    assert kind.max_symbol == "i32::MAX"
    assert kind.zero_symbol == "0"
    assert kind.min_value == -2147483648
    assert kind.max_value == 2147483647


def test_render_literal_maps_sentinels():
    kind = require_scalar("int4")
    assert kind.render_literal("MIN") == "i32::MIN"
    assert kind.render_literal("MAX") == "i32::MAX"
    assert kind.render_literal("ZERO") == "0"


def test_render_literal_passes_through_numeric():
    kind = require_scalar("int4")
    assert kind.render_literal("-100") == "-100"
    assert kind.render_literal("0") == "0"
    assert kind.render_literal("9999") == "9999"


def test_render_literal_rejects_non_numeric():
    kind = require_scalar("int4")
    with pytest.raises(ScalarError, match="not a valid i32 literal or sentinel"):
        kind.render_literal("oops")


def test_render_literal_rejects_out_of_range():
    kind = require_scalar("int4")
    with pytest.raises(ScalarError, match="out of range"):
        kind.render_literal("2147483648")  # i32::MAX + 1


def test_numeric_value_resolves_sentinels_and_literals():
    kind = require_scalar("int4")
    assert kind.numeric_value("MIN") == -2147483648
    assert kind.numeric_value("MAX") == 2147483647
    assert kind.numeric_value("ZERO") == 0
    assert kind.numeric_value("42") == 42
    assert kind.numeric_value("-1") == -1


def test_require_scalar_unknown_raises():
    with pytest.raises(ScalarError, match="unknown scalar token 'bogus'"):
        require_scalar("bogus")


def test_int4_registered_in_catalog():
    assert "int4" in SCALAR_KINDS
