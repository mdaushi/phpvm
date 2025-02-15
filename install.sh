#!/usr/bin/env bash

{ # Ensure the entire script is downloaded and executed

    set -euo pipefail

    phpvm_has() {
        type "$1" >/dev/null 2>&1
    }

    phpvm_echo() {
        command printf "\e[32m%s\e[0m\n" "$*"
    }

    phpvm_err() {
        command >&2 printf "\e[31mError: %s\e[0m\n" "$*"
    }

    phpvm_warn() {
        command >&2 printf "\e[33mWarning: %s\e[0m\n" "$*"
    }

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
            wget "$@"
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

        local DETECTED_PROFILE=''
        if [ "${SHELL#*zsh}" != "$SHELL" ]; then
            if [ -f "$HOME/.zshrc" ]; then DETECTED_PROFILE="$HOME/.zshrc"; fi
        elif [ "${SHELL#*bash}" != "$SHELL" ]; then
            if [ -f "$HOME/.bashrc" ]; then DETECTED_PROFILE="$HOME/.bashrc"; fi
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
        phpvm_download -fsSL "$GITHUB_REPO_URL" -o "$INSTALL_DIR/phpvm.sh"
        chmod +x "$INSTALL_DIR/phpvm.sh"
        ln -sf "$INSTALL_DIR/phpvm.sh" "$INSTALL_DIR/bin/phpvm"
    }

    phpvm_do_install() {
        phpvm_echo "Installing phpvm..."
        install_phpvm_as_script

        local PROFILE
        PROFILE="$(phpvm_detect_profile)"

        if [ -n "$PROFILE" ] && ! grep -qc 'phpvm.sh' "$PROFILE"; then
            phpvm_echo "Appending phpvm source to $PROFILE"
            echo -e "\nexport PHPVM_DIR=\"$(phpvm_install_dir)\"\n[ -s \"\$PHPVM_DIR/phpvm.sh\" ] && \\. \"\$PHPVM_DIR/phpvm.sh\"" >>"$PROFILE"
        fi

        phpvm_echo "Applying changes..."
        export PATH="$PHPVM_DIR/bin:$PATH"
        source "$PROFILE" || true

        phpvm_echo "phpvm installation complete!"
        phpvm_echo "Run: phpvm use 8.4"
    }

    phpvm_do_install

} # End of script
