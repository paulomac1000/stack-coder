---
description: How to create and maintain GitHub Pull Request descriptions
---

## When to Write / Update a PR Description

- **On PR creation** — always write a description, even for small PRs.
- **After each commit push to an existing PR** — update the description to reflect the current state of the branch. The description should always match `HEAD`.
- **Before requesting review** — verify the description is accurate and complete.

## PR Description Format

Use this template for every PR:

```markdown
## Summary

Short paragraph (2–4 sentences) explaining WHAT changed and WHY.

## Changes

| File / Area | What changed |
|-------------|--------------|
| `path/to/file.ext` | Description of the change |

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor / code quality
- [ ] Documentation
- [ ] CI / tooling

## Testing

How was this verified? Which tools were used?

```bash
# Example verification commands
docker compose config --quiet
shellcheck your_script.sh
```

Result: ✅ All checks passed.

## Notes for Reviewer

Any context the reviewer needs that is not obvious from the diff.

```

## Rules

> [!IMPORTANT]
> - NEVER leave PR description blank or set it to a generic placeholder.
> - After pushing new commits to an existing PR, ALWAYS update the description to reflect the new state.
> - The description must be accurate at the time of review — stale descriptions mislead reviewers.

## Commands

### Create a new PR with description

1.  Write the description in a temporary file, e.g., `pr.md`.
2.  Run the command:

```bash
gh pr create --title "type: short description" --body-file pr.md
```

### View current PR description

```bash
gh pr view --json number,title,body
```

## Conventional PR Titles

PR titles follow the same Conventional Commits standard as commit messages:

| Prefix | When to use |
|--------|-------------|
| `feat:` | New user-facing feature |
| `fix:` | Bug fix |
| `refactor:` | Code restructure without behaviour change |
| `docs:` | Documentation only |
| `chore:` | Tooling, deps, CI, version bumps |
| `test:` | Test additions or fixes |
