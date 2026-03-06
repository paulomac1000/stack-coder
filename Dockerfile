FROM codercom/code-server:latest

USER root

# SYSTEM TOOLS INSTALLATION
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Docker CLI - for host Docker access
    docker.io \
    \
    # Git and GitHub CLI
    git \
    gh \
    \
    # Networking and diagnostic tools
    curl \
    wget \
    jq \
    net-tools \
    iputils-ping \
    dnsutils \
    telnet \
    \
    # System utilities
    htop \
    vim \
    nano \
    less \
    tree \
    rsync \
    zip \
    unzip \
    \
    # Python and pip (for scripts)
    python3 \
    python3-pip \
    \
    # Other useful tools
    openssh-client \
    gnupg \
    apt-transport-https \
    ca-certificates \
    software-properties-common

# Install Google Cloud CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y google-cloud-cli && \
    # Cleanup
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# USER CONFIGURATION

# Add coder user to the docker group (for docker.sock access)
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
    printf 'Host github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/id_ed25519\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n\nHost *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/id_ed25519\n' > /home/coder/.ssh/config && \
    chown -R coder:coder /home/coder/.ssh && \
    chmod 600 /home/coder/.ssh/config

# CODE-SERVER EXTENSIONS INSTALLATION

USER coder

RUN code-server --install-extension Continue.continue && \
    code-server --install-extension redhat.vscode-yaml && \
    code-server --install-extension ms-python.python && \
    code-server --install-extension ms-azuretools.vscode-docker && \
    code-server --install-extension eamodio.gitlens && \
    code-server --install-extension usernamehw.errorlens && \
    code-server --install-extension Anthropic.claude-code

# PREPARATION FOR INIT.SH

# Create marker files to prevent init.sh from re-running installations
# (everything is already in the Dockerfile)
RUN mkdir -p /home/coder/.local/share/code-server && \
    touch /home/coder/.local/share/code-server/.git-configured && \
    touch /home/coder/.local/share/code-server/.ai-ready

WORKDIR /var/apps
