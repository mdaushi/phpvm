#!/bin/bash

# Install script for phpvm - PHP Version Manager

set -euo pipefail

PHPVM_DIR="$HOME/.phpvm"
PHPVM_SCRIPT="$PHPVM_DIR/phpvm.sh"
PHPVM_COMPLETION="$PHPVM_DIR/phpvm_completion.sh"
GITHUB_REPO_URL="https://raw.githubusercontent.com/Thavarshan/phpvm/main/phpvm.sh"

# ANSI color codes
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

phpvm_echo() {
    command printf "%b%s%b\n" "$GREEN" "$*" "$RESET"
}

phpvm_err() {
    command >&2 printf "%bError: %s%b\n" "$RED" "$*" "$RESET"
}

phpvm_warn() {
    command >&2 printf "%bWarning: %s%b\n" "$YELLOW" "$*" "$RESET"
}

# Ensure required commands are available
if ! command -v curl &>/dev/null; then
    phpvm_err "curl is required but not installed. Aborting."
    exit 1
fi

phpvm_echo "Installing phpvm..."

# Create phpvm directory if it doesn't exist
if ! mkdir -p "$PHPVM_DIR/bin"; then
    phpvm_err "Failed to create directory: $PHPVM_DIR/bin"
    exit 1
fi

# Download phpvm script
phpvm_echo "Downloading phpvm script from $GITHUB_REPO_URL..."
if ! curl -fsSL "$GITHUB_REPO_URL" -o "$PHPVM_SCRIPT"; then
    phpvm_err "Download failed. Please check your internet connection and URL."
    exit 1
fi

# Make the script executable
if ! chmod +x "$PHPVM_SCRIPT"; then
    phpvm_err "Failed to make the phpvm script executable."
    exit 1
fi

# Determine user's shell profile
if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

# Ensure phpvm is loaded in the shell
if [ -f "$SHELL_PROFILE" ] && ! grep -q "\[\[ -s \"$PHPVM_SCRIPT\" \]\] && source \"$PHPVM_SCRIPT\"" "$SHELL_PROFILE" 2>/dev/null; then
    phpvm_echo "Adding phpvm loader to $SHELL_PROFILE..."
    {
        echo ""
        echo "# Load phpvm automatically"
        echo "[[ -s \"$PHPVM_SCRIPT\" ]] && source \"$PHPVM_SCRIPT\""
        echo "[[ -s \"$PHPVM_COMPLETION\" ]] && source \"$PHPVM_COMPLETION\""
    } >>"$SHELL_PROFILE" || {
        phpvm_err "Failed to update $SHELL_PROFILE"
        exit 1
    }
else
    phpvm_warn "phpvm is already configured in $SHELL_PROFILE"
fi

# Apply changes immediately
phpvm_echo "Applying changes..."
export PATH="$PHPVM_DIR/bin:$PATH"
source "$SHELL_PROFILE"

phpvm_echo "phpvm installation complete!"
phpvm_echo "You can now use phpvm immediately."
phpvm_echo "Run: phpvm use 8.4"
