#!/bin/sh
set -e

echo "Activating feature 'claude-code'"

VERSION=${VERSION:-stable}
USEOAUTHTOKEN=${USEOAUTHTOKEN:-true}
AUTOUPDATES=${AUTOUPDATES:-true}
USESANDBOX=${USESANDBOX:-true}

echo "Installing Claude Code version: $VERSION"
echo "Use OAuth Token: $USEOAUTHTOKEN"
echo "Auto Updates: $AUTOUPDATES"
echo "Use Sandbox: $USESANDBOX"

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

# Detect OS and install all dependencies in a single pass
echo "Installing required dependencies..."

if [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    # Install all dependencies including jq and sandbox support in one command
    PACKAGES="libgcc libstdc++ ripgrep git curl bash jq"
    [ "$USESANDBOX" = "true" ] && PACKAGES="$PACKAGES bubblewrap"
    apk add --no-cache $PACKAGES
    export USE_BUILTIN_RIPGREP=0
    echo "Installed packages: $PACKAGES"
elif command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu"
    # Single apt-get update and install all packages at once
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    PACKAGES="curl git jq"

    # Try to install ripgrep (might not be available in all repos)
    if apt-cache show ripgrep >/dev/null 2>&1; then
        PACKAGES="$PACKAGES ripgrep"
    else
        echo "Note: ripgrep not available in default repositories. Claude Code will use built-in ripgrep."
    fi

    # Add sandbox support if enabled
    [ "$USESANDBOX" = "true" ] && PACKAGES="$PACKAGES bubblewrap"

    apt-get install -y $PACKAGES
    echo "Installed packages: $PACKAGES"
elif command -v yum >/dev/null 2>&1; then
    echo "Detected RHEL/CentOS/Fedora"
    PACKAGES="curl git jq"

    # Try to install ripgrep if available
    if yum list ripgrep >/dev/null 2>&1; then
        PACKAGES="$PACKAGES ripgrep"
    else
        echo "Note: ripgrep not available. Claude Code will use built-in ripgrep."
    fi

    # Add sandbox support if enabled
    [ "$USESANDBOX" = "true" ] && PACKAGES="$PACKAGES bubblewrap"

    yum install -y $PACKAGES
    echo "Installed packages: $PACKAGES"
else
    echo "Error: Unknown package manager. Please ensure curl, git, jq, and optionally ripgrep and bubblewrap are installed."
    exit 1
fi

# Verify essential tools are installed
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not installed and could not be automatically installed."
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Warning: git is not installed. Some Claude Code features may not work properly."
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed and could not be automatically installed."
    exit 1
fi

# Verify sandbox support if enabled
if [ "$USESANDBOX" = "true" ]; then
    if command -v bwrap >/dev/null 2>&1; then
        echo "Sandbox support (bubblewrap) installed successfully"
    else
        echo "Warning: bubblewrap installation may have failed. Sandbox features may not work."
    fi
fi

# Install Claude Code using the native binary installation script
echo "Downloading and installing Claude Code..."

# Install for the remote user if specified, otherwise for root
INSTALL_USER=${_REMOTE_USER:-root}
INSTALL_USER_HOME=${_REMOTE_USER_HOME:-$HOME}

echo "Installing for user: $INSTALL_USER (home: $INSTALL_USER_HOME)"

# Determine install command based on version
if [ "$VERSION" = "stable" ]; then
    INSTALL_CMD="curl -fsSL https://claude.ai/install.sh | bash"
elif [ "$VERSION" = "latest" ]; then
    INSTALL_CMD="curl -fsSL https://claude.ai/install.sh | bash -s latest"
else
    INSTALL_CMD="curl -fsSL https://claude.ai/install.sh | bash -s $VERSION"
fi

# Execute installation
if [ "$INSTALL_USER" != "root" ]; then
    su - "$INSTALL_USER" -c "$INSTALL_CMD"
else
    sh -c "$INSTALL_CMD"
fi

# Verify installation and create symlink
echo "Setting up claude command..."

# Find the claude binary
CLAUDE_BINARY=""
for home_dir in "$INSTALL_USER_HOME" "/root"; do
    if [ -f "$home_dir/.local/bin/claude" ]; then
        CLAUDE_BINARY="$home_dir/.local/bin/claude"
        break
    fi
done

if [ -z "$CLAUDE_BINARY" ]; then
    echo "Error: Claude Code binary not found after installation."
    exit 1
fi

# Create symlink and set permissions
chmod +x "$CLAUDE_BINARY"
ln -sf "$CLAUDE_BINARY" /usr/local/bin/claude
echo "Created symlink: /usr/local/bin/claude -> $CLAUDE_BINARY"

# Verify installation
echo "Verifying Claude Code installation..."
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code installed successfully!"
    claude --version || echo "Note: Could not retrieve version in container build environment"
else
    echo "Error: Claude Code command not found in PATH after installation."
    exit 1
fi

# Configure Claude Code settings
echo "Configuring Claude Code settings..."
CLAUDE_CONFIG_FILE="$INSTALL_USER_HOME/.claude.json"

# Prepare the values for jq
HAS_COMPLETED_ONBOARDING=$([ "$USEOAUTHTOKEN" = "true" ] && echo "true" || echo "false")
AUTO_UPDATES=$([ "$AUTOUPDATES" = "true" ] && echo "true" || echo "false")

# Create or update .claude.json
if [ -f "$CLAUDE_CONFIG_FILE" ]; then
    echo "Claude config file exists at $CLAUDE_CONFIG_FILE, merging settings..."
    # Backup existing config
    cp "$CLAUDE_CONFIG_FILE" "$CLAUDE_CONFIG_FILE.backup"
    echo "Backup created at $CLAUDE_CONFIG_FILE.backup"

    # Merge the new settings with existing config using jq
    TEMP_FILE=$(mktemp)
    jq --argjson hasCompleted "$HAS_COMPLETED_ONBOARDING" \
       --argjson autoUpdates "$AUTO_UPDATES" \
       '. + {hasCompletedOnboarding: $hasCompleted, autoUpdates: $autoUpdates}' \
       "$CLAUDE_CONFIG_FILE" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$CLAUDE_CONFIG_FILE"
    echo "Settings merged successfully, preserving existing configuration"
else
    echo "Creating new Claude config file at $CLAUDE_CONFIG_FILE..."
    # Create new config file with just our settings
    jq -n --argjson hasCompleted "$HAS_COMPLETED_ONBOARDING" \
          --argjson autoUpdates "$AUTO_UPDATES" \
          '{hasCompletedOnboarding: $hasCompleted, autoUpdates: $autoUpdates}' \
          > "$CLAUDE_CONFIG_FILE"
fi

# Set ownership to the install user
if [ "$INSTALL_USER" != "root" ]; then
    chown "$INSTALL_USER:$INSTALL_USER" "$CLAUDE_CONFIG_FILE"
    [ -f "$CLAUDE_CONFIG_FILE.backup" ] && chown "$INSTALL_USER:$INSTALL_USER" "$CLAUDE_CONFIG_FILE.backup"
fi

echo "Settings configured in $CLAUDE_CONFIG_FILE:"
echo "  hasCompletedOnboarding: $HAS_COMPLETED_ONBOARDING"
echo "  autoUpdates: $AUTO_UPDATES"

echo "Claude Code feature activation complete!"
