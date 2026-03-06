#!/bin/bash
# test-execpipe.sh - Tests the exec_cmd/exec_out IPC mechanism.
# Run from inside the container to verify agent terminal access works.

set -e

CMD_FILE="/var/apps/coder/exec_cmd"
OUT_FILE="/var/apps/coder/exec_out"
PASS=0
FAIL=0

run_test() {
  local name="$1"
  local cmd="$2"
  local expected="$3"

  rm -f "$CMD_FILE"
  echo "{\"cwd\": \"/var/apps/coder\", \"cmd\": \"$cmd\"}" > "$CMD_FILE"
  sleep 1

  if grep -q "$expected" "$OUT_FILE" 2>/dev/null; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name"
    echo "        Expected: $expected"
    echo "        Got: $(head -3 "$OUT_FILE" 2>/dev/null)"
    FAIL=$((FAIL + 1))
  fi
}

echo "============================================"
echo "  execpipe IPC Test Suite"
echo "============================================"
echo ""

# Check execpipe.sh is running on host
echo ">>> Checking if execpipe.sh is running on host..."
if pgrep -f execpipe.sh > /dev/null; then
  echo "  OK: execpipe.sh is running (PID: $(pgrep -f execpipe.sh))"
else
  echo "  ERROR: execpipe.sh is NOT running on host!"
  echo "  Fix: run fix-execpipe.sh on the HOST"
  exit 1
fi
echo ""

echo ">>> Running IPC tests..."
run_test "basic echo"        "echo hello"                          "hello"
run_test "working directory" "pwd"                                  "coder"
run_test "git available"     "git --version"                        "git version"
run_test "docker available"  "docker ps --format '{{.Names}}' 2>&1 | head -1" "."

echo ""
echo "============================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
