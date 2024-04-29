#!/usr/bin/env bash

# Set the repository URL
REPO_URL="https://github.com/theEricDevelops/doxtend.git"

# Set the temporary directory for cloning
TEMP_DIR="/tmp/doxtend"

# Clone the repository
git clone "$REPO_URL" "$TEMP_DIR"

# Navigate to the repository directory
cd "$TEMP_DIR" || exit

# Run the install.sh script
./install.sh

# Navigate back to the previous directory
cd - || exit

# Remove the temporary directory
rm -rf "$TEMP_DIR"
