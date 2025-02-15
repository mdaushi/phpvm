#!/bin/sh

# phpvm - A PHP Version Manager written in Shell

PHPVM_DIR="$HOME/.phpvm"
PHPVM_VERSIONS_DIR="$PHPVM_DIR/versions"
PHPVM_ACTIVE_VERSION_FILE="$PHPVM_DIR/active_version"
PHPVM_CURRENT_SYMLINK="$PHPVM_DIR/current"
HOMEBREW_PHP_CELLAR="/opt/homebrew/Cellar"
HOMEBREW_PHP_BIN="/opt/homebrew/bin"
DEBUG=false # Set to true to enable debug logs

# Create the required directory and exit if it fails.
mkdir -p "$PHPVM_VERSIONS_DIR" || {
    echo "Error: Failed to create directory $PHPVM_VERSIONS_DIR" >&2
    exit 1
}

# ANSI color codes
RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[0m')

# Output functions
phpvm_echo() { printf "%s%s%s\n" "$GREEN" "$*" "$RESET"; }
phpvm_err() { printf "%sError: %s%s\n" "$RED" "$*" "$RESET" >&2; }
phpvm_warn() { printf "%sWarning: %s%s\n" "$YELLOW" "$*" "$RESET" >&2; }
phpvm_debug() { [ "$DEBUG" = "true" ] && echo "Debug: $*"; }

# Helper function to check if Homebrew is installed
is_brew_installed() {
    command -v brew >/dev/null 2>&1
}

# Ensure Homebrew is installed before proceeding
if ! is_brew_installed; then
    phpvm_err "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# Helper function to install PHP using Homebrew
brew_install_php() {
    version="$1"
    phpvm_debug "Attempting to install PHP $version using Homebrew..."
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
    phpvm_debug "Getting installed PHP version..."
    if command -v php-config >/dev/null 2>&1; then
        php-config --version
    else
        php -v | awk '/^PHP/ {print $2}'
    fi
}

install_php() {
    version="$1"
    [ -z "$version" ] && {
        phpvm_err "No PHP version specified for installation."
        return 1
    }
    phpvm_echo "Installing PHP $version..."
    brew_install_php "$version" || return 1
    phpvm_echo "PHP $version installed."
    return 0
}

use_php_version() {
    version="$1"
    [ -z "$version" ] && {
        phpvm_err "No PHP version specified to switch."
        return 1
    }
    phpvm_echo "Switching to PHP $version..."
    phpvm_debug "Unlinking any existing PHP version..."
    brew unlink php >/dev/null 2>&1 || phpvm_warn "Failed to unlink current PHP version."
    if [ -d "$HOMEBREW_PHP_CELLAR/php@$version" ]; then
        phpvm_debug "Linking PHP $version..."
        brew link php@"$version" --force --overwrite || {
            phpvm_err "Failed to link PHP $version."
            return 1
        }
    elif [ -d "$HOMEBREW_PHP_CELLAR/php" ]; then
        installed_version=$(get_installed_php_version)
        if [ "$installed_version" = "$version" ]; then
            phpvm_echo "Using PHP $version installed as 'php'."
        else
            phpvm_err "PHP version $version is not installed. Installed version: $installed_version"
            return 1
        fi
    else
        phpvm_err "PHP version $version is not installed."
        return 1
    }
    phpvm_debug "Updating symlink to PHP $version..."
    rm -f "$PHPVM_CURRENT_SYMLINK"
    ln -s "$HOMEBREW_PHP_BIN/php" "$PHPVM_CURRENT_SYMLINK" || {
        phpvm_err "Failed to update symlink."
        return 1
    }
    echo "$version" >"$PHPVM_ACTIVE_VERSION_FILE" || {
        phpvm_err "Failed to write active version."
        return 1
    }
    phpvm_echo "Switched to PHP $version."
}

auto_switch_php_version() {
    local current_dir="$PWD"
    local found=0
    local depth=0
    local max_depth=5

    while [ "$current_dir" != "/" ] && [ $depth -lt $max_depth ]; do
        if [ -f "$current_dir/.phpvmrc" ]; then
            local version
            if ! version=$(tr -d '[:space:]' <"$current_dir/.phpvmrc"); then
                phpvm_err "Failed to read $current_dir/.phpvmrc"
                return 1
            fi
            if [ -n "$version" ]; then
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
        depth=$((depth + 1))
    done

    if [ $found -eq 0 ]; then
        phpvm_warn "No .phpvmrc file found in the current or parent directories."
        return 1
    fi
    return 0
}

main() {
    if [ "$#" -eq 0 ]; then
        phpvm_err "No command provided. Available commands: install <version>, use <version>."
        return 1
    fi
    command="$1"
    shift
    case "$command" in
    use)
        if [ "$#" -eq 0 ]; then
            phpvm_err "Missing PHP version argument for 'use' command."
            return 1
        fi
        use_php_version "$@"
        ;;
    install)
        if [ "$#" -eq 0 ]; then
            phpvm_err "Missing PHP version argument for 'install' command."
            return 1
        fi
        install_php "$@"
        ;;
    auto)
        auto_switch_php_version
        ;;
    *)
        phpvm_err "Unknown command: $command. Available commands: install <version>, use <version>."
        return 1
        ;;
    esac
}

main "$@"
