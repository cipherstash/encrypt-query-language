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
