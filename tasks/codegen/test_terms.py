"""Tests for the fixed scalar-domain term catalog."""

import pytest

from tasks.codegen.terms import (
    TermError,
    extractor_for_operator,
    operators_for_terms,
    require_terms,
    role_for_terms,
    term_json_keys,
    term_requires,
)


def test_hm_term_provides_equality():
    terms = require_terms(["hm"])
    hm = terms[0]
    assert hm.name == "hm"
    assert hm.json_key == "hm"
    assert hm.extractor == "eq_term"
    assert hm.returns == "eql_v2.hmac_256"
    assert hm.ctor == "hmac_256"
    assert hm.role == "eq"
    assert hm.operators == ("=", "<>")
    assert hm.requires == ("src/hmac_256/functions.sql",)


def test_ore_term_preserves_existing_int4_sql_contract():
    terms = require_terms(["ore"])
    ore = terms[0]
    assert ore.name == "ore"
    assert ore.json_key == "ob"
    assert ore.extractor == "ord_term"
    assert ore.returns == "eql_v2.ore_block_u64_8_256"
    assert ore.ctor == "ore_block_u64_8_256"
    assert ore.role == "ord"
    assert ore.operators == ("=", "<>", "<", "<=", ">", ">=")
    assert ore.requires == (
        "src/ore_block_u64_8_256/functions.sql",
        "src/ore_block_u64_8_256/operators.sql",
    )


def test_unknown_term_raises():
    with pytest.raises(TermError, match="unknown term 'bogus'"):
        require_terms(["bogus"])


def test_operators_are_union_in_catalog_order():
    assert operators_for_terms(["ore", "hm"]) == [
        "=", "<>", "<", "<=", ">", ">=",
    ]


def test_json_keys_come_from_catalog_not_manifest_names():
    assert term_json_keys(["hm", "ore"]) == ["hm", "ob"]


def test_term_requires_are_deduplicated():
    assert term_requires(["ore", "ore", "hm"]) == [
        "src/ore_block_u64_8_256/functions.sql",
        "src/ore_block_u64_8_256/operators.sql",
        "src/hmac_256/functions.sql",
    ]


def test_role_for_terms_handles_storage_eq_ord():
    assert role_for_terms([]) == "storage"
    assert role_for_terms(["hm"]) == "eq"
    assert role_for_terms(["ore"]) == "ord"


def test_operators_for_terms_handles_empty_list():
    assert operators_for_terms([]) == []


def test_term_json_keys_handles_empty_list():
    assert term_json_keys([]) == []


def test_term_requires_handles_empty_list():
    assert term_requires([]) == []


def test_extractor_for_operator_picks_first_term_supporting_op():
    assert extractor_for_operator(["hm"], "=") == "eq_term"
    assert extractor_for_operator(["ore"], "<") == "ord_term"
    # Multi-term domains: first supporting term wins.
    assert extractor_for_operator(["hm", "ore"], "=") == "eq_term"
    assert extractor_for_operator(["hm", "ore"], "<") == "ord_term"


def test_extractor_for_operator_returns_none_when_no_term_supports_op():
    assert extractor_for_operator(["hm"], "<") is None
    assert extractor_for_operator([], "=") is None
