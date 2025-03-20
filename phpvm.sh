#!/bin/sh

# phpvm - A PHP Version Manager for macOS and Linux

PHPVM_DIR="$HOME/.phpvm"
PHPVM_VERSIONS_DIR="$PHPVM_DIR/versions"
PHPVM_ACTIVE_VERSION_FILE="$PHPVM_DIR/active_version"
PHPVM_CURRENT_SYMLINK="$PHPVM_DIR/current"
DEBUG=false # Set to true to enable debug logs

# Create the required directory structure
create_directories() {
    mkdir -p "$PHPVM_VERSIONS_DIR" || {
        echo "Error: Failed to create directory $PHPVM_VERSIONS_DIR" >&2
        exit 1
    }
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

# Detect the system's package manager and OS
detect_system() {
    if [ "$(uname)" = "Darwin" ]; then
        PKG_MANAGER="brew"
        if ! command -v brew >/dev/null 2>&1; then
            phpvm_err "Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
        HOMEBREW_PREFIX="/opt/homebrew"
        PHP_BIN_PATH="$HOMEBREW_PREFIX/bin"
        return 0
    fi

    # Detect Linux package manager
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PHP_BIN_PATH="/usr/bin"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PHP_BIN_PATH="/usr/bin"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PHP_BIN_PATH="/usr/bin"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
        PHP_BIN_PATH="/usr/bin"
    elif command -v brew >/dev/null 2>&1; then
        PKG_MANAGER="brew"
        # Detect Linuxbrew path
        if [ -d "/home/linuxbrew/.linuxbrew" ]; then
            HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
        elif [ -d "$HOME/.linuxbrew" ]; then
            HOMEBREW_PREFIX="$HOME/.linuxbrew"
        else
            HOMEBREW_PREFIX="/usr/local" # Fallback location
        fi
        PHP_BIN_PATH="$HOMEBREW_PREFIX/bin"
    else
        phpvm_err "No supported package manager found (apt, dnf, yum, pacman, or brew)."
        exit 1
    fi
}

# Install PHP using the detected package manager
install_php() {
    version="$1"
    [ -z "$version" ] && {
        phpvm_err "No PHP version specified for installation."
        return 1
    }

    phpvm_echo "Installing PHP $version..."

    case "$PKG_MANAGER" in
    brew)
        if ! brew install php@"$version"; then
            phpvm_warn "php@$version is not available in Homebrew. Trying latest version..."
            if ! brew install php; then
                phpvm_err "Failed to install PHP."
                return 1
            fi
        fi
        ;;
    apt)
        # Check if we need sudo
        if [ "$(id -u)" -ne 0 ]; then
            SUDO="sudo"
        else
            SUDO=""
        fi

        $SUDO apt-get update
        if ! $SUDO apt-get install -y php"$version"; then
            phpvm_err "Failed to install PHP $version. Package php$version may not exist."
            return 1
        fi
        ;;
    dnf | yum)
        # Check if we need sudo
        if [ "$(id -u)" -ne 0 ]; then
            SUDO="sudo"
        else
            SUDO=""
        fi

        if ! $SUDO $PKG_MANAGER install -y php"$version"; then
            # Try with full version format for some repos
            if ! $SUDO $PKG_MANAGER install -y php-"$version".0; then
                phpvm_err "Failed to install PHP $version. Package php$version may not exist."
                return 1
            fi
        fi
        ;;
    pacman)
        # Check if we need sudo
        if [ "$(id -u)" -ne 0 ]; then
            SUDO="sudo"
        else
            SUDO=""
        fi

        $SUDO pacman -Sy
        if ! $SUDO pacman -S --noconfirm php"$version"; then
            phpvm_err "Failed to install PHP $version. Package php$version may not exist."
            return 1
        fi
        ;;
    esac

    phpvm_echo "PHP $version installed."
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

use_php_version() {
    version="$1"
    [ -z "$version" ] && {
        phpvm_err "No PHP version specified to switch."
        return 1
    }

    phpvm_echo "Switching to PHP $version..."

    case "$PKG_MANAGER" in
    brew)
        phpvm_debug "Unlinking any existing PHP version..."
        brew unlink php >/dev/null 2>&1 || phpvm_warn "Failed to unlink current PHP version."

        if [ -d "$HOMEBREW_PREFIX/Cellar/php@$version" ]; then
            phpvm_debug "Linking PHP $version..."
            brew link php@"$version" --force --overwrite || {
                phpvm_err "Failed to link PHP $version."
                return 1
            }
        elif [ -d "$HOMEBREW_PREFIX/Cellar/php" ]; then
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
        fi
        ;;
    apt | dnf | yum | pacman)
        # For Linux package managers, we use update-alternatives if available
        if command -v update-alternatives >/dev/null 2>&1; then
            # Check if we need sudo
            if [ "$(id -u)" -ne 0 ]; then
                SUDO="sudo"
            else
                SUDO=""
            fi

            if [ -f "/usr/bin/php$version" ]; then
                $SUDO update-alternatives --set php "/usr/bin/php$version" || {
                    phpvm_err "Failed to switch to PHP $version using update-alternatives."
                    return 1
                }
            else
                phpvm_err "PHP binary for version $version not found at /usr/bin/php$version"
                return 1
            fi
        else
            phpvm_err "update-alternatives command not found. Cannot switch PHP versions on this system."
            return 1
        fi
        ;;
    esac

    phpvm_debug "Updating symlink to PHP $version..."
    rm -f "$PHPVM_CURRENT_SYMLINK"
    ln -s "$PHP_BIN_PATH/php" "$PHPVM_CURRENT_SYMLINK" || {
        phpvm_err "Failed to update symlink."
        return 1
    }

    echo "$version" >"$PHPVM_ACTIVE_VERSION_FILE" || {
        phpvm_err "Failed to write active version."
        return 1
    }

    phpvm_echo "Switched to PHP $version."
    return 0
}

auto_switch_php_version() {
    current_dir="$PWD"
    found=0
    depth=0
    max_depth=5

    while [ "$current_dir" != "/" ] && [ $depth -lt $max_depth ]; do
        if [ -f "$current_dir/.phpvmrc" ]; then
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

list_installed_versions() {
    phpvm_echo "Installed PHP versions:"

    case "$PKG_MANAGER" in
    brew)
        if [ -d "$HOMEBREW_PREFIX/Cellar" ]; then
            for dir in "$HOMEBREW_PREFIX/Cellar/php"*; do
                if [ -d "$dir" ]; then
                    base_name=$(basename "$dir")
                    if [ "$base_name" = "php" ]; then
                        version=$(get_installed_php_version)
                        echo "  $version (latest)"
                    else
                        # Extract version from php@X.Y format
                        version=${base_name#php@}
                        echo "  $version"
                    fi
                fi
            done
        fi
        ;;
    apt)
        dpkg -l | grep -E '^ii +php[0-9]+\.[0-9]+' | awk '{print "  " $2}' | sed 's/^  php//'
        ;;
    dnf | yum)
        $PKG_MANAGER list installed | grep -E 'php[0-9]+\.' | awk '{print "  " $1}' | sed 's/^  php//'
        ;;
    pacman)
        pacman -Q | grep '^php' | awk '{print "  " $1}' | sed 's/^  php//'
        ;;
    esac

    echo ""
    if [ -f "$PHPVM_ACTIVE_VERSION_FILE" ]; then
        active_version=$(cat "$PHPVM_ACTIVE_VERSION_FILE")
        phpvm_echo "Active version: $active_version"
    else
        phpvm_warn "No active PHP version set."
    fi
}

print_help() {
    cat <<EOF
phpvm - PHP Version Manager

Usage:
  phpvm install <version>  Install specified PHP version
  phpvm use <version>      Switch to specified PHP version
  phpvm auto               Auto-switch based on .phpvmrc file
  phpvm list               List installed PHP versions
  phpvm help               Show this help message

Examples:
  phpvm install 8.1        Install PHP 8.1
  phpvm use 7.4            Switch to PHP 7.4
  phpvm auto               Auto-switch based on current directory
EOF
}

main() {
    create_directories
    detect_system

    if [ "$#" -eq 0 ]; then
        phpvm_err "No command provided."
        print_help
        exit 1
    fi

    command="$1"
    shift

    case "$command" in
    use)
        if [ "$#" -eq 0 ]; then
            phpvm_err "Missing PHP version argument for 'use' command."
            exit 1
        fi
        use_php_version "$@"
        ;;
    install)
        if [ "$#" -eq 0 ]; then
            phpvm_err "Missing PHP version argument for 'install' command."
            exit 1
        fi
        install_php "$@"
        ;;
    auto)
        auto_switch_php_version
        ;;
    list)
        list_installed_versions
        ;;
    help)
        print_help
        ;;
    *)
        phpvm_err "Unknown command: $command"
        print_help
        exit 1
        ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
