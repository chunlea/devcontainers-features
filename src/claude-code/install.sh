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

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_NAME="x64"
        ;;
    aarch64|arm64)
        ARCH_NAME="arm64"
        ;;
    *)
        echo "Warning: Architecture '$ARCH' may not be fully supported by Claude Code"
        ARCH_NAME="$ARCH"
        ;;
esac
echo "Detected architecture: $ARCH ($ARCH_NAME)"

# Helper function to retry commands with exponential backoff
retry_with_backoff() {
    local max_attempts=4
    local timeout=2
    local attempt=1
    local exitCode=0

    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        else
            exitCode=$?
        fi

        echo "Attempt $attempt failed. Retrying in ${timeout}s..."
        sleep $timeout
        attempt=$((attempt + 1))
        timeout=$((timeout * 2))
    done

    echo "Command failed after $max_attempts attempts"
    return $exitCode
}

# Install required dependencies
echo "Installing required dependencies..."

# Detect OS and install dependencies
if [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    echo "Installing required dependencies for Alpine..."
    apk add --no-cache libgcc libstdc++ ripgrep git curl bash
    export USE_BUILTIN_RIPGREP=0
elif command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu"
    apt-get update && apt-get install -y curl git ripgrep || {
        # ripgrep might not be in default repos, try without it
        apt-get install -y curl git
        echo "Note: ripgrep not available in default repositories. Claude Code will use built-in ripgrep."
    }
elif command -v yum >/dev/null 2>&1; then
    echo "Detected RHEL/CentOS"
    yum install -y curl git
    # Try to install ripgrep if available
    yum install -y ripgrep 2>/dev/null || echo "Note: ripgrep not available. Claude Code will use built-in ripgrep."
elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl git ripgrep
else
    echo "Warning: Unknown package manager. Please ensure curl, git, and ripgrep are installed."
fi

# Verify essential tools are installed
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not installed and could not be automatically installed."
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Warning: git is not installed. Some Claude Code features may not work properly."
fi

# Install Claude Code using the native binary installation script
echo "Downloading and installing Claude Code..."

# Install for the remote user if specified, otherwise for root
INSTALL_USER=${_REMOTE_USER:-root}
INSTALL_USER_HOME=${_REMOTE_USER_HOME:-$HOME}

echo "Installing for user: $INSTALL_USER (home: $INSTALL_USER_HOME)"

# Helper function to run the installer
run_installer() {
    local version_arg="$1"
    local install_cmd="curl -fsSL https://claude.ai/install.sh | bash"

    if [ -n "$version_arg" ]; then
        install_cmd="curl -fsSL https://claude.ai/install.sh | bash -s $version_arg"
    fi

    if [ "$INSTALL_USER" != "root" ]; then
        su - "$INSTALL_USER" -c "$install_cmd"
    else
        eval "$install_cmd"
    fi
}

# Determine version argument
VERSION_ARG=""
if [ "$VERSION" = "stable" ]; then
    VERSION_ARG=""
elif [ "$VERSION" = "latest" ]; then
    VERSION_ARG="latest"
else
    VERSION_ARG="$VERSION"
fi

# Run installer with retry logic
echo "Running Claude Code installer (with retry on network failure)..."
if ! retry_with_backoff run_installer "$VERSION_ARG"; then
    echo "Error: Failed to install Claude Code after multiple attempts"
    exit 1
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

# Configure Claude Code settings
echo "Configuring Claude Code settings..."
CLAUDE_CONFIG_FILE="$INSTALL_USER_HOME/.claude.json"

# Ensure jq is installed for JSON manipulation
if ! command -v jq >/dev/null 2>&1; then
    echo "jq is not installed. Installing jq for JSON manipulation..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y jq
    elif command -v yum >/dev/null 2>&1; then
        yum install -y jq
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache jq
    else
        echo "Error: Cannot install jq. Please install jq manually."
        exit 1
    fi
fi

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

# Install sandbox support if enabled
if [ "$USESANDBOX" = "true" ]; then
    echo "Installing sandbox support packages..."

    if [ -f /etc/alpine-release ]; then
        apk add --no-cache bubblewrap
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get install -y bubblewrap
    elif command -v yum >/dev/null 2>&1; then
        yum install -y bubblewrap
    else
        echo "Warning: Could not install bubblewrap for sandbox support. Please install manually if needed."
    fi

    if command -v bwrap >/dev/null 2>&1; then
        echo "Sandbox support (bubblewrap) installed successfully"
    else
        echo "Warning: bubblewrap installation may have failed. Sandbox features may not work."
    fi
else
    echo "Sandbox support disabled, skipping bubblewrap installation"
fi

echo "Claude Code feature activation complete!"
