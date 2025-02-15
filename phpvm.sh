#!/bin/bash

# phpvm - A PHP Version Manager written in Shell

PHPVM_DIR="$HOME/.phpvm"
PHPVM_VERSIONS_DIR="$PHPVM_DIR/versions"
PHPVM_ACTIVE_VERSION_FILE="$PHPVM_DIR/active_version"
PHPVM_CURRENT_SYMLINK="$PHPVM_DIR/current"
HOMEBREW_PHP_CELLAR="/opt/homebrew/Cellar"
HOMEBREW_PHP_BIN="/opt/homebrew/bin"

# Create the required directory and exit if it fails.
mkdir -p "$PHPVM_VERSIONS_DIR" || {
    echo "Error: Failed to create directory $PHPVM_VERSIONS_DIR" >&2
    exit 1
}

# ANSI color codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# Output functions
phpvm_echo() { printf "%b%s%b\n" "$GREEN" "$*" "$RESET"; }
phpvm_err() { printf "%bError: %s%b\n" "$RED" "$*" "$RESET" >&2; }
phpvm_warn() { printf "%bWarning: %s%b\n" "$YELLOW" "$*" "$RESET" >&2; }

# Helper function to check if Homebrew is installed
is_brew_installed() {
    command -v brew &>/dev/null
}

# Helper function to install PHP using Homebrew
brew_install_php() {
    local version=$1
    if ! brew install php@"$version"; then
        phpvm_warn "php@$version is not available in Homebrew. Trying latest version..."
        if ! brew install php; then
            phpvm_err "Failed to install PHP."
            return 1
        fi
    fi
    return 0
}

# Helper function to get the installed PHP version
get_installed_php_version() {
    if command -v php-config &>/dev/null; then
        php-config --version
    else
        php -v | awk '/^PHP/ {print $2}'
    fi
}

install_php() {
    local version=$1
    [[ -z $version ]] && {
        phpvm_err "No PHP version specified for installation."
        return 1
    }

    phpvm_echo "Installing PHP $version..."
    if is_brew_installed; then
        brew_install_php "$version" || return 1
    else
        phpvm_err "Unsupported package manager. Please install PHP manually."
        return 1
    fi
    phpvm_echo "PHP $version installed."
    return 0
}

use_php_version() {
    local version=$1
    [[ -z $version ]] && {
        phpvm_err "No PHP version specified to switch."
        return 1
    }

    phpvm_echo "Switching to PHP $version..."
    if is_brew_installed; then
        if [[ -d "$HOMEBREW_PHP_CELLAR/php@$version" ]]; then
            brew unlink php &>/dev/null || phpvm_warn "Failed to unlink current PHP version."
            brew link php@"$version" --force --overwrite || {
                phpvm_err "Failed to link PHP $version."
                return 1
            }
        elif [[ -d "$HOMEBREW_PHP_CELLAR/php" ]]; then
            local installed_version
            installed_version=$(get_installed_php_version)

            if [[ "$installed_version" == "$version"* ]]; then
                phpvm_echo "Using PHP $version installed as 'php'."
            else
                phpvm_err "PHP version $version is not installed."
                return 1
            fi
        else
            phpvm_err "PHP version $version is not installed."
            return 1
        fi
        ln -sfn "$HOMEBREW_PHP_BIN/php" "$PHPVM_CURRENT_SYMLINK" || {
            phpvm_err "Failed to update symlink."
            return 1
        }
        echo "$version" >"$PHPVM_ACTIVE_VERSION_FILE" || {
            phpvm_err "Failed to write active version."
            return 1
        }
        phpvm_echo "Switched to PHP $version."
    else
        phpvm_err "Homebrew is not installed."
        return 1
    fi
}

auto_switch_php_version() {
    local current_dir="$PWD"
    local found=0
    local depth=0
    local max_depth=5

    while [[ "$current_dir" != "/" && $depth -lt $max_depth ]]; do
        if [[ -f "$current_dir/.phpvmrc" ]]; then
            local version
            if ! version=$(tr -d '[:space:]' <"$current_dir/.phpvmrc"); then
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
                return 1
            fi
            found=1
            break
        fi
        current_dir=$(dirname "$current_dir")
        ((depth++))
    done

    if [[ $found -eq 0 ]]; then
        phpvm_warn "No .phpvmrc file found in the current or parent directories."
        return 1
    fi
    return 0
}
