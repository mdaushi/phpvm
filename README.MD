[![PHP Version Manager (phpvm)](./assets/Banner.jpg)](https://github.com/Thavarshan/phpvm)

[![Test](https://github.com/Thavarshan/phpvm/actions/workflows/test.yml/badge.svg)](https://github.com/Thavarshan/phpvm/actions/workflows/test.yml)
[![Use](https://github.com/Thavarshan/phpvm/actions/workflows/use.yml/badge.svg)](https://github.com/Thavarshan/phpvm/actions/workflows/use.yml)
[![Version](https://img.shields.io/github/v/release/Thavarshan/phpvm.svg)](https://github.com/Thavarshan/phpvm/releases)
[![GitHub stars](https://img.shields.io/github/stars/Thavarshan/phpvm.svg)](https://github.com/Thavarshan/phpvm/stargazers)

# PHP Version Manager (phpvm)

## Introduction

`phpvm` is a lightweight PHP Version Manager that allows you to easily install, switch between, and manage multiple PHP versions via the command line.

**Example:**

```sh
$ phpvm use 8.2
Now using PHP v8.2.10
$ php -v
PHP 8.2.10
$ phpvm use 8.1
Now using PHP v8.1.13
$ php -v
PHP 8.1.13
```

## Features

- Install and manage multiple PHP versions.
- Seamlessly switch between installed PHP versions.
- Auto-switch PHP versions based on project `.phpvmrc`.
- Supports macOS (via Homebrew) and Linux distributions.
- Works with common shells (`bash`, `zsh`).
- Improved error handling and informative, color-coded feedback.
- Includes unit tests with BATS for automated testing.

## Installation

### Install & Update phpvm

To **install** or **update** phpvm, run one of the following commands:

```sh
curl -o- https://raw.githubusercontent.com/Thavarshan/phpvm/main/install.sh | bash
```

```sh
wget -qO- https://raw.githubusercontent.com/Thavarshan/phpvm/main/install.sh | bash
```

This script will download and set up `phpvm` in `~/.phpvm` and automatically update your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.profile`) with the following lines:

```sh
export PHPVM_DIR="$HOME/.phpvm"
source "$PHPVM_DIR/phpvm.sh"
```

### Verify Installation

Run the following command:

```sh
command -v phpvm
```

If the installation was successful, it should output the path to `phpvm`.

## Usage

### Installing PHP Versions

To install a specific version of PHP:

```sh
phpvm install 8.1
```

### Switching PHP Versions

To switch between installed versions:

```sh
phpvm use 8.0
```

Verify the active version with:

```sh
php -v
```

### Auto-Switching PHP Versions

Create a `.phpvmrc` file in your project directory to specify the desired PHP version:

```sh
echo "8.1" > .phpvmrc
```

When you navigate to that project directory, `phpvm` will automatically switch to PHP 8.1.

### Uninstalling PHP Versions

To uninstall a specific PHP version:

```sh
phpvm uninstall 7.4
```

### Listing Installed Versions

To list installed PHP versions:

```sh
phpvm list
```

## Uninstallation

To completely remove `phpvm`, run:

```sh
rm -rf ~/.phpvm
```

Then remove the following lines from your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.profile`):

```sh
export PHPVM_DIR="$HOME/.phpvm"
source "$PHPVM_DIR/phpvm.sh"
```

## Troubleshooting

If you experience issues with `phpvm`, try the following:

- Ensure your shell profile is sourcing `phpvm.sh`.
- Restart your terminal after installing or updating.
- Verify that Homebrew is installed (for macOS users).
- Check for permission issues during the installation or PHP version switching process.
- Refer to the [Changelog](./CHANGELOG.md) for recent updates and fixes.

## Development & Testing

- This project includes a set of BATS unit tests located in the repository (e.g., `test_phpvm.bats`).
- Contributions, bug reports, and feature requests are welcome.

## Maintainers

`phpvm` is maintained by [Jerome Thayananthajothy](https://github.com/Thavarshan).

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.

## Disclaimer

`phpvm` is provided as-is without any warranties. Use it at your own risk.

```
