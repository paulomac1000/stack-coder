#!/bin/bash
# unit_tests.sh - Static checks for the coder project.
# Runs on the HOST (or in CI) without a running container.
# Uses script-relative paths so it works regardless of install location.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

check_file() {
  local path="$1"
  if [ -f "$path" ]; then
    echo "  PASS: found $path"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: missing $path"
    FAIL=$((FAIL + 1))
  fi
}

check_syntax() {
  local path="$1"
  if bash -n "$path" 2>/dev/null; then
    echo "  PASS: bash syntax OK -- $path"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: bash syntax error -- $path"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  Unit Tests -- coder project"
echo "  Project dir: $SCRIPT_DIR"
echo "============================================"
echo ""

echo ">>> Checking required files..."
check_file "$SCRIPT_DIR/../Dockerfile"
check_file "$SCRIPT_DIR/../docker-compose.yml"
check_file "$SCRIPT_DIR/init.sh"
check_file "$SCRIPT_DIR/execpipe.sh"
check_file "$SCRIPT_DIR/fix-execpipe.sh"
check_file "$SCRIPT_DIR/../README.md"
echo ""

echo ">>> Checking bash syntax for all shell scripts..."
for f in "$SCRIPT_DIR"/*.sh; do
  check_syntax "$f"
done
echo ""

echo "============================================"
if [ "$FAIL" -eq 0 ]; then
  echo "  Results: $PASS passed, 0 failed -- ALL OK"
else
  echo "  Results: $PASS passed, $FAIL failed -- ERRORS FOUND"
fi
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
