#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

# Gather container info
containers=()
while IFS='|' read -r name image status; do
    containers+=("$name|$image|$status")
done < <(docker ps -a --format "{{.Names}}|{{.Image}}|{{.Status}}")

if [ ${#containers[@]} -eq 0 ]; then
    print_box "$(print_colored "$WARNING_COLOR" "No containers found.")"
    exit 0
fi

# Calculate max widths (excluding color codes)
max_name=4  # 'Name'
max_image=5 # 'Image'
max_status=6 # 'Status'
for entry in "${containers[@]}"; do
    IFS='|' read -r name image status <<< "$entry"
    [ ${#name} -gt $max_name ] && max_name=${#name}
    [ ${#image} -gt $max_image ] && max_image=${#image}
    [ ${#status} -gt $max_status ] && max_status=${#status}
done

# Header
header="$(print_colored "$MENU_COLOR" "$(printf '%-*s | %-*s | %-*s' $max_name 'Name' $max_image 'Image' $max_status 'Status')")"
rows=()
for entry in "${containers[@]}"; do
    IFS='|' read -r name image status <<< "$entry"
    rows+=("$(print_colored "$INFO_COLOR" "$(printf '%-*s' $max_name "$name")") | $(print_colored "$SUCCESS_COLOR" "$(printf '%-*s' $max_image "$image")") | $(print_colored "$MENU_COLOR" "$(printf '%-*s' $max_status "$status")")")
done

print_box "$header" "${rows[@]}" 