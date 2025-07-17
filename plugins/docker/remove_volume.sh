#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

volumes=()
while IFS='|' read -r name driver mountpoint; do
    volumes+=("$name|$driver|$mountpoint")
done < <(docker volume ls --format "{{.Name}}|{{.Driver}}|{{.Mountpoint}}")

if [ ${#volumes[@]} -eq 0 ]; then
    print_box "$(print_colored "$WARNING_COLOR" "No volumes to remove.")"
    exit 0
fi

max_name=4
for entry in "${volumes[@]}"; do
    IFS='|' read -r name driver mountpoint <<< "$entry"
    [ ${#name} -gt $max_name ] && max_name=${#name}
done

rows=()
for i in "${!volumes[@]}"; do
    IFS='|' read -r name driver mountpoint <<< "${volumes[$i]}"
    rows+=("$(print_colored "$INFO_COLOR" "$(printf '%2d. %-*s' $((i+1)) $max_name "$name")")")
done
print_box "$(print_colored "$MENU_COLOR" "Available volumes:")" "${rows[@]}"

echo
read -p "Select a volume to remove [1-${#volumes[@]}]: " idx
if [[ $idx =~ ^[0-9]+$ ]] && [ $idx -ge 1 ] && [ $idx -le ${#volumes[@]} ]; then
    IFS='|' read -r name driver mountpoint <<< "${volumes[$((idx-1))]}"
    if docker volume rm "$name"; then
        print_box "$(print_colored "$SUCCESS_COLOR" "Removed volume: $name")"
    else
        print_box "$(print_colored "$ERROR_COLOR" "Failed to remove volume: $name")"
    fi
else
    print_box "$(print_colored "$ERROR_COLOR" "Invalid selection.")"
fi 