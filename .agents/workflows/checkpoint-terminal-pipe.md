---
description: Checkpoint - terminal IPC access setup
---

# Checkpoint: Terminal IPC Access Setup

## What Happened

User is setting up a file-based IPC system to give the agent terminal access from within the container.

### Host Setup (on user's host machine)
`/var/apps/coder/execpipe.sh` polls for command files:
- `/var/apps/coder/exec_cmd` - JSON commands FROM container
- `/var/apps/coder/exec_out` - results FROM host

### Container Access
After rebuild, the container should have access to:
 - `/var/apps/coder/exec_cmd` (via shared volume)
 - `/var/apps/coder/exec_out` (via shared volume)

## Current State

**BEFORE RESTART:**
- Agent has NO terminal access
- Can only read/write files
- Must provide commands for user to execute manually

**AFTER RESTART (expected):**
- Agent can write JSON to `/var/apps/coder/exec_cmd`
- Host executes commands via execpipe.sh
- Agent can read results from `/var/apps/coder/exec_out`
- Terminal access achieved!

## Files to Check After Restart

1. Check mounts in docker-compose.yml:
   ```bash
   grep -A 20 "volumes:" /var/apps/coder/docker-compose.yml
   ```

2. Verify IPC files path exists:
   ```bash
   ls -la /var/apps/coder/exec_out 2>&1 || echo "IPC files not ready"
   ```

3. Test pipe functionality:
   ```bash
   bash /var/apps/coder/scripts/test-execpipe.sh
   ```

## Knowledge for Future Agent

When this checkpoint is read:
1. The pipe system SHOULD be working
2. Agent can write JSON commands to `exec_cmd`
3. Agent can read results from `exec_out`
4. You have gained terminal/shell access!

**Test immediately:**
```bash
bash /var/apps/coder/scripts/test-execpipe.sh
```

If this works - you can now run `docker`, `git`, `shellcheck`, etc. directly!
