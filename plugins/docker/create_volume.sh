#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

echo
read -p "Enter new volume name: " vol_name
if [ -z "$vol_name" ]; then
    print_box "$(print_colored "$ERROR_COLOR" "Volume name is required.")"
    exit 1
fi

if docker volume ls --format '{{.Name}}' | grep -q "^$vol_name$"; then
    print_box "$(print_colored "$WARNING_COLOR" "Volume '$vol_name' already exists.")"
    exit 0
fi

if docker volume create "$vol_name"; then
    print_box "$(print_colored "$SUCCESS_COLOR" "Successfully created volume: $vol_name")"
else
    print_box "$(print_colored "$ERROR_COLOR" "Failed to create volume: $vol_name")"
fi 