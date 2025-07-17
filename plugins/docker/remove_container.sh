#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/docker_utils.sh"

containers=($(docker ps -a --filter 'status=exited' --format '{{.Names}}'))

if [ ${#containers[@]} -eq 0 ]; then
    print_box "$(print_colored "$WARNING_COLOR" "No stopped containers to remove.")"
    exit 0
fi

maxlen=0
for c in "${containers[@]}"; do [ ${#c} -gt $maxlen ] && maxlen=${#c}; done
rows=()
for i in "${!containers[@]}"; do
    rows+=("$(print_colored "$INFO_COLOR" "$(printf '%2d. %-*s' $((i+1)) $maxlen "${containers[$i]}")")")
done
print_box "$(print_colored "$MENU_COLOR" "Stopped containers:")" "${rows[@]}"

echo
read -p "Select a container to remove [1-${#containers[@]}]: " idx
if [[ $idx =~ ^[0-9]+$ ]] && [ $idx -ge 1 ] && [ $idx -le ${#containers[@]} ]; then
    cname="${containers[$((idx-1))]}"
    docker rm "$cname"
    print_box "$(print_colored "$SUCCESS_COLOR" "Removed container: $cname")"
else
    print_box "$(print_colored "$ERROR_COLOR" "Invalid selection.")"
fi 