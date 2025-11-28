# Bun (bun)

Installs Bun - a fast JavaScript runtime, bundler, transpiler, and package manager.

## Example Usage

```json
"features": {
    "ghcr.io/chunlea/devcontainers-features/bun:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version to install. Use 'latest' for the stable release, or specify a version number (e.g., '1.1.0'). | string | latest |

## What is Bun?

Bun is an all-in-one JavaScript runtime and toolkit designed for speed, featuring:

- A fast JavaScript/TypeScript runtime
- A bundler
- A transpiler
- A package manager (npm-compatible)

For more information, visit [bun.sh](https://bun.sh/).

## Installation Notes

This feature installs Bun using the official installation script from bun.sh. The `unzip` package is automatically installed as a dependency.

The Bun binary is symlinked to `/usr/local/bin/bun` for easy access from anywhere in the container.
