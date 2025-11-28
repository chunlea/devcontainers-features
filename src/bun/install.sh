#!/bin/sh
set -e

echo "Activating feature 'bun'"

VERSION=${VERSION:-latest}

echo "Installing Bun version: $VERSION"

# The 'install.sh' entrypoint script is always executed as the root user.
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

# Install required dependencies
echo "Installing required dependencies..."

# Detect OS and install dependencies (unzip is required for bun installation)
if [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    apk add --no-cache curl unzip bash
elif command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu"
    apt-get update && apt-get install -y curl unzip
elif command -v yum >/dev/null 2>&1; then
    echo "Detected RHEL/CentOS"
    yum install -y curl unzip
elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl unzip bash
else
    echo "Warning: Unknown package manager. Please ensure curl and unzip are installed."
fi

# Verify essential tools are installed
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not installed and could not be automatically installed."
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo "Error: unzip is not installed and could not be automatically installed."
    exit 1
fi

# Install Bun using the official installation script
echo "Downloading and installing Bun..."

# Install for the remote user if specified, otherwise for root
INSTALL_USER=${_REMOTE_USER:-root}
INSTALL_USER_HOME=${_REMOTE_USER_HOME:-$HOME}

echo "Installing for user: $INSTALL_USER (home: $INSTALL_USER_HOME)"

# Build installation command based on version
if [ "$VERSION" = "latest" ]; then
    INSTALL_CMD="curl -fsSL https://bun.sh/install | bash"
else
    # Install specific version (e.g., "1.1.0" -> "bun-v1.1.0")
    INSTALL_CMD="curl -fsSL https://bun.sh/install | bash -s bun-v$VERSION"
fi

# Execute installation
if [ "$INSTALL_USER" != "root" ]; then
    su - "$INSTALL_USER" -c "$INSTALL_CMD"
else
    eval "$INSTALL_CMD"
fi

# The installer places bun in ~/.bun/bin, which may not be in PATH yet
# Create symlink to /usr/local/bin for easier access
echo "Setting up bun command..."

# Check installation location for the user we installed for
if [ -f "$INSTALL_USER_HOME/.bun/bin/bun" ]; then
    ln -sf "$INSTALL_USER_HOME/.bun/bin/bun" /usr/local/bin/bun
    echo "Created symlink: /usr/local/bin/bun -> $INSTALL_USER_HOME/.bun/bin/bun"
    chmod +x "$INSTALL_USER_HOME/.bun/bin/bun"
elif [ -f "/root/.bun/bin/bun" ]; then
    ln -sf "/root/.bun/bin/bun" /usr/local/bin/bun
    echo "Created symlink: /usr/local/bin/bun -> /root/.bun/bin/bun"
    chmod +x "/root/.bun/bin/bun"
fi

# Verify installation
echo "Verifying Bun installation..."
if command -v bun >/dev/null 2>&1; then
    echo "Bun installed successfully!"
    bun --version || true
else
    echo "Warning: bun command not found in PATH. Installation may have failed."
    exit 1
fi

echo "Bun feature activation complete!"
