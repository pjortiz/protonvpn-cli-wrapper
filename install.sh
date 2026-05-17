#!/bin/bash

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

prompt_confirm() {
    local prompt="$1"
    local response
    if [ -t 0 ]; then
        read -r -p "$prompt (y/n) " response
    elif [ -r /dev/tty ]; then
        read -r -p "$prompt (y/n) " response </dev/tty
    else
        return 1
    fi
    [[ "$response" =~ ^[Yy]$ ]]
}

# Step 1: Download the wrapper script to temp directory
log_info "Downloading ProtonVPN wrapper from GitHub..."
if ! curl -fsSL "$REPO_URL/$WRAPPER_FILE" -o "$TEMP_DIR/$WRAPPER_FILE"; then
    log_error "Failed to download $WRAPPER_FILE from $REPO_URL"
    exit 1
fi
log_info "Downloaded successfully."

# Step 2: Check if already installed and prompt for confirmation
if [ -f "$INSTALL_DIR/$WRAPPER_FILE" ]; then
    log_warn "ProtonVPN wrapper is already installed at $INSTALL_DIR"
    if ! prompt_confirm "Do you want to override the existing installation?"; then
        log_info "Installation cancelled."
        exit 0
    fi
    log_info "Proceeding with override..."
fi

# Step 3: Create install directory and copy file
log_info "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$TEMP_DIR/$WRAPPER_FILE" "$INSTALL_DIR/$WRAPPER_FILE"
chmod +x "$INSTALL_DIR/$WRAPPER_FILE"
log_info "Installed successfully."

# Step 4: Add source line to shell rc files
SOURCE_LINE="[ -f $INSTALL_DIR/$WRAPPER_FILE ] && source $INSTALL_DIR/$WRAPPER_FILE"

# Array of shell rc files to check (in order of precedence)
RC_FILES=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.profile"
    "$HOME/.zshrc"
    "$HOME/.config/fish/config.fish"
)

# Check if source line already exists in any rc file
source_line_exists=false
for rc_file in "${RC_FILES[@]}"; do
    if [ -f "$rc_file" ]; then
        if grep -q "source $INSTALL_DIR/$WRAPPER_FILE" "$rc_file" 2>/dev/null; then
            log_warn "$rc_file already contains the source line"
            source_line_exists=true
            break
        fi
    fi
done

files_updated=0
files_found=0

# Only add to rc files if source line doesn't already exist
if [ "$source_line_exists" = false ]; then
    for rc_file in "${RC_FILES[@]}"; do
        if [ -f "$rc_file" ]; then
            ((files_found++))
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
    done
else
    # Count existing rc files for the final message
    for rc_file in "${RC_FILES[@]}"; do
        if [ -f "$rc_file" ]; then
            ((files_found++))
        fi
    done
fi

if [ $files_found -eq 0 ]; then
    log_warn "No shell rc files were found."
    log_info "Please manually add the following line to your shell rc file:"
    echo ""
    echo "    $SOURCE_LINE"
    echo ""
else
    log_info "Installation complete!"
    log_info "Reload your shell configuration by running: source ~/.bashrc (or your shell rc file)"
    source $INSTALL_DIR/$WRAPPER_FILE
    echo ""
    protonvpn_help
fi
