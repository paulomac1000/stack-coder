#!/bin/bash
set -e

echo "🔗 Running Integration Tests (Persistence & Config)..."

# 1. Verify Volume Mounts (Writability)
echo ">>> Checking volume persistence..."

check_writable() {
    local dir="$1"
    if [ -w "$dir" ]; then
        echo "✅ $dir is writable."
    else
        echo "❌ $dir is NOT writable or missing."
        exit 1
    fi
}

check_writable "/home/coder/.continue"
check_writable "/home/coder/.config/gcloud"
check_writable "/home/coder/.local/share/code-server"

# 2. Verify Continue Configuration
echo ">>> Checking Continue configuration..."
CONTINUE_CONFIG="/home/coder/.continue/config.json"

if [ -f "$CONTINUE_CONFIG" ]; then
    echo "✅ Continue config found."
    # Check if it's valid JSON
    if jq empty "$CONTINUE_CONFIG" >/dev/null 2>&1; then
        echo "✅ Continue config is valid JSON."
    else
        echo "❌ Continue config is invalid JSON."
        exit 1
    fi
else
    echo "⚠️  Continue config missing (First run?). init.sh should create this on startup."
fi

# 3. Verify Gemini/GCloud Auth
echo ">>> Checking Gemini/GCloud Auth persistence..."
GCLOUD_CRED="/home/coder/.config/gcloud/application_default_credentials.json"
GCLOUD_DB="/home/coder/.config/gcloud/credentials.db"

if [ -f "$GCLOUD_CRED" ] || [ -f "$GCLOUD_DB" ]; then
    echo "✅ GCloud credentials found (Persistence working)."
else
    echo "⚠️  No GCloud credentials found."
    echo "    (This is expected on first run. Run 'gcloud auth application-default login' to setup)."
fi

echo "🎉 Integration tests passed."