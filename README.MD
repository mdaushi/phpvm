[![PHP Version Manager (phpvm)](./assets/Banner.jpg)](https://github.com/Thavarshan/phpvm)

# PHP Version Manager (phpvm)

[![Version](https://img.shields.io/badge/version-v0.0.1-yellow.svg)](https://github.com/Thavarshan/phpvm/releases)
[![Tests](https://github.com/Thavarshan/phpvm/actions/workflows/test.yml/badge.svg?label=test&branch=main)](https://github.com/Thavarshan/phpvm/actions/workflows/test.yml)
[![Build](https://github.com/Thavarshan/phpvm/actions/workflows/use.yml/badge.svg?label=build&branch=main)](https://github.com/Thavarshan/phpvm/actions/workflows/use.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

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

## Installation

### Install & Update phpvm

To **install** or **update** phpvm, run one of the following commands:

```sh
curl -o- https://raw.githubusercontent.com/Thavarshan/phpvm/main/bin/install.sh | bash
```

```sh
wget -qO- https://raw.githubusercontent.com/Thavarshan/phpvm/main/bin/install.sh | bash
```

This script will download and set up `phpvm` in `~/.phpvm`, adding the following to your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.profile`):

```sh
export PHPVM_DIR="$HOME/.phpvm"
source "$PHPVM_DIR/phpvm"
```

### Verify Installation

Run the following command:

```sh
command -v phpvm
```

If the installation was successful, it should output `phpvm`.

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

Check the active version:

```sh
php -v
```

### Auto-Switching PHP Versions

If a `.phpvmrc` file is present in your project directory, `phpvm` will automatically switch to the specified version:

```sh
echo "8.1" > .phpvmrc
```

Upon entering the project directory, `phpvm` will switch to PHP 8.1 automatically.

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

And remove the following lines from your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```sh
export PHPVM_DIR="$HOME/.phpvm"
source "$PHPVM_DIR/phpvm"
```

## Troubleshooting

If you experience issues with `phpvm`, try the following:

- Ensure your shell profile is sourcing `phpvm`.
- Restart your terminal after installation.
- Make sure Homebrew is installed (for macOS users).
- Check for permission issues when installing PHP versions.

## Maintainers

`phpvm` is maintained by [Jerome Thayananthajothy](https://github.com/Thavarshan).

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.

## Disclaimer

`phpvm` is provided as-is, without any warranties. Use it at your own risk.
