FROM codercom/code-server:latest

USER root

# ── SYSTEM TOOLS ──────────────────────────────────────────────────────────────

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Docker CLI (access to host Docker daemon via socket)
    docker.io \
    # Git and GitHub CLI
    git \
    gh \
    # Network tools
    curl \
    wget \
    jq \
    net-tools \
    iputils-ping \
    dnsutils \
    telnet \
    # System utilities
    htop \
    vim \
    nano \
    less \
    tree \
    rsync \
    zip \
    unzip \
    # Python (scripts and test runner)
    python3 \
    python3-pip \
    python3-yaml \
    # Other
    openssh-client \
    gnupg \
    apt-transport-https \
    ca-certificates \
    software-properties-common && \
    # Install pytest for VS Code Test Explorer integration
    pip3 install --no-cache-dir pytest --break-system-packages && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# ── GOOGLE CLOUD CLI ──────────────────────────────────────────────────────────

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y google-cloud-cli && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# ── MKCERT (trusted LAN HTTPS — enables Clipboard API in browser) ─────────────

RUN curl -fsSL \
    https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 \
    -o /usr/local/bin/mkcert && chmod +x /usr/local/bin/mkcert

# ── USER CONFIGURATION ────────────────────────────────────────────────────────

# Add coder user to the docker group for Docker socket access
RUN usermod -aG docker coder

# Default Git configuration
RUN git config --system user.name "Code Server Agent" && \
    git config --system user.email "codeserver@hassio.local" && \
    git config --system init.defaultBranch main && \
    git config --system pull.rebase false && \
    git config --system core.autocrlf input

# Default SSH configuration
RUN mkdir -p /home/coder/.ssh && \
    chmod 700 /home/coder/.ssh && \
    printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n\nHost *\n  AddKeysToAgent yes\n  IdentityFile ~/.ssh/id_ed25519\n' \
        > /home/coder/.ssh/config && \
    chown -R coder:coder /home/coder/.ssh && \
    chmod 600 /home/coder/.ssh/config

# ── VS CODE EXTENSIONS ────────────────────────────────────────────────────────

USER coder

# Core extensions (available on Open VSX)
RUN code-server --install-extension Continue.continue && \
    code-server --install-extension redhat.vscode-yaml && \
    code-server --install-extension ms-python.python && \
    code-server --install-extension ms-azuretools.vscode-docker && \
    code-server --install-extension eamodio.gitlens && \
    code-server --install-extension usernamehw.errorlens && \
    code-server --install-extension Anthropic.claude-code

# Optional extensions (may not be on Open VSX — non-fatal failures)
# Preserved via data/vscode volume mount if installed manually
RUN code-server --install-extension GitHub.copilot || true && \
    code-server --install-extension GitHub.copilot-chat || true && \
    code-server --install-extension GoogleCloudTools.gemini-code-assist || true

USER root

# ── EXTENSION COLD-COPY ───────────────────────────────────────────────────────
# Copy extensions to a "cold source" dir so init.sh can restore them
# to an empty data/vscode volume on first startup without requiring rebuild.

RUN mkdir -p /usr/local/share/code-server-extensions && \
    cp -R /home/coder/.local/share/code-server/extensions/. \
        /usr/local/share/code-server-extensions/ || true && \
    chown -R coder:coder /usr/local/share/code-server-extensions

# ── FINAL ─────────────────────────────────────────────────────────────────────

USER coder
WORKDIR /var/apps
