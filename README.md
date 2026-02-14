# Dev Container Features Collection

This repository contains custom [dev container Features](https://containers.dev/implementors/features/) for use in VS Code Dev Containers and GitHub Codespaces. All features are hosted on GitHub Container Registry (GHCR) and follow the [dev container Feature distribution specification](https://containers.dev/implementors/features-distribution/).

## Available Features

This collection provides the following features:

### `bun`

Installs [Bun](https://bun.sh) - a fast JavaScript runtime, bundler, transpiler, and package manager.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/chunlea/devcontainers-features/bun:1": {
            "version": "latest"
        }
    }
}
```

**Options:**
- `version` (string): Select the version to install. Use `"latest"` for the stable release, or specify a version number (e.g., `"1.1.0"`). Default: `"latest"`

### `claude-code`

Installs [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) using native binary installation and the Claude Code VS Code extension.

```jsonc
{
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

**Options:**
- `version` (string): Select the version to install - `"stable"`, `"latest"`, or a specific version (e.g., `"2.0.25"`). Default: `"stable"`
- `useOAuthToken` (boolean): Skip onboarding and use OAuth token authentication. Default: `true`
- `autoUpdates` (boolean): Enable automatic updates for Claude Code. Default: `true`
- `useSandbox` (boolean): Install bubblewrap for sandbox support (required for bash command sandboxing on Linux). Default: `true`

**VS Code Extensions:** Automatically installs `anthropic.claude-code`

**Authentication:** Run `claude setup-token` on your host machine to get your OAuth token, then set it as the `CLAUDE_CODE_OAUTH_TOKEN` environment variable.

See the [claude-code feature README](src/claude-code/README.md) for detailed documentation, authentication options, and configuration examples.

## Usage

Reference features from this collection in your `devcontainer.json`:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/chunlea/devcontainers-features/bun:1": {},
        "ghcr.io/chunlea/devcontainers-features/claude-code:1": {
            "version": "stable"
        }
    }
}
```

## Repository Structure

```
├── src
│   ├── bun
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   └── README.md
│   ├── claude-code
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   ├── README.md
│   │   └── NOTES.md
...
```

Each Feature has:
- `devcontainer-feature.json` - Feature metadata and options
- `install.sh` - Installation script executed during container build
- `README.md` - Auto-generated documentation (generated from `devcontainer-feature.json` and optional `NOTES.md`)

## Development

### Repository Structure

Features are individually versioned by the `version` attribute in each Feature's `devcontainer-feature.json`. Features are versioned according to the [semver specification](https://semver.org/).

### Testing Locally

You can test features locally before publishing:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "./src/bun": {
            "version": "latest"
        }
    }
}
```

### Options

All available options for a Feature are declared in the `devcontainer-feature.json`. Options are exported as Feature-scoped environment variables during installation. For example:

```json
{
    "options": {
        "version": {
            "type": "string",
            "default": "latest",
            "description": "Version to install"
        }
    }
}
```

The option is available in `install.sh` as `${VERSION}` (capitalized and sanitized according to [option resolution](https://containers.dev/implementors/features/#option-resolution)).

## Publishing

This repository uses a [GitHub Action workflow](.github/workflows/release.yaml) that automatically publishes each Feature to GHCR when changes are pushed.

**Prerequisites:**
- *Allow GitHub Actions to create and approve pull requests* must be enabled in `Settings > Actions > General > Workflow permissions`
- Features must be marked as **public** in GHCR to stay within the free tier

### Marking Features Public

Navigate to each feature's package settings page and set visibility to `public`:

```
https://github.com/users/chunlea/packages/container/devcontainers-features%2F<featureName>/settings
```

### Collection Namespace

Features in this repository are published under the namespace:
```
ghcr.io/chunlea/devcontainers-features
```

A metadata package is also published containing information for tools that aid in Feature discovery.

## Adding to the Public Index

To make your features discoverable in the [containers.dev index](https://containers.dev/features):

1. Go to [github.com/devcontainers/devcontainers.github.io](https://github.com/devcontainers/devcontainers.github.io)
2. Open a PR to modify [collection-index.yml](https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml)

This index is used by [VS Code Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) and [GitHub Codespaces](https://github.com/features/codespaces) for their Feature selection UI.

## Resources

- [Dev Container Specification](https://containers.dev/)
- [Dev Container Features Specification](https://containers.dev/implementors/features/)
- [Features Distribution Specification](https://containers.dev/implementors/features-distribution/)
- [Bun Documentation](https://bun.sh/docs)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)

## License

See [LICENSE](LICENSE) for details.
