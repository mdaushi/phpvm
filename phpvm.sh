#!/bin/bash

# phpvm - A PHP Version Manager written in Shell

PHPVM_DIR="$HOME/.phpvm"
PHPVM_VERSIONS_DIR="$PHPVM_DIR/versions"
PHPVM_ACTIVE_VERSION_FILE="$PHPVM_DIR/active_version"
PHPVM_CURRENT_SYMLINK="$PHPVM_DIR/current"
HOMEBREW_PHP_CELLAR="/opt/homebrew/Cellar"
HOMEBREW_PHP_BIN="/opt/homebrew/bin"

# Create the required directory and exit if it fails.
mkdir -p "$PHPVM_VERSIONS_DIR" || { echo "Error: Failed to create directory $PHPVM_VERSIONS_DIR" >&2; exit 1; }

# ANSI color codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
# Removed BLUE as it is unused
RESET="\e[0m"

# Output functions for better readability and robust error checking.
phpvm_echo() {
    if ! command printf "%b%s%b\n" "$GREEN" "$*" "$RESET"; then
        echo "Error: Failed in phpvm_echo" >&2
    fi
}

phpvm_err() {
    command >&2 printf "%bError: %s%b\n" "$RED" "$*" "$RESET"
}

phpvm_warn() {
    command >&2 printf "%bWarning: %s%b\n" "$YELLOW" "$*" "$RESET"
}

# Function to install a specific PHP version with error handling.
install_php() {
    local version=$1
    if [[ -z $version ]]; then
         phpvm_err "No PHP version specified for installation."
         return 1
    fi

    phpvm_echo "Installing PHP $version..."

    if command -v brew &>/dev/null; then
        if ! brew install php@"$version"; then
            phpvm_err "Failed to install PHP $version via Homebrew."
            return 1
        fi
    elif command -v apt-get &>/dev/null; then
        if ! sudo apt-get update; then
            phpvm_err "apt-get update failed."
            return 1
        fi
        if ! sudo apt-get install -y php"$version"; then
            phpvm_err "Failed to install PHP $version via apt-get."
            return 1
        fi
    elif command -v dnf &>/dev/null; then
        if ! sudo dnf install -y php; then
            phpvm_err "Failed to install PHP via dnf."
            return 1
        fi
    else
        phpvm_err "Unsupported Linux distribution."
        return 1
    fi
    phpvm_echo "PHP $version installed."
    return 0
}

# Function to switch to a specific PHP version with robust error handling.
use_php_version() {
    local version=$1
    if [[ -z $version ]]; then
         phpvm_err "No PHP version specified to switch."
         return 1
    fi

    phpvm_echo "Switching to PHP $version..."

    if command -v brew &>/dev/null && [[ -d "$HOMEBREW_PHP_CELLAR/php@$version" ]]; then
        if ! brew unlink php &>/dev/null; then
            phpvm_warn "Failed to unlink current PHP version. Continuing..."
        fi
        if ! brew link php@"$version" --force --overwrite; then
            phpvm_err "Failed to link PHP $version."
            return 1
        fi
        if ! ln -sfn "$HOMEBREW_PHP_BIN/php" "$PHPVM_CURRENT_SYMLINK"; then
            phpvm_err "Failed to update current symlink."
            return 1
        fi
        if ! echo "$version" > "$PHPVM_ACTIVE_VERSION_FILE"; then
            phpvm_err "Failed to write active version to file."
            return 1
        fi
        phpvm_echo "Switched to PHP $version."
        return 0
    else
        phpvm_err "PHP version $version is not installed in Homebrew Cellar."
        return 1
    fi
}

# Function to auto-switch PHP version based on the .phpvmrc file with error handling.
auto_switch_php_version() {
    local current_dir="$PWD"
    local found=0

    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/.phpvmrc" ]]; then
            local version
            if ! version=$(cat "$current_dir/.phpvmrc" 2>/dev/null | tr -d '[:space:]'); then
                phpvm_err "Failed to read $current_dir/.phpvmrc"
                return 1
            fi
            if [[ -n "$version" ]]; then
                phpvm_echo "Auto-switching to PHP $version (from $current_dir/.phpvmrc)"
                if ! use_php_version "$version"; then
                    phpvm_err "Failed to switch to PHP $version from $current_dir/.phpvmrc"
                    return 1
                fi
            else
                phpvm_warn "No valid PHP version found in $current_dir/.phpvmrc."
            fi
            found=1
            break
        fi
        current_dir=$(dirname "$current_dir")
    done

    if [[ $found -eq 0 ]]; then
        phpvm_warn "No .phpvmrc file found in the current or parent directories."
        return 1
    fi
    return 0
}

# Stub function for uninstalling PHP. Added error handling.
uninstall_php() {
    local version=$1
    if [[ -z "$version" ]]; then
       phpvm_err "No PHP version specified for uninstallation."
       return 1
    fi
    # Placeholder for actual uninstallation logic.
    phpvm_warn "Uninstall PHP $version is not yet implemented."
    return 1
}

# Stub function for listing installed PHP versions. Added error handling.
list_php_versions() {
    # Placeholder for PHP version listing logic.
    phpvm_echo "Listing installed PHP versions is not yet implemented."
    return 1
}

# Prevent execution when sourced.
if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    case "$1" in
    install)
        if ! install_php "$2"; then
            phpvm_err "Installation failed."
            exit 1
        fi
        ;;
    uninstall)
        if ! uninstall_php "$2"; then
            phpvm_err "Uninstallation failed."
            exit 1
        fi
        ;;
    list)
        if ! list_php_versions; then
            phpvm_err "Listing PHP versions failed."
            exit 1
        fi
        ;;
    use)
        if ! use_php_version "$2"; then
            phpvm_err "Switching PHP version failed."
            exit 1
        fi
        ;;
    autoswitch)
        if ! auto_switch_php_version; then
            phpvm_err "Auto-switching PHP version failed."
            exit 1
        fi
        ;;
    *)
        phpvm_echo "Usage: phpvm {install|uninstall|list|use|autoswitch} <version>"
        exit 1
        ;;
    esac
fi
