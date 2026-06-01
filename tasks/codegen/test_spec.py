"""Tests for the scalar-domain manifest loader."""

import textwrap

import pytest

from tasks.codegen.spec import DomainSpec, SpecError, TypeSpec, load_spec


VALID_TOML = textwrap.dedent("""
    [domain]
    int4 = []
    int4_eq = ["hm"]
    int4_ord_ore = ["ore"]
    int4_ord = ["ore"]
""")


def write(tmp_path, name, text):
    p = tmp_path / name
    p.write_text(text)
    return p


def test_loads_valid_manifest_and_infers_token_from_filename(tmp_path):
    spec = load_spec(write(tmp_path, "int4.toml", VALID_TOML))
    assert isinstance(spec, TypeSpec)
    assert spec.token == "int4"
    assert spec.domains == [
        DomainSpec(name="int4", terms=[]),
        DomainSpec(name="int4_eq", terms=["hm"]),
        DomainSpec(name="int4_ord_ore", terms=["ore"]),
        DomainSpec(name="int4_ord", terms=["ore"]),
    ]


def test_missing_domain_table_raises(tmp_path):
    with pytest.raises(SpecError, match="missing required table '\\[domain\\]'"):
        load_spec(write(tmp_path, "int4.toml", ""))


def test_empty_domain_table_raises(tmp_path):
    with pytest.raises(SpecError, match="at least one domain"):
        load_spec(write(tmp_path, "int4.toml", "[domain]\n"))


def test_domain_value_must_be_list(tmp_path):
    bad = textwrap.dedent("""
        [domain]
        int4_eq = "hm"
    """)
    with pytest.raises(SpecError, match="must be a list of term names"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_domain_term_must_be_string(tmp_path):
    bad = textwrap.dedent("""
        [domain]
        int4_eq = [1]
    """)
    with pytest.raises(SpecError, match="term names must be strings"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_unknown_term_raises_with_domain_context(tmp_path):
    bad = textwrap.dedent("""
        [domain]
        int4_eq = ["bogus"]
    """)
    with pytest.raises(SpecError, match="\\[domain\\] int4_eq: unknown term 'bogus'"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_domain_name_must_start_with_type_token(tmp_path):
    bad = textwrap.dedent("""
        [domain]
        text = []
    """)
    with pytest.raises(SpecError, match="domain name must start with 'int4'"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_domain_name_must_be_token_or_token_underscore(tmp_path):
    bad = textwrap.dedent("""
        [domain]
        int4xfoo = []
    """)
    with pytest.raises(SpecError, match="domain name must start with 'int4'"):
        load_spec(write(tmp_path, "int4.toml", bad))


@pytest.mark.parametrize("filename", [
    "Int4.toml",
    "int-4.toml",
    "int 4.toml",
    "4int.toml",
    "int4;drop.toml",
])
def test_token_must_be_sql_identifier(tmp_path, filename):
    with pytest.raises(SpecError, match=r"token .* must match"):
        load_spec(write(tmp_path, filename, VALID_TOML))


@pytest.mark.parametrize("bad_name", [
    "int4-eq",
    "int4 eq",
    "INT4_eq",
    "int4;drop",
])
def test_domain_name_must_be_sql_identifier(tmp_path, bad_name):
    bad = textwrap.dedent(f"""
        [domain]
        "{bad_name}" = []
    """)
    with pytest.raises(SpecError, match=r"domain name .* must match"):
        load_spec(write(tmp_path, "int4.toml", bad))


FIXTURE_TOML = VALID_TOML + textwrap.dedent("""
    [fixture]
    values = ["MIN", "-100", "-1", "ZERO", "1", "9999", "MAX"]
""")


def test_fixture_values_default_to_none_when_absent(tmp_path):
    spec = load_spec(write(tmp_path, "int4.toml", VALID_TOML))
    assert spec.fixture_values is None


def test_loads_fixture_values_when_present(tmp_path):
    spec = load_spec(write(tmp_path, "int4.toml", FIXTURE_TOML))
    assert spec.fixture_values == [
        "MIN", "-100", "-1", "ZERO", "1", "9999", "MAX",
    ]


def test_fixture_values_must_be_a_list(tmp_path):
    bad = VALID_TOML + '\n[fixture]\nvalues = "MIN"\n'
    with pytest.raises(SpecError, match=r"\[fixture\] values: must be a list"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_table_requires_values_key(tmp_path):
    bad = VALID_TOML + "\n[fixture]\nother = 1\n"
    with pytest.raises(SpecError, match=r"\[fixture\]: missing required key 'values'"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_values_must_be_non_empty(tmp_path):
    bad = VALID_TOML + "\n[fixture]\nvalues = []\n"
    with pytest.raises(SpecError, match=r"\[fixture\] values: must not be empty"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_values_must_be_strings(tmp_path):
    bad = VALID_TOML + "\n[fixture]\nvalues = [1, 2]\n"
    with pytest.raises(SpecError, match=r"\[fixture\] values: must be strings"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_values_reject_invalid_literal(tmp_path):
    bad = VALID_TOML + '\n[fixture]\nvalues = ["MIN", "oops", "ZERO", "MAX"]\n'
    with pytest.raises(SpecError, match="not a valid i32 literal"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_values_require_min_max_zero(tmp_path):
    bad = VALID_TOML + '\n[fixture]\nvalues = ["1", "2", "3"]\n'
    with pytest.raises(SpecError, match="must include MIN, MAX, and zero"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_values_require_max_even_if_min_and_zero_present(tmp_path):
    bad = VALID_TOML + '\n[fixture]\nvalues = ["MIN", "ZERO", "1"]\n'
    with pytest.raises(SpecError, match="must include MIN, MAX, and zero"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_values_reject_duplicate_literal(tmp_path):
    bad = VALID_TOML + '\n[fixture]\nvalues = ["MIN", "1", "ZERO", "1", "MAX"]\n'
    with pytest.raises(SpecError, match=r"must be distinct.*duplicate values.*'1'"):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_values_reject_sentinel_literal_alias(tmp_path):
    # "MIN" and the i32::MIN literal resolve to the same plaintext value;
    # the distinct-plaintext contract must reject the pair.
    bad = (
        VALID_TOML
        + '\n[fixture]\nvalues = ["MIN", "-2147483648", "ZERO", "MAX"]\n'
    )
    with pytest.raises(
        SpecError,
        match=r"must be distinct.*'-2147483648' duplicates 'MIN' \(both resolve to -2147483648\)",
    ):
        load_spec(write(tmp_path, "int4.toml", bad))


def test_fixture_for_unknown_scalar_token_raises(tmp_path):
    bad = textwrap.dedent("""
        [domain]
        int8 = []

        [fixture]
        values = ["1"]
    """)
    with pytest.raises(SpecError, match="unknown scalar token 'int8'"):
        load_spec(write(tmp_path, "int8.toml", bad))
