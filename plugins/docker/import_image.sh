#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

echo
read -p "Enter path to tar file: " tar_file
if [ -z "$tar_file" ]; then
    print_box "$(print_colored "$ERROR_COLOR" "Tar file path is required.")"
    exit 1
fi

if [ ! -f "$tar_file" ]; then
    print_box "$(print_colored "$ERROR_COLOR" "File not found: $tar_file")"
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

print_box "$(print_colored "$INFO_COLOR" "Importing image from $tar_file as $image_name:$tag ...")"

if docker load -i "$tar_file" | grep -q "Loaded image"; then
    # Try to tag the loaded image with the specified name
    if docker tag "$(docker images --format "{{.Repository}}:{{.Tag}}" | head -1)" "$image_name:$tag"; then
        print_box "$(print_colored "$SUCCESS_COLOR" "Successfully imported: $image_name:$tag")"
    else
        print_box "$(print_colored "$WARNING_COLOR" "Image imported but tagging failed. Check 'docker images' for loaded image.")"
    fi
else
    print_box "$(print_colored "$ERROR_COLOR" "Failed to import image")"
fi 