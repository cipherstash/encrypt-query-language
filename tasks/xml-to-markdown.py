#!/usr/bin/env python3
"""
Simple Doxygen XML to Markdown converter for SQL function documentation.

Extracts function documentation from Doxygen XML and generates clean Markdown files.
This is a lightweight alternative to doxybook2/moxygen focused on SQL functions.
"""

import xml.etree.ElementTree as ET
from pathlib import Path
import sys
import re

def clean_text(text):
    """Remove extra whitespace and normalize text"""
    if not text:
        return ""
    return re.sub(r'\s+', ' ', text.strip())

def extract_para_text(element):
    """Extract text from para elements, including nested content"""
    if element is None:
        return ""

    parts = []
    if element.text:
        parts.append(element.text)

    for child in element:
        if child.tag == 'ref':
            # Keep references as inline code
            if child.text:
                parts.append(f"`{child.text}`")
        elif child.tag == 'computeroutput':
            if child.text:
                parts.append(f"`{child.text}`")
        else:
            parts.append(extract_para_text(child))

        if child.tail:
            parts.append(child.tail)

    return clean_text(''.join(parts))

def extract_parameter_list(desc_element):
    """Extract structured parameter list from detaileddescription"""
    if desc_element is None:
        return []

    params = []
    for paramlist in desc_element.findall('.//parameterlist[@kind="param"]'):
        for item in paramlist.findall('parameteritem'):
            name_elem = item.find('.//parametername')
            desc_elem = item.find('.//parameterdescription/para')

            if name_elem is not None and name_elem.text:
                param_desc = extract_para_text(desc_elem) if desc_elem is not None else ""

                # Parse "type description" format
                # Doxygen puts "@param name type description" → description = "type description"
                # Need to split on first word (type) and rest (description)
                param_type = ""
                param_text = ""

                if param_desc:
                    parts = param_desc.split(None, 1)  # Split on first whitespace
                    if len(parts) == 2:
                        param_type = parts[0]
                        param_text = parts[1]
                    elif len(parts) == 1:
                        # Only type, no description
                        param_type = parts[0]
                        param_text = ""
                    else:
                        param_text = param_desc

                params.append({
                    'name': name_elem.text,
                    'type': param_type,
                    'description': param_text
                })

    return params

def extract_simplesects(desc_element):
    """Extract simplesect elements (return, note, warning, see, etc.)"""
    if desc_element is None:
        return {}

    sections = {}
    for simplesect in desc_element.findall('.//simplesect'):
        kind = simplesect.get('kind')
        if kind:
            para = simplesect.find('para')
            if para is not None:
                sections[kind] = extract_para_text(para)

    return sections

def extract_exceptions(desc_element):
    """Extract exception/throws documentation from parameterlist[@kind='exception']"""
    if desc_element is None:
        return []

    exceptions = []
    for paramlist in desc_element.findall('.//parameterlist[@kind="exception"]'):
        for item in paramlist.findall('parameteritem'):
            desc_elem = item.find('.//parameterdescription/para')
            if desc_elem is not None:
                exception_text = extract_para_text(desc_elem)
                if exception_text:
                    exceptions.append(exception_text)

    return exceptions

def extract_description(desc_element):
    """Extract description from briefdescription or detaileddescription, excluding parameterlist/simplesect"""
    if desc_element is None:
        return ""

    lines = []

    # Find all para elements that are NOT inside parameterlist or simplesect
    for para in desc_element.findall('para'):
        # Skip if this para is inside a parameterlist or simplesect
        parent = para
        skip = False
        while parent is not None:
            if parent.tag in ['parameterlist', 'simplesect']:
                skip = True
                break
            parent = list(desc_element.iter()).__contains__(parent)  # Check if still in tree
            parent = None  # Simple approach: only check direct parent
            break

        # Check if para has parameterlist or simplesect children
        if para.find('parameterlist') is not None or para.find('simplesect') is not None:
            # Extract only the text before these elements
            text_parts = []
            if para.text:
                text_parts.append(para.text)
            for child in para:
                if child.tag in ['parameterlist', 'simplesect']:
                    break
                if child.tag == 'ref' and child.text:
                    text_parts.append(f"`{child.text}`")
                if child.tail:
                    text_parts.append(child.tail)
            text = clean_text(''.join(text_parts))
        else:
            text = extract_para_text(para)

        if text:
            lines.append(text)

    return '\n\n'.join(lines)

def process_function(memberdef):
    """Extract function documentation from memberdef element"""
    name = memberdef.find('name')
    if name is None or not name.text:
        return None

    func_name = name.text

    # Extract descriptions
    brief = extract_description(memberdef.find('briefdescription'))
    detailed_elem = memberdef.find('detaileddescription')
    detailed = extract_description(detailed_elem)

    # Skip if no documentation
    if not brief and not detailed:
        return None

    # Extract structured parameter list from @param tags in detaileddescription
    param_docs = extract_parameter_list(detailed_elem)

    # Also try to extract params from function signature (fallback)
    signature_params = []
    for param in memberdef.findall('.//param'):
        param_type = param.find('type')
        param_name = param.find('declname')

        if param_name is not None and param_name.text:
            # Look for matching doc in param_docs
            param_doc = next((p for p in param_docs if p['name'] == param_name.text), None)

            param_info = {
                'name': param_name.text,
                'type': extract_para_text(param_type) if param_type is not None else '',
                'description': param_doc['description'] if param_doc else ''
            }
            signature_params.append(param_info)

    # Use documented params if available, otherwise fall back to signature params
    params = param_docs if param_docs else signature_params

    # Extract simplesects (return, note, warning, see, etc.)
    simplesects = extract_simplesects(detailed_elem)

    # Extract exceptions
    exceptions = extract_exceptions(detailed_elem)

    # Extract return type
    return_type = memberdef.find('type')

    # Extract location
    location = memberdef.find('location')
    source_file = location.get('file') if location is not None else ''
    line_num = location.get('line') if location is not None else ''

    return {
        'name': func_name,
        'brief': brief,
        'detailed': detailed,
        'params': params,
        'return_type': extract_para_text(return_type) if return_type is not None else '',
        'return_desc': simplesects.get('return', ''),
        'exceptions': exceptions,
        'notes': simplesects.get('note', ''),
        'warnings': simplesects.get('warning', ''),
        'see_also': simplesects.get('see', ''),
        'source': source_file,
        'line': line_num
    }

def generate_markdown(func):
    """Generate Markdown for a function"""
    lines = []

    # Function name as heading
    lines.append(f"## `{func['name']}`")
    lines.append("")

    # Brief description
    if func['brief']:
        lines.append(func['brief'])
        lines.append("")

    # Detailed description
    if func['detailed'] and func['detailed'] != func['brief']:
        lines.append(func['detailed'])
        lines.append("")

    # Parameters
    if func['params']:
        lines.append("### Parameters")
        lines.append("")
        lines.append("| Name | Type | Description |")
        lines.append("|------|------|-------------|")
        for param in func['params']:
            name = f"`{param['name']}`"
            param_type = f"`{param['type']}`" if param.get('type') else ""
            description = param.get('description', '')
            lines.append(f"| {name} | {param_type} | {description} |")
        lines.append("")

    # Return value
    if func['return_desc']:
        lines.append("### Returns")
        lines.append("")
        if func['return_type']:
            lines.append(f"**Type:** `{func['return_type']}`")
            lines.append("")
        lines.append(func['return_desc'])
        lines.append("")

    # Notes
    if func.get('notes'):
        lines.append("### Note")
        lines.append("")
        lines.append(func['notes'])
        lines.append("")

    # Exceptions
    if func.get('exceptions'):
        lines.append("### Exceptions")
        lines.append("")
        for exc in func['exceptions']:
            lines.append(f"- {exc}")
        lines.append("")

    # Warnings
    if func.get('warnings'):
        lines.append("### ⚠️ Warning")
        lines.append("")
        lines.append(func['warnings'])
        lines.append("")

    # See Also
    if func.get('see_also'):
        lines.append("### See Also")
        lines.append("")
        lines.append(func['see_also'])
        lines.append("")

    # Source reference
    if func['source']:
        source_path = func['source'].replace('/Users/tobyhede/src/encrypt-query-language/.worktrees/sql-documentation/', '')
        lines.append("### Source")
        lines.append("")
        lines.append(f"[{source_path}:{func['line']}](../../{source_path}#L{func['line']})")
        lines.append("")

    lines.append("---")
    lines.append("")

    return '\n'.join(lines)

def main():
    if len(sys.argv) < 2:
        print("Usage: xml-to-markdown.py <xml_dir> [output_dir]")
        sys.exit(1)

    xml_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('docs/api/markdown')

    if not xml_dir.exists():
        print(f"Error: XML directory not found: {xml_dir}")
        sys.exit(1)

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Process all XML files
    functions = []
    xml_files = list(xml_dir.glob('*.xml'))

    print(f"Processing {len(xml_files)} XML files...")

    for xml_file in xml_files:
        if xml_file.name in ['index.xml', 'Doxyfile.xml']:
            continue

        try:
            tree = ET.parse(xml_file)
            root = tree.getroot()

            # Find all function members
            for memberdef in root.findall('.//memberdef[@kind="function"]'):
                func = process_function(memberdef)
                if func:
                    functions.append(func)
        except ET.ParseError as e:
            print(f"Warning: Failed to parse {xml_file.name}: {e}")
            continue

    if not functions:
        print("No documented functions found!")
        return

    # Sort by name
    functions.sort(key=lambda f: f['name'])

    # Generate index
    index_lines = [
        "# EQL API Reference",
        "",
        "Complete API reference for the Encrypt Query Language (EQL) PostgreSQL extension.",
        "",
        "## Functions",
        ""
    ]

    for func in functions:
        index_lines.append(f"- [`{func['name']}`](#{func['name'].lower().replace('_', '-')}) - {func['brief']}")

    index_lines.append("")
    index_lines.append("---")
    index_lines.append("")

    # Add all function docs
    for func in functions:
        index_lines.append(generate_markdown(func))

    # Write output
    output_file = output_dir / 'API.md'
    output_file.write_text('\n'.join(index_lines))

    print(f"✓ Generated Markdown documentation: {output_file}")
    print(f"  Functions documented: {len(functions)}")

if __name__ == '__main__':
    main()
