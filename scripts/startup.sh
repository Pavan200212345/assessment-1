#!/bin/bash

set -e

CONTAINER_NAME="taskflow-nginx"

echo "Starting TaskFlow application..."

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    exit 1
fi

sudo systemctl enable docker
sudo systemctl start docker

if sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Existing container found."

    if ! sudo docker start "$CONTAINER_NAME"; then
        echo "ERROR: Failed to start container."
        exit 1
    fi
else
    echo "Container does not exist yet."
    echo "Create the container through the deployment workflow first."
    exit 0
fi

echo "Container started successfully."
sudo docker ps