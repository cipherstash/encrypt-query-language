#!/usr/bin/env bash
#MISE description="Validates SQL syntax for all documented files"

set -e

PGHOST=${PGHOST:-localhost}
PGPORT=${PGPORT:-7432}
PGUSER=${PGUSER:-cipherstash}
PGPASSWORD=${PGPASSWORD:-password}
PGDATABASE=${PGDATABASE:-postgres}
source_directory="src"

echo "Validating SQL syntax for all documented files..."
echo ""

errors=0
validated=0

if [ ! -d $source_directory ]; then
  echo "error: source directory does not exist: ${source_directory}"
  exit 2
fi

for file in $(find $source_directory -name "*.sql" -not -name "*_test.sql" | sort); do
  echo -n "Validating $file... "

  # Capture both stdout and stderr
  error_output=$(PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
          -f "$file" --set ON_ERROR_STOP=1 -q 2>&1) || exit_code=$?

  if [ "${exit_code:-0}" -eq 0 ]; then
    echo "✓"
    validated=$((validated + 1))
  else
    echo "✗ SYNTAX ERROR"
    echo "  Error in: $file"
    echo "  Details:"
    echo "$error_output" | tail -10 | sed 's/^/    /'
    echo ""
    errors=$((errors + 1))
  fi
  exit_code=0
done

echo ""
echo "Validation complete:"
echo "  Validated: $validated"
echo "  Errors: $errors"

if [ $errors -gt 0 ]; then
  echo ""
  echo "❌ Validation failed with $errors errors"
  exit 1
else
  echo ""
  echo "✅ All SQL files validated successfully"
  exit 0
fi
