---
description: How to develop features or modify code safely
---

## Architecture Invariants

> [!IMPORTANT]
> These rules are non-negotiable.

| Invariant | Rule |
|-----------|------|
| **BASH SCRIPTS** | All shell scripts must run flawlessly without `shellcheck` errors. Use `# shellcheck disable=SCXXXX` only when absolutely necessary and provide a reason. |
| **DOCUMENTATION** | All documentation and code comments MUST be in English. |

## Mandatory Verification Before Commit

> [!WARNING]
> NEVER consider a task complete without running linting and tests (if applicable).

```bash
# Run pre-commit hooks if configured
pre-commit run --all-files

# Verify docker compose config
docker compose config --quiet
```

Do NOT commit if any of the above fail.

## Git Workflow Rules

> [!CAUTION]
> Breaking these rules corrupts the repository history.

- **NEVER commit or push directly to `main`** — it is protected by convention.
- **NEVER run `git push` without explicit user approval**.
- **NEVER run `git commit` without explicit user approval** — even if tests are green. Always present a summary and wait for confirmation.
- **Feature branches only** — the default workflow is to create a feature branch, commit changes (with user approval), push to the remote (with user approval), and then open a PR to `main` via GitHub (`gh pr create`).
- **Check `.gitignore` when creating new files** — verify the file is not silently ignored.
- **Accidental commit to `main`** — undo immediately with `git reset --soft HEAD~1` (preserves staged changes, removes commit).
- **Before staging files** — always run `git status` first; never use `git add -A` or `git add .` blindly. Verify that `.gitignore` exclusions are respected (e.g. `google-cloud-key.json`, `nohup.out`, `var/`, `.env`).

## Known Agent Pitfalls (lessons from past sessions)

> [!WARNING]
> These are recurring mistakes made by AI agents. Read before touching anything.

| Mistake | What happened | Rule |
|---------|--------------|------|
| **Wrong IPC file path** | Agent created `/var/apps/coder/var/apps/exec_cmd` inside the git repo instead of using the correct container path `/var/apps/coder/exec_cmd`. | IPC files live at the **project root** (`exec_cmd`, `exec_out`). They are gitignored. Never create `var/` inside the repo. |
| **Scripts in wrong location** | Shell scripts were referenced at the project root but they live in `scripts/`. | All shell scripts are in `scripts/`. Entrypoint is `scripts/init.sh`. Check paths before referencing. |
| **Planning artifact left behind** | Agent created a shell script as an execution plan instead of just performing the task directly. | Do the work — don't write a script describing the work you were asked to do. |
| **Duplicate files instead of updates** | Agent created `init-new.sh` and `docker-compose-new.yml` alongside the originals with conflicting content. | Edit existing files. Only create a new file when the old one truly cannot serve the purpose. |
| **Stale name references after rename** | After renaming `codercom` → `coder`, many paths, docs, and scripts still referenced `codercom`. | After any project rename, always do a full-repo search: `grep -r "codercom" .` and fix every hit. |
| **Hardcoded host paths** | `execpipe.sh` and `fix-execpipe.sh` had hardcoded `/var/apps/coder/` which breaks if the project moves. | Use `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` for self-relative paths in host-side scripts. |
| **Staged secrets** | `google-cloud-key.json` was added to git despite being in `.gitignore` (staged before `.gitignore` took effect). | Run `git status` after every `git add`. Files in `.gitignore` can still be staged if added explicitly or before the ignore was set. |
| **Continue config overwritten** | init.sh always regenerated `~/.continue/config.json`, losing models added via UI. | init.sh now preserves existing config. Only generate if config is missing or has no models. MCP is always patched via jq. |
