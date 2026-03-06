---
description: Agent onboarding — start here every session, project overview and quick commands
---

# Coder.com Environment — Agent Onboarding

Welcome! This is your entry point for every session working on the `coder` project. Read this before touching any code or configuration.

## What Is This Project?

This project provides a self-contained, pre-configured development environment using `code-server`. It's designed for managing smart-home infrastructure, but can be used as a general-purpose dev container.

| Service | Port | Role |
|---------|------|------|
| `code-server` | 8100 | The web-based VS Code IDE. |

## Important Files

The project is configured via a few key files:

- `.env`: Environment variables (API keys, passwords, timezone).
- `docker-compose.yml`: Defines the `code-server` service, mounts, and ports.
- `Dockerfile`: Builds the custom image with all tools and extensions pre-installed.
- `init.sh`: A script that runs on container start to perform initial setup (Docker check, Git/SSH config, etc.).

## Step 1 — Get Your Bearings (ALWAYS do this first)

Always verify the project status.

```bash
git status
docker compose ps
```

## Step 2 — Working with Code and Commits

> [!CAUTION]
> Key rules for agents:

- ALL COMMENTS inside code files (like `.sh`, `.yml`) MUST BE IN ENGLISH.
- If you make a bash script, always ensure `shellcheck` compatibility.
- NEVER commit or push without explicit user approval.
- NEVER push directly to `main`. The default workflow is strictly feature branches and Pull Requests to `main` via GitHub (`gh pr create`).

## Knowledge Retention

> [!IMPORTANT]
> You are part of an iterative chain of agents. Your context will be cleared. Write down knowledge!

If you write new workflows or diagnostics, store them in `.agents/workflows/` so that subsequent LLMs can pick up where you left off.
