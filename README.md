# Code Server Stack

Development environment for smart-home infrastructure management with **full Docker access** and **AI integration**.

## 🚀 New Features

### Docker Access
- ✅ **Docker socket mounted** - full access to host Docker daemon
- ✅ **Docker CLI pre-installed** - run `docker` and `docker compose` commands directly
- ✅ **User in docker group** - no sudo required for Docker commands
- ✅ **Same paths as host** - `/var/apps` workspace (no `/workspace` mapping)

### Pre-installed Tools
- **Docker**: `docker`, `docker compose`
- **Git & GitHub**: `git`, `gh` (GitHub CLI)
- **Network**: `curl`, `wget`, `jq`, `net-tools`, `ping`, `dig`, `telnet`
- **System**: `htop`, `vim`, `nano`, `less`, `tree`, `rsync`, `zip`, `unzip`
- **Python**: `python3`, `pip3`
- **SSH**: `openssh-client`, `ssh-keygen`

### VS Code Extensions
- Continue (AI assistant)
- Red Hat YAML
- Microsoft Python
- Azure Docker
- GitLens
- ErrorLens
- Anthropic Claude Code

## 📁 Workspace Structure

```
/var/apps/                    # Main workspace (same as host!)
├── codercom/                # This stack
│   ├── docker-compose.yml   # Build from Dockerfile
│   ├── Dockerfile           # Custom image with all tools
│   ├── init.sh              # Initialization script
│   ├── .env                 # Environment variables
│   └── ...
├── hassio/                  # Home Assistant configuration
├── folder-vault/            # NAS platform
├── ha-mcp-readonly/         # MCP server
└── ...
```

## 💾 Data Persistence

To ensure your configuration, extensions, and authentication states survive container rebuilds, the following directories are mapped to the local `data/` folder (which is ignored by git):

- **VS Code State** (`data/vscode`): Installed extensions, global settings, and state.
- **Continue AI** (`data/continue`): Chat history, configuration (`config.json`), and indices.
- **Google Cloud** (`data/gcloud`): Authentication credentials for Gemini Code Assist.
- **SSH Keys** (`data/ssh`): Generated SSH keys for GitHub access.

**Note:** If you need to reset the environment completely, you can delete the `data/` folder (warning: this will delete your AI config and login sessions).

## 🔧 Scripts

### `verify_and_setup_git.sh`
Verifies hassio repository before commit:
- Clears Git cache
- Stages files according to `.gitignore`
- Verifies no sensitive files are staged

```bash
cd /var/apps/coder
bash scripts/verify_and_setup_git.sh
```

### `restart_and_show_ssh_key.sh`
Restarts code-server and displays SSH key for GitHub:
- Restarts container (interrupts session!)
- Retrieves generated SSH public key
- Provides GitHub setup instructions

```bash
cd /var/apps/codercom
bash restart_and_show_ssh_key.sh
```

## ✅ Pre-commit Hooks

This project uses the `pre-commit` framework to enforce code quality and consistency. The hooks are configured in `.pre-commit-config.yaml`.

**Checks:**
- **YAML**: Validates YAML syntax.
- **ShellCheck**: Lints shell scripts for errors.
- **Hadolint**: Lints the `Dockerfile` for best practices.
- General checks for trailing whitespace, end-of-file, and large files.

### Setup

To enable the hooks for your local repository, run the following commands inside the `code-server` terminal:

```bash
# 1. Install the framework
pip install pre-commit

# 2. Install the git hooks
pre-commit install
```
Once installed, the hooks will run automatically on every `git commit`.

## 🐳 Docker Commands (Available Inside Container)

```bash
# List all containers
docker ps

# View logs
docker logs <container_name>

# Restart a container
docker restart <container_name>

# Manage stacks with docker compose
cd /var/apps/folder-vault
docker compose up -d
docker compose ps
docker compose logs -f

# Build and run
docker compose build
docker compose up -d --force-recreate
```

## 🤖 Continue MCP Configuration

To enable MCP server access in Continue extension:

1. Merge `continue_mcp_config_example.json` into `/var/apps/codercom/continue/config.json`
2. Add the `mcpServers` section to your existing config
3. Restart code-server

MCP Server: `http://192.168.0.101:9092/sse`

## 🤖 AI Assistant Setup

### Gemini Code Assistant (Google)

To use the Gemini Code Assistant, you need to authenticate with your Google account. This only needs to be done once, as the credentials will be saved to a persistent volume.

1.  **Open a terminal in code-server.**
2.  **Run the login command:**
    ```bash
    gcloud auth application-default login
    ```
3.  **Follow the link:** The CLI will provide a URL. Copy it and open it in your local browser.
4.  **Authenticate:** Log in with your Google account and grant the required permissions.
5.  **Copy the code:** After authenticating, your browser will display a verification code. Copy it.
6.  **Paste the code:** Paste the verification code back into the code-server terminal.

Once completed, the Gemini extension will be authenticated and will remain logged in even after the container is rebuilt.

## 🚀 First Start

### 1. Build the new image

```bash
cd /var/apps/codercom
docker compose build
```

### 2. Start the container

```bash
docker compose up -d
```

### 3. Access code-server

Open: `https://192.168.0.101:8100`

(Accept the self-signed certificate in your browser)

### 4. Add SSH key to GitHub

The init.sh script will generate an SSH key on first run. Copy the public key from the logs and add it to:
https://github.com/settings/ssh/new

### 5. Log in to GitHub CLI

To use the `gh` command for managing repositories and pull requests, you need to authenticate.

```bash
# In the code-server terminal, run:
gh auth login

# > Select "GitHub.com"
# > Select "SSH" as your preferred protocol
# > Upload your SSH key when prompted
# > Follow the browser-based authentication flow
```
This only needs to be done once.

### 6. Test Docker access

Open terminal in code-server and run:

```bash
docker ps
docker compose version
```

## 🔐 Security Notes

- Docker socket is mounted **read-only** (`:ro`)
- User `coder` is added to docker group (GID 999)
- No sudo required for Docker commands
- All tools pre-installed in Dockerfile (no runtime installs)

## 📊 Managed Repositories

- `/var/apps/hassio/` - Smart home configuration (tracked in git)
- `/var/apps/ha-mcp-readonly/` - MCP server for Home Assistant
- `/var/apps/folder-vault/` - NAS platform (tracked in git)

## 🛠️ Useful Commands

```bash
# Check Docker access
docker info

# Check current user and groups
id

# View installed tools
which git gh docker docker-compose python3

# Test GitHub CLI
gh --version

# Navigate workspace
cd /var/apps
ls -la
```
