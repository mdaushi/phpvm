#!/bin/bash

# Install script for phpvm - PHP Version Manager

set -euo pipefail

PHPVM_DIR="$HOME/.phpvm"
PHPVM_SCRIPT="$PHPVM_DIR/phpvm.sh"
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
if ! mkdir -p "$PHPVM_DIR"; then
    phpvm_err "Failed to create directory: $PHPVM_DIR"
    exit 1
fi

phpvm_echo "Downloading phpvm script from $GITHUB_REPO_URL..."
if ! curl -fsSL "$GITHUB_REPO_URL" -o "$PHPVM_SCRIPT"; then
    phpvm_err "Download failed. Please check your internet connection and URL."
    exit 1
fi

if ! chmod +x "$PHPVM_SCRIPT"; then
    phpvm_err "Failed to make the phpvm script executable."
    exit 1
fi

# Determine user's shell profile
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

# Add phpvm to shell profile if not already present
if ! grep -q "source \"$PHPVM_SCRIPT\"" "$SHELL_PROFILE" 2>/dev/null; then
    phpvm_echo "Adding phpvm to $SHELL_PROFILE..."
    {
        echo ""
        echo "# Load phpvm"
        echo "if [ -f \"$PHPVM_SCRIPT\" ]; then"
        echo "    source \"$PHPVM_SCRIPT\""
        echo "fi"
    } >> "$SHELL_PROFILE" || { phpvm_err "Failed to update $SHELL_PROFILE"; exit 1; }
else
    phpvm_warn "phpvm is already configured in $SHELL_PROFILE"
fi

phpvm_echo "phpvm installation complete!"
phpvm_echo "Restart your terminal or run:"
phpvm_echo "source $SHELL_PROFILE"
