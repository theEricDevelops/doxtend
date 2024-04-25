#!/usr/bin/env bash
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
    echo "jq could not be found. Attempting to install..."
    sudo apt-get install -y jq || sudo yum install -y jq || {
        echo "Please install jq before proceeding."
        echo "On Ubuntu/Debian: sudo apt-get install jq"
        echo "On CentOS: sudo yum install jq"
        echo "On Windows or MacOS: https://stedolan.github.io/jq/download/"
        exit 1
    }
fi

# Installation directory setup
setup_directory() {
    sudo mkdir -p "$INSTALL_DIR" || { echo "Failed to create installation directory"; exit 1; }
    sudo cp -r "$script_dir"/src/* "$INSTALL_DIR"
    sudo chmod +x "$INSTALL_DIR"/*
    sed -i "s|run-install.sh|$INSTALL_DIR/docker-upgrade.sh|" $script_dir/src/docker
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