#!/usr/bin/env bash
#MISE description="Validate SQL documentation"

set -e

echo
echo "Checking documentation coverage..."
mise run --output prefix docs:validate:coverage

echo
echo "Validating required tags..."
mise run --output prefix docs:validate:required-tags
