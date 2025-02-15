#!/usr/bin/env bats

# Source the script under test.
# Adjust the relative path if necessary.
source "./phpvm.sh"

setup() {
  # Save the original PATH
  ORIGINAL_PATH="$PATH"
  # Create a temporary directory for our mock commands
  MOCK_DIR="$(mktemp -d)"
  PATH="$MOCK_DIR:$PATH"

  # Create a dummy 'brew' command
  cat <<'EOF' >"$MOCK_DIR/brew"
#!/bin/bash
# Simply print the arguments to verify the call.
echo "brew $*"
exit 0
EOF
  chmod +x "$MOCK_DIR/brew"
}

teardown() {
  PATH="$ORIGINAL_PATH"
  rm -rf "$MOCK_DIR"
  # Remove any temporary test directories if created.
  [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

@test "install_php returns error if version not provided" {
  run install_php ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"No PHP version specified"* ]]
}

@test "install_php calls brew with version" {
  run install_php "7.4"
  [ "$status" -eq 0 ]
  # Check that the function echoed the installation messages.
  [[ "$output" == *"Installing PHP 7.4..."* ]]
  [[ "$output" == *"PHP 7.4 installed."* ]]
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
  # Run from a temporary directory that does not contain .phpvmrc.
  TEST_DIR="$(mktemp -d)"
  pushd "$TEST_DIR" >/dev/null
  run auto_switch_php_version
  popd >/dev/null
  [ "$status" -ne 0 ]
  [[ "$output" == *"No .phpvmrc file found"* ]]
}

@test "auto_switch_php_version switches PHP version from .phpvmrc" {
  # Create a temporary directory with a .phpvmrc file
  TEST_DIR="$(mktemp -d)"
  echo "7.4" >"$TEST_DIR/.phpvmrc"

  # Create a fake Homebrew cellar directory to simulate an installed PHP version.
  mkdir -p "/opt/homebrew/Cellar/php@7.4"

  pushd "$TEST_DIR" >/dev/null
  run auto_switch_php_version
  popd >/dev/null

  [ "$status" -eq 0 ]
  [[ "$output" == *"Auto-switching to PHP 7.4"* ]]
}
