#!/usr/bin/env bash

# Script to update a Docker container

# Define the path to your functions file
functions_file="doxtend-helpers.sh"

# Source the functions file
if [ -r "$functions_file" ]; then
    source "$functions_file"
else
    echo "Error: Missing or unreadable required file '$functions_file'"
    exit 1
fi

# Check if the functions were loaded successfully
if [ "${_initialize_successfully_loaded:-0}" -ne 1 ]; then
    echo "Error: Failed to load required functions correctly from '$functions_file'."
    exit 1
fi

# Default values
EXEC=false
IMAGE=""
declare -a ENV_VARS=()
QUIET=false
CONTAINER=""
filtered_args=()

# Usage function to display help
usage() {
    echo "Usage: $0 [options] <container-name>"
    echo ""
    echo "Options:"
    echo "  -e <env_var>     Environment variables to set in the container, can be used multiple times."
    echo "  -i <image>       Docker image to use for the container."
    echo "  -x               Execute the Docker run command instead of printing it."
    echo "  -q               Enable quiet mode to minimize the script output."
    echo "  -h               Display this help and exit."
    echo ""
    echo "Example:"
    echo "  $0 -e KEY=VALUE -i ubuntu:latest -x my_container"
}

# Parse command line arguments
while getopts ":e:i:xqh" opt; do
    case ${opt} in
        e)
            ENV_VARS+=("-e ${OPTARG}")
            ;;
        i)
            IMAGE="${OPTARG}"
            ;;
        x)
            EXEC=true
            ;;
        q)
            QUIET=true
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" 1>&2
            usage
            exit 1
            ;;
        :)
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Parse and filter out the -x option
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -x) # Do not add the -x option to filtered_args
            ;;
        *) # Add all other arguments to filtered_args
            filtered_args+=("$1")
            ;;
    esac
    shift
done

# Ensure that a container name is provided
if [[ -z "${filtered_args[-1]}" || "${filtered_args[-1]}" == -* || ${#filtered_args[@]} -eq 0 ]]; then
    echo "Error: Container name/id is required."
    usage
    exit 1
fi
CONTAINER="${filtered_args[-1]}"

# Pass all arguments to docker-creator.sh and capture the docker run command
docker_run_command=$(bash docker-creator.sh "${filtered_args[@]}" -q | tail -n 1)

# Verify the docker run command contains the image and container name
if [[ "$docker_run_command" == *"docker run"* && "$docker_run_command" == *"--name $CONTAINER"* && "$docker_run_command" == *"-d"* ]]; then
    echo "Valid docker run command captured: $docker_run_command"
else
    echo "Error: No valid docker command created. Exiting..."
    exit 1
fi

# Define the new container name
new_container="${CONTAINER}-new"

# Stop the current container
echo "Stopping current container: $CONTAINER"
docker stop "$CONTAINER"

# Verify the container has stopped
echo "Verifying the original container has stopped..."
stop_check_interval=5
max_checks=12
current_check=0

while [[ $current_check -lt $max_checks ]]; do
    state=$(docker inspect -f '{{.State.Status}}' "$CONTAINER")

    if [[ "$state" == "exited" ]]; then
        echo "Container $CONTAINER has successfully stopped."
        break
    else
        echo "Container $CONTAINER is still $state. Checking again in $stop_check_interval seconds..."
        sleep $stop_check_interval
        ((current_check++))
    fi
done

if [[ "$state" != "exited" ]]; then
    echo "Failed to stop the container $CONTAINER within the expected time."
    exit 1
fi

# Create a new container with '-new' appended to its name
echo "Creating new container: $new_container"
new_docker_run_command=$(echo "$docker_run_command" | sed "s/--name ${CONTAINER}/--name ${new_container}/")
eval "$new_docker_run_command"

# Wait for the new container to be up and running
stop_check_interval=5
max_checks=12
current_check=0

echo "Waiting for new container to start..."
while [[ $current_check -lt $max_checks ]]; do
    # Check if the container is running and the status starts with 'Up'
    if is_good_status "$new_container"; then
        echo "New container is up and running without errors."
        break
    else
        echo "Checking again in ${stop_check_interval} seconds..."
        sleep $stop_check_interval
        ((current_check++))
    fi
done

if [[ $current_check -eq $max_checks ]]; then
    echo "Failed to start the new container within the expected time."
    # Initiate rollback or other error handling...

    exit 1
fi

# Remove the old container safely, assuming it was stopped earlier
echo "Removing old container: $CONTAINER"
docker rm "$CONTAINER"

# Verify removal
if container_exists "$CONTAINER"; then
    echo "Failed to remove the container: $CONTAINER. Please check for errors."
    exit 1
else
    echo "Container $CONTAINER successfully removed."
fi

# Rename the new container to the original name
echo "Renaming new container to original name: $CONTAINER"
docker rename "$new_container" "$CONTAINER"
if ! container_renamed "$new_container" "$CONTAINER"; then
    echo "Container update failed. Please check for errors."
    exit 1    
fi

# Output final confirmation
echo "Update complete. ${CONTAINER} has been updated successfully."
