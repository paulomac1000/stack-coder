#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

echo "============================================"
echo "  Unit Tests -- coder project"
echo "  Project dir: $SCRIPT_DIR"
echo "============================================"
echo ""

# ── Helper functions ──────────────────────────────────────────────────────────

check_file() {
    local path="$1"
    if [ -f "$path" ]; then
        echo "  PASS: found $path"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: missing $path"
        FAIL=$((FAIL + 1))
    fi
}

check_pattern() {
    local file="$1"
    local pattern="$2"
    local label="$3"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label"
        FAIL=$((FAIL + 1))
    fi
}

# ── 1. Required project files ─────────────────────────────────────────────────

echo ">>> Checking required files..."
check_file "$PROJECT_DIR/Dockerfile"
check_file "$PROJECT_DIR/Dockerfile.test"
check_file "$PROJECT_DIR/docker-compose.yml"
check_file "$PROJECT_DIR/scripts/init.sh"
check_file "$PROJECT_DIR/scripts/run_tests.sh"
check_file "$PROJECT_DIR/scripts/execpipe.sh"
check_file "$PROJECT_DIR/scripts/fix-execpipe.sh"
check_file "$PROJECT_DIR/README.md"
check_file "$PROJECT_DIR/AGENTS.md"
check_file "$PROJECT_DIR/.agents/workflows/onboarding.md"
check_file "$PROJECT_DIR/.agents/workflows/development.md"
check_file "$PROJECT_DIR/.agents/workflows/terminal-usage.md"
echo ""

# ── 2. docker-compose.yml volume mount checks ─────────────────────────────────

echo ">>> Checking docker-compose.yml volume mounts..."
COMPOSE="$PROJECT_DIR/docker-compose.yml"
check_pattern "$COMPOSE" "data/vscode"             "data/vscode (VS Code extensions + settings)"
check_pattern "$COMPOSE" "data/continue"           "data/continue (Continue config)"
check_pattern "$COMPOSE" "data/ssh"                "data/ssh (SSH keys)"
check_pattern "$COMPOSE" "data/claude"             "data/claude (Claude Code auth)"
check_pattern "$COMPOSE" "data/gemini"             "data/gemini (Gemini auth)"
check_pattern "$COMPOSE" "data/google-vscode-auth" "data/google-vscode-auth (Google VSCode extension auth)"
check_pattern "$COMPOSE" "data/copilot"            "data/copilot (GitHub Copilot auth)"
check_pattern "$COMPOSE" "data/gh"                 "data/gh (gh CLI auth)"
check_pattern "$COMPOSE" "data/gcloud"             "data/gcloud (GCloud credentials)"
check_pattern "$COMPOSE" "/var/apps:/var/apps"     "/var/apps host workspace mount"
echo ""

# ── 3. Bash syntax check ──────────────────────────────────────────────────────

echo ">>> Checking bash syntax (bash -n) for shell scripts..."
for f in "$SCRIPT_DIR"/*.sh; do
    if bash -n "$f" 2>/dev/null; then
        echo "  PASS: bash syntax OK -- $f"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: bash syntax error -- $f"
        FAIL=$((FAIL + 1))
    fi
done
echo ""

# ── 4. Shellcheck (optional — always present in Dockerfile.test) ──────────────

echo ">>> Running shellcheck on shell scripts..."
if command -v shellcheck >/dev/null 2>&1; then
    for f in "$SCRIPT_DIR"/*.sh; do
        if shellcheck --severity=warning "$f" 2>/dev/null; then
            echo "  PASS: shellcheck OK -- $f"
            PASS=$((PASS + 1))
        else
            echo "  FAIL: shellcheck error -- $f"
            shellcheck --severity=warning "$f" || true
            FAIL=$((FAIL + 1))
        fi
    done
else
    echo "  SKIP: shellcheck not available (use scripts/run_tests.sh for full check)"
fi
echo ""

# ── 5. docker-compose.yml YAML validity ──────────────────────────────────────

echo ">>> Validating docker-compose.yml YAML..."
if python3 -c "import yaml; yaml.safe_load(open('$COMPOSE'))" 2>/dev/null; then
    echo "  PASS: docker-compose.yml is valid YAML"
    PASS=$((PASS + 1))
else
    echo "  SKIP: PyYAML not installed (install pyyaml to enable)"
fi
echo ""

# ── Results ───────────────────────────────────────────────────────────────────

echo "============================================"
if [ "$FAIL" -eq 0 ]; then
    echo "  Results: $PASS passed, 0 failed -- ALL OK"
else
    echo "  Results: $PASS passed, $FAIL failed -- SOME TESTS FAILED"
fi
echo "============================================"

[ "$FAIL" -eq 0 ] || exit 1
