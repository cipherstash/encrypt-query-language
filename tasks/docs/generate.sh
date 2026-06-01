#!/usr/bin/env bash
#MISE description="Generate API documentation (with Doxygen)"
# Build first so generated encrypted-domain SQL exists under src/.
#MISE depends=["build"]

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
