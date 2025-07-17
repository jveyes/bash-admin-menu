#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

# Create example volumes
volumes=("app_data" "db_data" "config_data" "logs_data")

for volume in "${volumes[@]}"; do
    if ! docker volume ls --format '{{.Name}}' | grep -q "^$volume$"; then
        docker volume create "$volume"
        print_box "$(print_colored "$SUCCESS_COLOR" "Created volume: $volume")"
    else
        print_box "$(print_colored "$WARNING_COLOR" "Volume '$volume' already exists. Skipping.")"
    fi
done

print_box "$(print_colored "$INFO_COLOR" "Example volumes created: ${volumes[*]}")" 