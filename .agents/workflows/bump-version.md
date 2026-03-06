---
description: How to bump the project version
---

## Overview

The version is stored in a single file: `VERSION` (root of repo), one line, SemVer format: `MAJOR.MINOR.PATCH`.

This version number refers to the configuration of the `coder` environment itself, not the applications running inside it.

## When to Bump

| Type | When to use | Example |
|------|-------------|---------|
| **PATCH** | Bug fixes, small tweaks, doc updates, minor script changes | `1.0.2 → 1.0.3` |
| **MINOR** | New tools, new extensions, significant new scripts or features | `1.0.3 → 1.1.0` |
| **MAJOR** | Breaking changes, major Dockerfile or architecture rewrites | `1.1.0 → 2.0.0` |

## Steps

1. Read current version:

```bash
cat ./VERSION
```

2. Decide bump type (PATCH / MINOR / MAJOR) based on the table above.

3. Update `VERSION` — single line, no trailing whitespace:

```text
MAJOR.MINOR.PATCH
```

4. Verify the file was written correctly:

```bash
cat ./VERSION
```

5. Stage the change:

```bash
git add VERSION
```

6. **STOP** — present a summary to the user and wait for approval:
   > Version bumped from `OLD` → `NEW`. Ready to commit — shall I proceed?

7. After user approval, commit:

```bash
git commit -m "chore: bump version to MAJOR.MINOR.PATCH"
```

## Notes

> [!WARNING]
> NEVER commit without explicit user approval (see `development.md` → Git Workflow Rules).

- To create a release tag (only if the user explicitly requests it):

```bash
git tag vMAJOR.MINOR.PATCH
git push origin vMAJOR.MINOR.PATCH
```
