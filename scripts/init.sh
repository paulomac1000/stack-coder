#!/bin/bash
set -e

MARKER="/home/coder/.local/share/code-server/.ai-ready"
GIT_MARKER="/home/coder/.local/share/code-server/.git-configured"
CONFIG="/home/coder/.continue/config.json"
SSH_KEY="/home/coder/.ssh/id_ed25519"

echo "============================================"
echo "  INIT.SH SCRIPT STARTED"
echo "============================================"
echo ""

# ── 0. PERMISSIONS FIX (For mounted volumes) ──
echo ">>> Fixing permissions for persistent volumes..."
sudo chown -R coder:coder /home/coder/.local/share/code-server
sudo chown -R coder:coder /home/coder/.continue
sudo chown -R coder:coder /home/coder/.config/gcloud
sudo chown -R coder:coder /home/coder/.ssh

# ── 1. DOCKER ACCESS CHECK ──
echo ">>> Verifying Docker access..."
if docker ps --format '{{.Names}}' | grep -q "code-server"; then
    echo "✅ Docker is running! code-server container is visible."
else
    echo "⚠️  Docker is responding, but the code-server container is not visible (perhaps first launch?)"
fi

echo ""
echo ">>> Available Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "   (no access or Docker is not responding)"
echo ""

# ── 2. GIT AND SSH CONFIGURATION (one-time) ──
if [ ! -f "$GIT_MARKER" ]; then
  echo ">>> Configuring Git and SSH..."

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
    echo "  🔑 SSH KEY GENERATED!"
    echo "============================================"
    echo ""
    echo "Add this public key to your GitHub account:"
    echo "https://github.com/settings/ssh/new"
    echo ""
    echo "--- COPY THE KEY BELOW ---"
    cat "${SSH_KEY}.pub"
    echo "--- END OF KEY ---"
    echo ""
    echo "After adding the key to GitHub, you can use:"
    echo "  git clone git@github.com:username/repo.git"
    echo ""
    echo "Test the connection:"
    echo "  ssh -T git@github.com"
    echo ""
    echo "============================================"
    echo ""
  else
    echo ">>> SSH key already exists"
  fi

  touch "$GIT_MARKER"
  echo ">>> Git and SSH configured"
else
  echo ">>> Git is already configured (marker file exists)"
fi

# ── 3. EXTENSIONS INSTALLATION (one-time) ──
# Extensions are pre-installed in the Dockerfile, checking marker.
if [ ! -f "$MARKER" ]; then
  echo ">>> First run — creating extensions marker..."
  touch "$MARKER"
  echo ">>> Extensions already installed (from Dockerfile)"
else
  echo ">>> Extensions already installed (marker file exists)"
fi

# ── 4. GENERATE CONTINUE CONFIG ──
mkdir -p /home/coder/.continue
echo ">>> Generating Continue config from ENV variables..."

MODELS=""

add_model() {
  [ -n "$MODELS" ] && MODELS="$MODELS,"
  MODELS="$MODELS
$1"
}

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  echo "    + Anthropic"
  add_model '    {
      "title": "Claude Sonnet 4",
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514",
      "apiKey": "'"$ANTHROPIC_API_KEY"'"
    }'
fi

if [ -n "${OPENROUTER_API_KEY:-}" ]; then
  echo "    + OpenRouter"
  add_model '    {
      "title": "Claude Sonnet 4 (OpenRouter)",
      "provider": "openrouter",
      "model": "anthropic/claude-sonnet-4-20250514",
      "apiKey": "'"$OPENROUTER_API_KEY"'"
    }'
  add_model '    {
      "title": "GPT-4o (OpenRouter)",
      "provider": "openrouter",
      "model": "openai/gpt-4o",
      "apiKey": "'"$OPENROUTER_API_KEY"'"
    }'
  add_model '    {
      "title": "Gemini 2.5 Pro (OpenRouter)",
      "provider": "openrouter",
      "model": "google/gemini-2.5-pro-preview",
      "apiKey": "'"$OPENROUTER_API_KEY"'"
    }'
  add_model '    {
      "title": "Kimi (OpenRouter)",
      "provider": "openrouter",
      "model": "kimi/kimi",
      "apiKey": "'"$OPENROUTER_API_KEY"'"
    }'
fi

if [ -n "${GEMINI_API_KEY:-}" ]; then
  echo "    + Gemini"
  add_model '    {
      "title": "Gemini 2.5 Pro",
      "provider": "gemini",
      "model": "gemini-2.5-pro",
      "apiKey": "'"$GEMINI_API_KEY"'"
    }'
  add_model '    {
      "title": "Gemini 2.0 Flash",
      "provider": "gemini",
      "model": "gemini-2.0-flash",
      "apiKey": "'"$GEMINI_API_KEY"'"
    }'
fi

if [ -z "$MODELS" ]; then
  echo "    !! NO API KEYS FOUND - please set them in the .env file !!"
fi

TAB=""
if [ -n "${GEMINI_API_KEY:-}" ]; then
  TAB='"tabAutocompleteModel": {
    "title": "Gemini Flash (autocomplete)",
    "provider": "gemini",
    "model": "gemini-2.0-flash",
    "apiKey": "'"$GEMINI_API_KEY"'"
  },'
elif [ -n "${OPENROUTER_API_KEY:-}" ]; then
  TAB='"tabAutocompleteModel": {
    "title": "Autocomplete (OpenRouter)",
    "provider": "openrouter",
    "model": "qwen/qwen-2.5-coder-32b-instruct",
    "apiKey": "'"$OPENROUTER_API_KEY"'"
  },'
fi

echo ">>> Generating Continue configuration..."
cat > "$CONFIG" << EOF
{
  "systemMessage": "You have direct terminal access on the HOST machine via file-based IPC. To execute commands: \n1. Use 'create_new_file' to write a JSON payload to '/var/apps/coder/exec_cmd'. \n2. JSON format: {\\"cwd\\": \\"/var/apps/coder\\", \\"cmd\\": \\"your-command\\"}. \n3. Wait ~1s. \n4. Read result from '/var/apps/coder/exec_out'.",
  "models": [$MODELS
  ],
  $TAB
  "allowAnonymousTelemetry": false
}
EOF
echo ">>> Config saved."
echo ""

# ── 5. GENERATE DEFAULT VS CODE SETTINGS ──
SETTINGS_DIR="/home/coder/.local/share/code-server/User"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo ">>> Generating default VS Code settings..."
  mkdir -p "$SETTINGS_DIR"
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "editor.formatOnSave": true,
  "files.exclude": {
    "**/.git": true,
    "**/.svn": true,
    "**/.hg": true,
    "**/CVS": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true,
    "**/node_modules": true,
    "**/__pycache__": true,
    "**/*.pyc": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/__pycache__": true
  },
  "editor.renderWhitespace": "selection",
  "editor.guides.bracketPairs": true,
  "workbench.colorTheme": "Default Dark Modern",
  "terminal.integrated.defaultProfile.linux": "bash",
  "continue.enableTabAutocomplete": true,
  "continue.telemetryEnabled": false
}
EOF
  echo ">>> VS Code settings saved."
else
  echo ">>> VS Code settings already exist. Skipping..."
fi
echo ""

# ── 5. STARTING CODE-SERVER WITH HTTPS ──
echo "============================================"
echo "  STARTING CODE-SERVER WITH HTTPS"
echo "============================================"
echo ""
echo "📍 Available paths:"
echo "   /var/apps            - main workspace (same as host)"
echo "   /var/apps/coder      - this directory"
echo "   /var/apps/hassio     - Home Assistant"
echo "   /var/apps/folder-vault - Folder Vault"
echo ""
echo "🐳 Docker:"
echo "   docker ps            - list containers"
echo "   docker compose       - manage stacks"
echo ""
echo "🌐 Addresses:"
echo "   code-server: https://192.168.0.101:8100"
echo "   (accept the self-signed certificate in your browser)"
echo ""
echo "============================================"
echo ""

exec code-server \
  --bind-addr 0.0.0.0:8100 \
  --cert \
  --auth password \
  /var/apps
