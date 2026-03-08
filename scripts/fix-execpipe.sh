#!/bin/bash
# fix-execpipe.sh - Restores the exec_cmd/exec_out IPC mechanism on the HOST.
# Run this on the HOST if the agent loses terminal access.
# Self-relative: works regardless of the project's location on the host.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXECPIPE="$PROJECT_DIR/execpipe.sh"
CMD_FILE="$PROJECT_DIR/exec_cmd"
OUT_FILE="$PROJECT_DIR/exec_out"
LOCK_FILE="$PROJECT_DIR/exec_lock"

echo "============================================"
echo "  fix-execpipe.sh - Restoring agent terminal access"
echo "============================================"
echo ""

# 1. Stop old instances
echo ">>> Stopping old execpipe.sh instances..."
pkill -f execpipe.sh 2>/dev/null && echo "  Stopped." || echo "  None running."
sleep 0.5

# 2. Verify execpipe.sh exists
echo ">>> Checking execpipe.sh at $EXECPIPE..."
if [ ! -f "$EXECPIPE" ]; then
  echo "  ERROR: $EXECPIPE not found. Is this the correct project directory?"
  exit 1
fi
chmod +x "$EXECPIPE"
echo "  OK."

# 3. Check jq
echo ">>> Checking jq..."
if ! command -v jq &>/dev/null; then
  echo "  jq not found - installing..."
  sudo apt-get install -y jq
else
  echo "  jq OK: $(jq --version)"
fi

# 4. Clean up stale IPC files
echo ">>> Cleaning stale IPC files..."
rm -f "$CMD_FILE" "$OUT_FILE" "$LOCK_FILE"
echo "  Done."

# 5. Start execpipe
echo ">>> Starting execpipe.sh..."
nohup "$EXECPIPE" >> /tmp/execpipe.log 2>&1 &
echo "  PID: $!"
sleep 1

# 6. Test
echo ">>> Testing IPC..."
echo "{\"cwd\": \"$PROJECT_DIR\", \"cmd\": \"echo IPC_OK\"}" > "$CMD_FILE"
sleep 1
if grep -q "IPC_OK" "$OUT_FILE" 2>/dev/null; then
  echo "  SUCCESS! Agent terminal access is working."
  cat "$OUT_FILE"
else
  echo "  FAIL! Check /tmp/execpipe.log for errors."
  cat /tmp/execpipe.log
  exit 1
fi

echo ""
echo "============================================"
echo "  Agent terminal access restored!"
echo "  CMD_FILE: $CMD_FILE"
echo "  OUT_FILE: $OUT_FILE"
echo "============================================"
