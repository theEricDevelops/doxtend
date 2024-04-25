#!/usr/bin/env bash

# Initialization at the start of the file
_initialize_successfully_loaded=0

# Function to find the Docker executable path
function update_docker_path() {
  # Predefined common paths for Docker
  local paths=("$DOCKER_PATH" "/usr/bin/docker" "/usr/local/bin/docker")
  local path_found=""

  # Iterate over possible Docker paths and check if executable
  for path in "${paths[@]}"; do
    if command -v "$path" &> /dev/null; then
      printf "Found Docker at %s\n" "$path"
      path_found="$path"
      break
    fi
  done

  # Prompt the user for manual input if Docker not found
  if [ -z "$path_found" ]; then
    printf "Unable to find Docker in predefined paths. Please enter the full path to the Docker executable:"
    while :; do
      read -e -p "> " user_path
      if [ -z "$user_path" ]; then
        printf "No path provided. Exiting.\n"
        exit 1
      elif command -v "$user_path" &> /dev/null; then
        printf "Using Docker at %s\n" "$user_path"
        path_found="$user_path"
        break
      else
        printf "The specified path does not contain a valid Docker executable. Try again:"
      fi
    done
  fi

  if [ -n "$path_found" ]; then
    # Update DOCKER_PATH in .env and export it
    sed -i "s|^DOCKER_PATH=.*|DOCKER_PATH=$path_found|" .env
    export DOCKER_PATH="$path_found"
  fi
}

function docker_installed() {
  # Ensure DOCKER_PATH is set and executable
  if [ -z "$DOCKER_PATH" ] || [ ! -x "$DOCKER_PATH" ]; then
    printf "DOCKER_PATH is not set or is not executable. Attempting to update path...\n"
    update_docker_path
  fi

  if command -v "$DOCKER_PATH" &> /dev/null; then
    printf "Docker is installed at %s\n" "$DOCKER_PATH"
    sed -i "s|docker-binary|$DOCKER_PATH|" $script_dir/src/docker
  else
    printf "Docker is not installed or not accessible at %s. Please check the installation.\n" "$DOCKER_PATH"
    exit 1
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