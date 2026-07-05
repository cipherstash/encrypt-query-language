#!/usr/bin/env bash
#MISE description="Generate JSON manifest from XML documentation"
#USAGE arg "version" help="Version to include in the manifest" default="DEV"

VERSION=${ARGC_VERSION:-DEV}

echo "Converting XML to JSON manifest..."

# Ensure XML exists
if [ ! -d "docs/api/xml" ]; then
  echo "warning: XML documentation not found"
  echo "Generating XML documentation..."
  mise run --output prefix docs:generate
fi

# Run converter
mise run --output prefix docs:generate:xml-to-json docs/api/xml docs/api/json "$VERSION"

echo ""
echo "✓ JSON manifest: docs/api/json/eql-manifest.json"
