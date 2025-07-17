#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

echo
read -p "Enter image name to pull (e.g., nginx:latest): " img
if [ -z "$img" ]; then
    print_box "$(print_colored "$ERROR_COLOR" "No image name entered.")"
    exit 1
fi

print_box "$(print_colored "$INFO_COLOR" "Pulling image: $img ...")"
docker pull "$img"
if [ $? -eq 0 ]; then
    print_box "$(print_colored "$SUCCESS_COLOR" "Successfully pulled: $img")"
else
    print_box "$(print_colored "$ERROR_COLOR" "Failed to pull: $img")"
fi 