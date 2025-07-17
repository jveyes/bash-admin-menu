#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

echo
read -p "Enter path to Dockerfile (or press Enter for current directory): " dockerfile_path
if [ -z "$dockerfile_path" ]; then
    dockerfile_path="."
fi

if [ ! -f "$dockerfile_path/Dockerfile" ] && [ "$dockerfile_path" != "." ]; then
    print_box "$(print_colored "$ERROR_COLOR" "Dockerfile not found at: $dockerfile_path")"
    exit 1
fi

read -p "Enter image name: " image_name
if [ -z "$image_name" ]; then
    print_box "$(print_colored "$ERROR_COLOR" "Image name is required.")"
    exit 1
fi

read -p "Enter tag (default: latest): " tag
if [ -z "$tag" ]; then
    tag="latest"
fi

print_box "$(print_colored "$INFO_COLOR" "Building image: $image_name:$tag from $dockerfile_path ...")"

if docker build -t "$image_name:$tag" "$dockerfile_path"; then
    print_box "$(print_colored "$SUCCESS_COLOR" "Successfully built: $image_name:$tag")"
else
    print_box "$(print_colored "$ERROR_COLOR" "Failed to build image")"
fi 