#!/bin/bash
set -e

echo "============================================"
echo "  Git Verification and Setup"
echo "  for hassio repository"
echo "============================================"
echo ""

cd /var/apps/hassio

# Step 1: Clear Git cache
echo ">>> Step 1: Clearing Git cache..."
git rm -r --cached . 2>/dev/null || true
echo "✓ Cache cleared"
echo ""

# Step 2: Stage files according to .gitignore
echo ">>> Step 2: Staging files according to .gitignore..."
git add .
echo "✓ Files staged"
echo ""

# Step 3: Check status
echo ">>> Step 3: Repository status:"
echo "============================================"
git status
echo "============================================"
echo ""

# Step 4: Statistics for files to be committed
echo ">>> Step 4: Statistics for files to be committed:"
echo "============================================"
git diff --cached --stat | tail -50
echo "============================================"
echo ""

# Step 5: Verify that no unwanted files are staged
echo ">>> Step 5: Verifying that NO unwanted files are staged:"
echo ""

ERRORS=0

# Check for .db files
if git diff --cached --name-only | grep -E '\.db$|\.db-shm$|\.db-wal$'; then
    echo "❌ ERROR: Database files (.db) found!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No .db files found"
fi

# Check for .log files
if git diff --cached --name-only | grep -E '\.log'; then
    echo "❌ ERROR: Log files (.log) found!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No .log files found"
fi

# Check for secrets.yaml (not .example)
if git diff --cached --name-only | grep 'secrets.yaml' | grep -v 'example'; then
    echo "❌ ERROR: secrets.yaml found (potential secret leak)!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No secrets.yaml found (only .example)"
fi

# Check for .env (not .example)
if git diff --cached --name-only | grep -E '^\.env$'; then
    echo "❌ ERROR: .env file found (potential secret leak)!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No .env file found (only .example)"
fi

# Check for backups directory
if git diff --cached --name-only | grep 'backups/'; then
    echo "❌ ERROR: backups/ directory found!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No backups/ directory found"
fi

# Check for .storage directory
if git diff --cached --name-only | grep '\.storage/'; then
    echo "❌ ERROR: .storage/ directory found!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No .storage/ directory found"
fi

# Check for archive directory
if git diff --cached --name-only | grep 'www/archive/'; then
    echo "❌ ERROR: www/archive/ directory found (camera recordings)!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No www/archive/ directory found"
fi

# Check for .pt model files
if git diff --cached --name-only | grep '\.pt$'; then
    echo "❌ ERROR: .pt files found (YOLO models)!"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No .pt files found"
fi

echo ""
echo "============================================"

if [ $ERRORS -eq 0 ]; then
    echo "✅ VERIFICATION SUCCEEDED!"
    echo "============================================"
    echo ""
    echo ">>> Step 6: Expected files to be tracked:"
    echo ""
    git diff --cached --name-only | grep -E '\.(yaml|yml|py|md|txt|sh|json|conf)$|Dockerfile|docker-compose' | head -30
    echo ""
    echo "============================================"
    echo ">>> Next steps:"
    echo "============================================"
    echo ""
    echo "If everything looks OK, add the remote and prepare to commit:"
    echo ""
    echo "  cd /var/apps/hassio"
    echo "  git remote add origin git@github.com:paulomac1000/stack-hassio.git"
    echo "  git branch -M main"
    echo ""
    echo "WARNING: Do NOT commit yet - you must add the SSH key to GitHub first!"
    echo ""
    echo "To do this, run the script:"
    echo "  cd /var/apps/coder"
    echo "  bash scripts/restart_and_show_ssh_key.sh"
    echo ""
else
    echo "❌ VERIFICATION FAILED - Found $ERRORS errors!"
    echo "============================================"
    echo ""
    echo "Check your .gitignore and fix the issues before proceeding."
    exit 1
fi
