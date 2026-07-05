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
        manifest = build_manifest(Path(d), "1.2.3")

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


if __name__ == "__main__":
    test_build_manifest_shape()
    test_skips_index_and_doxyfile()
    print("✓ all tests passed")
