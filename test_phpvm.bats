#!/usr/bin/env bats

# Set up test environment
setup() {
  # Create a temporary directory for tests
  export TEMP_DIR=$(mktemp -d)
  export HOME="$TEMP_DIR"
  export PHPVM_DIR="$HOME/.phpvm"
  export PHPVM_VERSIONS_DIR="$PHPVM_DIR/versions"
  export PHPVM_ACTIVE_VERSION_FILE="$PHPVM_DIR/active_version"
  export PHPVM_CURRENT_SYMLINK="$PHPVM_DIR/current"

  # Mock the brew command
  mkdir -p "$TEMP_DIR/bin"
  cat >"$TEMP_DIR/bin/brew" <<'EOF'
#!/bin/sh
if [ "$1" = "install" ]; then
    if [ "$2" = "php@7.4" ]; then
        echo "Installing php@7.4..."
        mkdir -p /opt/homebrew/Cellar/php@7.4/bin
        return 0
    elif [ "$2" = "php" ]; then
        echo "Installing php (latest)..."
        mkdir -p /opt/homebrew/Cellar/php/bin
        return 0
    else
        echo "Error: Formula php@$2 not available" >&2
        return 1
    fi
elif [ "$1" = "unlink" ]; then
    return 0
elif [ "$1" = "link" ]; then
    return 0
fi
EOF
  chmod +x "$TEMP_DIR/bin/brew"

  # Mock php and php-config
  cat >"$TEMP_DIR/bin/php" <<'EOF'
#!/bin/sh
if [ "$1" = "-v" ]; then
    echo "PHP 8.0.0 (cli)"
fi
EOF
  chmod +x "$TEMP_DIR/bin/php"

  cat >"$TEMP_DIR/bin/php-config" <<'EOF'
#!/bin/sh
if [ "$1" = "--version" ]; then
    echo "8.0.0"
fi
EOF
  chmod +x "$TEMP_DIR/bin/php-config"

  # Add mocks to PATH
  export PATH="$TEMP_DIR/bin:$PATH"

  # Create required directories
  mkdir -p /opt/homebrew/Cellar
  mkdir -p /opt/homebrew/bin

  # Source the script under test
  source ./phpvm
}

# Clean up after tests
teardown() {
  rm -rf "$TEMP_DIR"
}

# Utility function to create mock PHP installations
create_mock_php_installation() {
  local version="$1"
  mkdir -p "/opt/homebrew/Cellar/php@$version"
  mkdir -p "/opt/homebrew/bin"
  touch "/opt/homebrew/bin/php"
}

# Test directory creation
@test "phpvm creates required directories" {
  rm -rf "$PHPVM_DIR"
  mkdir -p "$PHPVM_DIR" || true
  [ -d "$PHPVM_VERSIONS_DIR" ]
}

# Test install command
@test "install command with valid version" {
  run install_php "7.4"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing PHP 7.4"* ]]
  [[ "$output" == *"PHP 7.4 installed"* ]]
}

@test "install command with missing version" {
  run install_php ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"No PHP version specified for installation"* ]]
}

# Test use command
@test "use command with installed version" {
  create_mock_php_installation "7.4"
  run use_php_version "7.4"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Switching to PHP 7.4"* ]]
  [[ "$output" == *"Switched to PHP 7.4"* ]]
  [ "$(cat $PHPVM_ACTIVE_VERSION_FILE)" == "7.4" ]
}

@test "use command with missing version" {
  run use_php_version ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"No PHP version specified to switch"* ]]
}

@test "use command with non-installed version" {
  run use_php_version "5.6"
  [ "$status" -eq 1 ]
  [[ "$output" == *"PHP version 5.6 is not installed"* ]]
}

# Test auto-switch functionality
@test "auto-switch with valid .phpvmrc" {
  create_mock_php_installation "7.4"
  mkdir -p "$HOME/project"
  echo "7.4" >"$HOME/project/.phpvmrc"
  cd "$HOME/project"
  run auto_switch_php_version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Auto-switching to PHP 7.4"* ]]
  [ "$(cat $PHPVM_ACTIVE_VERSION_FILE)" == "7.4" ]
}

@test "auto-switch with invalid .phpvmrc" {
  mkdir -p "$HOME/project"
  echo "" >"$HOME/project/.phpvmrc"
  cd "$HOME/project"
  run auto_switch_php_version
  [ "$status" -eq 1 ]
  [[ "$output" == *"No valid PHP version found"* ]]
}

@test "auto-switch with no .phpvmrc" {
  mkdir -p "$HOME/project"
  cd "$HOME/project"
  run auto_switch_php_version
  [ "$status" -eq 1 ]
  [[ "$output" == *"No .phpvmrc file found"* ]]
}

# Test main command dispatcher
@test "main with no arguments" {
  run main
  [ "$status" -eq 1 ]
  [[ "$output" == *"No command provided"* ]]
}

@test "main with unknown command" {
  run main "unknown"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command: unknown"* ]]
}

@test "main with use command but no version" {
  run main "use"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing PHP version argument for 'use' command"* ]]
}

@test "main with install command but no version" {
  run main "install"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing PHP version argument for 'install' command"* ]]
}

@test "main with valid use command" {
  create_mock_php_installation "7.4"
  run main "use" "7.4"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Switched to PHP 7.4"* ]]
}

@test "main with valid install command" {
  run main "install" "7.4"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PHP 7.4 installed"* ]]
}

@test "main with valid auto command" {
  create_mock_php_installation "7.4"
  mkdir -p "$HOME/project"
  echo "7.4" >"$HOME/project/.phpvmrc"
  cd "$HOME/project"
  run main "auto"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Auto-switching to PHP 7.4"* ]]
}

# Test helper functions
@test "get_installed_php_version returns correct version" {
  run get_installed_php_version
  [ "$status" -eq 0 ]
  [ "$output" = "8.0.0" ]
}

@test "is_brew_installed returns success" {
  run is_brew_installed
  [ "$status" -eq 0 ]
}
