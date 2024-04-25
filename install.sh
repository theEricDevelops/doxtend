#!/usr/bin/env bash

# Load or initialize environment variables
if [ -f .env ]; then
    source .env
elif [ -f .env.example ]; then
    cp .env.example .env
    echo "Copied .env.example to .env"
    source .env
else
    echo "Error: No .env file found. Attempting to use defaults."
    VERSION=$(grep "Version:" README.md | awk '{print $2}')
    echo "VERSION=$VERSION" > .env
    echo "INSTALL_DIR=/usr/bin/doxtend" >> .env
    echo "DOCKER_PATH=/usr/bin/docker" >> .env
    source .env
fi

# Determine the directory where this script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the helper functions from doxtend-helpers.sh
source "$script_dir/src/doxtend-helpers.sh"

# Check dependencies
errors=0

if ! docker_installed "$DOCKER_PATH"; then
    echo "Docker is not installed or not in your PATH."
    errors=1
fi

if ! type jq > /dev/null; then
  echo "jq could not be found. Please install jq before proceeding."
  echo "On Ubuntu/Debian: sudo apt-get install jq"
  echo "On CentOS: sudo yum install jq"
  echo "On Windows or MacOS: https://stedolan.github.io/jq/download/"
  errors=1
fi

if [ $errors -eq 1 ]; then
    echo "Please resolve the above errors and re-run the installation script."
    exit 1
fi

# Installation directory setup
setup_directory() {
    mkdir -p "$INSTALL_DIR" || { echo "Failed to create installation directory"; exit 1; }
    cp "$script_dir"/src/* "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR"/*.sh
    cp "$DOCKER_PATH" "$INSTALL_DIR/docker"
    chmod +x "$INSTALL_DIR/docker"
}

# Update PATH in .bashrc
update_path() {
    if ! grep -q "$INSTALL_DIR" ~/.bashrc; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
        echo "PATH updated. Please restart your terminal."
    else
        echo "PATH already includes $INSTALL_DIR"
    fi
}

# Main installation steps
setup_directory
update_path