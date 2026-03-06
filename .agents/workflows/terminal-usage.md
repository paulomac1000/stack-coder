---
description: How to work with terminal commands in this project
---

# Terminal Access via exec_cmd/exec_out

## The Agent HAS Terminal Access

Commands run on the HOST via a file-based IPC mechanism.

## How It Works

1. Agent writes JSON to `/var/apps/coder/exec_cmd` (via `create_new_file` tool)
2. `execpipe.sh` on host picks it up (polls every 0.1s), deletes the file
3. Host executes the command in specified `cwd`
4. Result written to `/var/apps/coder/exec_out` (wrapped in EXEC_START/EXEC_END markers)
5. Agent reads `/var/apps/coder/exec_out` (via `read_file` tool)

## Usage

Write to `/var/apps/coder/exec_cmd`:
```json
{"cwd": "/var/apps/coder", "cmd": "git status --short"}
```

Wait ~1s, then read `/var/apps/coder/exec_out`.

**Note:** `exec_cmd` is deleted by execpipe.sh after execution, so use `create_new_file` each time.

## execpipe.sh (running on host)

The `execpipe.sh` script runs on the host machine, polling for commands.
It is self-relative — uses the directory it lives in as the IPC file location.
On the server it lives at `/var/apps/coder/execpipe.sh`.

Start on host:
```bash
nohup /var/apps/coder/execpipe.sh > /tmp/execpipe.log 2>&1 &
```

Check if running:
```bash
ps aux | grep execpipe
```

## Important Notes

- Commands run on the **HOST** (not inside the container)
- `/var/apps/coder` is the workspace root — agent tools work relative to it
- `exec_cmd`, `exec_out`, and `exec_lock` are in `.gitignore`
- `jq` must be installed on host (`sudo apt-get install jq`)
- Output is wrapped: look for `--- EXEC_START --- ... --- EXEC_END ---` markers
- If `exec_out` is stale or empty, execpipe.sh is not running — ask user to run `fix-execpipe.sh`

## If Agent Loses Access

Ask user to run on HOST:
```bash
bash /var/apps/coder/fix-execpipe.sh
```

## Testing

Run from container:
```bash
bash /var/apps/coder/test-execpipe.sh
```

## How This Was Built (History)

1. User had `execpipe.sh` on host using FIFO pipes (`/var/pipe`) — caused deadlocks
2. Switched to **file-based polling** (`exec_cmd` / `exec_out` regular files)
3. First used `/var/apps/exec_cmd` (outside workspace) — agent couldn't access via tools
4. Moved IPC files to `/var/apps/codercom/exec_cmd` (inside workspace) — agent can use `create_new_file` + `read_file` directly
5. `execpipe.sh` polls every 0.2s, uses lock file to prevent double execution
6. `jq` installed on host for JSON parsing of payload
7. Project renamed from `codercom` to `coder` — IPC files now at `/var/apps/coder/exec_cmd`; `execpipe.sh` uses `SCRIPT_DIR` (self-relative) instead of hardcoded paths; upgraded to atomic locking and timestamped logging
