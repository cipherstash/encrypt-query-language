#!/usr/bin/env bash
#MISE description="Generate API documentation (with Doxygen)"

set -e

if ! which -s doxygen; then
  echo "error: doxygen not installed"
  exit 2
fi

echo "Generating API documentation..."
echo
doxygen Doxyfile
echo "✓ Documentation generated:"
echo "  - XML (primary): docs/api/xml/"
echo "  - HTML (preview): docs/api/html/index.html"
echo ""
echo "See docs/api/README.md for XML format details"
