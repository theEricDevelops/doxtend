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

if ! docker_installed; then
    echo "Docker is not installed or not in your PATH."
    errors=1
fi

if [ $errors -eq 1]; then
    echo "Please resolve the above errors and re-run the installation script."
    exit 1
fi

# Function to setup the installation directory
setup_directory() {
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir"
    else
        echo "Installation directory already exists."
    fi

    # Copy all script files
    cp "$script_dir"/src/* "$install_dir"

    # Set executable permissions for all scripts
    chmod +x "$install_dir"/docker
    chmod +x "$install_dir"/*.sh
}

# Function to update PATH
update_path() {
    # Add doxtend directory to the beginning of PATH in .bashrc or .profile
    if grep -q "export PATH=\"$install_dir:\$PATH\"" ~/.bashrc; then
        echo "PATH already updated in .bashrc"
    else
        echo "export PATH=\"$install_dir:\$PATH\"" >> ~/.bashrc
        source ~/.bashrc
    fi
    echo "Doxtend has been successfully installed and configured."
}

# Main installation steps
setup_directory
update_path