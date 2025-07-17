#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

# Example images to pull
images=("hello-world:latest" "busybox:latest" "alpine:3.18" "debian:bullseye-slim")

for image in "${images[@]}"; do
    if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^$image$"; then
        print_box "$(print_colored "$INFO_COLOR" "Pulling image: $image ...")"
        docker pull "$image"
        if [ $? -eq 0 ]; then
            print_box "$(print_colored "$SUCCESS_COLOR" "Successfully pulled: $image")"
        else
            print_box "$(print_colored "$ERROR_COLOR" "Failed to pull: $image")"
        fi
    else
        print_box "$(print_colored "$WARNING_COLOR" "Image '$image' already exists. Skipping.")"
    fi
done

print_box "$(print_colored "$INFO_COLOR" "Example images pulled: ${images[*]}")" 