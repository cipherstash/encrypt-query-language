#!/usr/bin/env python3
#MISE hide=true
"""
Doxygen XML -> structured JSON manifest for EQL's SQL API.

A machine-readable companion to xml-to-markdown.py. Same Doxygen XML, same
SQL-via-Doxygen quirk handling (parameter name/type swap, operator names in
brief text, RETURNS extraction) — this emits JSON instead of Markdown, for
downstream consumers: docs generation, agents, and drift checks against the
hand-written reference.

Reuses the extraction in xml-to-markdown.py so the manifest and the Markdown
reference can never diverge in how they read the XML.

Usage: xml-to-json.py <xml_dir> [output_dir] [version]
"""

import importlib.util
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# xml-to-markdown.py has a hyphen in its name, so it can't be `import`ed
# normally; load it by path and reuse process_function verbatim.
_spec = importlib.util.spec_from_file_location(
    "eql_xml_to_markdown", Path(__file__).parent / "xml-to-markdown.py"
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
process_function = _mod.process_function


def _strip_ticks(value):
    return value.strip("`").strip() if value else ""


def _int_or_none(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _to_entry(func):
    """Shape one extracted function into a manifest entry."""
    return {
        "name": func["name"],
        "signature": func["signature"],
        "visibility": "private" if func["is_private"] else "public",
        "brief": func["brief"],
        "description": func["detailed"],
        "params": func["params"],  # [{name, type, description}]
        "returns": {
            "type": _strip_ticks(func["return_type"]),
            "description": func["return_desc"],
        },
        "throws": func["exceptions"],
        "notes": func["notes"],
        "warnings": func["warnings"],
        "seeAlso": func["see_also"],
        "source": {"file": func["source"], "line": _int_or_none(func["line"])},
    }


def build_manifest(xml_dir: Path, version: str) -> dict:
    functions = []
    for xml_file in sorted(xml_dir.glob("*.xml")):
        if xml_file.name in ("index.xml", "Doxyfile.xml"):
            continue
        try:
            root = ET.parse(xml_file).getroot()
        except ET.ParseError as exc:
            print(f"Warning: failed to parse {xml_file.name}: {exc}", file=sys.stderr)
            continue
        for memberdef in root.findall('.//memberdef[@kind="function"]'):
            func = process_function(memberdef)
            if func:
                functions.append(func)

    functions.sort(key=lambda f: (f["is_private"], f["name"], f["signature"]))

    return {
        "$schema": "https://schemas.cipherstash.com/eql/manifest/v1.json",
        "name": "eql",
        "version": version,
        "generatedFrom": "doxygen-xml",
        "counts": {
            "functions": len(functions),
            "public": sum(1 for f in functions if not f["is_private"]),
            "private": sum(1 for f in functions if f["is_private"]),
        },
        "functions": [_to_entry(f) for f in functions],
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: xml-to-json.py <xml_dir> [output_dir] [version]")
        sys.exit(1)

    xml_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("docs/api/json")
    version = sys.argv[3] if len(sys.argv) > 3 else "DEV"

    if not xml_dir.exists():
        print(f"Error: XML directory not found: {xml_dir}")
        sys.exit(1)

    manifest = build_manifest(xml_dir, version)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / "eql-manifest.json"
    output_file.write_text(json.dumps(manifest, indent=2) + "\n")

    counts = manifest["counts"]
    print(f"✓ Generated JSON manifest: {output_file}")
    print(
        f"  Functions: {counts['functions']} "
        f"({counts['public']} public, {counts['private']} private)"
    )


if __name__ == "__main__":
    main()
