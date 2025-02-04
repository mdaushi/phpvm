#!/bin/bash

# Install script for phpvm - PHP Version Manager

PHPVM_DIR="$HOME/.phpvm"
PHPVM_SCRIPT="$PHPVM_DIR/phpvm"
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

phpvm_echo "Installing phpvm..."

# Create phpvm directory
mkdir -p "$PHPVM_DIR"

# Download phpvm script
phpvm_echo "Downloading phpvm script..."
curl -fsSL "$GITHUB_REPO_URL" -o "$PHPVM_SCRIPT"
chmod +x "$PHPVM_SCRIPT"

# Add phpvm to shell profile
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

if ! grep -q "source \$PHPVM_SCRIPT" "$SHELL_PROFILE"; then
    phpvm_echo "Adding phpvm to $SHELL_PROFILE..."
    echo -e "\n# Load phpvm\nif [ -f \"$PHPVM_SCRIPT\" ]; then\n    source \"$PHPVM_SCRIPT\"\nfi" >>"$SHELL_PROFILE"
fi

phpvm_echo "phpvm installation complete! Restart your terminal or run:"
phpvm_echo "source $SHELL_PROFILE"
