#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "Copied .env.example to .env"
        source .env
    else
        echo "Error: No .env file found. Attempting to use defaults."
        VERSION=$(grep "Version:" README.md | sed 's/.*: //')
        echo "VERSION=$VERSION" > .env
        echo "INSTALL_DIR=/usr/bin/doxtend" >> .env
        echo "DOCKER_PATH=/usr/bin/docker" >> .env
        source .env
    fi
fi

# Determine the directory where this script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the helper functions from doxtend-helpers.sh
source "$script_dir/src/doxtend-helpers.sh"

# Check dependencies
errors=0

if ! jq_installed; then
    echo "jq is not installed. Please install jq before proceeding."
    errors=1
fi

if ! docker_installed "$DOCKER_PATH"; then
    echo "Docker is not installed or not in your PATH."
    errors=1
fi

if [ $errors -eq 1 ]; then
    echo "Please resolve the above errors and re-run the installation script."
    exit 1
fi

# Function to setup the installation directory
setup_directory() {
    source .env  # Reload environment variables to get the latest changes
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    else
        echo "Installation directory already exists."
    fi

    # Copy all script files
    cp "$script_dir"/src/* "$INSTALL_DIR"

    # Set executable permissions for all scripts
    chmod +x "$INSTALL_DIR"/*.sh

    # Replace the system Docker path with the one specified in .env, if different
    if [ "$DOCKER_PATH" != "/usr/bin/docker" ]; then  # Assuming DOCKER_PATH must be valid to reach here
        cp "$DOCKER_PATH" "$INSTALL_DIR/docker"
    else
        cp "/usr/bin/docker" "$INSTALL_DIR/docker"  # Default path
    fi
    chmod +x "$INSTALL_DIR/docker"
}

# Function to update PATH
update_path() {
    if ! grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" ~/.bashrc; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
        source ~/.bashrc
        echo "Doxtend has been successfully installed and configured. Please restart your terminal."
    else
        echo "PATH already updated in .bashrc. Doxtend is ready to use."
    fi
}

# Main installation steps
setup_directory
update_path