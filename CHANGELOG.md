# Release Notes

## [v1.2.0](https://github.com/Thavarshan/phpvm/compare/v1.1.0...v1.2.0) - 2025-02-15

### Added

- **GitHub Actions CI/CD Integration:** Added workflows for running automated tests and verifying PHPVM functionality on macOS and Linux.
- **Linux Compatibility:** Implemented Homebrew mock support to allow testing on both macOS and Linux environments.
- **Extended Test Suite:** Improved BATS test coverage to handle different system environments and dependencies.

### Changed

- **Improved Homebrew Detection:** The script now properly checks for Homebrew availability and handles missing installations more gracefully.
- **Refactored Test Setup:** The `setup` function in `test_phpvm.bats` now ensures correct sourcing of `phpvm.sh` and mocks Homebrew on Linux.
- **Better Error Messages:** Adjusted error outputs for clarity when Homebrew or PHP versions are unavailable.

### Fixed

- **Fixed Ubuntu Compatibility Issues:** The tests no longer fail due to missing Homebrew; instead, they mock Homebrew behavior on Linux.
- **Resolved Test Failures:** The `install_php`, `use_php_version`, and `auto_switch_php_version` tests now properly execute across different OS platforms.
- **Prevented Test Cleanup Failures:** The `teardown` function now ensures `.phpvmrc` and other temporary files are removed only if they exist.

## [v1.1.0](https://github.com/Thavarshan/phpvm/compare/v1.0.0...v1.1.0) - 2025-02-09

### Added

- Added comprehensive error handling to the main `phpvm` script for robust operations.
- Added checks for command availability (e.g., `curl`) in the installation script.
- Added a suite of unit tests using BATS for automated testing of core functionalities.
- Added clear and informative, color-coded terminal messages for user interactions.

### Changed

- Enhanced the installation script to safely modify user shell profiles and avoid duplicate entries.
- Updated the main `phpvm` script to use strict mode (`set -euo pipefail`) for improved reliability.
- Improved overall error reporting to capture and relay issues during directory creation, downloading, and setting file permissions.

### Fixed

- Fixed various shellcheck warnings such as:
  - SC2034 (unused variables)
  - SC2086 (unquoted variables)
  - SC2155 (variable declaration and assignment in one line)
  - SC2128 (incorrect array handling)
- Fixed potential issues with word splitting and globbing by ensuring proper quoting of variables in command calls.

## [v1.0.0](https://github.com/Thavarshan/phpvm/compare/v0.0.1...v1.0.0) - 2025-02-04

### Added

- Auto-switching PHP versions based on `.phpvmrc`.
- Improved support for macOS Homebrew installations.
- Enhanced installation script for easy setup using `curl` or `wget`.
- More robust error handling and output formatting.
- Extended compatibility with `bash` and `zsh` shells.

### Fixed

- Resolved issues with Homebrew PHP detection on macOS.
- Prevented terminal crashes due to incorrect sourcing in shell startup scripts.
- Improved handling of missing PHP versions.

## [v0.0.1](https://github.com/Thavarshan/phpvm/compare/v0.0.0...v0.0.1) - 2024-10-05

Initial release for public testing and feedback.
