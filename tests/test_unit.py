"""
Unit tests for the coder project — visible in VS Code Test Explorer.

These tests mirror the logic in scripts/unit_tests.sh and can be run via:
  - VS Code Test Explorer (Python extension)
  - pytest tests/
  - scripts/run_tests.sh unit (inside Docker)

Tests are categorised into three classes:
  - TestRequiredFiles     : critical project files must exist
  - TestDockerCompose     : docker-compose.yml must have correct volume mounts
  - TestInitShScript      : init.sh must contain required logic
"""

import os
import re
import subprocess
import pytest

PROJECT_DIR = "/var/apps/coder"
SCRIPTS_DIR = os.path.join(PROJECT_DIR, "scripts")
COMPOSE_FILE = os.path.join(PROJECT_DIR, "docker-compose.yml")
DOCKERFILE = os.path.join(PROJECT_DIR, "Dockerfile")
INIT_SH = os.path.join(SCRIPTS_DIR, "init.sh")


def _file_contains(filepath: str, pattern: str) -> bool:
    """Return True if filepath contains pattern (simple substring match)."""
    try:
        with open(filepath, encoding="utf-8") as fh:
            return pattern in fh.read()
    except OSError:
        return False


# ── Required project files ────────────────────────────────────────────────────


class TestRequiredFiles:
    """All critical project files must exist."""

    def test_dockerfile_exists(self):
        assert os.path.isfile(os.path.join(PROJECT_DIR, "Dockerfile"))

    def test_dockerfile_test_exists(self):
        assert os.path.isfile(os.path.join(PROJECT_DIR, "Dockerfile.test"))

    def test_docker_compose_exists(self):
        assert os.path.isfile(COMPOSE_FILE)

    def test_init_sh_exists(self):
        assert os.path.isfile(INIT_SH)

    def test_run_tests_sh_exists(self):
        assert os.path.isfile(os.path.join(SCRIPTS_DIR, "run_tests.sh"))

    def test_unit_tests_sh_exists(self):
        assert os.path.isfile(os.path.join(SCRIPTS_DIR, "unit_tests.sh"))

    def test_integration_tests_sh_exists(self):
        assert os.path.isfile(os.path.join(SCRIPTS_DIR, "integration_tests.sh"))

    def test_execpipe_sh_exists(self):
        assert os.path.isfile(os.path.join(SCRIPTS_DIR, "execpipe.sh"))

    def test_fix_execpipe_sh_exists(self):
        assert os.path.isfile(os.path.join(SCRIPTS_DIR, "fix-execpipe.sh"))

    def test_readme_exists(self):
        assert os.path.isfile(os.path.join(PROJECT_DIR, "README.md"))

    def test_agents_md_exists(self):
        assert os.path.isfile(os.path.join(PROJECT_DIR, "AGENTS.md"))

    def test_agents_onboarding_exists(self):
        assert os.path.isfile(
            os.path.join(PROJECT_DIR, ".agents", "workflows", "onboarding.md")
        )

    def test_agents_development_exists(self):
        assert os.path.isfile(
            os.path.join(PROJECT_DIR, ".agents", "workflows", "development.md")
        )

    def test_agents_terminal_usage_exists(self):
        assert os.path.isfile(
            os.path.join(PROJECT_DIR, ".agents", "workflows", "terminal-usage.md")
        )

    def test_pre_commit_config_exists(self):
        assert os.path.isfile(os.path.join(PROJECT_DIR, ".pre-commit-config.yaml"))

    def test_pyproject_toml_exists(self):
        assert os.path.isfile(os.path.join(PROJECT_DIR, "pyproject.toml"))

    def test_env_example_exists(self):
        assert os.path.isfile(os.path.join(PROJECT_DIR, ".env.example")), (
            ".env.example must exist to document required environment variables"
        )

    def test_env_example_has_mcp_url(self):
        env_example = os.path.join(PROJECT_DIR, ".env.example")
        assert _file_contains(env_example, "MCP_SSE_URL"), (
            ".env.example must document MCP_SSE_URL so users know how to configure the MCP server"
        )


# ── docker-compose.yml volume mounts ─────────────────────────────────────────


class TestDockerCompose:
    """docker-compose.yml must declare all required volume mounts for persistence."""

    REQUIRED_VOLUMES = [
        ("data/vscode", "VS Code extensions and settings"),
        ("data/continue", "Continue AI config"),
        ("data/ssh", "SSH keys for GitHub"),
        ("data/claude", "Claude Code auth"),
        ("data/gemini", "Gemini Code Assist auth"),
        ("data/google-vscode-auth", "Google VS Code extension auth"),
        ("data/copilot", "GitHub Copilot auth"),
        ("data/gh", "gh CLI auth"),
        ("data/gcloud", "Google Cloud credentials"),
        ("/var/apps:/var/apps", "host workspace mount"),
    ]

    @pytest.mark.parametrize("pattern,description", REQUIRED_VOLUMES)
    def test_volume_mount_present(self, pattern: str, description: str):
        assert _file_contains(COMPOSE_FILE, pattern), (
            f"docker-compose.yml is missing volume mount for {description} "
            f"(expected pattern: {pattern!r})"
        )

    def test_no_obsolete_version_attribute(self):
        """docker-compose.yml must not have the obsolete 'version:' top-level key."""
        pytest.importorskip("yaml", reason="PyYAML not installed")
        import yaml  # noqa: PLC0415
        with open(COMPOSE_FILE, encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
        assert "version" not in data, (
            "docker-compose.yml must not have 'version' attribute — it is obsolete in "
            "Compose v2 and causes warnings that break CI strict mode"
        )

    def test_env_file_is_optional(self):
        """env_file in docker-compose.yml must be optional so CI works without .env."""
        assert _file_contains(COMPOSE_FILE, "required: false"), (
            "docker-compose.yml env_file must be configured with 'required: false' "
            "so that CI pipelines without a .env file don't fail"
        )

    def test_extra_hosts_hostname_fix(self):
        """extra_hosts must map code-server to 127.0.0.1 so sudo can resolve hostname."""
        assert _file_contains(COMPOSE_FILE, "code-server:127.0.0.1"), (
            "docker-compose.yml must have extra_hosts entry 'code-server:127.0.0.1' "
            "to prevent 'sudo: unable to resolve host' warnings on startup"
        )

    def test_compose_is_valid_yaml(self):
        """docker-compose.yml must be parseable YAML."""
        pytest.importorskip("yaml", reason="PyYAML not installed — skipping YAML validation")
        import yaml  # noqa: PLC0415
        with open(COMPOSE_FILE, encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
        assert "services" in data, "docker-compose.yml has no 'services' key"

    def test_compose_has_code_server_service(self):
        pytest.importorskip("yaml", reason="PyYAML not installed")
        import yaml  # noqa: PLC0415
        with open(COMPOSE_FILE, encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
        assert "code-server" in data.get("services", {}), (
            "docker-compose.yml must define a 'code-server' service"
        )


# ── init.sh content checks ────────────────────────────────────────────────────


class TestInitShScript:
    """init.sh must contain all critical setup logic."""

    def test_mkcert_certificate_generation(self):
        assert _file_contains(INIT_SH, "mkcert"), (
            "init.sh must call mkcert to generate HTTPS certificate"
        )

    def test_docker_api_version_fix(self):
        assert _file_contains(INIT_SH, "DOCKER_API_VERSION"), (
            "init.sh must export DOCKER_API_VERSION for Docker client/daemon compat"
        )

    def test_mcp_configured_for_continue(self):
        assert _file_contains(INIT_SH, "ha-mcp"), (
            "init.sh must patch ha-mcp MCP server into Continue config"
        )

    def test_mcp_configured_for_claude_code(self):
        assert _file_contains(INIT_SH, "CLAUDE_SETTINGS"), (
            "init.sh must configure MCP server for Claude Code"
        )

    def test_mcp_url_from_env(self):
        """init.sh must read MCP_SSE_URL from environment (not hardcoded)."""
        assert _file_contains(INIT_SH, "MCP_SSE_URL"), (
            "init.sh must use MCP_SSE_URL variable so the URL is configurable via .env"
        )

    def test_vscode_mcp_always_patched(self):
        """VS Code settings MCP section must be patched on every startup, not just first run."""
        assert _file_contains(INIT_SH, "Patching MCP into VS Code settings"), (
            "init.sh must always patch MCP into VS Code settings (not only on first run) "
            "so that MCP_SSE_URL changes take effect without wiping data/vscode"
        )

    def test_ssh_key_generation(self):
        assert _file_contains(INIT_SH, "ssh-keygen"), (
            "init.sh must generate SSH key for GitHub"
        )

    def test_claude_json_symlink(self):
        assert _file_contains(INIT_SH, "claude.json"), (
            "init.sh must symlink ~/.claude.json into the volume"
        )

    def test_extensions_restore(self):
        assert _file_contains(INIT_SH, "code-server-extensions"), (
            "init.sh must restore extensions from image cold-copy when volume is empty"
        )

    def test_auth_status_report(self):
        assert _file_contains(INIT_SH, "AUTH PERSISTENCE STATUS"), (
            "init.sh must print auth status on startup"
        )

    def test_starts_code_server(self):
        assert _file_contains(INIT_SH, "exec code-server"), (
            "init.sh must launch code-server via exec"
        )

    def test_workspace_is_var_apps(self):
        assert _file_contains(INIT_SH, "/var/apps"), (
            "init.sh must launch code-server with /var/apps workspace"
        )

    def test_cache_dir_chowned_not_subdir(self):
        """init.sh must chown /home/coder/.cache (not just google-vscode-extension subdir).

        Docker creates the .cache parent directory as root when mounting a subdirectory
        volume.  If only the subdir is chowned, VS Code cannot create .cache/Microsoft/
        and extensions like Gemini Code Assist fail to load (EACCES).
        """
        with open(INIT_SH, encoding="utf-8") as fh:
            content = fh.read()
        assert "/home/coder/.cache\n" in content or "/home/coder/.cache \\" in content, (
            "init.sh must chown /home/coder/.cache (the parent), not only its subdirectory. "
            "Docker mounts subdirectory volumes with root-owned parents."
        )

    def test_continue_config_preserved_if_exists(self):
        """init.sh must NOT unconditionally overwrite the Continue config.

        Overwriting destroys models added via the UI.  The config should only be
        generated when it is missing or contains no models.
        """
        assert _file_contains(INIT_SH, "preserving"), (
            "init.sh must skip generating Continue config when it already has models"
        )


# ── Shell script syntax ───────────────────────────────────────────────────────


class TestShellScripts:
    """All shell scripts must pass bash -n syntax check."""

    @pytest.fixture(
        params=[
            f
            for f in os.listdir(SCRIPTS_DIR)
            if f.endswith(".sh")
        ]
    )
    def script_file(self, request):
        return os.path.join(SCRIPTS_DIR, request.param)

    def test_bash_syntax(self, script_file):
        result = subprocess.run(
            ["bash", "-n", script_file],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"Bash syntax error in {script_file}:\n{result.stderr}"
        )

    @pytest.fixture(
        params=[
            f
            for f in os.listdir(SCRIPTS_DIR)
            if f.endswith(".sh")
        ]
    )
    def script_file_sc(self, request):
        return os.path.join(SCRIPTS_DIR, request.param)

    def test_shellcheck(self, script_file_sc):
        """Run shellcheck if available; skip otherwise."""
        if subprocess.run(["which", "shellcheck"], capture_output=True).returncode != 0:
            pytest.skip("shellcheck not installed")
        result = subprocess.run(
            ["shellcheck", "--severity=warning", script_file_sc],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"shellcheck found issues in {script_file_sc}:\n{result.stdout}"
        )


# ── Dockerfile checks ─────────────────────────────────────────────────────────


class TestDockerfile:
    """Dockerfile must install required tools and extensions."""

    def test_mkcert_installed(self):
        assert _file_contains(DOCKERFILE, "mkcert"), (
            "Dockerfile must install mkcert for HTTPS certificate generation"
        )

    def test_claude_code_extension(self):
        assert _file_contains(DOCKERFILE, "Anthropic.claude-code"), (
            "Dockerfile must install Claude Code extension"
        )

    def test_continue_extension(self):
        assert _file_contains(DOCKERFILE, "Continue.continue"), (
            "Dockerfile must install Continue extension"
        )

    def test_github_copilot_extension(self):
        assert _file_contains(DOCKERFILE, "GitHub.copilot"), (
            "Dockerfile must attempt to install GitHub Copilot extension"
        )

    def test_extensions_cold_copy(self):
        assert _file_contains(DOCKERFILE, "code-server-extensions"), (
            "Dockerfile must copy extensions to cold-copy dir for volume restore"
        )
