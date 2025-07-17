#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

# Set max widths for each column
max_name=20
max_driver=10
max_mount=40

volumes=()
while IFS='|' read -r name driver mountpoint; do
    # Truncate each field if necessary
    [ ${#name} -gt $max_name ] && name="${name:0:$(($max_name-3))}..."
    [ ${#driver} -gt $max_driver ] && driver="${driver:0:$(($max_driver-3))}..."
    [ ${#mountpoint} -gt $max_mount ] && mountpoint="${mountpoint:0:$(($max_mount-3))}..."
    volumes+=("$name|$driver|$mountpoint")
done < <(docker volume ls --format "{{.Name}}|{{.Driver}}|{{.Mountpoint}}")

if [ ${#volumes[@]} -eq 0 ]; then
    print_box "$(print_colored "$WARNING_COLOR" "No volumes found.")"
    exit 0
fi

header="$(print_colored "$MENU_COLOR" "$(printf '%-*s | %-*s | %-*s' $max_name 'Name' $max_driver 'Driver' $max_mount 'Mountpoint')")"
rows=()
for entry in "${volumes[@]}"; do
    IFS='|' read -r name driver mountpoint <<< "$entry"
    rows+=("$(print_colored "$INFO_COLOR" "$(printf '%-*s' $max_name "$name")") | $(print_colored "$SUCCESS_COLOR" "$(printf '%-*s' $max_driver "$driver")") | $(print_colored "$MENU_COLOR" "$(printf '%-*s' $max_mount "$mountpoint")")")
done

print_box "$header" "${rows[@]}" 