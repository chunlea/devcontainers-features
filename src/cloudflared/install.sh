#!/bin/sh
set -e

echo "Activating feature 'cloudflared'"

VERSION=${VERSION:-latest}

echo "Installing cloudflared version: $VERSION"

# The 'install.sh' entrypoint script is always executed as the root user.
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    armv7l)
        ARCH="arm"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected architecture: $ARCH"

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
echo "Detected OS: $OS"

# Install required dependencies
echo "Installing required dependencies..."

if [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    apk add --no-cache curl ca-certificates
elif command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu"
    apt-get update && apt-get install -y curl ca-certificates
elif command -v yum >/dev/null 2>&1; then
    echo "Detected RHEL/CentOS"
    yum install -y curl ca-certificates
elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl ca-certificates
else
    echo "Warning: Unknown package manager. Please ensure curl and ca-certificates are installed."
fi

# Verify curl is installed
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not installed and could not be automatically installed."
    exit 1
fi

# Determine download URL
if [ "$VERSION" = "latest" ]; then
    DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${OS}-${ARCH}"
else
    # Strip leading 'v' if present
    CLEAN_VERSION="${VERSION#v}"
    DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/download/${CLEAN_VERSION}/cloudflared-${OS}-${ARCH}"
fi

echo "Downloading cloudflared from: $DOWNLOAD_URL"

# Download and install cloudflared
curl -fsSL "$DOWNLOAD_URL" -o /usr/local/bin/cloudflared

# Make executable
chmod +x /usr/local/bin/cloudflared

# Verify installation
echo "Verifying cloudflared installation..."
if command -v cloudflared >/dev/null 2>&1; then
    echo "cloudflared installed successfully!"
    cloudflared --version || true
else
    echo "Error: cloudflared command not found. Installation may have failed."
    exit 1
fi

echo "cloudflared feature activation complete!"
