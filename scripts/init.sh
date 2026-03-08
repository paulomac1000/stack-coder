#!/bin/bash
set -e

echo "============================================"
echo "  CODER INIT.SH STARTED"
echo "============================================"

# ── 0. DOCKER FIXES ──────────────────────────────────────────────────────────

# Fix sudo hostname resolution (avoids "unable to resolve host" warnings)
if ! grep -q "127.0.0.1 $(hostname)" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts > /dev/null
fi

# Fix Docker client/daemon API version mismatch
export DOCKER_API_VERSION=1.44

# Fix Docker socket permissions
if [ -S /var/run/docker.sock ]; then
    sudo chmod 666 /var/run/docker.sock
fi

echo ">>> Docker fix applied (DOCKER_API_VERSION=$DOCKER_API_VERSION)"

# ── 1. VOLUME PERMISSIONS ─────────────────────────────────────────────────────

echo ">>> Fixing permissions for volume mounts..."
sudo mkdir -p \
    /home/coder/.local/share/code-server \
    /home/coder/.continue \
    /home/coder/.claude \
    /home/coder/.gemini \
    /home/coder/.cache \
    /home/coder/.config/github-copilot \
    /home/coder/.config/gh \
    /home/coder/.ssh
# chown .cache (not just the subdir) — Docker creates the parent as root when mounting
# a subdirectory volume, which breaks VS Code trying to create .cache/Microsoft/
sudo chown -R coder:coder \
    /home/coder/.local/share/code-server \
    /home/coder/.continue \
    /home/coder/.claude \
    /home/coder/.gemini \
    /home/coder/.cache \
    /home/coder/.config/github-copilot \
    /home/coder/.config/gh \
    /home/coder/.ssh

# ── 2. EXTENSIONS RESTORE ─────────────────────────────────────────────────────
# If the volume-mounted extensions dir is empty but the image has a cold copy, restore them.

EXT_DIR="/home/coder/.local/share/code-server/extensions"
EXT_SOURCE="/usr/local/share/code-server-extensions"
if [ -d "$EXT_SOURCE" ] && [ "$(ls -A "$EXT_DIR" 2>/dev/null | wc -l)" -lt 3 ]; then
    echo ">>> Extensions volume is empty — restoring from image..."
    mkdir -p "$EXT_DIR"
    cp -R "$EXT_SOURCE"/. "$EXT_DIR/"
    sudo chown -R coder:coder "$EXT_DIR"
    echo ">>> Extensions restored."
else
    echo ">>> Extensions volume already populated."
fi

# ── 3. SSH KEY ────────────────────────────────────────────────────────────────

SSH_KEY="/home/coder/.ssh/id_ed25519"
GIT_MARKER="/home/coder/.local/share/code-server/.git-configured"

if [ ! -f "$GIT_MARKER" ]; then
    if [ ! -f "$SSH_KEY" ]; then
        echo ">>> Generating SSH key for GitHub..."
        mkdir -p /home/coder/.ssh
        ssh-keygen -t ed25519 -C "codeserver@hassio.local" -f "$SSH_KEY" -N ""
        chmod 700 /home/coder/.ssh
        chmod 600 "$SSH_KEY"
        chmod 644 "${SSH_KEY}.pub"

        cat > /home/coder/.ssh/config << 'SSHEOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
SSHEOF
        chmod 600 /home/coder/.ssh/config

        echo ""
        echo "============================================"
        echo "  SSH KEY GENERATED — add to GitHub:"
        echo "  https://github.com/settings/ssh/new"
        echo "============================================"
        cat "${SSH_KEY}.pub"
        echo "============================================"
    else
        echo ">>> SSH key already exists."
    fi
    touch "$GIT_MARKER"
else
    echo ">>> Git/SSH already configured (marker found)."
fi

# ── 4. ~/.claude.json PERSISTENCE ────────────────────────────────────────────
# ~/.claude.json sits outside ~/.claude/ and is not covered by the volume mount.
# We symlink it into the volume so it survives rebuild.

CLAUDE_JSON_LINK="/home/coder/.claude.json"
CLAUDE_JSON_TARGET="/home/coder/.claude/root-config.json"

if [ -f "$CLAUDE_JSON_LINK" ] && [ ! -L "$CLAUDE_JSON_LINK" ]; then
    # Real file (not symlink) — move it into the volume
    mv "$CLAUDE_JSON_LINK" "$CLAUDE_JSON_TARGET" 2>/dev/null || true
fi
# Force symlink (idempotent)
ln -sf "$CLAUDE_JSON_TARGET" "$CLAUDE_JSON_LINK"
echo ">>> ~/.claude.json → volume symlink ensured."

# ── 5. MKCERT HTTPS CERTIFICATE ───────────────────────────────────────────────

CERT_DIR="/home/coder/.local/share/code-server/certs"
if [ ! -f "$CERT_DIR/server.crt" ]; then
    echo ">>> Generating mkcert certificate for LAN (first run)..."
    mkdir -p "$CERT_DIR/ca"
    CAROOT="$CERT_DIR/ca" mkcert -install
    CAROOT="$CERT_DIR/ca" mkcert \
        -cert-file "$CERT_DIR/server.crt" \
        -key-file  "$CERT_DIR/server.key" \
        192.168.0.101 localhost 127.0.0.1
    cp "$CERT_DIR/ca/rootCA.pem" "$CERT_DIR/rootCA.pem"

    echo ""
    echo "============================================"
    echo "  MKCERT CA GENERATED — install in browser:"
    echo "  HOST: /var/apps/coder/data/vscode/certs/rootCA.pem"
    echo "  Chrome:  Settings > Privacy > Manage certs > Authorities > Import"
    echo "  Firefox: Settings > Privacy > View Certs > Authorities > Import"
    echo "============================================"
else
    echo ">>> HTTPS certificate already exists."
fi

# ── 6. CONTINUE CONFIG ────────────────────────────────────────────────────────

mkdir -p /home/coder/.continue
CONFIG="/home/coder/.continue/config.json"

# Only generate if config is missing or has no models (preserves UI-added models)
if [ ! -f "$CONFIG" ] || ! jq -e '.models | length > 0' "$CONFIG" >/dev/null 2>&1; then
    echo ">>> Continue config missing/empty — generating from ENV..."

    MODELS=""
    add_model() {
        [ -n "$MODELS" ] && MODELS="$MODELS,"
        MODELS="$MODELS
$1"
    }

    # shellcheck disable=SC2154
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        add_model '    {"title":"Claude Sonnet 4","provider":"anthropic","model":"claude-sonnet-4-20250514","apiKey":"'"$ANTHROPIC_API_KEY"'"}'
    fi
    if [ -n "${OPENROUTER_API_KEY:-}" ]; then
        add_model '    {"title":"Claude Sonnet 4 (OpenRouter)","provider":"openrouter","model":"anthropic/claude-sonnet-4-20250514","apiKey":"'"$OPENROUTER_API_KEY"'"}'
        add_model '    {"title":"GPT-4o (OpenRouter)","provider":"openrouter","model":"openai/gpt-4o","apiKey":"'"$OPENROUTER_API_KEY"'"}'
        add_model '    {"title":"Gemini 2.5 Pro (OpenRouter)","provider":"openrouter","model":"google/gemini-2.5-pro","apiKey":"'"$OPENROUTER_API_KEY"'"}'
        add_model '    {"title":"Kimi K2.5 (OpenRouter)","provider":"openrouter","model":"moonshotai/kimi-k2.5","apiKey":"'"$OPENROUTER_API_KEY"'"}'
    fi
    if [ -n "${GEMINI_API_KEY:-}" ]; then
        add_model '    {"title":"Gemini 2.5 Pro","provider":"gemini","model":"gemini-2.5-pro-preview-05-06","apiKey":"'"$GEMINI_API_KEY"'"}'
        add_model '    {"title":"Gemini 2.0 Flash","provider":"gemini","model":"gemini-2.0-flash","apiKey":"'"$GEMINI_API_KEY"'"}'
    fi

    cat > "$CONFIG" << EOF
{
  "models": [$MODELS
  ],
  "allowAnonymousTelemetry": false
}
EOF
    echo ">>> Continue config generated."
else
    echo ">>> Continue config exists with models — preserving."
fi

# Always patch MCP server (idempotent jq merge)
echo ">>> Patching MCP into Continue config..."
jq '.mcpServers = {"ha-mcp": {"transport": {"type": "sse", "url": "http://192.168.0.10:9092/sse"}}}' \
    "$CONFIG" > /tmp/continue_tmp.json && mv /tmp/continue_tmp.json "$CONFIG"

# ── 7. CLAUDE CODE MCP SETTINGS ──────────────────────────────────────────────

CLAUDE_SETTINGS="/home/coder/.claude/settings.json"
if [ ! -f "$CLAUDE_SETTINGS" ]; then
    mkdir -p /home/coder/.claude
    printf '{\n  "mcpServers": {\n    "ha-mcp": {"type":"sse","url":"http://192.168.0.10:9092/sse"}\n  }\n}\n' \
        > "$CLAUDE_SETTINGS"
    echo ">>> Claude Code settings created with MCP."
elif ! jq -e '.mcpServers' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
    jq '. + {"mcpServers": {"ha-mcp": {"type":"sse","url":"http://192.168.0.10:9092/sse"}}}' \
        "$CLAUDE_SETTINGS" > /tmp/claude_tmp.json && mv /tmp/claude_tmp.json "$CLAUDE_SETTINGS"
    echo ">>> MCP patched into Claude Code settings."
else
    echo ">>> Claude Code MCP settings already present."
fi

# ── 8. VS CODE USER SETTINGS ─────────────────────────────────────────────────

VSCODE_SETTINGS="/home/coder/.local/share/code-server/User/settings.json"
if [ ! -f "$VSCODE_SETTINGS" ]; then
    mkdir -p "$(dirname "$VSCODE_SETTINGS")"
    cat > "$VSCODE_SETTINGS" << 'EOF'
{
  "editor.formatOnSave": true,
  "workbench.colorTheme": "Default Dark Modern",
  "terminal.integrated.defaultProfile.linux": "bash",
  "continue.enableTabAutocomplete": true,
  "continue.telemetryEnabled": false,
  "redhat.telemetry.enabled": false,
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "python.testing.pytestArgs": [
    "/var/apps/coder/tests"
  ],
  "mcp": {
    "servers": {
      "ha-mcp": {
        "type": "sse",
        "url": "http://192.168.0.10:9092/sse"
      }
    }
  },
  "cloudcode.gemini.mcpServers": [
    {
      "name": "ha-mcp",
      "transport": "sse",
      "url": "http://192.168.0.10:9092/sse"
    }
  ]
}
EOF
    echo ">>> VS Code user settings created."
else
    echo ">>> VS Code user settings already exist."
fi

# ── 9. CODE-SERVER CONFIG (password) ─────────────────────────────────────────

echo ">>> Writing code-server config.yaml..."
mkdir -p /home/coder/.config/code-server
cat > /home/coder/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8100
auth: password
password: ${PASSWORD:-changeme}
cert: ${CERT_DIR}/server.crt
cert-key: ${CERT_DIR}/server.key
EOF

# ── 10. AUTH STATUS REPORT ────────────────────────────────────────────────────

echo ""
echo "============================================"
echo "  AUTH PERSISTENCE STATUS"
echo "============================================"
[ -f /home/coder/.claude/.credentials.json ] \
    && echo "  Claude Code:     LOGGED IN" \
    || echo "  Claude Code:     not logged in"
[ -f /home/coder/.gemini/oauth_creds.json ] \
    && echo "  Gemini:          LOGGED IN" \
    || echo "  Gemini:          not logged in"
[ -f /home/coder/.config/github-copilot/hosts.json ] \
    && echo "  GitHub Copilot:  LOGGED IN" \
    || echo "  GitHub Copilot:  not logged in"
[ -f /home/coder/.config/gh/hosts.yml ] \
    && echo "  gh CLI:          LOGGED IN" \
    || echo "  gh CLI:          not logged in"
[ -f /home/coder/.ssh/id_ed25519 ] \
    && echo "  SSH key:         EXISTS" \
    || echo "  SSH key:         missing"
echo "============================================"
echo ""

# ── 11. DOCKER STATUS ────────────────────────────────────────────────────────

echo ">>> Available Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "  (Docker not responding)"
echo ""

# ── 12. START CODE-SERVER ─────────────────────────────────────────────────────

echo "============================================"
echo "  STARTING CODE-SERVER"
echo "  https://192.168.0.101:8100"
echo "  Workspace: /var/apps"
echo "============================================"

exec code-server \
    --bind-addr 0.0.0.0:8100 \
    --cert "${CERT_DIR}/server.crt" \
    --cert-key "${CERT_DIR}/server.key" \
    --auth password \
    /var/apps
