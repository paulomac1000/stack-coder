#!/bin/bash
set -e

echo ">>> [INTEGRATION] Starting integration tests inside the container..."

# Helper function
check_writable() {
    if [ -w "$1" ]; then
        echo "  PASS: Directory $1 is writable."
    else
        echo "  FAIL: Directory $1 is NOT writable or does not exist."
        exit 1
    fi
}

# 1. Check new auth volumes
echo ">>> Checking auth volume mounts..."
check_writable "/home/coder/.claude"
check_writable "/home/coder/.gemini"
check_writable "/home/coder/.config/github-copilot"
check_writable "/home/coder/.config/gh"

# 2. Check MCP configuration in Continue
echo ">>> Checking MCP configuration in Continue..."
CONTINUE_CONFIG="/home/coder/.continue/config.json"
if [ -f "$CONTINUE_CONFIG" ]; then
    if grep -q "ha-mcp" "$CONTINUE_CONFIG"; then
        echo "  PASS: Continue config contains 'ha-mcp' definition."
    else
        echo "  FAIL: Continue config does not contain 'ha-mcp'."
        exit 1
    fi
else
    echo "  WARN: Continue's config.json does not exist yet (will be created on start)."
fi

# 3. Check SSH keys
echo ">>> Checking SSH keys..."
if [ -f "/home/coder/.ssh/id_ed25519" ]; then
    echo "  PASS: SSH key exists."
else
    echo "  FAIL: SSH key is missing."
    exit 1
fi

# 4. Check SSL certificates
echo ">>> Checking SSL certificates..."
if [ -f "/home/coder/.local/share/code-server/certs/server.crt" ]; then
    echo "  PASS: SSL certificate generated."
else
    echo "  FAIL: SSL certificate is missing."
    exit 1
fi

echo ">>> [INTEGRATION] All tests finished successfully."
