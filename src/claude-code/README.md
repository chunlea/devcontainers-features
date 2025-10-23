
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
| version | Select the version to install. Use 'stable' for the stable release, 'latest' for the most recent version, or specify a version number (e.g., '1.0.58'). | string | stable |

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
        "ghcr.io/<owner>/<repo>/claude-code:1": {
            "version": "stable"
        }
    }
}
```

## Version Options

- `stable` (default): Installs the stable release of Claude Code
- `latest`: Installs the most recent version of Claude Code
- Specific version number (e.g., `1.0.58`): Installs that specific version

## Authentication

⚠️ **Important**: This feature installs Claude Code but does NOT handle authentication. You must configure authentication separately.

### Authentication Methods

Claude Code supports three authentication methods:

#### 1. Docker Volume Mount (Recommended for Dev Containers)

This is Anthropic's official pattern. Use a Docker volume to persist credentials across container rebuilds:

```jsonc
{
    "features": {
        "ghcr.io/<owner>/<repo>/claude-code:1": {}
    },
    "mounts": [
        "source=claude-credentials,target=/home/vscode/.claude,type=volume"
    ]
}
```

**First-time setup**: Run `claude` inside the container to authenticate. Credentials persist in the volume.

**Pros**: Isolated, persists across rebuilds, secure
**Cons**: Requires initial authentication inside container

#### 2. Host Directory Bind Mount (Local Development)

Mount your host's `.claude` directory to share credentials:

```jsonc
{
    "features": {
        "ghcr.io/<owner>/<repo>/claude-code:1": {}
    },
    "mounts": [
        "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"
    ]
}
```

**Pros**: Shares credentials with host, no re-authentication
**Cons**: Host credentials accessible in container

#### 3. Environment Variable (CI/CD & Teams)

Use an API key via environment variable:

```jsonc
{
    "features": {
        "ghcr.io/<owner>/<repo>/claude-code:1": {}
    },
    "containerEnv": {
        "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
    }
}
```

Or use remoteEnv for Codespaces:

```jsonc
{
    "features": {
        "ghcr.io/<owner>/<repo>/claude-code:1": {}
    },
    "remoteEnv": {
        "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
    }
}
```

**Pros**: Works for CI/CD, shareable with team
**Cons**: Requires API key management

## Configuration

### Project-Level Settings

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

## Complete Examples

### Example 1: Local Development with Host Credentials

```jsonc
{
    "name": "My Project",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/<owner>/<repo>/claude-code:1": {
            "version": "stable"
        }
    },
    "mounts": [
        // Share host's Claude credentials
        "source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"
    ]
}
```

### Example 2: Team Development with Docker Volume

```jsonc
{
    "name": "Team Project",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/<owner>/<repo>/claude-code:1": {
            "version": "latest"
        }
    },
    "mounts": [
        // Persistent credentials in Docker volume
        "source=claude-credentials-${devcontainerId},target=/home/vscode/.claude,type=volume"
    ]
}
```

Create `.claude/settings.json` in your project:
```json
{
  "model": "claude-sonnet-4-5",
  "permissions": {
    "allowedTools": ["Read", "Write", "Edit", "Bash(git *)"]
  }
}
```

### Example 3: CI/CD with API Key

```jsonc
{
    "name": "CI/CD Container",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/<owner>/<repo>/claude-code:1": {
            "version": "stable"
        }
    },
    "remoteEnv": {
        "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
    }
}
```

Set the API key in your CI environment variables or GitHub Codespaces secrets.

## Security Considerations

⚠️ **Important Security Notes**:

1. **Only use Claude Code in dev containers with trusted repositories** - A malicious project could access credentials mounted in the container
2. **Never commit credentials** to source control - Use volumes or environment variables
3. **Use project-level config** (`.claude/settings.json`) for team settings, not credentials
4. **Network isolation**: Consider Anthropic's firewall pattern for additional security ([see docs](https://docs.claude.com/en/docs/claude-code/devcontainer))

## After Installation

Once the container is built, you can use:

### CLI Commands
```bash
claude --version
claude --help
claude doctor
```

### VS Code Extension
The Claude Code extension will be automatically installed and available in VS Code's sidebar.

## Troubleshooting

### Authentication Issues

If `claude` reports authentication errors:

1. **Volume mount**: Run `claude` to authenticate inside the container
2. **Bind mount**: Authenticate on host first with `claude`
3. **API key**: Verify `ANTHROPIC_API_KEY` is set: `echo $ANTHROPIC_API_KEY`

### Permission Errors

If you see permission errors accessing `.claude`:
- Ensure the mount target matches the container user's home directory
- Default is `/home/vscode/.claude` for the vscode user

### VS Code Extension Not Loading

If the extension doesn't appear:
- Rebuild the container: Command Palette → "Dev Containers: Rebuild Container"
- Check the extension is listed: Command Palette → "Extensions: Show Installed Extensions"

## Additional Resources

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Dev Container Specification](https://containers.dev/)
- [Anthropic's Official Dev Container Setup](https://docs.claude.com/en/docs/claude-code/devcontainer)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/chunlea/devcontainers-features/blob/main/src/claude-code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
