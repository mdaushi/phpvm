#!/usr/bin/env bats

# Source the script under test.
setup() {
  ORIGINAL_PATH="$PATH"
  MOCK_DIR="$(mktemp -d)"
  PATH="$MOCK_DIR:$PATH"

  # Ensure phpvm.sh exists before sourcing
  if [[ ! -f "./phpvm.sh" ]]; then
    echo "Error: phpvm.sh not found!"
    exit 1
  fi

  chmod +x "./phpvm.sh"
  source "./phpvm.sh"
}

teardown() {
  PATH="$ORIGINAL_PATH"
  rm -rf "$MOCK_DIR"
  # Ensure .phpvmrc exists before attempting to remove it
  if [[ -f "$PWD/.phpvmrc" ]]; then
    rm -f "$PWD/.phpvmrc"
  fi
}

@test "install_php returns error if version not provided" {
  run install_php ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"No PHP version specified"* ]]
}

@test "install_php calls brew with version" {
  run install_php "8.3"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing PHP 8.3..."* ]]
  [[ "$output" == *"PHP 8.3 installed."* ]]
}

@test "use_php_version returns error if version not provided" {
  run use_php_version ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"No PHP version specified to switch."* ]]
}

@test "use_php_version returns error if version not installed (brew cellar missing)" {
  run use_php_version "7.4"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PHP version 7.4 is not installed"* ]]
}

@test "auto_switch_php_version warns when .phpvmrc is not found" {
  run auto_switch_php_version
  [ "$status" -ne 0 ]
  [[ "$output" == *"No .phpvmrc file found"* ]]
}

@test "auto_switch_php_version switches PHP version from .phpvmrc" {
  echo "8.3" >.phpvmrc
  export HOMEBREW_PHP_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_PHP_BIN="/opt/homebrew/bin" # Ensure binary path is available
  run auto_switch_php_version
  echo "Test output: $output" # Debugging line to inspect output
  [ "$status" -eq 0 ]
  [[ "$output" == *"Auto-switching to PHP 8.3"* ]]
  rm -f .phpvmrc # Cleanup after test
}
