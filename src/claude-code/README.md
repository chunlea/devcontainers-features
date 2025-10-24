
# Claude Code (claude-code)

Installs Claude Code CLI using native binary installation

## Example Usage

```json
"features": {
    "ghcr.io/chunlea/devcontainers-features/claude-code:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version to install. Use 'stable' for the stable release, 'latest' for the most recent version, or specify a version number (e.g., '2.0.25'). | string | stable |
| useOAuthToken | If true, marks hasCompletedOnboarding as true to use OAuth token authentication. | boolean | true |
| autoUpdates | Enable automatic updates for Claude Code. | boolean | true |
| useSandbox | Install bubblewrap for sandbox support. Required for bash command sandboxing on Linux. | boolean | true |

## Customizations

### VS Code Extensions

- `anthropic.claude-code`

## Overview

This feature installs:
- **Claude Code CLI** using the native binary installation method
- **Claude Code VS Code Extension** (`anthropic.claude-code`) automatically

## Quick Start

### Basic Installation

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/chunlea/devcontainers-features/claude-code:1": {
            "version": "stable"
        }
    }
}
```

## Configuration options

### Version

- `stable` (default): Installs the stable release of Claude Code
- `latest`: Installs the most recent version of Claude Code
- Specific version number (e.g., `2.0.25`): Installs that specific version

### Feature options

```jsonc
{
    "features": {
        "ghcr.io/chunlea/devcontainers-features/claude-code:1": {
            "version": "stable",           // Version to install (stable/latest/2.0.25)
            "useOAuthToken": true,         // Skip onboarding, use OAuth (default: true)
            "autoUpdates": true,           // Enable automatic updates (default: true)
            "useSandbox": true            // Install sandbox support (default: true)
        }
    }
}
```

**`useOAuthToken`** (default: `true`)
- When enabled, sets `hasCompletedOnboarding: true` in `~/.claude.json`
- Skips the initial onboarding flow and uses OAuth authentication
- Recommended for devcontainers to streamline setup

**`autoUpdates`** (default: `true`)
- Controls whether Claude Code automatically updates to newer versions
- Writes to `~/.claude.json` configuration

**`useSandbox`** (default: `true`)
- Installs `bubblewrap` for bash command sandboxing on Linux
- Required for secure execution of bash commands in isolated environments
- Includes installation of `git` and `ripgrep` dependencies

## Authentication

With `useOAuthToken: true` (default), Claude Code will skip the onboarding flow. You have two authentication options:

### Option 1: OAuth token environment variable (recommended)

Use an OAuth token via environment variable:

```jsonc
{
    "features": {
        "ghcr.io/chunlea/devcontainers-features/claude-code:1": {
            "useOAuthToken": true
        }
    },
    "containerEnv": {
        "CLAUDE_CODE_OAUTH_TOKEN": "${localEnv:CLAUDE_CODE_OAUTH_TOKEN}"
    }
}
```

**Getting your token**: Run this command on your host machine to get your OAuth token:

```bash
claude setup-token
```

This will display your token that you can set as the `CLAUDE_CODE_OAUTH_TOKEN` environment variable.

**Switching accounts**: If you need to use a different account, use the `/logout` command in Claude Code, then run `claude setup-token` again to get a new token.

### Option 2: Direct login

You can authenticate in two ways:

1. **During onboarding**: Run `claude` in your container and authenticate through the OAuth flow
2. **Using `/login` command**: Type `/login` in Claude Code to authenticate

```bash
claude
```

This will open a browser for authentication. Your credentials will be saved in the container.

## Configuration

### Project-level settings

Create `.claude/settings.json` in your project root for team-shared configuration:

```json
{
  "model": "claude-sonnet-4-5",
  "maxTokens": 8000,
  "permissions": {
    "allowedTools": [
      "Read",
      "Write",
      "Edit",
      "Bash(npm *)",
      "Bash(git *)",
      "Bash(docker *)"
    ],
    "deny": [
      "**/.env*",
      "**/secrets/**"
    ]
  },
  "hooks": {
    "postToolUse": {
      "Write(*.py)": "bash -c 'black $FILE_PATH'",
      "Edit(*.ts)": "bash -c 'prettier --write $FILE_PATH'"
    }
  },
  "env": {
    "NODE_ENV": "development"
  }
}
```

**Configuration Hierarchy** (highest to lowest precedence):
1. Enterprise managed policies
2. Command-line arguments
3. `.claude/settings.local.json` (git-ignored, personal)
4. `.claude/settings.json` (committed, team-shared) ← **Use this**
5. `~/.claude/settings.json` (user-level)

### Add to .gitignore

Add this to your `.gitignore`:

```gitignore
# Claude Code local settings (personal preferences)
.claude/settings.local.json
```

## Complete examples

### Example 1: Using OAuth token environment variable

```jsonc
{
    "name": "Team Project",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/chunlea/devcontainers-features/claude-code:1": {
            "version": "stable",
            "useOAuthToken": true,
            "autoUpdates": true,
            "useSandbox": true
        }
    },
    "containerEnv": {
        "CLAUDE_CODE_OAUTH_TOKEN": "${localEnv:CLAUDE_CODE_OAUTH_TOKEN}"
    }
}
```

Run `claude setup-token` on your host to get the token, then set `CLAUDE_CODE_OAUTH_TOKEN` in your environment variables.

### Example 2: Basic setup with direct login

```jsonc
{
    "name": "My Project",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/chunlea/devcontainers-features/claude-code:1": {
            "version": "stable",
            "useOAuthToken": true,
            "autoUpdates": true,
            "useSandbox": true
        }
    }
}
```

After the container starts, run `claude` or use `/login` command in Claude Code to authenticate.

### Example 3: Real-world Rails application

```jsonc
{
    "name": "best_crm",
    "dockerComposeFile": "compose.yaml",
    "service": "rails-app",
    "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
    "features": {
        "ghcr.io/devcontainers/features/github-cli:1": {},
        "ghcr.io/rails/devcontainer/features/activestorage": {},
        "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {
            "moby": false
        },
        "ghcr.io/rails/devcontainer/features/sqlite3": {},
        "ghcr.io/chunlea/devcontainers-features/claude-code:1": {
            "version": "stable",
            "useOAuthToken": true,
            "autoUpdates": true,
            "useSandbox": true
        }
    },
    "containerEnv": {
        "CAPYBARA_SERVER_PORT": "45678",
        "SELENIUM_HOST": "selenium",
        "KAMAL_REGISTRY_PASSWORD": "$KAMAL_REGISTRY_PASSWORD",
        "CLAUDE_CODE_OAUTH_TOKEN": "${localEnv:CLAUDE_CODE_OAUTH_TOKEN}"
    },
    "forwardPorts": [3000],
    "postCreateCommand": "bin/setup --skip-server"
}
```

This example shows:
- Integration with Docker Compose for multi-container setup
- Using `CLAUDE_CODE_OAUTH_TOKEN` environment variable for OAuth authentication
- Combined with other devcontainer features (GitHub CLI, Rails features, Docker)
- Production-like setup with custom ports and initialization scripts

## Security considerations

⚠️ **Important security notes**:

1. **Only use Claude Code in dev containers with trusted repositories** - A malicious project could access your credentials
2. **Never commit credentials** to source control - Use environment variables or login directly
3. **Use project-level config** (`.claude/settings.json`) for team settings, not credentials
4. **OAuth tokens**: If using `CLAUDE_CODE_OAUTH_TOKEN`, treat it like a password and store it securely

## After installation

Once the container is built, you can use:

### CLI commands
```bash
claude --version
claude --help
claude doctor
```

### VS Code extension
The Claude Code extension will be automatically installed and available in VS Code's sidebar.

## Troubleshooting

### Authentication issues

If `claude` reports authentication errors:

1. **OAuth token**: Run `claude setup-token` on your host to get your token, then set `CLAUDE_CODE_OAUTH_TOKEN`
2. **Direct login**: Run `claude` inside the container or use `/login` command in Claude Code
3. **Verify token**: Check if `CLAUDE_CODE_OAUTH_TOKEN` is set: `echo $CLAUDE_CODE_OAUTH_TOKEN`
4. **Different account**: Use `/logout` command in Claude Code, then use `/login` or run `claude setup-token` to get a new token

### VS Code extension not loading

If the extension doesn't appear:
- Rebuild the container: Command Palette → "Dev Containers: Rebuild Container"
- Check the extension is listed: Command Palette → "Extensions: Show Installed Extensions"

## Additional resources

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Dev Container Specification](https://containers.dev/)
- [Anthropic's Official Dev Container Setup](https://docs.claude.com/en/docs/claude-code/devcontainer)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/chunlea/devcontainers-features/blob/main/src/claude-code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
