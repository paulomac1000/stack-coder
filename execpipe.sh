#!/bin/bash
# execpipe.sh - File-based IPC for agent terminal access (runs on HOST)
# Polls for exec_cmd, executes, writes result to exec_out.
# Uses self-relative paths so the script works regardless of install location.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CMD_FILE="$SCRIPT_DIR/exec_cmd"
OUT_FILE="$SCRIPT_DIR/exec_out"
LOCK_FILE="$SCRIPT_DIR/exec_lock"
LOG_FILE="/tmp/execpipe.log"

log() {
  echo "[execpipe] [$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Clean up stale lock file left by a previous crash
if [ -f "$LOCK_FILE" ]; then
  log "Warning: stale lock file found on start. Removing."
  rm -f "$LOCK_FILE"
fi

log "--- execpipe.sh started (PID: $$) ---"
log "    CMD_FILE: $CMD_FILE"

while true; do
  # Atomic lock: succeed only if file does not exist yet
  if (set -o noclobber; echo $$ > "$LOCK_FILE") 2>/dev/null; then
    # Release the lock on any exit signal
    trap 'rm -f "$LOCK_FILE"; log "Lock released on exit."; exit' INT TERM EXIT

    if [ -f "$CMD_FILE" ]; then
      log "Command file detected. Processing..."
      payload=$(cat "$CMD_FILE")
      rm -f "$CMD_FILE"

      cwd=$(echo "$payload" | jq -r '.cwd // "/"')
      cmd=$(echo "$payload" | jq -r '.cmd // "echo ERROR: no command provided"')

      log "CWD: $cwd | CMD: $cmd"

      {
        echo "--- EXEC_START $(date +%s) ---"
        (
          cd "$cwd" 2>/dev/null || { echo "ERROR: cannot cd to '$cwd'"; exit 1; }
          eval "$cmd"
        )
        echo "--- EXEC_END $(date +%s) ---"
      } > "$OUT_FILE" 2>&1

      log "Execution finished."
    fi

    rm -f "$LOCK_FILE"
    trap - INT TERM EXIT
  fi

  sleep 0.1
done
