#!/usr/bin/env bash

# Ensure the script is run with root or sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

set -euo pipefail

# Determine the directory where this script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load or initialize environment variables
if [ -f .env ]; then
    source .env
else
    echo "No .env file found. Creating one with default values."
    cat > .env <<EOF
${VERSION:-VERSION=$(grep "Version:" $script_dir/README.md | awk '{print $2}' || echo "unknown")}
${INSTALL_DIR:-INSTALL_DIR=/usr/opt/doxtend}
${DOCKER_PATH:-DOCKER_PATH=$(command -v docker || echo 'set-me')}
EOF
    # Set the variables for the script's session
    eval $(grep ^[A-Z] .env)
fi

# Source the helper functions from doxtend-helpers.sh
if [ ! -f "$script_dir/src/doxtend-helpers.sh" ]; then
    echo "doxtend-helpers.sh not found in src directory. Please check your installation files."
    exit 1
fi
source "$script_dir/src/doxtend-helpers.sh"

# Verify Docker installation using helper function
if ! docker_installed; then
    echo "Attempting to set Docker path..."
    update_docker_path
fi

# Recheck after attempting to update path
if [ ! -x "${DOCKER_PATH}" ]; then
    echo "Failed to locate or install Docker. Please install Docker and rerun this script."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq could not be found."
    read -r -e -i "y" -p "Do you want to proceed with attempting to install? [Y/n]: " install_jq
    if [[ "$install_jq" =~ ^[Nn] ]]; then
        echo "Exiting..."
        echo "Please install jq manually and rerun this script."
        echo "On Ubuntu/Debian: sudo apt-get install jq"
        echo "On CentOS: sudo yum install jq"
        echo "On Windows or MacOS: https://stedolan.github.io/jq/download/"
        exit 1
    fi
    apt-get install -y jq || sudo yum install -y jq || {
        echo "Unsuccessful in installing jq. Please install jq manually and rerun this script."
        echo "On Ubuntu/Debian: sudo apt-get install jq"
        echo "On CentOS: sudo yum install jq"
        echo "On Windows or MacOS: https://stedolan.github.io/jq/download/"
        exit 1
    }
fi

# Installation directory setup
setup_directory() {
    # Replace the placeholders with the actual paths
    sed -i "s|install_location|$INSTALL_DIR|" $script_dir/src/docker
    sed -i "s|doxtend-helpers.sh|$INSTALL_DIR/doxtend-helpers.sh|" $script_dir/src/docker-upgrade.sh
    sed -i "s|docker-creator.sh|$INSTALL_DIR/docker-creator.sh|" $script_dir/src/docker-upgrade.sh
    # Create the installation directory
    mkdir -p "$INSTALL_DIR" || { echo "Failed to create installation directory"; exit 1; }
    # Copy the script files to the installation directory
    cp -r "$script_dir"/src/*.sh "$INSTALL_DIR"
    # Make the scripts executable
    chmod +x "$INSTALL_DIR"/*.sh

    # Copy docker executable script to a folder in PATH before /usr/bin
    cp -r "$script_dir"/src/docker /usr/local/bin/docker || {
        echo "Failed to copy $INSTALL_DIR/src/docker to /usr/local/bin. Please copy it manually."
        exit 1
    }
    
    # We try it even though it doesn't always work coming from us
    hash -r

    printf "Installation complete. Scripts copied to %s and docker executable copied to /usr/local/bin\n" "$INSTALL_DIR"
    printf "You may need to restart your shell or run 'hash -r' to recognize the new command.\n"
    exit 0
}

# Main installation steps
setup_directory