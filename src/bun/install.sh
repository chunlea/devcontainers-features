#!/bin/sh
set -e

echo "Activating feature 'bun'"

VERSION=${VERSION:-latest}
USEBASELINE=${USEBASELINE:-false}
CONFIGUREPATH=${CONFIGUREPATH:-true}

echo "Installing Bun version: $VERSION"
echo "Use baseline build: $USEBASELINE"
echo "Configure PATH: $CONFIGUREPATH"

# The 'install.sh' entrypoint script is always executed as the root user.
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

# Detect OS and install all dependencies in a single pass
echo "Installing required dependencies..."

if [ -f /etc/alpine-release ]; then
    echo "Detected Alpine Linux"
    apk add --no-cache curl unzip bash
elif command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get install -y curl unzip
elif command -v yum >/dev/null 2>&1; then
    echo "Detected RHEL/CentOS/Fedora"
    yum install -y curl unzip
else
    echo "Error: Unknown package manager. Please ensure curl and unzip are installed."
    exit 1
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

# Set environment variables for Bun installation
export BUN_INSTALL="$INSTALL_USER_HOME/.bun"

# Determine installation command based on version and build type
INSTALL_CMD="curl -fsSL https://bun.com/install | bash"

if [ "$VERSION" = "latest" ]; then
    # Standard latest stable release
    INSTALL_ARGS=""
elif [ "$VERSION" = "canary" ]; then
    # Canary pre-release build
    INSTALL_ARGS="-s bun-canary"
else
    # Specific version (e.g., "1.1.0" or "v1.1.0")
    CLEAN_VERSION="${VERSION#v}"
    INSTALL_ARGS="-s bun-v$CLEAN_VERSION"
fi

# Add baseline build flag if requested
if [ "$USEBASELINE" = "true" ]; then
    echo "Installing baseline build for older CPU compatibility..."
    export BUN_BASELINE="1"
fi

# Execute installation
if [ "$INSTALL_USER" != "root" ]; then
    if [ -n "$INSTALL_ARGS" ]; then
        su - "$INSTALL_USER" -c "export BUN_INSTALL=\"$BUN_INSTALL\"; ${USEBASELINE:+export BUN_BASELINE=\"1\"; }$INSTALL_CMD $INSTALL_ARGS"
    else
        su - "$INSTALL_USER" -c "export BUN_INSTALL=\"$BUN_INSTALL\"; ${USEBASELINE:+export BUN_BASELINE=\"1\"; }$INSTALL_CMD"
    fi
else
    if [ -n "$INSTALL_ARGS" ]; then
        sh -c "$INSTALL_CMD $INSTALL_ARGS"
    else
        sh -c "$INSTALL_CMD"
    fi
fi

# Verify installation and create symlink
echo "Setting up bun command..."

# Find the bun binary
BUN_BINARY=""
for home_dir in "$INSTALL_USER_HOME" "/root"; do
    if [ -f "$home_dir/.bun/bin/bun" ]; then
        BUN_BINARY="$home_dir/.bun/bin/bun"
        break
    fi
done

if [ -z "$BUN_BINARY" ]; then
    echo "Error: Bun binary not found after installation."
    exit 1
fi

# Create symlink and set permissions
chmod +x "$BUN_BINARY"
ln -sf "$BUN_BINARY" /usr/local/bin/bun
echo "Created symlink: /usr/local/bin/bun -> $BUN_BINARY"

# Verify installation
echo "Verifying Bun installation..."
if command -v bun >/dev/null 2>&1; then
    echo "Bun installed successfully!"
    bun --version
    bun --revision || echo "Note: Could not retrieve revision info"
else
    echo "Error: bun command not found in PATH after installation."
    exit 1
fi

# Configure PATH in shell profiles if requested
if [ "$CONFIGUREPATH" = "true" ] && [ "$INSTALL_USER" != "root" ]; then
    echo "Configuring PATH in shell profiles..."

    BUN_BIN_DIR="$INSTALL_USER_HOME/.bun/bin"

    # Function to add PATH configuration to a profile file
    configure_shell_profile() {
        PROFILE_FILE="$1"
        if [ -f "$PROFILE_FILE" ]; then
            # Check if configuration already exists
            if ! grep -q "BUN_INSTALL" "$PROFILE_FILE" 2>/dev/null; then
                echo "" >> "$PROFILE_FILE"
                echo "# Bun" >> "$PROFILE_FILE"
                echo "export BUN_INSTALL=\"\$HOME/.bun\"" >> "$PROFILE_FILE"
                echo "export PATH=\"\$BUN_INSTALL/bin:\$PATH\"" >> "$PROFILE_FILE"
                echo "Configured PATH in $PROFILE_FILE"
            else
                echo "PATH already configured in $PROFILE_FILE"
            fi
        fi
    }

    # Configure common shell profiles
    for profile in ".bashrc" ".zshrc" ".profile"; do
        configure_shell_profile "$INSTALL_USER_HOME/$profile"
    done

    # Configure fish shell if config exists
    FISH_CONFIG="$INSTALL_USER_HOME/.config/fish/config.fish"
    if [ -f "$FISH_CONFIG" ]; then
        if ! grep -q "BUN_INSTALL" "$FISH_CONFIG" 2>/dev/null; then
            echo "" >> "$FISH_CONFIG"
            echo "# Bun" >> "$FISH_CONFIG"
            echo "set -gx BUN_INSTALL \"\$HOME/.bun\"" >> "$FISH_CONFIG"
            echo "set -gx PATH \"\$BUN_INSTALL/bin\" \$PATH" >> "$FISH_CONFIG"
            echo "Configured PATH in $FISH_CONFIG"
        else
            echo "PATH already configured in $FISH_CONFIG"
        fi
    fi

    # Set ownership of modified files
    if [ "$INSTALL_USER" != "root" ]; then
        for profile in ".bashrc" ".zshrc" ".profile"; do
            [ -f "$INSTALL_USER_HOME/$profile" ] && chown "$INSTALL_USER:$INSTALL_USER" "$INSTALL_USER_HOME/$profile"
        done
        [ -f "$FISH_CONFIG" ] && chown "$INSTALL_USER:$INSTALL_USER" "$FISH_CONFIG"
    fi
fi

echo "Bun feature activation complete!"
