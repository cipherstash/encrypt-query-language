#!/usr/bin/env bash
#MISE description="Generate Markdown from XML documentation"

echo "Converting XML to Markdown..."

# Ensure XML exists
if [ ! -d "docs/api/xml" ]; then
  echo "warning: XML documentation not found"
  echo "Generating XML documentation..."
  mise run --output prefix docs:generate
fi

# Run converter
mise run --output prefix docs:generate:xml-to-markdown docs/api/xml docs/api/markdown

echo ""
echo "✓ Markdown documentation: docs/api/markdown/API.md"
