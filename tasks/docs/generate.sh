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
echo
echo "Documentation generated at docs/api/html/index.html"
