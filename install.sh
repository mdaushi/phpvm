#!/bin/sh
{
    # Ensure the entire script is downloaded and executed
    set -e

    phpvm_has() {
        command -v "$1" >/dev/null 2>&1
    }

    phpvm_echo() {
        printf "\033[32m%s\033[0m\n" "$*"
    }

    phpvm_err() {
        printf "\033[31mError: %s\033[0m\n" "$*" >&2
    }

    phpvm_warn() {
        printf "\033[33mWarning: %s\033[0m\n" "$*" >&2
    }

    # Default installation directory
    PHPVM_DIR="${PHPVM_DIR:-$HOME/.phpvm}"
    PHPVM_SCRIPT="$PHPVM_DIR/phpvm.sh"
    GITHUB_REPO_URL="https://raw.githubusercontent.com/Thavarshan/phpvm/main/phpvm.sh"

    phpvm_install_dir() {
        if [ -n "$PHPVM_DIR" ]; then
            printf %s "$PHPVM_DIR"
        else
            printf %s "$HOME/.phpvm"
        fi
    }

    phpvm_download() {
        if phpvm_has "curl"; then
            curl --fail --compressed -q "$@"
        elif phpvm_has "wget"; then
            # Adding -O- to output to stdout for wget
            wget -O- "$@"
        else
            phpvm_err "curl or wget is required to install phpvm."
            exit 1
        fi
    }

    phpvm_detect_profile() {
        if [ -n "${PROFILE-}" ] && [ -f "$PROFILE" ]; then
            echo "$PROFILE"
            return
        fi

        local DETECTED_PROFILE=""
        local SHELL_NAME=""

        # Get the shell from PS1 or SHELL variable
        SHELL_NAME="$(basename "$SHELL")"

        if [ "$SHELL_NAME" = "zsh" ]; then
            if [ -f "$HOME/.zshrc" ]; then
                DETECTED_PROFILE="$HOME/.zshrc"
            fi
        elif [ "$SHELL_NAME" = "bash" ]; then
            if [ -f "$HOME/.bashrc" ]; then
                DETECTED_PROFILE="$HOME/.bashrc"
            fi
        fi

        if [ -z "$DETECTED_PROFILE" ]; then
            for EACH_PROFILE in ".profile" ".bashrc" ".zshrc"; do
                if [ -f "$HOME/$EACH_PROFILE" ]; then
                    DETECTED_PROFILE="$HOME/$EACH_PROFILE"
                    break
                fi
            done
        fi

        echo "$DETECTED_PROFILE"
    }

    install_phpvm_as_script() {
        local INSTALL_DIR
        INSTALL_DIR="$(phpvm_install_dir)"
        mkdir -p "$INSTALL_DIR/bin"

        phpvm_echo "Downloading phpvm script from $GITHUB_REPO_URL..."
        phpvm_download "$GITHUB_REPO_URL" >"$INSTALL_DIR/phpvm.sh" || {
            phpvm_err "Failed to download phpvm script"
            exit 1
        }

        chmod +x "$INSTALL_DIR/phpvm.sh"
        ln -sf "$INSTALL_DIR/phpvm.sh" "$INSTALL_DIR/bin/phpvm"
    }

    phpvm_do_install() {
        phpvm_echo "Installing phpvm..."
        install_phpvm_as_script

        local PROFILE
        PROFILE="$(phpvm_detect_profile)"

        if [ -n "$PROFILE" ] && ! grep -q 'phpvm.sh' "$PROFILE"; then
            phpvm_echo "Appending phpvm source to $PROFILE"
            printf "\nexport PHPVM_DIR=\"%s\"\nexport PATH=\"\$PHPVM_DIR/bin:\$PATH\"\n[ -s \"\$PHPVM_DIR/phpvm.sh\" ] && . \"\$PHPVM_DIR/phpvm.sh\"\n" "$(phpvm_install_dir)" >>"$PROFILE"
        fi

        phpvm_echo "Applying changes..."
        export PATH="$PHPVM_DIR/bin:$PATH"

        # Only source the profile if it exists
        if [ -f "$PROFILE" ]; then
            # Use . instead of source for POSIX compatibility
            . "$PROFILE" || true
        fi

        phpvm_echo "phpvm installation complete!"
        phpvm_echo "Run: phpvm use 8.4"
    }

    phpvm_do_install
} # End of script
