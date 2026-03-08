# Onboarding

## Volume Structure (Persistence)
All key data is mapped from the host to the container to survive rebuilds:

| Host Path | Container Path | Description |
|-----------|----------------|------|
| `./data/vscode` | `~/.local/share/code-server` | VS Code settings, SSL certificates |
| `./data/ssh` | `~/.ssh` | SSH keys (GitHub) |
| `./data/continue` | `~/.continue` | Continue configuration and chat history |
| `./data/claude` | `~/.claude` | Claude Code authorization and settings |
| `./data/gemini` | `~/.gemini` | Gemini Code Assist authorization |
| `./data/copilot` | `~/.config/github-copilot` | GitHub Copilot authorization |

## SSL Certificates (Clipboard Fix)
A CA certificate is generated on the first run.
1. Download `data/vscode/certs/rootCA.pem` from the host.
2. Install it in your browser under the "Authorities" section (Trusted Root Certification Authorities).
3. Refresh the page — the clipboard (Clipboard API) will now work.

## MCP Server
The MCP server is available at `http://192.168.0.10:9092/sse`.
It is automatically added to the Continue and Claude Code configuration on container startup.
