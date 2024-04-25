#!/usr/bin/env bash

# Initialization at the start of the file
_initialize_successfully_loaded=0

# Function to check for jq
jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq could not be found. Please install jq before proceeding."
        echo "On Ubuntu/Debian: sudo apt-get install jq"
        echo "On CentOS: sudo yum install jq"
        echo "On Windows or MacOS: https://stedolan.github.io/jq/download/"
    else 
        echo "jq is installed."
    fi
}

# Function to find the Docker executable path
docker_path() {
    # Try to get Docker path from .env or default locations
    local paths=("$DOCKER_PATH" "/usr/bin/docker" "/usr/local/bin/docker")
    local path_found=""

    for path in "${paths[@]}"; do
        if [ -x "$path" ]; then
            echo "Found Docker at $path"
            path_found="$path"
            break
        fi
    done

    # If Docker is not found, ask the user to enter the path manually
    while [ -z "$path_found" ]; do
        echo "Please enter the full path to the Docker executable or leave blank to exit:"
        read -r user_path
        if [ -z "$user_path" ]; then
            echo "No path provided. Exiting."
            exit 1
        elif [ -x "$user_path" ]; then
            echo "Using Docker at $user_path"
            path_found="$user_path"
            break
        else
            echo "The specified path does not contain a valid Docker executable."
        fi
    done

    # Update DOCKER_PATH in .env
    if [ -n "$path_found" ]; then
        sed -i "s|DOCKER_PATH=.*|DOCKER_PATH=$path_found|" .env
        export DOCKER_PATH="$path_found"
    fi
}

# Function to check if Docker is installed and accessible
docker_installed() {
    local docker_path="$1"
    if [ -x "$docker_path" ]; then
        echo "Docker is installed at $docker_path."
        return 0  # Docker is installed
    else
        echo "Docker is not installed at $docker_path."
        return 1  # Docker is not installed
    fi
}

# Function to check if a Docker container is up and running properly
is_good_status() {
    local container_name="$1"
    local container_status
    local exit_code

    container_status=$(docker inspect -f '{{.State.Status}}' "$container_name")
    exit_code=$(docker inspect -f '{{.State.ExitCode}}' "$container_name")

    # Check if the container is running and the status starts with 'Up'
    if [[ "$container_status" == "running" && "$exit_code" == "0" ]]; then
        echo "Container $container_name is up and running without errors."
        return 0  # Success
    else
        echo "Container status: $container_status, Exit code: $exit_code"
        return 1  # Failure
    fi
}

# Function to check if the container still exists
container_exists() {
    local container_name="$1"
    if [[ $(docker ps -a --filter "name=^/${container_name}$" --format '{{.Names}}') ]]; then
        return 0  # Container still exists
    else
        return 1  # Container does not exist
    fi
}

# Function to verify if the new name is in use and the old name is not
container_renamed() {
    local old_name="$1"
    local new_name="$2"

    # Check if the new name is active
    if [[ $(docker ps -a --filter "name=^/${new_name}$" --format '{{.Names}}') ]]; then
        echo "Container has been successfully renamed to $new_name."
    else
        echo "Failed to rename container to $new_name. Please check for errors."
        return 1  # Rename failed
    fi

    # Ensure the old name is no longer in use
    if [[ $(docker ps -a --filter "name=^/${old_name}$" --format '{{.Names}}') ]]; then
        echo "Old container name $old_name is still in use. Rename operation may not have been successful."
        return 1  # Old name still exists
    fi

    return 0  # Rename successful and old name not in use
}

# At the end of the file, set the success indicator
_initialize_successfully_loaded=1