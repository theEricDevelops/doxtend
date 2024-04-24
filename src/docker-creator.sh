#!/bin/bash

# Script to create a docker run command to update a container

# Define the path to your functions file
functions_file="update-docker-functions.sh"

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

# Ensure that a container name is provided
if [[ -z "$1" || "$1" == -* ]]; then
    echo "Error: Container name/id is required."
    usage
    exit 1
fi
CONTAINER="$1"
shift

# Get the JSON formatted inspection data
JSON=$(docker inspect $CONTAINER)
if [ -z "$JSON" ]; then
    echo "Failed to inspect container: $CONTAINER"
    exit 1
fi

# Extract the Docker image name to pull/use
if [ -z "$IMAGE" ]; then
    IMAGE=$(echo $JSON | jq -r '.[0].Config.Image')
fi

# Extract volume bindings and format for docker run
volume_bindings=$(echo $JSON | jq -r '.[0].HostConfig.Binds[] | "-v " + .')

# Extract port bindings and format for docker run
port_bindings=$(echo $JSON | jq -r '.[0].HostConfig.PortBindings | to_entries[] | "-p " + (.key | gsub("/tcp|/udp"; "")) + ":" + (.value[].HostPort)')

# Extract and format the restart policy
restart_policy=$(echo $JSON | jq -r '.[0].HostConfig.RestartPolicy | if .Name == "on-failure" and .MaximumRetryCount > 0 then "--restart=" + .Name + ":" + (.MaximumRetryCount|tostring) else "--restart=" + .Name end')

# Extract networks and format for docker run
networks=$(echo $JSON | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key != "bridge" and .key != "host") | "--network=" + .key')

if [ "$QUIET" = false ]; then
    echo $CONTAINER
    echo "=========================="
    echo "Image:"
    echo "$IMAGE"
    echo "Volume Bindings:"
    echo "$volume_bindings"
    echo "Port Bindings:"
    echo "$port_bindings"
    echo "Restart Policy:"
    echo "$restart_policy"
    echo "Networks:"
    echo "$networks"
    echo "Environment Variables:"
    echo "$ENV_VARS"
    echo "=========================="
fi

# Build the docker run command
docker_run_command="docker run -d --name ${CONTAINER} ${restart_policy} ${networks} ${port_bindings} ${volume_bindings} ${ENV_VARS[@]} $IMAGE"

# Print or execute the docker run command
if [ "$EXEC" = true ]; then
    eval $docker_run_command
else
    echo $docker_run_command
fi