#!/bin/bash

# phpvm - A PHP Version Manager written in Shell

PHPVM_DIR="$HOME/.phpvm"
PHPVM_VERSIONS_DIR="$PHPVM_DIR/versions"
PHPVM_ACTIVE_VERSION_FILE="$PHPVM_DIR/active_version"
PHPVM_CURRENT_SYMLINK="$PHPVM_DIR/current"
HOMEBREW_PHP_CELLAR="/opt/homebrew/Cellar"
HOMEBREW_PHP_BIN="/opt/homebrew/bin"

mkdir -p "$PHPVM_VERSIONS_DIR"

# ANSI color codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Output functions for better readability
phpvm_echo() {
    command printf "%b%s%b\n" "$GREEN" "$*" "$RESET"
}

phpvm_err() {
    command >&2 printf "%bError: %s%b\n" "$RED" "$*" "$RESET"
}

phpvm_warn() {
    command >&2 printf "%bWarning: %s%b\n" "$YELLOW" "$*" "$RESET"
}

# Function to install a specific PHP version
install_php() {
    local version=$1
    phpvm_echo "Installing PHP $version..."

    if command -v brew &>/dev/null; then
        brew install php@$version
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y php$version
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y php
    else
        phpvm_err "Unsupported Linux distribution."
        return 1
    fi
    phpvm_echo "PHP $version installed."
}

# Function to switch to a specific PHP version
use_php_version() {
    local version=$1
    phpvm_echo "Switching to PHP $version..."

    if command -v brew &>/dev/null && [[ -d "$HOMEBREW_PHP_CELLAR/php@$version" ]]; then
        brew unlink php &>/dev/null
        brew link php@$version --force --overwrite
        ln -sfn "$HOMEBREW_PHP_BIN/php" "$PHPVM_CURRENT_SYMLINK"
        echo "$version" >"$PHPVM_ACTIVE_VERSION_FILE"
        phpvm_echo "Switched to PHP $version."
    else
        phpvm_err "PHP version $version is not installed in Homebrew Cellar."
        return 1
    fi
}

# Improved auto-switch PHP version based on .phpvmrc
auto_switch_php_version() {
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/.phpvmrc" ]]; then
            local version=$(cat "$current_dir/.phpvmrc" | tr -d '[:space:]')
            if [[ -n "$version" ]]; then
                phpvm_echo "Auto-switching to PHP $version (from $current_dir/.phpvmrc)"
                use_php_version "$version"
            else
                phpvm_warn "No valid PHP version found in .phpvmrc."
            fi
            return
        fi
        current_dir=$(dirname "$current_dir")
    done
    phpvm_warn "No .phpvmrc file found in the current or parent directories."
}

# Prevent execution when sourced
if [[ "$0" == "$BASH_SOURCE" ]]; then
    # CLI argument parsing
    case "$1" in
    install)
        install_php "$2"
        ;;
    uninstall)
        uninstall_php "$2"
        ;;
    list)
        list_php_versions
        ;;
    use)
        use_php_version "$2"
        ;;
    autoswitch)
        auto_switch_php_version
        ;;
    *)
        phpvm_echo "Usage: phpvm {install|uninstall|list|use|autoswitch} <version>"
        exit 1
        ;;
    esac
fi
