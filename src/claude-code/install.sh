#!/bin/sh
set -e

echo "Activating feature 'claude-code'"

VERSION=${VERSION:-stable}
echo "Installing Claude Code version: $VERSION"

# The 'install.sh' entrypoint script is always executed as the root user.
#
# These following environment variables are passed in by the dev container CLI.
# These may be useful in instances where the context of the final
# remoteUser or containerUser is useful.
# For more details, see https://containers.dev/implementors/features#user-env-var
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

echo "The effective dev container containerUser is '$_CONTAINER_USER'"
echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"

# Detect OS
if [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    echo "Installing required dependencies for Alpine..."
    apk add --no-cache libgcc libstdc++ ripgrep curl bash
    export USE_BUILTIN_RIPGREP=0
fi

# Ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
    echo "curl is not installed. Installing curl..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y curl
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl
    else
        echo "Error: Cannot install curl. Please install curl manually."
        exit 1
    fi
fi

# Install Claude Code using the native binary installation script
echo "Downloading and installing Claude Code..."

# Install for the remote user if specified, otherwise for root
INSTALL_USER=${_REMOTE_USER:-root}
INSTALL_USER_HOME=${_REMOTE_USER_HOME:-$HOME}

echo "Installing for user: $INSTALL_USER (home: $INSTALL_USER_HOME)"

if [ "$VERSION" = "stable" ]; then
    # Install stable version (default)
    if [ "$INSTALL_USER" != "root" ]; then
        su - "$INSTALL_USER" -c "curl -fsSL https://claude.ai/install.sh | bash"
    else
        curl -fsSL https://claude.ai/install.sh | bash
    fi
elif [ "$VERSION" = "latest" ]; then
    # Install latest version
    if [ "$INSTALL_USER" != "root" ]; then
        su - "$INSTALL_USER" -c "curl -fsSL https://claude.ai/install.sh | bash -s latest"
    else
        curl -fsSL https://claude.ai/install.sh | bash -s latest
    fi
else
    # Install specific version
    if [ "$INSTALL_USER" != "root" ]; then
        su - "$INSTALL_USER" -c "curl -fsSL https://claude.ai/install.sh | bash -s $VERSION"
    else
        curl -fsSL https://claude.ai/install.sh | bash -s "$VERSION"
    fi
fi

# The installer places claude in ~/.local/bin, which may not be in PATH yet
# Create symlink to /usr/local/bin for easier access
echo "Setting up claude command..."

# Check installation location for the user we installed for
if [ -f "$INSTALL_USER_HOME/.local/bin/claude" ]; then
    ln -sf "$INSTALL_USER_HOME/.local/bin/claude" /usr/local/bin/claude
    echo "Created symlink: /usr/local/bin/claude -> $INSTALL_USER_HOME/.local/bin/claude"
    # Make sure the binary is executable by all users
    chmod +x "$INSTALL_USER_HOME/.local/bin/claude"
elif [ -f "/root/.local/bin/claude" ]; then
    ln -sf "/root/.local/bin/claude" /usr/local/bin/claude
    echo "Created symlink: /usr/local/bin/claude -> /root/.local/bin/claude"
    chmod +x "/root/.local/bin/claude"
fi

# Verify installation
echo "Verifying Claude Code installation..."
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code installed successfully!"
    claude --version || true
    echo "Note: Skipping 'claude doctor' check in container build environment"
else
    echo "Warning: Claude Code command not found in PATH. Installation may have failed."
    exit 1
fi

echo "Claude Code feature activation complete!"
