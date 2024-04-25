#!/usr/bin/env bash

# Ensure the script is run with root or sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

set -euo pipefail
$current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Uninstall doxtend
echo "Uninstalling doxtend..."

if grep -q "#doxtend" /usr/local/bin/docker; then
    printf "Removing docker wrapper..."
    rm -rf /usr/local/bin/docker
    printf "done. \n"
fi

printf "Removing doxtend folder..."
rm -rf $current_dir
printf "done. \nReseting hash..."
hash -r
printf "done. \nUninstall complete.\n"

# We try it even if it doesn't always work
hash -r