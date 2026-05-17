#!/bin/bash

set -e

# ProtonVPN CLI Wrapper Installer
# This script downloads and installs the protonvpn wrapper to ~/.protonvpn-wrapper
# and adds the necessary source line to shell rc files.

REPO_URL="https://raw.githubusercontent.com/pjortiz/protonvpn-cli-wrapper/main"
WRAPPER_FILE="protonvpn_wrapper.sh"
INSTALL_DIR="$HOME/.protonvpn-wrapper"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Download the wrapper script to temp directory
log_info "Downloading ProtonVPN wrapper from GitHub..."
if ! curl -fsSL "$REPO_URL/$WRAPPER_FILE" -o "$TEMP_DIR/$WRAPPER_FILE"; then
    log_error "Failed to download $WRAPPER_FILE from $REPO_URL"
    exit 1
fi
log_info "Downloaded successfully."

# Step 2: Create install directory and copy file
log_info "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$TEMP_DIR/$WRAPPER_FILE" "$INSTALL_DIR/$WRAPPER_FILE"
chmod +x "$INSTALL_DIR/$WRAPPER_FILE"
log_info "Installed successfully."

# Step 3: Add source line to shell rc files
SOURCE_LINE="[ -f $INSTALL_DIR/$WRAPPER_FILE ] && source $INSTALL_DIR/$WRAPPER_FILE"

# Array of shell rc files to check (in order of precedence)
RC_FILES=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.profile"
    "$HOME/.zshrc"
    "$HOME/.config/fish/config.fish"
)

files_updated=0

for rc_file in "${RC_FILES[@]}"; do
    if [ -f "$rc_file" ]; then
        # Check if source line already exists
        if grep -q "source $INSTALL_DIR/$WRAPPER_FILE" "$rc_file" 2>/dev/null; then
            log_warn "$rc_file already contains the source line (skipping)"
        else
            # Add the source line to the file
            if [ "$(basename "$rc_file")" = "config.fish" ]; then
                # Fish shell uses different syntax
                echo "[ -f $INSTALL_DIR/$WRAPPER_FILE ] && source $INSTALL_DIR/$WRAPPER_FILE" >> "$rc_file"
            else
                echo "" >> "$rc_file"
                echo "# ProtonVPN CLI Wrapper" >> "$rc_file"
                echo "$SOURCE_LINE" >> "$rc_file"
            fi
            log_info "Added source line to $rc_file"
            ((files_updated++))
        fi
    fi
done

if [ $files_updated -eq 0 ]; then
    log_warn "No shell rc files were found or updated."
    log_info "Please manually add the following line to your shell rc file:"
    echo ""
    echo "    $SOURCE_LINE"
    echo ""
else
    log_info "Installation complete!"
    log_info "Reload your shell configuration by running: source ~/.bashrc (or your shell rc file)"
    echo ""
    echo "Available commands:"
    echo "  protonvpn connect           Start connection with port-forwarding keep-alive"
    echo "  protonvpn disconnect        Stop keep-alive before disconnecting"
    echo "  protonvpn get-port          Print the current mapped port"
    echo "  protonvpn keepalive-logs    Follow the live keep-alive log"
    echo "  protonvpn keepalive-stop    Stop the keep-alive background process"
fi
