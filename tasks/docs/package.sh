#!/bin/bash
#MISE description="Package documentation for release"

set -e

VERSION=${1:-"dev"}
OUTPUT_DIR="release"
DOCS_DIR="docs/api"

echo "Packaging documentation for version: ${VERSION}"

# Validate documentation exists
if [ ! -f "${DOCS_DIR}/html/index.html" ]; then
  echo "Error: ${DOCS_DIR}/html/index.html not found"
  echo "Run 'mise run docs:generate' first to generate documentation"
  exit 1
fi

# Validate documentation directory has content
if [ ! -d "${DOCS_DIR}/html" ] || [ -z "$(ls -A ${DOCS_DIR}/html)" ]; then
  echo "Error: ${DOCS_DIR}/html is empty or does not exist"
  exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Create archives
echo "Creating archives..."
cd "${DOCS_DIR}"

# Create ZIP archive
zip -r -q "../../${OUTPUT_DIR}/eql-docs-${VERSION}.zip" html/
echo "Created ${OUTPUT_DIR}/eql-docs-${VERSION}.zip"

# Create tarball
tar czf "../../${OUTPUT_DIR}/eql-docs-${VERSION}.tar.gz" html/
echo "Created ${OUTPUT_DIR}/eql-docs-${VERSION}.tar.gz"

cd ../..

# Verify archives created
if [ -f "${OUTPUT_DIR}/eql-docs-${VERSION}.zip" ] && [ -f "${OUTPUT_DIR}/eql-docs-${VERSION}.tar.gz" ]; then
  echo ""
  echo "Documentation packaged successfully:"
  ls -lh "${OUTPUT_DIR}/eql-docs-${VERSION}".*
  exit 0
else
  echo "Error: Failed to create archives"
  exit 1
fi
