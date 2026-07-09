#!/usr/bin/env python3
"""
Tests for xml-to-json.py

Verifies the JSON manifest is built from the same Doxygen XML extraction as
the Markdown reference (reuse of process_function), and has the expected shape.
"""

import importlib.util
import json
import tempfile
from pathlib import Path

# xml-to-json.py is hyphenated → load by path.
_spec = importlib.util.spec_from_file_location(
    "eql_xml_to_json", Path(__file__).parent / "xml-to-json.py"
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
build_manifest = _mod.build_manifest
load_domains = _mod.load_domains

# Shape of `eql-codegen dump-catalog` output.
CATALOG_JSON = """{
  "types": [
    { "token": "text", "is_eq_only": false, "domains": [
      { "segment": "storage", "suffix": "", "typname": "eql_v3_text", "supported_ops": [], "terms": [] },
      { "segment": "eq", "suffix": "_eq", "typname": "eql_v3_text_eq", "supported_ops": ["=", "<>"],
        "terms": [{"key": "hm", "extractor": "eq_term", "ctor": "hmac_256"}] },
      { "segment": "search", "suffix": "_search", "typname": "eql_v3_text_search",
        "supported_ops": ["=", "<>", "<", "<=", ">", ">=", "@>", "<@"],
        "terms": [
          {"key": "hm", "extractor": "eq_term", "ctor": "hmac_256"},
          {"key": "bf", "extractor": "match_term", "ctor": "bloom_filter"}
        ] }
    ]}
  ],
  "stevec": [
    { "full_name": "json", "typname": "eql_v3_json", "name": "json", "terms": [] },
    { "full_name": "jsonb_entry", "typname": "eql_v3_jsonb_entry", "name": "entry", "terms": [
      {"key": "hm", "extractor": "eq_term", "ctor": "hmac_256"},
      {"key": "op", "extractor": "ord_ope_term", "ctor": "ope_cllw"}
    ] },
    { "full_name": "query_jsonb", "typname": "query_jsonb", "name": "query", "terms": [] }
  ]
}"""

SAMPLE_XML = """<?xml version="1.0"?>
<doxygen>
  <compounddef>
    <memberdef kind="function">
      <name>hmac_256</name>
      <argsstring>(val jsonb) RETURNS text</argsstring>
      <param>
        <type><ref>val</ref> </type>
        <declname>jsonb</declname>
      </param>
      <briefdescription><para>Compute the HMAC-SHA-256 term for a value.</para></briefdescription>
      <detaileddescription>
        <para>Used for equality search.
          <parameterlist kind="param">
            <parameteritem>
              <parameternamelist><parametername>val</parametername></parameternamelist>
              <parameterdescription><para>jsonb the encrypted value</para></parameterdescription>
            </parameteritem>
          </parameterlist>
          <simplesect kind="return"><para>the HMAC term</para></simplesect>
        </para>
      </detaileddescription>
      <location file="src/hmac_256/functions.sql" line="12"/>
    </memberdef>
  </compounddef>
</doxygen>"""


def test_build_manifest_shape():
    with tempfile.TemporaryDirectory() as d:
        (Path(d) / "hmac.xml").write_text(SAMPLE_XML)
        (Path(d) / "empty-catalog.json").write_text('{"types": []}')
        manifest = build_manifest(
            Path(d), "1.2.3", catalog_path=Path(d) / "empty-catalog.json"
        )

    assert manifest["name"] == "eql"
    assert manifest["version"] == "1.2.3"
    assert manifest["counts"]["functions"] == 1
    assert manifest["counts"]["public"] == 1

    fn = manifest["functions"][0]
    assert fn["name"] == "hmac_256"
    assert fn["visibility"] == "public"
    assert "HMAC" in fn["brief"]
    assert fn["returns"]["description"] == "the HMAC term"
    assert fn["source"] == {"file": "src/hmac_256/functions.sql", "line": 12}
    assert any(p["name"] == "val" for p in fn["params"])

    # Must be JSON-serializable.
    json.dumps(manifest)


def test_skips_index_and_doxyfile():
    with tempfile.TemporaryDirectory() as d:
        (Path(d) / "index.xml").write_text(SAMPLE_XML)
        (Path(d) / "Doxyfile.xml").write_text(SAMPLE_XML)
        manifest = build_manifest(Path(d), "DEV")
    assert manifest["counts"]["functions"] == 0


def test_load_domains():
    with tempfile.TemporaryDirectory() as d:
        cat = Path(d) / "eql-catalog.json"
        cat.write_text(CATALOG_JSON)
        domains = load_domains(cat)

    by_name = {x["name"]: x for x in domains}
    # v3 user domains live in `public`; the extractor functions are `eql_v3`.
    assert by_name["public.eql_v3_text"]["capabilities"] == ["storage"]
    assert by_name["public.eql_v3_text_eq"]["type"] == "text"
    assert by_name["public.eql_v3_text_eq"]["variant"] == "eq"
    assert by_name["public.eql_v3_text_eq"]["capabilities"] == ["equality"]
    assert by_name["public.eql_v3_text_eq"]["supportedOperators"] == ["=", "<>"]
    assert by_name["public.eql_v3_text_eq"]["termFunctions"] == ["eql_v3.eq_term"]
    # text_search carries all three capabilities, derived from its operators.
    assert by_name["public.eql_v3_text_search"]["capabilities"] == ["equality", "order", "match"]
    # SteVec (jsonb) domains come from the `stevec` section. Term extractors are
    # hardcoded on `jsonb_entry` (the sv element type) ONLY — hm -> eq_term,
    # op -> ord_ope_term; the `json` container and `query_jsonb` carry none.
    assert by_name["public.eql_v3_json"]["termFunctions"] == []
    assert by_name["eql_v3.query_jsonb"]["termFunctions"] == []
    assert by_name["public.eql_v3_jsonb_entry"]["capabilities"] == ["json"]
    assert by_name["public.eql_v3_jsonb_entry"]["shape"] == "stevec"
    assert by_name["public.eql_v3_jsonb_entry"]["termFunctions"] == ["eql_v3.eq_term", "eql_v3.ord_ope_term"]


if __name__ == "__main__":
    test_build_manifest_shape()
    test_skips_index_and_doxyfile()
    test_load_domains()
    print("✓ all tests passed")
